function tests = testFFmpegEncoderFallback
%TESTFFMPEGENCODERFALLBACK Encoder preflight and NVENC-to-CPU fallback tests.
%
%   Run the real startVideoAcquisition -> configureSingleCamera -> ffmpeg ->
%   stopVideoAcquisition path with a virtual camera (fixtures/private/virtualCamera)
%   and a generated RigParameters class. Needs ffmpeg with libx264; no camera,
%   GPU or Image Acquisition Toolbox. The toolbox folders are taken off the
%   path for the session so the videoinput double shadows the real class.
%
%   The fallback is forced with an encoder name containing "nvenc" that no
%   ffmpeg build has, so it does not depend on the GPU or driver.
%   testInstalledNvenc also tries the real h264_nvenc and accepts either
%   outcome (NVENC works, or fallback with the driver's diagnostic).
%
%       results = runtests('testFFmpegEncoderFallback')
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
here = fileparts(mfilename('fullpath'));
testCase.TestData.originalPath = path;
testCase.TestData.originalEnvPath = getenv('PATH');
testCase.TestData.root = tempname;
mkdir(testCase.TestData.root);

% WinGet installs ffmpeg in a Links folder that older sessions may lack.
links = fullfile(getenv('LOCALAPPDATA'), 'Microsoft', 'WinGet', 'Links');
if ispc && isfile(fullfile(links, 'ffmpeg.exe'))
    setenv('PATH', [links pathsep getenv('PATH')]);
end

% Class precedence would pick IMAQ's videoinput over the fixture function.
entries = strsplit(path, pathsep);
imaq = entries(contains(entries, fullfile('toolbox', 'imaq')));
if ~isempty(imaq)
    rmpath(imaq{:});
end
addpath(fileparts(here));                                  % sensors/camera
addpath(fullfile(here, 'fixtures', 'private', 'virtualCamera'));

ffmpegExe = findFFmpeg();
assert(~isempty(ffmpegExe), 'ffmpeg is required for the encoder fallback tests.');
testCase.TestData.ffmpegExe = ffmpegExe;
end

function teardownOnce(testCase)
clear('RigParameters');
path(testCase.TestData.originalPath);
setenv('PATH', testCase.TestData.originalEnvPath);
try
    rmdir(testCase.TestData.root, 's');
catch
end
end

function teardown(testCase)
if isfield(testCase.TestData, 'rigDir')
    rmpath(testCase.TestData.rigDir);
    testCase.TestData = rmfield(testCase.TestData, 'rigDir');
end
clear('RigParameters');
end

% -------------------------------------------------------------------------

function testRequestedCpuEncoderRecords(testCase)
writeRig(testCase, 'libx264', '');
vr = verifyWarningFree(testCase, @() startRecording(testCase));
verifyEqual(testCase, vr.v.encoder, 'libx264');
verifyFalse(testCase, vr.v.encoderFallback);
verifyEqual(testCase, vr.videoAcqInfo.video_encoder, 'libx264');
verifyNumElements(testCase, vr.v.preflight, 1);
verifyTrue(testCase, vr.v.preflight.ok);
verifyFalse(testCase, isfield(vr.v, 'drainTimer'));
stopAndVerifyVideo(testCase, vr);
end

function testInvalidNvencFallsBackToCpu(testCase)
encoder = 'purevirmen_invalid_nvenc';
writeRig(testCase, encoder, '');
lastwarn('');
vr = verifyWarning(testCase, @() startRecording(testCase), ...
    'PureVirmen:ffmpegEncoderFallback');
% The warning keeps ffmpeg's own diagnostic, not just "it failed".
verifySubstring(testCase, lastwarn, sprintf('Unknown encoder ''%s''', encoder));
verifySubstring(testCase, lastwarn, vr.v.logfile);

verifyEqual(testCase, vr.v.requestedEncoder, encoder);
verifyEqual(testCase, vr.v.encoder, 'libx264');
verifyTrue(testCase, vr.v.encoderFallback);
verifyTrue(testCase, vr.videoAcqInfo.video_encoder_fallback);
verifyEqual(testCase, [vr.v.preflight.ok], [false true]);
verifySubstring(testCase, vr.v.cmd, '-c:v libx264');

log = fileread(vr.v.logfile);
verifySubstring(testCase, log, sprintf('Unknown encoder ''%s''', encoder));
verifySubstring(testCase, log, 'Preflight libx264: passed');
stopAndVerifyVideo(testCase, vr);
end

function testFailedCpuFallbackErrorsBeforeRecording(testCase)
import matlab.unittest.fixtures.SuppressedWarningsFixture
testCase.applyFixture(SuppressedWarningsFixture('PureVirmen:ffmpegEncoderFallback'));
% The NVENC attempt fails on the encoder name; the libx264 attempt then
% rejects the profile from ffmpegExtraArgs.
writeRig(testCase, 'purevirmen_invalid_nvenc', '-profile:v purevirmen_bad_profile');
err = verifyErrorWithMessage(testCase, @() startRecording(testCase), ...
    'PureVirmen:ffmpegPreflightFailed');
verifySubstring(testCase, err.message, 'Recording has not started');
verifySubstring(testCase, err.message, 'Unknown encoder');        % NVENC diagnostic
verifySubstring(testCase, err.message, 'purevirmen_bad_profile'); % CPU diagnostic
verifyEmpty(testCase, findVideos(testCase));
end

function testFailedCpuEncoderErrorsWithoutFallback(testCase)
writeRig(testCase, 'libx264', '-purevirmen_bad_option 1');
lastwarn('');
err = verifyErrorWithMessage(testCase, @() startRecording(testCase), ...
    'PureVirmen:ffmpegPreflightFailed');
verifySubstring(testCase, err.message, 'purevirmen_bad_option');
[~, warnId] = lastwarn;
verifyNotEqual(testCase, warnId, 'PureVirmen:ffmpegEncoderFallback');
verifyEmpty(testCase, findVideos(testCase));
end

function testInstalledNvenc(testCase)
% Live check of this machine's GPU. Either outcome is correct; what must not
% happen is a failed NVENC preflight without fallback, or a broken video.
writeRig(testCase, 'h264_nvenc', '');
lastwarn('');
vr = startRecording(testCase);
[~, warnId] = lastwarn;
if vr.v.preflight(1).ok
    verifyEqual(testCase, vr.v.encoder, 'h264_nvenc');
    verifyFalse(testCase, vr.v.encoderFallback);
    fprintf('h264_nvenc works on this machine.\n');
else
    verifyEqual(testCase, warnId, 'PureVirmen:ffmpegEncoderFallback');
    verifyEqual(testCase, vr.v.encoder, 'libx264');
    verifyNotEmpty(testCase, vr.v.preflight(1).diagnostic);
    fprintf('h264_nvenc failed its preflight, recorded with libx264:\n%s\n', ...
        vr.v.preflight(1).diagnostic);
end
stopAndVerifyVideo(testCase, vr);
end

% -------------------------------------------------------------------------

function err = verifyErrorWithMessage(testCase, fcn, id)
err = [];
try
    fcn();
catch err
end
verifyNotEmpty(testCase, err, sprintf('Expected error %s.', id));
if ~isempty(err)
    verifyEqual(testCase, err.identifier, id, err.message);
end
end

function writeRig(testCase, encoder, extraArgs)
% A fresh folder per test, so MATLAB loads a fresh RigParameters class.
[~, name] = fileparts(tempname);
rigDir = fullfile(testCase.TestData.root, ['rig_' name]);
mkdir(rigDir);
videoDir = fullfile(testCase.TestData.root, ['videos_' name]);
lines = {
    'classdef RigParameters'
    '    properties (Constant)'
    sprintf('        video_parent_path = ''%s''', strrep(videoDir, '''', ''''''))
    '        video_ext = ''.mj2'''
    '        video_acquisition_rate = 30'
    '        video_gain = 0'
    '        video_exposure_time_in_microseconds = 5000'
    '        useFFmpeg = true'
    sprintf('        ffmpegEncoder = ''%s''', encoder)
    '        ffmpegPreset = ''fast'''
    '        ffmpegBitrate = ''5M'''
    '        ffmpegCRF = 18'
    sprintf('        ffmpegExtraArgs = ''%s''', extraArgs)
    '    end'
    'end'
    };
fid = fopen(fullfile(rigDir, 'RigParameters.m'), 'w');
fprintf(fid, '%s\n', lines{:});
fclose(fid);
clear('RigParameters');
addpath(rigDir);
testCase.TestData.rigDir = rigDir;
testCase.TestData.videoDir = videoDir;
end

function vr = startRecording(testCase)
vr = struct('preTic', tic);
vr = startVideoAcquisition(vr, 'testuser_mouse01', 1);
v = vr.v;
testCase.addTeardown(@() releaseQuietly(v));
end

function stopAndVerifyVideo(testCase, vr)
% stopVideoAcquisition deletes the camera, so copy what we check first.
cam = vr.v.cam;
verifyTrue(testCase, cam.Started);
filename   = vr.v.filename;
resolution = cam.VideoResolution;
nFrames    = cam.NumFrames;
marker     = [cam.MarkerRow cam.MarkerCol];
vr = stopVideoAcquisition(vr);
verifyEmpty(testCase, vr.v);

reader = VideoReader(filename);
verifyEqual(testCase, [reader.Width reader.Height], resolution);
verifyEqual(testCase, reader.NumFrames, nFrames);
for k = [1 2 nFrames]
    frame = read(reader, k);
    gray = double(frame(:, :, 1));
    % Corner tag k*12 checks frame order (including the final flush at stop).
    verifyLessThan(testCase, abs(mean(mean(gray(2:4, 2:4))) - 12 * k), 6, ...
        sprintf('Frame %d out of order or missing.', k));
    [~, idx] = max(reshape(gray(6:end, 6:end), [], 1));
    [row, col] = ind2sub(size(gray) - 5, idx);
    verifyLessThanOrEqual(testCase, abs([row col] + 5 - marker), 1, ...
        sprintf('Marker misplaced in frame %d (byte-order bug).', k));
end
end

function files = findVideos(testCase)
files = dir(fullfile(testCase.TestData.videoDir, '**', '*.mp4'));
end

function releaseQuietly(v)
try
    if isvalid(v.cam), delete(v.cam); end
catch
end
try
    if v.proc.isAlive(), v.proc.destroyForcibly(); end
catch
end
end
