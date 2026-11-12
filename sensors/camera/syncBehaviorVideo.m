function [syncVideoFrame, syncBehavior] = syncBehaviorVideo(log, video_fullname)
%SYNCBEHAVIORVIDEO Align video frames to behavioral iterations post-hoc.
%
%   [syncVideoFrame, syncBehavior] = syncBehaviorVideo(log, video_fullname)
%
%   Inputs:
%     log            - struct saved at end of session, with fields:
%       .timeElapsedVideoStart  - seconds from vr.preTic to video start
%                                 (copied from vr.timeElapsedVideoStart)
%       .iterationTimes         - Nx1 vector of per-iteration timestamps in
%                                 seconds, relative to the engine loop start
%                                 (i.e. starting near zero, increasing each frame)
%       .timeElapsedFirstTrial  - seconds from vr.preTic to engine loop start
%                                 (copied from vr.timeElapsedFirstTrial)
%     video_fullname - full path to the recorded video file
%
%   Outputs:
%     syncVideoFrame - [nFrames x 2] single matrix:
%                        col 1: absolute frame time (s from preTic)
%                        col 2: index into log.iterationTimes of the last
%                               iteration at/before the frame (NaN before first)
%     syncBehavior   - [nIter x 2] single matrix:
%                        col 1: iteration time (s from preTic)
%                        col 2: index of the last video frame before that iteration
%                               (NaN if video had not started yet)
%
%   Both outputs are empty if the video and behavior do not overlap.
%
%   NOTE: frame times are reconstructed from the file frame rate, which
%   ASSUMES the camera held a constant frame rate
%   with no dropped frames. FLIR cameras can and do drop frames under load,
%   in which case this alignment drifts. If you have true per-frame
%   timestamps (e.g. logged from the camera or DiskLogger metadata), pass
%   those in via log.frameTimes to override the reconstruction below.
%
%   See also: startVideoAcquisition, stopVideoAcquisition

if ~isfield(log, 'timeElapsedFirstTrial')
    error('PureVirmen:missingTimingReference', ...
        'log.timeElapsedFirstTrial is required to align engine and video clocks.');
end

% Compare in double precision; convert only the returned arrays to single.
% Both clocks must be relative to preTic, including initialization time.
iterTimes = double(log.iterationTimes(:)) + double(log.timeElapsedFirstTrial);
syncVideoFrame = [];
syncBehavior = [];
if isempty(iterTimes)
    return;
end

% Absolute time of each video frame, anchored to vr.preTic.
if isfield(log, 'frameTimes') && ~isempty(log.frameTimes)
    frameTimes = double(log.frameTimes(:)) + double(log.timeElapsedVideoStart);
else
    v = VideoReader(video_fullname);
    frameTimes = (0:v.NumFrames-1)' / v.FrameRate + double(log.timeElapsedVideoStart);
end

nFrames   = length(frameTimes);
nIter     = length(iterTimes);
if nFrames == 0 || frameTimes(end) < iterTimes(1) || iterTimes(end) < frameTimes(1)
    return;
end

% Both lookups are "find the last entry of a sorted vector that is <= a query
% time". iterTimes and frameTimes are monotonically increasing, so this is a
% single O(n log n) binned search rather than an O(n*m) nested scan.
%
% discretize(query, [edges Inf]) returns the index of the bin each query
% falls into, i.e. the index of the last edge that is <= query (or NaN when
% the query precedes the first edge).

% --- syncVideoFrame: for each frame, index of the last iteration at/before it ---
syncVideoFrame = NaN(nFrames, 2, 'single');
syncVideoFrame(:, 1) = frameTimes;
if nIter > 0
    syncVideoFrame(:, 2) = discretize(frameTimes, [iterTimes; Inf]);
end

% --- syncBehavior: for each iteration, index of the last frame strictly before it ---
syncBehavior = NaN(nIter, 2, 'single');
syncBehavior(:, 1) = iterTimes;
if nFrames > 0
    % Strict "<" (frame before the iteration): nudge edges so an exact tie
    % maps to the previous frame rather than the simultaneous one.
    syncBehavior(:, 2) = discretize(iterTimes, [frameTimes; Inf]);
    exactTie = ismember(iterTimes, frameTimes);
    syncBehavior(exactTie, 2) = syncBehavior(exactTie, 2) - 1;
    syncBehavior(syncBehavior(:, 2) < 1, 2) = NaN;
end

end
