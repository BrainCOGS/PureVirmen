function pushFramesToFFmpeg(cam, stdin, width, height, logfile) %#ok<INUSL>
%PUSHFRAMESTOFFMPEG Drain buffered camera frames to an ffmpeg stdin stream.
%
%   pushFramesToFFmpeg(cam, stdin, width, height)
%   pushFramesToFFmpeg(cam, stdin, width, height, logfile)
%
%   Used as the FramesAcquiredFcn callback for the ffmpeg recording path
%   (see startVideoAcquisition) and called once more at shutdown to flush
%   the final buffered frames (see stopVideoAcquisition).
%
%   Inputs:
%     cam           - videoinput object currently acquiring Mono8 frames
%     stdin         - Java OutputStream connected to ffmpeg's stdin
%     width, height - frame dimensions (unused; kept for call-site clarity)
%     logfile       - (optional) ffmpeg log path, named in the warning if the
%                     write fails
%
%   getdata returns frames as height x width x 1 x N (uint8, column-major).
%   ffmpeg's rawvideo 'gray' format expects each frame in row-major order, so
%   rows and columns are swapped before serialising. Frames are written one
%   at a time to avoid making another full copy of the acquisition buffer.
%
%   ffmpeg's output goes to a log file, not a pipe, so this blocking write
%   cannot deadlock against an undrained stderr. If ffmpeg has exited, the
%   write fails; that is reported as a warning (once per stream) and
%   stopVideoAcquisition reports ffmpeg's exit code and log.

if nargin < 5
    logfile = '';
end

try
    nAvail = cam.FramesAvailable;
    if nAvail < 1
        return;
    end
    frames = getdata(cam, nAvail);                        % H x W x 1 x N uint8
    frames = reshape(frames, size(frames, 1), size(frames, 2), []);
    % Swap rows/cols so column-major (:) yields row-major bytes per frame.
    for k = 1:size(frames, 3)
        rowMajor = frames(:, :, k)';
        stdin.write(typecast(rowMajor(:), 'int8'));
    end
    stdin.flush();
catch err
    % A broken pipe means ffmpeg died. Don't crash the experiment loop from
    % inside a callback, but don't repeat the warning on every callback.
    if firstFailure(stdin)
        if isempty(logfile)
            where = '';
        else
            where = sprintf(' See %s.', logfile);
        end
        warning('PureVirmen:ffmpegWriteFailed', ...
            'Failed writing frames to ffmpeg; the recording is incomplete.%s\n%s', ...
            where, err.message);
    end
end

end

% -------------------------------------------------------------------------

function tf = firstFailure(stdin)
persistent failed
if isempty(failed)
    failed = {};
end
tf = true;
for i = 1:numel(failed)
    try
        if failed{i} == stdin   % Java object identity
            tf = false;
            return;
        end
    catch
    end
end
failed{end+1} = stdin;
if numel(failed) > 16
    failed = failed(end-15:end);
end
end
