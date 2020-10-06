function [epoch] = getRegionMaze(vr)
% Get the specific epoch of the trail where subject is right now PoissonTowers

% Check if animal has met the trial violation criteria
if isViolationTrial(vr)
    epoch = Region.Violation;
    
    % Check if animal has entered a choice region after it has entered an arm
elseif vr.iArmEntry > 0
    epoch = Region.InArm;
    
    % Check if animal has entered the T-maze arms after the turn region
elseif vr.iTurnEntry > 0
    epoch = Region.InTurn;
    
    % Check if animal has entered the turn region after the memory period
elseif vr.iMemEntry > 0
    epoch = Region.InMemory;
    
    % Check if animal has entered the memory region after the cue period
elseif vr.iCueEntry > 0 && isPastCrossing(vr.cross_memory, vr.position)
    epoch = Region.InMemory0;
    
    % If still in the start region, do nothing
elseif vr.iCueEntry < 1 && ~isPastCrossing(vr.cross_cue, vr.position)
    epoch = Region.InStart;
    
    % If in the cue region, make cues visible when the animal is close enough
else
    epoch = Region.InCues;
end

end

