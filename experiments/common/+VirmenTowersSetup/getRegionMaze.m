function [region, region_changed, region_struct] = getRegionMaze(vr, current_region)
% Get the specific epoch of the trail where subject is right now PoissonTowers

region                       = current_region;
region_changed               = false;
region_struct                = vr.virmen_structures.regions;
region_table                 = region_struct.region_table;

% for i=current_region+1:size(region_table,1)
%     
%     if(isPastCrossing(region_table{i,'cross'}{:}, vr.position))
%         region_table{i, 'entry'} = vr.iterFcn(vr.logger.iterationStamp()); 
%         region_changed = true;
%         region = Region2(i);
%         vr.BpodMod.sendEvent(i);
%         region_struct.region_table   = region_table;
%         break;
%     end
% end

last_region_crossed = current_region;
for i=1:size(region_table,1)
    
    if(isPastCrossing(region_table{i,'cross'}{:}, vr.position))
        last_region_crossed = i;
    end

end

if last_region_crossed ~= current_region
    region_table{last_region_crossed, 'entry'} = vr.iterFcn(vr.logger.iterationStamp()); 
    region_changed = true;
    region = Region2(last_region_crossed);
    vr.BpodMod.sendEvent(last_region_crossed);
    region_struct.region_table   = region_table;
end



% current_region
% 
% 
% 
% % Check if animal has met the trial violation criteria
% if isViolationTrial(vr)
%     region = Region.Violation;
%     
%     % Check if animal has entered a choice region after it has entered an arm
% elseif vr.iArmEntry > 0
%     region = Region.InArm;
%     
%     % Check if animal has entered the T-maze arms after the turn region
% elseif vr.iTurnEntry > 0
%     region = Region.InTurn;
%     
%     % Check if animal has entered the turn region after the memory period
% elseif vr.iMemEntry > 0
%     region = Region.InMemory;
%     
%     % Check if animal has entered the memory region after the cue period
% elseif vr.iCueEntry > 0 && isPastCrossing(vr.cross_memory, vr.position)
%     region = Region.InMemoryZero;
%     
%     % If still in the start region, do nothing
% elseif vr.iCueEntry < 1 && ~isPastCrossing(vr.cross_cue, vr.position)
%     region = Region.InStart;
%     
%     % If in the cue region, make cues visible when the animal is close enough
% else
%     region = Region.InCues;
% end

end

