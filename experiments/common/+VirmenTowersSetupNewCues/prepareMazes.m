%% Processes the definition for a sequence of progressively more difficult mazes.
% The mazes input should be a struct array with as many elements as there
% are mazes. Field names with special interpretations:
%   world   : Which Virmen world to set as current
%   vtx_*   : A pair [wrongSF,rightSF] of luminosity scale factors to be
%             applied to the named walls/floors when their directions are
%             the wrong/right choice respectively
%   tri_*   : False will force this object to always be invisible
% Everything else is assumed to be a Virmen variable that will be set to
% the given value.
%
% Optionally a criteria structure with the same number of elements as mazes
% can be provided, which will be stored under the "citeria" field of the
% output vr.mazes structure.
function vr = prepareMazes(vr, mazes, criteria, globalSettings)

  %When you update a variable such as cueMinSeparation,
  %Cue locations are refreshed if they have a "symbolic" correspondence
  %e.g. leftTurnCues.y = (1 + (0:(nCueSlots-1))) * cueMinSeparation
  for iSetting = 1:2:numel(globalSettings)-1
    vr.exper.variables.(globalSettings{iSetting})       ...
            = mat2str(globalSettings{iSetting+1});
  end

  vr.mazes  = repmat( struct( 'world'     , {1}         ... % World number
                            , 'variable'  , {struct()}  ... % Variable name
                            , 'visible'   , {struct()}  ... % Triangles to set the visibility of
                            , 'color'     , {struct()}  ... % Vertices to set the color of
                            )                           ...
                    , 1, numel(mazes)                   ...
                    );
  
  for iMaze = 1:numel(mazes)
    % hack to add a "turn off visual guide during delay?" flag for
    % protocols without this parameter
    if ~isfield(mazes(iMaze),'turnHint_Mem')
      mazes(iMaze).turnHint_Mem = false;
    end
    
    maze    = mazes(iMaze);
    for field = fieldnames(maze)'
      name  = field{:};
      if strcmp(name, 'world')
        vr.mazes(iMaze).world           = maze.(name);
      elseif strncmp(name, 'tri_', 4)
        vr.mazes(iMaze).visible.(name)  = maze.(name);
        if isnan(maze.(name))
          error('prepareMazes:visible', 'NaN values not allowed for %s in protocol.', name);
        end
      elseif strncmp(name, 'vtx_', 4)
        vr.mazes(iMaze).color.(name)    = maze.(name);
      elseif strncmp(name, 'turnHint_Mem', 12)
        vr.mazes(iMaze).(name)  = maze.(name);
      else
        vr.mazes(iMaze).variable.(name) = num2str(maze.(name));
      end
    end
    
  end
  
  if nargin > 2 && ~isempty(criteria)
    for iMaze = 1:numel(mazes)
      if ~issorted(floor(criteria(iMaze).warmupMaze))
        error('prepareMazes:sanity', 'Warmup mazes must be non-decreasing in maze ID.');
      end
      vr.mazes(iMaze).criteria          = criteria(iMaze);
    end
    
%     if isfield(criteria, 'demoteBlockSize')
%       for iMaze = 1:numel(mazes)
%         vr.mazes(iMaze).criteria.demoteCount                    ...
%             = repmat( ceil(criteria(iMaze).demoteBlockSize/2)   ...
%                     , ChoiceExperimentStats.NUM_CHOICES         ...
%                     , criteria(iMaze).demoteNumBlocks           ...
%                     );
%       end
%     end
  end

end
