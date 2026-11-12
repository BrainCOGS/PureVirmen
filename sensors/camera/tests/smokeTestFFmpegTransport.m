function smokeTestFFmpegTransport()
%SMOKETESTFFMPEGTRANSPORT Validate the ffmpeg frame transport without hardware.
%
%   Drives the REAL pushFramesToFFmpeg through a REAL ffmpeg subprocess using a
%   mocked camera (FakeImaqCamera) producing synthetic frames. Confirms:
%     1. frames actually reach ffmpeg and a non-empty .mp4 is produced;
%     2. closing stdin finalizes a readable file (VideoReader can open it);
%     3. byte ordering is correct — an asymmetric marker pixel written at
%        (row, col) reads back at (row, col), NOT transposed.
%
%   Requires ffmpeg on PATH. No Image Acquisition Toolbox or camera needed.
%   Uses libx264 -crf 18 (visually lossless, standard High profile). NOTE:
%   -crf 0 produces a "High 4:4:4 Predictive" profile that MATLAB's bundled
%   VideoReader cannot decode, so we avoid it here; crf 18 is far more than
%   enough to locate a single 255-valued marker pixel.
%
%   Errors (with a clear message) on any failed assertion; prints PASS lines
%   otherwise.

here = fileparts(mfilename('fullpath'));
addpath(fileparts(here));   % so pushFramesToFFmpeg.m is on the path

% --- ffmpeg availability ---
[st, ~] = system('ffmpeg -version');
assert(st == 0, ['ffmpeg not found on PATH; cannot run smoke test. ' ...
    'Install it (macOS: "brew install ffmpeg"; Linux: "apt install ffmpeg"; ' ...
    'Windows: add ffmpeg''s bin folder to PATH) and retry.']);

% --- synthetic frames: distinct marker per frame at asymmetric coordinates ---
width  = 64;
height = 48;                 % H ~= W so a transpose would change dimensions too
nFrames = 10;
markerRow = 11;             % row ~= col on purpose: catches a transpose bug
markerCol = 37;

frames = zeros(height, width, 1, nFrames, 'uint8');
for k = 1:nFrames
    f = zeros(height, width, 'uint8');
    f(markerRow, markerCol) = 255;   % bright marker
    f(1, 1) = uint8(k * 10);          % per-frame tag in a corner
    frames(:, :, 1, k) = f;
end

cam = FakeImaqCamera(frames);

% --- build the SAME ffmpeg command the production code builds ---
outFile = [tempname '.mp4'];
fps = 30;
cmdParts = { 'ffmpeg', '-y', ...
    '-f', 'rawvideo', '-pix_fmt', 'gray', ...
    '-s', sprintf('%dx%d', width, height), '-r', num2str(fps), ...
    '-i', 'pipe:0', ...
    '-c:v', 'libx264', '-preset', 'fast', '-crf', '18', ...  % visually lossless
    '-pix_fmt', 'yuv420p', outFile };

pb = java.lang.ProcessBuilder(cmdParts);
pb.redirectErrorStream(true);
proc = pb.start();
stdin = proc.getOutputStream();

% Drain ffmpeg output so it can't deadlock on a full pipe.
reader = java.io.BufferedReader(java.io.InputStreamReader(proc.getInputStream()));

% --- stream frames through the REAL transport function ---
pushFramesToFFmpeg(cam, stdin, width, height);

% --- finalize exactly like stopVideoAcquisition does ---
stdin.flush();
stdin.close();
drainQuietly(reader);
proc.waitFor();

cleanupReader = onCleanup(@() delete(outFile));

% --- assertion 1: file exists and is non-empty ---
info = dir(outFile);
assert(~isempty(info) && info.bytes > 0, ...
    'ffmpeg produced no output file (transport failed).');
fprintf('PASS: ffmpeg produced a non-empty file (%d bytes)\n', info.bytes);

% --- assertion 2: file is a readable, finalized mp4 ---
vr = VideoReader(outFile); %#ok<TNMLP>
assert(vr.NumFrames >= 1, 'Output has no frames.');
fprintf('PASS: file is readable, %d frames, %dx%d\n', ...
    vr.NumFrames, vr.Width, vr.Height);

% --- assertion 3: dimensions preserved (no transpose at the container level) ---
assert(vr.Width == width && vr.Height == height, ...
    'Frame dimensions changed: expected %dx%d, got %dx%d (transpose bug).', ...
    width, height, vr.Width, vr.Height);
fprintf('PASS: dimensions preserved (%dx%d)\n', vr.Width, vr.Height);

% --- assertion 4: marker pixel is at (row, col), not transposed ---
firstFrame = read(vr, 1);
gray = firstFrame(:, :, 1);            % luminance channel

[~, idx] = max(gray(:));
[gotRow, gotCol] = ind2sub(size(gray), idx);

% Lossy-codec safety: even at crf 0, allow the brightest pixel within a small
% neighborhood of the intended marker (chroma subsampling can smear by ~1px).
assert(abs(gotRow - markerRow) <= 1 && abs(gotCol - markerCol) <= 1, ...
    ['Marker pixel misplaced: wrote (%d,%d), read brightest at (%d,%d). ', ...
     'A swap of row/col here indicates a frame-transpose / byte-order bug.'], ...
    markerRow, markerCol, gotRow, gotCol);
fprintf('PASS: marker at (%d,%d) read back at (%d,%d) -- byte order correct\n', ...
    markerRow, markerCol, gotRow, gotCol);

fprintf('\nALL CHECKS PASSED\n');

end

% -------------------------------------------------------------------------

function drainQuietly(reader)
try
    while reader.ready()
        if isempty(reader.readLine()); break; end
    end
catch
end
end
