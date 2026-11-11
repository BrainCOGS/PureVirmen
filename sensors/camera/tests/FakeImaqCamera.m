classdef FakeImaqCamera < handle
%FAKEIMAQCAMERA Minimal stand-in for an IMAQ videoinput object.
%
%   Exposes only the surface that pushFramesToFFmpeg relies on:
%     .FramesAvailable   - count of unread frames (dependent property, like IMAQ)
%     getdata(obj, n)    - returns the next n frames as H x W x 1 x n uint8
%
%   Lets the ffmpeg frame-transport be smoke-tested with synthetic frames and
%   no Image Acquisition Toolbox / no real camera.

    properties
        Frames          % H x W x 1 x N uint8 stack of queued frames
        Cursor = 0      % number of frames already consumed by getdata
    end

    properties (Dependent)
        FramesAvailable % unread frames remaining, matching IMAQ property access
    end

    methods
        function obj = FakeImaqCamera(frames)
            obj.Frames = frames;
        end

        function n = get.FramesAvailable(obj)
            n = size(obj.Frames, 4) - obj.Cursor;
        end

        function data = getdata(obj, n)
            i0 = obj.Cursor + 1;
            i1 = obj.Cursor + n;
            data = obj.Frames(:, :, :, i0:i1);
            obj.Cursor = i1;
        end
    end
end
