classdef PendingDiskCamera < handle
    % Simulate disk writing that completes shortly after acquisition stops.
    properties
        FramesAcquired = 17
        State
        StopTime = []
    end
    properties (Dependent)
        DiskLoggerFrameCount
    end
    methods
        function obj = PendingDiskCamera(state)
            obj.State = state;
        end
        function stop(obj)
            obj.StopTime = tic;
        end
        function n = get.DiskLoggerFrameCount(obj)
            n = 0;
            if ~isempty(obj.StopTime) && toc(obj.StopTime) >= 0.1
                n = obj.FramesAcquired;
            end
        end
        function delete(obj)
            obj.State.LostFrames = obj.DiskLoggerFrameCount < obj.FramesAcquired;
            obj.State.Deleted = true;
        end
    end
end
