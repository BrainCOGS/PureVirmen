%% Modify the ViRMen world to the specifications of the given maze.
function [vr, lCue, stimParameters] = configureMaze(vr, mazeID, mainMazeID, hasDisplay, verbose)

  %% If no more mazes, print congratulations and do nothing
  if mazeID > numel(vr.mazes)
    fprintf ( [ '\n\n             ********************  CONGRATULATIONS  ********************\n\n'        ...
                '  Your mouse has achieved maze %d/%d and there is nothing more for him to learn!\n\n\n'  ...
              ]                                                                                           ...
            , mazeID, numel(vr.mazes)                                                                     ...
            );
    vr.experimentEnded  = true;
    vr.mazeID           = numel(vr.mazes);
    lCue                = 0;
    stimParameters      = {};
    return;
  end

  if nargin < 5 || verbose
    fprintf('Preparing maze %d\n', mazeID);
  end
    
  %% Set the current maze
  % hack to add a "turn off visual guide during delay?" flag for
  % protocols without this parameter
  if ~isfield(vr.mazes(mazeID),'turnHint_Mem')
    vr.mazes(mazeID).turnHint_Mem = false;
  end
  
  maze                  = vr.mazes(mazeID);
  vr.mazeID             = mazeID;
  vr.currentWorld       = maze.world;

  %% Adjust world parameters as specified
  mazeVars              = fieldnames(maze.variable)';
  if mazeID ~= mainMazeID
    mazeVars            = setdiff(mazeVars, vr.inheritedVariables);
    mainMaze            = vr.mazes(mainMazeID);
    for var = vr.inheritedVariables
      vr.exper.variables.(var{:}) = mainMaze.variable.(var{:});
    end
  end

  for var = mazeVars
    vr.exper.variables.(var{:})   = maze.variable.(var{:});
  end

  %% Store variables that affect the course of the experiment
  for var = vr.experimentVars
    if ischar(var{:})
      vr.(var{:})         = eval(vr.exper.variables.(var{:}));
    elseif isfield(vr.exper.variables, var{:}{1})
      vr.(var{:}{1})      = eval(vr.exper.variables.(var{:}{1}));
    else
      vr.(var{:}{1})      = var{:}{2};
    end
  end
  
  if nargin < 4 || hasDisplay
    % Recompute triangles and layout
    vr.worlds{vr.currentWorld}    = loadVirmenWorld(vr.exper.worlds{vr.currentWorld});
    vr                            = adjustColorsForProjector(vr);
    
    % Turn off world visibility until start of trial
    vr.surfaceVisibility          = false(size(vr.worlds{vr.currentWorld}.surface.visible));
  end

  %% Get list of parameters that the stimulus configuration depends on
  if nargout > 1
    if isfield(vr, 'lCue')
      lCue              = vr.lCue;
    else
      lCue              = str2double(vr.exper.variables.lCue);
    end
    if isfield(vr, 'lastCueLeeway')
      lCue              = lCue - vr.lastCueLeeway;
    end
  end

end
