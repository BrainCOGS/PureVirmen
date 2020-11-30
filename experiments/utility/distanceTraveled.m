function distance = distanceTraveled(position)
% Calculate distance traveled by subject in maze
% Inputs
% position = position vector, (1st column x coord, 2nd column y coord) 
% Outputs
% distance = distance traveled by subject

distance      = 0;

if ~isempty(position)
    displacement  = diff(position(:,1:2), 1);
    distance      = sum( sqrt(sum(displacement.^2, 2)) );
end

end