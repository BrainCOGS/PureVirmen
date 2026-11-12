function tests = testDiskLoggerShutdown
% No hardware required. Run: runtests('testDiskLoggerShutdown').
tests = functiontests(localfunctions);
end

function testPendingFramesFinishBeforeDelete(testCase)
originalPath = path;
cleanup = onCleanup(@() path(originalPath)); %#ok<NASGU>
here = fileparts(mfilename('fullpath'));
addpath(fileparts(here), fullfile(here, 'fixtures'));
state = CameraDeletionState;
cam = PendingDiskCamera(state);
vr = stopVideoAcquisition(struct('v', cam));
verifyEmpty(testCase, vr.v);
verifyTrue(testCase, state.Deleted);
verifyFalse(testCase, state.LostFrames);
end
