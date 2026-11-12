classdef VirtualCamera < handle
%VIRTUALCAMERA Test double for an IMAQ videoinput on the ffmpeg path.
% Kept below private/ so genpath(repo) never exposes camera mocks to experiments.
%
%   start() synchronously "acquires" NumFrames 64x48 Mono8 frames, firing
%   FramesAcquiredFcn every FramesAcquiredFcnCount frames like IMAQ does.
%   Frames not drained by the callback stay buffered for
%   stopVideoAcquisition's final flush. Each frame has a bright marker at
%   (MarkerRow, MarkerCol) and a 5x5 corner tag of k*12 for frame k.

    properties
        VideoResolution = [64 48]
        NumFrames = 17
        MarkerRow = 11
        MarkerCol = 37
        FramesPerTrigger
        TriggerRepeat
        LoggingMode
        FramesAcquiredFcnCount = 0
        FramesAcquiredFcn
        Source
        Frames
        Cursor = 0
        Started = false
        Stopped = false
    end

    properties (Dependent)
        FramesAvailable
    end

    methods
        function obj = VirtualCamera
            obj.Source = VirtualSource;
            obj.Frames = zeros(48, 64, 1, 0, 'uint8');
        end

        function n = get.FramesAvailable(obj)
            n = size(obj.Frames, 4) - obj.Cursor;
        end

        function s = getselectedsource(obj)
            s = obj.Source;
        end

        function frames = getdata(obj, n)
            frames = obj.Frames(:, :, :, obj.Cursor + (1:n));
            obj.Cursor = obj.Cursor + n;
        end

        function start(obj)
            obj.Started = true;
            for k = 1:obj.NumFrames
                frame = zeros(obj.VideoResolution(2), obj.VideoResolution(1), 'uint8');
                frame(obj.MarkerRow, obj.MarkerCol) = 255;
                frame(1:5, 1:5) = uint8(k * 12);
                obj.Frames(:, :, :, end + 1) = frame;
                if obj.FramesAcquiredFcnCount > 0 && ...
                        mod(k, obj.FramesAcquiredFcnCount) == 0
                    obj.FramesAcquiredFcn(obj, []);
                end
            end
        end

        function stop(obj)
            obj.Stopped = true;
        end
    end
end
