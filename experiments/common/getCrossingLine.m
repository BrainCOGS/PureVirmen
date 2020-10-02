function crossing = getCrossingLine(vr, floorName, coordinate, selector)

  for iFloor = 1:numel(floorName)
    % Get the floor object
    floorIndex      = vr.worlds{vr.currentWorld}.objects.indices.(floorName{iFloor});
    floor           = vr.exper.worlds{vr.currentWorld}.objects{floorIndex};

    % Compute corners of the rectangle
    angle           = floor.rotation * pi/180;
    corner          = bsxfun( @plus                                   ...
                            , [ floor.x; floor.y ]                    ...
                            , [ cos(angle), -sin(angle)               ...
                              ; sin(angle),  cos(angle)               ...
                              ]                                       ...
                            * [ [1 -1 -1  1] * floor.width/2          ...
                              ; [1  1 -1 -1] * floor.height/2         ...
                              ]                                       ...
                            );

    % Find the coordinate of interest
    corner          = corner(coordinate, :);
    cross           = selector(corner);
    corner(corner == cross) = [];

    % Store information structure
    crossing(iFloor).coordinate   = coordinate;
    crossing(iFloor).crossing     = cross;
    if isempty(corner)            % Deduce direction based on whether the user wants the nearer or further edge
      crossing(iFloor).sign       = -selector([-1 1]);
    else
      crossing(iFloor).sign       = sign(corner(1) - cross);
    end
  end
  
end
