classdef shapeBoundary < virmenShape
    properties
    end
    methods
        function [x y] = coords2D(obj)
            x = obj.locations([1 1 2 2 1]',1);
            y = obj.locations([1 2 2 1 1]',2);
        end
    end
end