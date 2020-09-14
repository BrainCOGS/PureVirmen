classdef shapeRectangle < virmenShape
    properties
    end
    methods
        function obj = shapeRectangle
            obj.iconLocations = [0 0; 50 30];
            obj.helpString = 'Click and drag a rectangle';
        end
        function obj = getPoints(obj)
            rect = getrect(gcf);
            ptr = get(gca,'currentpoint');
            ptr = ptr(1,1:2);
            loc = [rect(1) rect(2); rect(1)+rect(3) rect(2)+rect(4)];
            if abs(ptr(1)-loc(1,1)) < abs(ptr(1)-loc(2,1))
                loc(:,1) = loc([2 1],1);
            end
            if abs(ptr(2)-loc(1,2)) < abs(ptr(1)-loc(2,2))
                loc(:,2) = loc([2 1],2);
            end
            obj.x = loc(:,1);
            obj.y = loc(:,2);
            if rect(3)==0 || rect(4)==0
                obj.x = [];
                obj.y = [];
            end
        end
        function [x y] = coords2D(obj)
            if size(obj.locations,1) < 2
                x = obj.locations([1 1 1 1 1]',1);
                y = obj.locations([1 1 1 1 1]',2);
            else
                x = obj.locations([1 1 2 2 1]',1);
                y = obj.locations([1 2 2 1 1]',2);
            end
        end
    end
end