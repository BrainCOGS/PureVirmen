function [ vr ] = getCrossingsMaze( vr )
% function that calls getCrossingLine for many different landmarks

  % Mouse is considered to have made a choice if it enters one of these areas
  vr.cross_choice           = getCrossingLine(vr, {'choiceLFloor', 'choiceRFloor'}, 1, @minabs);

  %% Other regions of interest in the maze
  vr.cross_cue              = getCrossingLine(vr, {'cueFloor'}   , 2, @min);
  vr.cross_memory           = getCrossingLine(vr, {'memoryFloor'}, 2, @min);
  vr.cross_turn             = getCrossingLine(vr, {'turnFloor'}  , 2, @min);
  vr.cross_arms             = getCrossingLine(vr, {'armsFloor'}  , 2, @min);
end

