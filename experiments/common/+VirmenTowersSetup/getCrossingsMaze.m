function [region_struct] = getCrossingsMaze(vr, region_struct)
% function that calls getCrossingLine for many different landmarks

region_table = region_struct.region_table;

for i=1:size(region_table,1)

  region_name = {[region_table{i, 'region_name'}{:} 'Floor']};
  crossing = getCrossingLine(vr, region_name, ...
                                 region_table{i, 'coordinate'}, ...
                                 region_table{i, 'selector_function'}{:})
                             
  region_table{i, 'cross'} = {crossing}                        
end
                                         
  % Mouse is considered to have made a choice if it enters one of these areas
  vr.cross_choice           = getCrossingLine(vr, {'choiceLFloor', 'choiceRFloor'}, 1, @minabs);

  %% Other regions of interest in the maze
  vr.cross_cue              = getCrossingLine(vr, {'cueFloor'}   , 2, @min);
  vr.cross_memory           = getCrossingLine(vr, {'memoryFloor'}, 2, @min);
  vr.cross_turn             = getCrossingLine(vr, {'turnFloor'}  , 2, @min);
  vr.cross_arms             = getCrossingLine(vr, {'armsFloor'}  , 2, @min);

region_struct.region_table = region_table;


