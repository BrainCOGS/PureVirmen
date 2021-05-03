function [region_changed, region_index] = getRegionMaze(region_struct, current_region, position)
% Get the specific epoch of the trail where subject is right now PoissonTowers

%region                       = current_region;
region_changed               = false;
%region_struct                = vr.virmen_structures.regions;
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

region_index = current_region;
for i=region_index+1:size(region_table,1)
    
    if(isPastCrossing(region_table{i,'cross'}{:}, position))
        region_index = i;
        break;
    end

end

if region_index ~= current_region
    %region_table{last_region_crossed, 'entry'} = vr.iterFcn(vr.logger.iterationStamp()); 
    region_changed = true;
    %region = vr.Regions{last_region_crossed};
    %vr.BpodMod.sendEvent(region_index);
    %region_struct.region_table   = region_table;
end

end

