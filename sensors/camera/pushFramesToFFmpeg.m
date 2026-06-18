function pushFramesToFFmpeg(cam, stdin, width, height) %#ok<INUSD>
%PUSHFRAMESTOFFMPEG Drain buffered camera frames to an ffmpeg stdin stream.
%
%   pushFramesToFFmpeg(cam, stdin, width, height)
%
%   Used as the FramesAcquiredFcn callback for the ffmpeg recording path
%   (see startVideoAcquisition) and called once more at shutdown to flush
%   the final buffered frames (see stopVideoAcquisition).
%
%   Inputs:
%     cam           - videoinput object currently acquiring Mono8 frames
%     stdin         - Java OutputStream connected to ffmpeg's stdin
%     width, height - frame dimensions (unused; kept for call-site clarity)
%
%   getdata returns frames as height x width x 1 x N (uint8, column-major).
%   ffmpeg's rawvideo 'gray' format expects each frame in row-major order, so
%   we transpose rows<->cols before serialising. Frames are written one at a
%   time to keep memory flat regardless of how many were buffered.

try
    nAvail = cam.FramesAvailable;
    if nAvail < 1
        return;
    end
    frames = getdata(cam, nAvail);      % H x W x 1 x nAvail, uint8
    frames = squeeze(frames);           % H x W x nAvail (or H x W if nAvail==1)
    for k = 1:size(frames, 3)
        % Transpose so column-major (:) serialisation yields row-major bytes,
        % which is the layout ffmpeg's rawvideo 'gray' input expects.
        frameRowMajor = frames(:, :, k)';
        stdin.write(typecast(frameRowMajor(:), 'int8'));
    end
    stdin.flush();
catch err
    % A broken pipe means ffmpeg died; surface it so the rig operator knows
    % the recording stopped, but don't crash the experiment loop.
    warning('PureVirmen:ffmpegWriteFailed', ...
        'Failed writing frame to ffmpeg (recording may be incomplete): %s', ...
        err.message);
end

end
