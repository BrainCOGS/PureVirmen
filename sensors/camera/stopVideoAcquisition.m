function vr = stopVideoAcquisition(vr, logger)
%STOPVIDEOACQUISITION Stop camera recording and release hardware resources.
%
%   vr = stopVideoAcquisition(vr)
%   vr = stopVideoAcquisition(vr, logger)
%
%   Call from experiment termination code. Safe to call even if acquisition
%   was never started (checks for vr.v before acting).
%
%   Inputs:
%     vr     - ViRMEn runtime struct containing vr.v from startVideoAcquisition
%     logger - (optional) object exposing save_timeElapsedFirstTrial(t).
%              If provided and vr.timeElapsedFirstTrial exists, saves it now.

if nargin < 2
    logger = [];
end

if ~isempty(logger) && isfield(vr, 'timeElapsedFirstTrial')
    logger.save_timeElapsedFirstTrial(vr.timeElapsedFirstTrial);
end

if isfield(vr, 'v') && ~isempty(vr.v)
    stop(vr.v);
    delete(vr.v);
    vr.v = [];
end

end
