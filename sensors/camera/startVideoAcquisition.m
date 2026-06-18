function vr = startVideoAcquisition(vr, subject_name, session_number, logger)
%STARTVIDEOACQUISITION Configure camera, start recording, and store sync timestamp.
%
%   vr = startVideoAcquisition(vr, subject_name, session_number)
%   vr = startVideoAcquisition(vr, subject_name, session_number, logger)
%
%   Must be called from experiment initialization code, after the engine has
%   set vr.preTic (available automatically from virmenEngine).
%
%   Inputs:
%     vr             - ViRMEn runtime struct (must contain vr.preTic)
%     subject_name   - string identifier for the subject (e.g. 'labuser_mouse01')
%     session_number - integer session index used in the output filename
%     logger         - (optional) object exposing save_timeElapsedFirstTrial(t).
%                      Pass [] or omit to disable logging. Compatible with
%                      ViRMEn's ExperimentLog class.
%
%   Output:
%     vr - updated struct with fields:
%       vr.v                     - camera handle (videoinput or ffmpeg struct)
%       vr.videoAcqInfo          - struct with recording metadata and filename
%       vr.timeElapsedVideoStart - seconds from vr.preTic to acquisition start
%
%   Recording backend is selected by RigParameters.useFFmpeg (default false).
%   See configureSingleCamera and RigParameters.m.example for details.
%
%   Requires: Image Acquisition Toolbox + FLIR Spinnaker GenTL support.
%   RigParameters must define: video_parent_path, video_ext,
%     video_acquisition_rate, video_gain.

if nargin < 4
    logger = [];
end

checkCameraRigParameters();

video_fullname = setupVideoFile(RigParameters.video_parent_path, ...
    RigParameters.video_ext, subject_name, session_number);

vr.v = configureSingleCamera(RigParameters, video_fullname);

% Resolve actual filename (ffmpeg may have changed the extension to .mp4)
if isstruct(vr.v) && strcmp(vr.v.type, 'ffmpeg')
    actual_filename = vr.v.filename;
else
    actual_filename = video_fullname;
end

vr.videoAcqInfo = struct( ...
    'video_parent_path',      RigParameters.video_parent_path, ...
    'video_acquisition_rate', RigParameters.video_acquisition_rate, ...
    'video_gain',             RigParameters.video_gain, ...
    'video_fullname',         actual_filename);

% Capture timestamp immediately before starting — this is the sync anchor.
% vr.preTic is set by virmenEngine before initialization(), so toc(vr.preTic)
% gives seconds elapsed since the engine's time zero.
vr.timeElapsedVideoStart = toc(vr.preTic);
startCamera(vr.v);

if ~isempty(logger) && isfield(vr, 'timeElapsedFirstTrial')
    logger.save_timeElapsedFirstTrial(vr.timeElapsedFirstTrial);
end

end

% -------------------------------------------------------------------------

function startCamera(v)
if isstruct(v) && strcmp(v.type, 'ffmpeg')
    % Stream frames to ffmpeg's stdin as they are acquired. The callback
    % drains the IMAQ buffer and writes raw bytes; firing every few frames
    % keeps callback overhead low without letting the buffer grow unbounded.
    cam = v.cam;
    cam.FramesAcquiredFcnCount = 5;
    cam.FramesAcquiredFcn = @(src, ev) pushFramesToFFmpeg(src, v.stdin, v.width, v.height);
    start(cam);
else
    start(v);
end
end
