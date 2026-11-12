function v = configureSingleCamera(RigParameters, video_filename)
%CONFIGURESINGLECAMERA Configure a FLIR camera for disk-logged recording.
%
%   v = configureSingleCamera(RigParameters, video_filename)
%
%   Two recording paths are supported, selected by RigParameters.useFFmpeg:
%
%   VideoWriter path (default, useFFmpeg = false):
%     Configures a FLIR camera via the GenTL adapter and sets up a VideoWriter
%     (Motion JPEG 2000) disk logger. Returns a videoinput object.
%     Requires: Image Acquisition Toolbox + FLIR Spinnaker GenTL support.
%
%   ffmpeg path (useFFmpeg = true):
%     Configures the FLIR camera via GenTL and pipes raw frames to an ffmpeg
%     subprocess for GPU-accelerated (NVENC) or CPU (libx264) H.264 encoding.
%     Returns a struct instead of a videoinput object; pass it directly to
%     startVideoAcquisition / stopVideoAcquisition which handle both types.
%     Requires: ffmpeg on system PATH.
%     See RigParameters.m.example for encoder configuration.
%     The requested encoder is tested before acquisition. An incompatible
%     GPU/driver fails with diagnostics; choose libx264 explicitly for CPU.
%     FFmpeg output is saved next to the video as <name>.ffmpeg.log.
%
%   Required RigParameters properties:
%     video_acquisition_rate  - frame rate in fps
%     video_gain              - analog gain
%
%   Optional RigParameters properties:
%     video_exposure_time_in_microseconds - exposure; omit to use camera default
%     useFFmpeg               - logical, default false
%     ffmpegEncoder           - 'h264_nvenc' (NVIDIA GPU) or 'libx264' (CPU)
%     ffmpegPreset            - encoder preset string
%     ffmpegBitrate           - target bitrate string for NVENC (e.g. '5M')
%     ffmpegCRF               - quality value for libx264 (0-51)
%     ffmpegExtraArgs         - raw string appended to ffmpeg command

useFFmpeg = isprop(RigParameters, 'useFFmpeg') && RigParameters.useFFmpeg;

if useFFmpeg
    v = configureWithFFmpeg(RigParameters, video_filename);
else
    v = configureWithVideoWriter(RigParameters, video_filename);
end

end

% -------------------------------------------------------------------------

function v = configureWithVideoWriter(RigParameters, video_filename)

imaqreset;
v   = videoinput('gentl', 1, 'Mono8');
src = getselectedsource(v);

src.AcquisitionFrameRateEnable = 'true';
src.AcquisitionFrameRate       = RigParameters.video_acquisition_rate;

if isprop(RigParameters, 'video_exposure_time_in_microseconds') && ...
        RigParameters.video_exposure_time_in_microseconds
    src.ExposureTime = RigParameters.video_exposure_time_in_microseconds;
end

src.Gain = RigParameters.video_gain;

v.FramesPerTrigger = Inf;
v.TriggerRepeat    = Inf;

logfile             = VideoWriter(video_filename, 'Motion JPEG 2000');
logfile.MJ2BitDepth = 8;
logfile.FrameRate   = RigParameters.video_acquisition_rate;

v.LoggingMode = 'disk';
v.DiskLogger  = logfile;

end

% -------------------------------------------------------------------------

function v = configureWithFFmpeg(RigParameters, video_filename)
% Check ffmpeg availability
if ispc
    [status, found] = system('where ffmpeg');
else
    [status, found] = system('command -v ffmpeg');
end
if status ~= 0
    warning('PureVirmen:noFFmpeg', ...
        ['ffmpeg not found on PATH. ' ...
         'Falling back to VideoWriter (Motion JPEG 2000).']);
    v = configureWithVideoWriter(RigParameters, video_filename);
    return;
end

ffmpegExe = strtok(strtrim(found), sprintf('\r\n'));

% Configure the FLIR camera. Frames are NOT written to disk by IMAQ; they are
% buffered in memory and a FramesAcquiredFcn callback (wired up in
% startVideoAcquisition) drains them and streams raw bytes to ffmpeg's stdin.
imaqreset;
cam = videoinput('gentl', 1, 'Mono8');
src = getselectedsource(cam);

src.AcquisitionFrameRateEnable = 'true';
src.AcquisitionFrameRate       = RigParameters.video_acquisition_rate;

if isprop(RigParameters, 'video_exposure_time_in_microseconds') && ...
        RigParameters.video_exposure_time_in_microseconds
    src.ExposureTime = RigParameters.video_exposure_time_in_microseconds;
end

src.Gain = RigParameters.video_gain;

cam.FramesPerTrigger = Inf;
cam.TriggerRepeat    = Inf;
% Buffer frames in memory for the callback to drain (no IMAQ disk logger on
% the ffmpeg path). 'memory' is the IMAQ default but we set it explicitly so
% a recycled/preconfigured object can't leave a stale DiskLogger attached.
cam.LoggingMode = 'memory';

% Build ffmpeg command
vidInfo  = cam.VideoResolution;       % [width height]
width    = vidInfo(1);
height   = vidInfo(2);
fps      = RigParameters.video_acquisition_rate;
encoder  = 'h264_nvenc';
if isprop(RigParameters, 'ffmpegEncoder')
    encoder = RigParameters.ffmpegEncoder;
end

encoderArgs = buildEncoderArgs(RigParameters, encoder);

extraArgs = '';
if isprop(RigParameters, 'ffmpegExtraArgs') && ~isempty(RigParameters.ffmpegExtraArgs)
    extraArgs = RigParameters.ffmpegExtraArgs;
end

