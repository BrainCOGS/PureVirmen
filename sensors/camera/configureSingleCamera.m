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
%     Before recording, the selected encoder is preflighted: synthetic frames
%     at the camera's resolution and frame rate go through a real ffmpeg
%     process with the recording's options. If an NVENC encoder fails (for
%     example, a driver older than the ffmpeg build needs), the session
%     records with CPU libx264 and warns PureVirmen:ffmpegEncoderFallback with
%     ffmpeg's diagnostic. If no encoder works, this errors with
%     PureVirmen:ffmpegPreflightFailed before acquisition starts. The encoder
%     never changes once recording has started.
%
%     ffmpeg's output (preflights included) goes to <name>.ffmpeg.log next to
%     the video. Struct fields of interest: filename, logfile, encoder (the
%     one used), requestedEncoder, encoderFallback, preflight (results).
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
% Check ffmpeg availability. Resolve the absolute path so the Java
% subprocess launches the same binary system() finds.
ffmpegExe = findFFmpeg();
if isempty(ffmpegExe)
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

vidInfo = cam.VideoResolution;       % [width height]
width   = vidInfo(1);
height  = vidInfo(2);
fps     = RigParameters.video_acquisition_rate;

% Replace .mj2 extension with .mp4 if caller passed the wrong extension.
% ffmpeg's combined stdout/stderr goes to an adjacent .ffmpeg.log file.
[fdir, fname, ~] = fileparts(video_filename);
mp4_filename = fullfile(fdir, [fname '.mp4']);
logfile      = fullfile(fdir, [fname '.ffmpeg.log']);

% Choose the encoder now. Falling back mid-recording would change the file's
% encoding silently, so the only fallback is here, before acquisition.
try
    [opts, preflight, fellBack] = selectEncoder(ffmpegExe, RigParameters, ...
        width, height, fps, logfile);
catch err
    delete(cam);
    rethrow(err);
end

cmdParts = buildFFmpegCommand(ffmpegExe, opts, width, height, fps, ...
    'pipe:0', mp4_filename);
appendLog(logfile, sprintf('Recording command:\n  %s\n\n', strjoin(cmdParts, ' ')));

% Launch ffmpeg via Java ProcessBuilder so we get a real handle on its stdin.
% Its output is appended to the log file by the OS, so nothing in MATLAB has
% to drain a pipe while frames are written or while stop waits for exit.
try
    pb = java.lang.ProcessBuilder(cmdParts);
    pb.redirectErrorStream(true);
    pb.redirectOutput(javaMethod('appendTo', 'java.lang.ProcessBuilder$Redirect', ...
        java.io.File(logfile)));
    proc = pb.start();
catch err
    delete(cam);
    error('PureVirmen:ffmpegLaunchFailed', ...
        'Failed to launch ffmpeg.\n  Command: %s\n  Error: %s\n  Log: %s', ...
        strjoin(cmdParts, ' '), err.message, logfile);
end

% Package everything the start/stop functions need. The frame-streaming
% callback is wired up in startVideoAcquisition once acquisition begins.
v = struct();
v.type             = 'ffmpeg';
v.cam              = cam;
v.proc             = proc;
v.stdin            = proc.getOutputStream();   % we write raw frames here
v.filename         = mp4_filename;
v.logfile          = logfile;
v.width            = width;
v.height           = height;
v.cmd              = strjoin(cmdParts, ' ');
v.encoder          = opts.encoder;
v.requestedEncoder = preflight(1).encoder;
v.encoderFallback  = fellBack;
v.preflight        = preflight;

end

% -------------------------------------------------------------------------

function [opts, preflight, fellBack] = selectEncoder(ffmpegExe, RigParameters, ...
        width, height, fps, logfile)
% Preflight the requested encoder. If an NVENC encoder fails, warn with
% ffmpeg's diagnostic and use libx264 instead; if that also fails, or a
% non-NVENC encoder fails, error before the experiment starts.

fid = fopen(logfile, 'w');
if fid < 0
    error('PureVirmen:ffmpegLogFailed', 'Cannot write ffmpeg log file %s.', logfile);
end
fprintf(fid, 'PureVirmen ffmpeg log, %s\nffmpeg: %s\n\n', ...
    datestr(now, 'yyyy-mm-dd HH:MM:SS'), ffmpegExe);
fclose(fid);

opts      = ffmpegEncoderOptions(RigParameters);
preflight = preflightFFmpegEncoder(ffmpegExe, opts, width, height, fps);
logPreflight(logfile, preflight);
fellBack  = false;

if preflight.ok
    return;
end

if ~contains(opts.encoder, 'nvenc')
    error('PureVirmen:ffmpegPreflightFailed', ...
        ['ffmpeg could not encode test frames with encoder ''%s'' at %dx%d, ' ...
         '%g fps. Recording has not started.\n' ...
         'Check RigParameters.ffmpegEncoder, ffmpegPreset, ffmpegCRF and ' ...
         'ffmpegExtraArgs, or set useFFmpeg = false to record with VideoWriter.\n' ...
         'Log: %s\n\nffmpeg output:\n%s'], ...
        opts.encoder, width, height, fps, logfile, preflight.diagnostic);
end

warning('PureVirmen:ffmpegEncoderFallback', ...
    ['GPU encoder ''%s'' failed its preflight, so this session will record ' ...
     'with CPU libx264 instead. Update the NVIDIA driver, or set ' ...
     'RigParameters.ffmpegEncoder = ''libx264'' to skip the GPU attempt.\n' ...
     'Log: %s\n\nffmpeg output:\n%s'], ...
    opts.encoder, logfile, preflight.diagnostic);

opts     = ffmpegEncoderOptions(RigParameters, 'libx264');
fallback = preflightFFmpegEncoder(ffmpegExe, opts, width, height, fps);
logPreflight(logfile, fallback);
preflight = [preflight, fallback];
fellBack  = true;

if ~fallback.ok
    error('PureVirmen:ffmpegPreflightFailed', ...
        ['Neither GPU encoder ''%s'' nor CPU fallback libx264 could encode ' ...
         'test frames at %dx%d, %g fps. Recording has not started.\n' ...
         'Check RigParameters.ffmpegExtraArgs and the ffmpeg build, or set ' ...
         'useFFmpeg = false to record with VideoWriter.\nLog: %s\n\n' ...
         '%s output:\n%s\n\nlibx264 output:\n%s'], ...
        preflight(1).encoder, width, height, fps, logfile, ...
        preflight(1).encoder, preflight(1).diagnostic, fallback.diagnostic);
end

end

% -------------------------------------------------------------------------

function logPreflight(logfile, result)
if result.ok
    status = 'passed';
else
    status = sprintf('FAILED (exit code %g)', result.exitCode);
end
appendLog(logfile, sprintf('Preflight %s: %s\n  %s\n%s\n\n', ...
    result.encoder, status, result.command, result.diagnostic));
end

function appendLog(logfile, text)
fid = fopen(logfile, 'a');
if fid >= 0
    fwrite(fid, text, 'char');
    fclose(fid);
end
end
