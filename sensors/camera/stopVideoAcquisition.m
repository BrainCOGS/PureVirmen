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
%   returning, so the output file is complete when this returns.
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
    % ffmpeg path: stop the camera first (no more frames will be produced),
    % flush any frames still buffered, then close ffmpeg's stdin. Closing the
    % stream signals EOF, which makes ffmpeg finalize and close the .mp4.
    if isfield(vr.v, 'cam') && ~isempty(vr.v.cam) && isvalid(vr.v.cam)
        stop(vr.v.cam);
        % Drain whatever remained in the IMAQ buffer at stop time.
        try
            if vr.v.cam.FramesAvailable > 0
                pushFramesToFFmpeg(vr.v.cam, vr.v.stdin, vr.v.width, vr.v.height);
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

    % Wait for ffmpeg to flush and exit so the file is complete on return.
    if isfield(vr.v, 'proc') && ~isempty(vr.v.proc)
        try
            vr.v.proc.waitFor();
        catch
        end
    end

    % Tear down the log-drain timer.
    if isfield(vr.v, 'drainTimer') && ~isempty(vr.v.drainTimer) && isvalid(vr.v.drainTimer)
        stop(vr.v.drainTimer);
        delete(vr.v.drainTimer);
    end
else
    % VideoWriter path
    stop(vr.v);
    delete(vr.v);
end

vr.v = [];

end
