function tests = testFFmpegRecording
% Virtual camera + real FFmpeg. Run: runtests('testFFmpegRecording').
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.oldPath = path;
testCase.TestData.root = tempname;
mkdir(testCase.TestData.root);
here = fileparts(mfilename('fullpath'));
entries = strsplit(path, pathsep);
imaq = entries(contains(entries, fullfile('toolbox', 'imaq')));
if ~isempty(imaq), rmpath(imaq{:}); end
addpath(fileparts(here), fullfile(here, 'fixtures'), ...
    fullfile(here, 'fixtures', 'private', 'virtualCamera'));
end

function teardownOnce(testCase)
path(testCase.TestData.oldPath);
rmdir(testCase.TestData.root, 's');
end

function testCpuRecordingAndFinalFlush(testCase)
rig = EncoderTestSettings;
filename = fullfile(testCase.TestData.root, 'cpu.mp4');
v = configureSingleCamera(rig, filename);
cleanup = onCleanup(@() release(v)); %#ok<NASGU>
v.cam.FramesAcquiredFcnCount = 5;
v.cam.FramesAcquiredFcn = @(cam, ~) pushFramesToFFmpeg(cam, v.stdin, v.width, v.height);
start(v.cam);
verifyEqual(testCase, v.cam.FramesAvailable, 2);
vr = stopVideoAcquisition(struct('v', v));
verifyEmpty(testCase, vr.v);
reader = VideoReader(filename);
verifyEqual(testCase, [reader.Width reader.Height reader.NumFrames], [64 48 17]);
for k = [1 2 17]
    frame = read(reader, k);
    verifyLessThan(testCase, abs(mean(double(frame(2:4, 2:4, 1)), 'all') - k*12), 6);
    gray = frame(6:end, 6:end, 1);
    [~, i] = max(gray(:));
    [row, col] = ind2sub(size(gray), i);
    verifyLessThanOrEqual(testCase, abs([row col]+5-[11 37]), 1);
end
verifyTrue(testCase, isfile(v.logfile));
end

function testInvalidEncoderFailsBeforeRecording(testCase)
rig = EncoderTestSettings;
rig.ffmpegEncoder = 'purevirmen_invalid_nvenc';
filename = fullfile(testCase.TestData.root, 'invalid.mp4');
verifyError(testCase, @() configureSingleCamera(rig, filename), 'PureVirmen:ffmpegPreflightFailed');
verifyFalse(testCase, isfile(filename));
verifySubstring(testCase, fileread(fullfile(testCase.TestData.root, 'invalid.ffmpeg.log')), ...
    'purevirmen_invalid_nvenc');
end

function testFailedProcessIsReported(testCase)
pb = java.lang.ProcessBuilder({'ffmpeg', '-purevirmen_invalid_option'});
logfile = fullfile(testCase.TestData.root, 'failed.log');
pb.redirectErrorStream(true);
pb.redirectOutput(java.io.File(logfile));
proc = pb.start();
cleanup = onCleanup(@() proc.destroy()); %#ok<NASGU>
v = struct('type', 'ffmpeg', 'proc', proc, 'stdin', proc.getOutputStream(), 'logfile', logfile);
verifyError(testCase, @() stopVideoAcquisition(struct('v', v)), 'PureVirmen:ffmpegFailed');
end

function release(v)
if isvalid(v.cam), delete(v.cam); end
try, v.stdin.close(); catch, end
if v.proc.isAlive(), v.proc.destroyForcibly(); end
end
