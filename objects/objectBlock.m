classdef objectBlock < virmenObject
    properties (SetObservable)
        width = 5;
        height = 5;
        bottom = 0;
        top = 40;
        colorScaleNorth = 1;
        colorScaleSouth = 1;
        colorScaleEast = 1;
        colorScaleWest = 1;
    end
    methods
        function obj = objectBlock
            obj.iconLocations = [0 0];
            obj.helpString = 'Click block centers, then press Enter';
        end
        function obj = getPoints(obj)
            [obj.x, obj.y] = getpts(gcf);
        end
        function [x, y, z] = coords2D(obj)
            x = zeros(0,1);
            y = zeros(0,1);
            z = zeros(0,1);
            
            w = obj.width/2;
            h = obj.height/2;
            b = obj.bottom;
            t = obj.top;
          
            % Bottom face
            x = [x; -w; +w; +w; -w; -w; +w; nan];
            y = [y; -h; -h; +h; -h; +h; +h; nan];
            z = [z;  b;  b;  b;  b;  b;  b; nan];
            
            % Top face
            x = [x; +w; -w; -w; +w; +w; -w; nan];
            y = [y; -h; -h; +h; -h; +h; +h; nan];
            z = [z;  t;  t;  t;  t;  t;  t; nan];
            
            % Vertical edges
            x = [x; -w; -w; nan; +w; +w; nan; +w; +w; nan; -w; -w; nan];
            y = [y; -h; -h; nan; -h; -h; nan; +h; +h; nan; -h; -h; nan];
            z = [z;  b;  t; nan;  b;  t; nan;  b;  t; nan;  b;  t; nan];
            
            % Replicate as many times as necessary
            loc = obj.locations;
            x = bsxfun(@plus, x, loc(:,1)');
            y = bsxfun(@plus, y, loc(:,2)');
            z = repmat(z, size(loc,1), 1);
            x = x(:);
            y = y(:);
        end
        function objSurface = coords3D(obj)
            texture = tile(obj.texture,obj.tiling);
            objSurface.vertices = zeros(0,3);
            objSurface.triangulation = zeros(0,3);
            objSurface.cdata = zeros(0,size(texture.triangles.cdata,2));

            vx = texture.triangles.vertices(:,1);
            vy = texture.triangles.vertices(:,2);
            z = (vy-min(vy(:)))/range(vy(:))*(obj.top-obj.bottom)+obj.bottom;
            x = ((vx-min(vx(:)))/range(vx(:))-0.5)*obj.width;
            y = ((vx-min(vx(:)))/range(vx(:))-0.5)*obj.height;
            loc = obj.locations;
            
            for ndx = 1:size(loc,1)
                % North/south surfaces
                vtx = [x zeros(size(x)) z];
                objSurface.triangulation = [objSurface.triangulation; texture.triangles.triangulation+size(objSurface.vertices,1)];
                objSurface.vertices = [objSurface.vertices; bsxfun(@plus,vtx,[loc(ndx,1), loc(ndx,2)-obj.height/2, 0])];
                objSurface.cdata = [objSurface.cdata; texture.triangles.cdata * obj.colorScaleSouth];
                objSurface.triangulation = [objSurface.triangulation; texture.triangles.triangulation+size(objSurface.vertices,1)];
                objSurface.vertices = [objSurface.vertices; bsxfun(@plus,vtx,[loc(ndx,1), loc(ndx,2)+obj.height/2, 0])];
                objSurface.cdata = [objSurface.cdata; texture.triangles.cdata * obj.colorScaleNorth];
                
                % East/west surfaces
                vtx = [zeros(size(y)) y z];
                objSurface.triangulation = [objSurface.triangulation; texture.triangles.triangulation+size(objSurface.vertices,1)];
                objSurface.vertices = [objSurface.vertices; bsxfun(@plus,vtx,[loc(ndx,1)-obj.width/2, loc(ndx,2), 0])];
                objSurface.cdata = [objSurface.cdata; texture.triangles.cdata * obj.colorScaleWest];
                objSurface.triangulation = [objSurface.triangulation; texture.triangles.triangulation+size(objSurface.vertices,1)];
                objSurface.vertices = [objSurface.vertices; bsxfun(@plus,vtx,[loc(ndx,1)+obj.width/2, loc(ndx,2), 0])];
                objSurface.cdata = [objSurface.cdata; texture.triangles.cdata * obj.colorScaleEast];
            end
        end
        function edges = edges(obj)
            edges = zeros(0,4);
            loc = obj.locations;
            for iLoc = 1:size(loc,1)
              edges(end + (1:4), :) = bsxfun( @plus                                                   ...
                                            , [ -obj.width , -obj.height, +obj.width , +obj.height    ...
                                              ; +obj.width , -obj.height, +obj.width , +obj.height    ...
                                              ; +obj.width , +obj.height, -obj.width , +obj.height    ...
                                              ; -obj.width , +obj.height, -obj.width , -obj.height    ...
                                              ]                                                       ...
                                            , loc(iLoc, [1 2 1 2])                                    ...
                                            );
            end
        end
    end
end