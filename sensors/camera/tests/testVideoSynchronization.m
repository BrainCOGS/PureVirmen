function tests = testVideoSynchronization
% Post-processing regressions. Run: runtests('testVideoSynchronization').
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.originalPath = path;
testCase.TestData.root = tempname;
mkdir(testCase.TestData.root);
addpath(fileparts(fileparts(mfilename('fullpath'))));

end

function teardownOnce(testCase)
path(testCase.TestData.originalPath);
rmdir(testCase.TestData.root, 's');
end

function testInitializationOffset(testCase)
log = struct('frameTimes', [0; 1; 2], 'timeElapsedVideoStart', 5, ...
    'timeElapsedFirstTrial', 6, 'iterationTimes', (0:8)');
[frames, behavior] = syncBehaviorVideo(log, '');
verifyEqual(testCase, frames(:, 2), single([NaN; 1; 2]));
verifyEqual(testCase, behavior(:, 1), single((6:14)'));
end

function testNoOverlap(testCase)
log = struct('frameTimes', [0; 1; 2], 'timeElapsedVideoStart', 5, ...
    'timeElapsedFirstTrial', 10, 'iterationTimes', (0:2)');
[frames, behavior] = syncBehaviorVideo(log, '');
verifyEmpty(testCase, frames);
verifyEmpty(testCase, behavior);
log.timeElapsedVideoStart = 20;
[frames, behavior] = syncBehaviorVideo(log, '');
verifyEmpty(testCase, frames);
verifyEmpty(testCase, behavior);
end

function testMissingClockReference(testCase)
log = struct('frameTimes', 0, 'timeElapsedVideoStart', 0, 'iterationTimes', 0);
verifyError(testCase, @() syncBehaviorVideo(log, ''), 'PureVirmen:missingTimingReference');
end

function testEmptyAndSingleTimelines(testCase)
log = struct('frameTimes', 0, 'timeElapsedVideoStart', 0, ...
    'timeElapsedFirstTrial', 0, 'iterationTimes', []);
[frames, behavior] = syncBehaviorVideo(log, '');
verifyEmpty(testCase, frames);
verifyEmpty(testCase, behavior);
log.iterationTimes = 0;
[frames, behavior] = syncBehaviorVideo(log, '');
verifyEqual(testCase, frames, single([0 1]));
verifyEqual(testCase, behavior, single([0 NaN]));
end

function testFileFrameTimes(testCase)
filename = fullfile(testCase.TestData.root, 'timing.avi');
writer = VideoWriter(filename, 'Grayscale AVI');
writer.FrameRate = 30;
open(writer);
writeVideo(writer, zeros(48, 64, 1, 10, 'uint8'));
close(writer);
log = struct('timeElapsedVideoStart', 0, 'timeElapsedFirstTrial', 0, ...
    'iterationTimes', (0:0.01:1)');
[frames, ~] = syncBehaviorVideo(log, filename);
verifyEqual(testCase, frames(:, 1), single((0:9)' / 30), 'AbsTol', single(1e-6));
end


