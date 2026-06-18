function vr = startVideoAcquisition(vr, subject_name, session_number, logger)
%STARTvideoacquisition Configure camera, start recording, and store sync timestamp.
%
%   vr = startVideoAcquisition(vr, subject_name, session_number)
%   vr = startVideoAcquisition(vr, subject_name, session_number, logger)
%
%   Must be called from experiment initialization code, after the engine has
%   set vr.preTic (available automatically from PureVirmen r2+ onwards).
%
%   Inputs:
%     vr             - ViRMEn runtime struct (must contain vr.preTic)
%     subject_name   - string identifier for the subject (e.g. 'labuser_mouse01')
%     session_number - integer session index used in the filename
%     logger         - (optional) object exposing save_timeElapsedFirstTrial(t).
%                      Pass [] or omit to disable logging. Compatible with
%                      ViRMEn's ExperimentLog class.
%
%   Output:
%     vr - updated struct with fields:
%       vr.v                    - videoinput object (pass to stopVideoAcquisition)
%       vr.videoAcqInfo         - struct with recording metadata
%       vr.timeElapsedVideoStart - seconds from vr.preTic to acquisition start
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

vr.videoAcqInfo = struct( ...
    'video_parent_path',      RigParameters.video_parent_path, ...
    'video_acquisition_rate', RigParameters.video_acquisition_rate, ...
    'video_gain',             RigParameters.video_gain, ...
    'video_fullname',         video_fullname);

% Capture timestamp immediately before starting — this is the sync anchor.
% vr.preTic is set by virmenEngine before initialization(), so toc(vr.preTic)
% gives seconds elapsed since the engine's time zero.
vr.timeElapsedVideoStart = toc(vr.preTic);
start(vr.v);

if ~isempty(logger) && isfield(vr, 'timeElapsedFirstTrial')
    logger.save_timeElapsedFirstTrial(vr.timeElapsedFirstTrial);
end

end
