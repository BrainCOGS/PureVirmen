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
%     video_fullname - full path to the recorded video file
%
%   Outputs:
%     syncVideoFrame - [nFrames x 2] single matrix:
%                        col 1: absolute frame time (s from preTic)
%                        col 2: index into log.iterationTimes of the nearest
%                               behavioral iteration (NaN before first iteration)
%     syncBehavior   - [nIter x 2] single matrix:
%                        col 1: iteration time (s from preTic)
%                        col 2: index of the last video frame before that iteration
%                               (NaN if video had not started yet)
%
%   Both outputs are empty if the video and behavior do not overlap.
%
%   See also: startVideoAcquisition, stopVideoAcquisition

v = VideoReader(video_fullname);

% Absolute time of each video frame, anchored to vr.preTic
frameTimes = single(linspace(0, v.Duration, v.NumFrames)' + log.timeElapsedVideoStart);

iterTimes = single(log.iterationTimes(:));
nFrames   = length(frameTimes);
nIter     = length(iterTimes);

% --- syncVideoFrame: for each frame, find the nearest preceding iteration ---
syncVideoFrame = NaN(nFrames, 2, 'single');
syncVideoFrame(:, 1) = frameTimes;

for i = 1:nFrames
    idx = find(iterTimes <= frameTimes(i), 1, 'last');
    if ~isempty(idx)
        syncVideoFrame(i, 2) = idx;
    end
end

% --- syncBehavior: for each iteration, find the last frame before it ---
syncBehavior = NaN(nIter, 2, 'single');
syncBehavior(:, 1) = iterTimes;

for i = 1:nIter
    idx = find(frameTimes < iterTimes(i), 1, 'last');
    if ~isempty(idx)
        syncBehavior(i, 2) = idx;
    end
end

% Return empty if there is no overlap
if all(isnan(syncVideoFrame(:, 2))) || all(isnan(syncBehavior(:, 2)))
    syncVideoFrame = [];
    syncBehavior   = [];
end

end
