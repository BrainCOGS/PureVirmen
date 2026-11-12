function result = preflightFFmpegEncoder(ffmpegExe, opts, width, height, fps, timeoutSeconds)
%PREFLIGHTFFMPEGENCODER Encode synthetic frames with the real recording settings.
%
%   result = preflightFFmpegEncoder(ffmpegExe, opts, width, height, fps)
%   result = preflightFFmpegEncoder(..., timeoutSeconds)   % default 30
%
%   Runs a real ffmpeg subprocess with the same command the recording uses
%   (buildFFmpegCommand), but reading a few synthetic Mono8 frames of the
%   camera's actual resolution from a temporary file. This catches encoders
%   that ffmpeg lists but cannot open, such as NVENC on a driver that is too
%   old, before the experiment starts.
%
%   result fields:
%     ok         - true if ffmpeg exited 0 and wrote a non-empty .mp4
%     encoder    - opts.encoder
%     exitCode   - ffmpeg exit code (NaN if it timed out or did not launch)
%     command    - the preflight command line
%     diagnostic - ffmpeg's combined stdout/stderr, or the launch error

if nargin < 6
    timeoutSeconds = 30;
end

nFrames = 3;
workDir = tempname;
mkdir(workDir);
cleanup = onCleanup(@() removeQuietly(workDir)); %#ok<NASGU>

rawFile = fullfile(workDir, 'preflight.gray');
outFile = fullfile(workDir, 'preflight.mp4');
logFile = fullfile(workDir, 'preflight.log');

% Row-major gray8 frames with some texture so the encoder does real work.
[cols, rows] = meshgrid(0:width-1, 0:height-1);
fid = fopen(rawFile, 'w');
if fid < 0
    error('PureVirmen:ffmpegPreflightFileFailed', ...
        'Cannot create synthetic-frame file %s for the encoder preflight.', rawFile);
end
for k = 1:nFrames
    frame = uint8(mod(rows + cols + 16 * k, 256));
    fwrite(fid, frame', 'uint8');
end
fclose(fid);

cmdParts = buildFFmpegCommand(ffmpegExe, opts, width, height, fps, rawFile, outFile);

result = struct('ok', false, 'encoder', opts.encoder, 'exitCode', NaN, ...
    'command', strjoin(cmdParts, ' '), 'diagnostic', '');

try
    pb = java.lang.ProcessBuilder(cmdParts);
    pb.redirectErrorStream(true);
    pb.redirectOutput(java.io.File(logFile));
    proc = pb.start();
catch err
    result.diagnostic = sprintf('Failed to launch ffmpeg: %s', err.message);
    return;
end
processCleanup = onCleanup(@() terminateIfRunning(proc)); %#ok<NASGU>
proc.getOutputStream().close();   % input comes from rawFile, not stdin

finished = proc.waitFor(int64(timeoutSeconds), java.util.concurrent.TimeUnit.SECONDS);
if ~finished
    proc.destroyForcibly();
    proc.waitFor(int64(5), java.util.concurrent.TimeUnit.SECONDS);
end

if isfile(logFile)
    result.diagnostic = strtrim(fileread(logFile));
end

if ~finished
    result.diagnostic = sprintf('ffmpeg did not finish within %d seconds.\n%s', ...
        timeoutSeconds, result.diagnostic);
    return;
end

result.exitCode = proc.exitValue();
info = dir(outFile);
result.ok = result.exitCode == 0 && ~isempty(info) && info.bytes > 0;
if result.exitCode == 0 && ~result.ok
    result.diagnostic = sprintf('ffmpeg exited 0 but wrote no output.\n%s', ...
        result.diagnostic);
end

end

% -------------------------------------------------------------------------

function removeQuietly(folder)
try
    rmdir(folder, 's');
catch
end
end

function terminateIfRunning(proc)
if proc.isAlive(), proc.destroyForcibly(); end
end
