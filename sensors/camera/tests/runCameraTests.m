function runCameraTests()
%RUNCAMERATESTS Run all hardware-free camera tests; exit(1) on any failure.
%
%   Intended for headless / CI use:
%
%       matlab -batch "addpath('sensors/camera/tests'); runCameraTests"
%
%   Prints a PASS/FAIL line per test and a final summary. Calls exit(1) if any
%   test fails so a CI job reflects the result, and exit(0) on success.

here = fileparts(mfilename('fullpath'));
addpath(here);
addpath(fileparts(here));   % sensors/camera (the code under test)

tests = { @smokeTestFFmpegTransport };

nFail = 0;
for i = 1:numel(tests)
    name = func2str(tests{i});
    fprintf('\n==== %s ====\n', name);
    try
        tests{i}();
        fprintf('---- %s: PASS ----\n', name);
    catch err
        nFail = nFail + 1;
        fprintf(2, '---- %s: FAIL ----\n%s\n', name, getReport(err));
    end
end

fprintf('\n==== %d/%d tests passed ====\n', numel(tests) - nFail, numel(tests));

if nFail > 0
    exit(1);
end
% In -batch mode, return normally so MATLAB exits 0.
end