% Replace .mj2 extension with .mp4 if caller passed the wrong extension
[fdir, fname, ~] = fileparts(video_filename);
mp4_filename = fullfile(fdir, [fname '.mp4']);

% Camera delivers single-channel Mono8 (-pix_fmt gray on input). Force a
% widely-compatible output pixel format so the .mp4 plays in standard
% players / H.264 decoders that don't accept grayscale streams.
cmdParts = { ffmpegExe, '-hide_banner', '-nostats', '-y', ...
    '-f', 'rawvideo', '-pix_fmt', 'gray', ...
    '-s', sprintf('%dx%d', width, height), '-r', num2str(fps), ...
    '-i', 'pipe:0', ...
    '-c:v', encoder };
cmdParts = [cmdParts, splitArgs(encoderArgs), splitArgs(extraArgs), ...
            {'-pix_fmt', 'yuv420p', mp4_filename}];

% Check the selected encoder before starting acquisition. Use the same
% command/settings for the probe and recording; encoder choice stays explicit.
logfile = fullfile(fdir, [fname '.ffmpeg.log']);
try
    verifyEncoder(cmdParts, width, height, logfile);
    pb = java.lang.ProcessBuilder(cmdParts);
    pb.redirectErrorStream(true);
    % Write output directly to disk: MATLAB timers cannot drain stderr while
    % a blocking Java stdin write or waitFor is running.
    pb.redirectOutput(java.io.File(logfile));
    proc = pb.start();
catch err
    delete(cam);
    rethrow(err);
end
stdin = proc.getOutputStream();

% Package everything the start/stop functions need. The frame-streaming
% callback is wired up in startVideoAcquisition once acquisition begins.
v = struct();
v.type       = 'ffmpeg';
v.cam        = cam;
v.proc       = proc;
v.stdin      = stdin;
v.logfile    = logfile;
v.filename   = mp4_filename;
v.width      = width;
v.height     = height;
v.cmd        = strjoin(cmdParts, ' ');

end

% -------------------------------------------------------------------------

function verifyEncoder(cmdParts, width, height, logfile)
% Encode three frames at the actual resolution with the recording options.
folder = tempname;
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's')); %#ok<NASGU>
rawfile = fullfile(folder, 'frames.gray');
fid = fopen(rawfile, 'w');
if fid < 0, error('PureVirmen:ffmpegProbeFile', 'Cannot write %s.', rawfile); end
for k = 1:3, fwrite(fid, zeros(width, height, 'uint8'), 'uint8'); end
fclose(fid);
probe = cmdParts;
probe{find(strcmp(probe, '-i'), 1) + 1} = rawfile;
probe{end} = fullfile(folder, 'probe.mp4');
pb = java.lang.ProcessBuilder(probe);
pb.redirectErrorStream(true);
pb.redirectOutput(java.io.File(logfile));
proc = pb.start();
processCleanup = onCleanup(@() terminateProcess(proc)); %#ok<NASGU>
proc.getOutputStream().close();
finished = proc.waitFor(int64(30), java.util.concurrent.TimeUnit.SECONDS);
if ~finished
    proc.destroyForcibly();
    proc.waitFor(int64(5), java.util.concurrent.TimeUnit.SECONDS);
end
if ~finished || proc.exitValue() ~= 0
    error('PureVirmen:ffmpegPreflightFailed', ...
        ['FFmpeg encoder check failed; recording has not started. ' ...
         'Check the encoder/driver or set RigParameters.ffmpegEncoder = ''libx264''.\n' ...
         'Log: %s\n%s'], logfile, fileread(logfile));
end
end

function terminateProcess(proc)
if proc.isAlive(), proc.destroyForcibly(); end
end
function parts = splitArgs(argStr)
% Split a whitespace-separated argument string into a cell array, dropping
% empties. ProcessBuilder needs each token as a separate element (no shell
% to do word-splitting for us).
if isempty(argStr)
    parts = {};
    return;
end
parts = strsplit(strtrim(argStr));
parts = parts(~cellfun(@isempty, parts));
end

% -------------------------------------------------------------------------

function args = buildEncoderArgs(RigParameters, encoder)
% Build encoder-specific ffmpeg argument string.
%
%   NVENC (h264_nvenc / hevc_nvenc):
%     Uses ffmpegBitrate and ffmpegPreset.
%     CRF is not supported by NVENC â€” use bitrate control instead.
%
%   libx264 / libx265 (CPU):
%     Uses ffmpegCRF and ffmpegPreset.
%     Bitrate is not set â€” CRF gives constant-quality output.

isNvenc  = contains(encoder, 'nvenc');
isX264   = contains(encoder, 'libx264') || contains(encoder, 'libx265');

preset = 'fast';
if isprop(RigParameters, 'ffmpegPreset') && ~isempty(RigParameters.ffmpegPreset)
    preset = RigParameters.ffmpegPreset;
end

if isNvenc
    % NVENC: bitrate-controlled
    bitrate = '5M';
    if isprop(RigParameters, 'ffmpegBitrate') && ~isempty(RigParameters.ffmpegBitrate)
        bitrate = RigParameters.ffmpegBitrate;
    end
    args = sprintf('-preset %s -b:v %s', preset, bitrate);

elseif isX264
    % libx264/libx265: CRF quality-controlled
    crf = 23;
    if isprop(RigParameters, 'ffmpegCRF') && ~isempty(RigParameters.ffmpegCRF)
        crf = RigParameters.ffmpegCRF;
    end
    args = sprintf('-preset %s -crf %d', preset, crf);

else
    % Unknown encoder â€” pass no extra args; rely on ffmpegExtraArgs if needed
    args = '';
end

end
