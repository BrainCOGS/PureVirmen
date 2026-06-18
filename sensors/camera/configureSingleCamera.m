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
[status, ~] = system('ffmpeg -version');
if status ~= 0
    warning('PureVirmen:noFFmpeg', ...
        ['ffmpeg not found on PATH. ' ...
         'Falling back to VideoWriter (Motion JPEG 2000).']);
    v = configureWithVideoWriter(RigParameters, video_filename);
    return;
end

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
cmdParts = { 'ffmpeg', '-y', ...
    '-f', 'rawvideo', '-pix_fmt', 'gray', ...
    '-s', sprintf('%dx%d', width, height), '-r', num2str(fps), ...
    '-i', 'pipe:0', ...
    '-c:v', encoder };
cmdParts = [cmdParts, splitArgs(encoderArgs), splitArgs(extraArgs), ...
            {'-pix_fmt', 'yuv420p', mp4_filename}];

% Launch ffmpeg via Java ProcessBuilder so we get a real handle on its stdin.
% redirectErrorStream keeps stderr from filling the OS pipe buffer (which
% would otherwise deadlock ffmpeg); a drain thread empties it continuously.
try
    pb = java.lang.ProcessBuilder(cmdParts);
    pb.redirectErrorStream(true);
    proc = pb.start();
catch err
    delete(cam);
    error('PureVirmen:ffmpegLaunchFailed', ...
        'Failed to launch ffmpeg.\n  Command: %s\n  Error: %s', ...
        strjoin(cmdParts, ' '), err.message);
end

stdin = proc.getOutputStream();   % we write raw frames here

% Background-drain ffmpeg's merged stdout/stderr so its output buffer never
% fills and stalls encoding. A MATLAB timer polling the reader is portable
% (no custom Java class needed); it stops itself once ffmpeg closes the stream.
logReader = java.io.BufferedReader( ...
    java.io.InputStreamReader(proc.getInputStream()));
drainTimer = timer( ...
    'ExecutionMode', 'fixedSpacing', ...
    'Period',        0.5, ...
    'BusyMode',      'drop', ...
    'TimerFcn',      @(t, ~) drainReader(t, logReader), ...
    'Name',          'ffmpegLogDrain');
start(drainTimer);

% Package everything the start/stop functions need. The frame-streaming
% callback is wired up in startVideoAcquisition once acquisition begins.
v = struct();
v.type       = 'ffmpeg';
v.cam        = cam;
v.proc       = proc;
v.stdin      = stdin;
v.drainTimer = drainTimer;
v.filename   = mp4_filename;
v.width      = width;
v.height     = height;
v.cmd        = strjoin(cmdParts, ' ');

end

% -------------------------------------------------------------------------

function drainReader(t, reader)
% Read and discard all currently-available lines from ffmpeg's output. When
% the stream is closed (ffmpeg exited), readLine returns [] and we stop.
try
    while reader.ready()
        line = reader.readLine();
        if isempty(line)
            stop(t);
            return;
        end
    end
catch
    stop(t);   % stream closed underneath us; nothing more to drain
end
end

% -------------------------------------------------------------------------

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

function drainProcessOutput(proc)
% Continuously read and discard ffmpeg's (merged) stdout/stderr on a Java
% thread so its output buffer never fills and stalls encoding. The thread
% exits on its own when ffmpeg closes the stream at shutdown.
reader = java.io.BufferedReader( ...
    java.io.InputStreamReader(proc.getInputStream()));
runnable = java.lang.Runnable.empty; %#ok<NASGU>
t = java.lang.Thread(DrainRunnable(reader)); %#ok<NASGU>
% DrainRunnable is unavailable as a Java class in base MATLAB, so fall back
% to a timer that polls the reader if the helper class is absent.
% (Kept simple: use a MATLAB timer to drain.)
end

% -------------------------------------------------------------------------

function args = buildEncoderArgs(RigParameters, encoder)
% Build encoder-specific ffmpeg argument string.
%
%   NVENC (h264_nvenc / hevc_nvenc):
%     Uses ffmpegBitrate and ffmpegPreset.
%     CRF is not supported by NVENC — use bitrate control instead.
%
%   libx264 / libx265 (CPU):
%     Uses ffmpegCRF and ffmpegPreset.
%     Bitrate is not set — CRF gives constant-quality output.

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
    % Unknown encoder — pass no extra args; rely on ffmpegExtraArgs if needed
    args = '';
end

end
