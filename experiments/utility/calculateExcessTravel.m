function [excessTravel, lessMaxTravel] = calculateExcessTravel(distance, mazeLength, maxTravel)
% Calculate excess travel ratio by subject in maze
% Inputs
% distance     = distance traveled by subject
% mazeLength   = length of the current maze
% Outputs
% excessTravel = measure of excess distance run by subject
                 % 0 if subject travelled in straight line through the maze
                 
excessTravel = (distance / mazeLength) - 1;

lessMaxTravel = excessTravel <= maxTravel;


end

