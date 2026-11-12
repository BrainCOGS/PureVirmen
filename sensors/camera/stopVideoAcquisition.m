function vr = stopVideoAcquisition(vr, logger)
%STOPVIDEOACQUISITION Stop camera recording and release hardware resources.
%
%   vr = stopVideoAcquisition(vr)
%   vr = stopVideoAcquisition(vr, logger)
%
%   Handles both VideoWriter-based (videoinput object) and ffmpeg-based
%   (struct with type='ffmpeg') camera handles returned by startVideoAcquisition.
%
%   For the ffmpeg path, closing the pipe signals ffmpeg to finalize the
%   output file. This function waits for ffmpeg to flush and exit before
%   returning. A failed encoder raises PureVirmen:ffmpegFailed with its log;
%   an encoder that does not exit within 30 seconds is terminated and reported.
%   The VideoWriter path waits for pending disk frames before deleting the camera.
%
%   Inputs:
%     vr     - ViRMEn runtime struct containing vr.v from startVideoAcquisition
%     logger - (optional) object exposing save_timeElapsedFirstTrial(t).
%              If provided and vr.timeElapsedFirstTrial exists, saves it now.

if nargin < 2
    logger = [];
end

if ~isempty(logger) && isfield(vr, 'timeElapsedFirstTrial')
    logger.save_timeElapsedFirstTrial(vr.timeElapsedFirstTrial);
end

if ~isfield(vr, 'v') || isempty(vr.v)
    return;
end

if isstruct(vr.v) && strcmp(vr.v.type, 'ffmpeg')
    v = vr.v;
    cleanup = onCleanup(@() releaseFFmpeg(v)); %#ok<NASGU>
    % ffmpeg path: stop the camera first (no more frames will be produced),
    % flush any frames still buffered, then close ffmpeg's stdin. Closing the
    % stream signals EOF, which makes ffmpeg finalize and close the .mp4.
    if isfield(vr.v, 'cam') && ~isempty(vr.v.cam) && isvalid(vr.v.cam)
        stop(vr.v.cam);
        % Drain whatever remained in the IMAQ buffer at stop time.
        try
            if vr.v.cam.FramesAvailable > 0
                logfile = '';
                if isfield(vr.v, 'logfile'), logfile = vr.v.logfile; end
                pushFramesToFFmpeg(vr.v.cam, vr.v.stdin, vr.v.width, vr.v.height, logfile);
            end
        catch
            % best effort; proceed to finalize regardless
        end
        delete(vr.v.cam);
    end

    if isfield(vr.v, 'stdin') && ~isempty(vr.v.stdin)
        try
            vr.v.stdin.flush();
            vr.v.stdin.close();          % EOF -> ffmpeg finalizes the file
        catch
        end
    end

    % A timed wait avoids hanging experiment termination on a stuck encoder.
    % Output is redirected to v.logfile at launch, so no MATLAB timer needs
    % to run while Java is waiting or writing frames.
    if isfield(v, 'proc') && ~isempty(v.proc)
        seconds = java.util.concurrent.TimeUnit.SECONDS;
        if ~v.proc.waitFor(int64(30), seconds)
            v.proc.destroyForcibly();
            error('PureVirmen:ffmpegShutdownTimeout', ...
                'FFmpeg did not finish within 30 seconds; recording may be incomplete.\n%s', ...
                encoderDiagnostics(v));
        end
        if v.proc.exitValue() ~= 0
            error('PureVirmen:ffmpegFailed', ...
                'FFmpeg exited with code %d; recording is incomplete.\n%s', ...
                v.proc.exitValue(), encoderDiagnostics(v));
        end
    end

    % Tear down the log-drain timer.
    if isfield(vr.v, 'drainTimer') && ~isempty(vr.v.drainTimer) && isvalid(vr.v.drainTimer)
        stop(vr.v.drainTimer);
        delete(vr.v.drainTimer);
    end
else
    % stop ends acquisition before asynchronous disk writing has necessarily
    % finished. Deleting earlier discards frames still queued for the logger.
    camera = vr.v;
    cleanup = onCleanup(@() deleteIfValid(camera)); %#ok<NASGU>
    stop(camera);
    shutdownStart = tic;
    while camera.DiskLoggerFrameCount < camera.FramesAcquired
        if toc(shutdownStart) > 30
            error('PureVirmen:diskLoggerShutdownTimeout', ...
                'Disk logging did not finish within 30 seconds (%d of %d frames written).', ...
                camera.DiskLoggerFrameCount, camera.FramesAcquired);
        end
        pause(0.05);
    end
end

vr.v = [];

end

function text = encoderDiagnostics(v)
text = '';
if isfield(v, 'logfile') && isfile(v.logfile)
    text = sprintf('FFmpeg log: %s\n%s', v.logfile, fileread(v.logfile));
end
end

function releaseFFmpeg(v)
if isfield(v, 'cam'), deleteIfValid(v.cam); end
if isfield(v, 'stdin') && ~isempty(v.stdin)
    try, v.stdin.close(); catch, end
end
if isfield(v, 'proc') && ~isempty(v.proc)
    try
        if v.proc.isAlive(), v.proc.destroyForcibly(); end
    catch
    end
end
% Also clean up handles created before log-file redirection was introduced.
if isfield(v, 'drainTimer') && ~isempty(v.drainTimer) && isvalid(v.drainTimer)
    stop(v.drainTimer);
    delete(v.drainTimer);
end
end

function deleteIfValid(camera)
if ~isempty(camera) && isvalid(camera), delete(camera); end
end
