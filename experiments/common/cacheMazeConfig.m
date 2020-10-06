%% Cache various properties of the loaded world (maze configuration), for speed.
function vr = cacheMazeConfig(vr, forceVisibility)

  maze                = vr.mazes(vr.mazeID);
  if nargin < 2
    forceVisibility   = false;
  end

  % Store default visibility of objects
  vr.visibilityMask   = true(size(vr.worlds{vr.currentWorld}.surface.visible));
  for name = fieldnames(maze.visible)'
    if iscell(vr.(name{:}))
      for iObj = 1:numel(vr.(name{:}))
        vr.visibilityMask(vr.(name{:}){iObj})           ...
                      = forceVisibility                 ...
                      | (maze.visible.(name{:}) ~= 0)   ...
                      ;
      end
    else
      vr.visibilityMask(vr.(name{:}))                   ...
                      = forceVisibility                 ...
                      | (maze.visible.(name{:}) ~= 0)   ...
                      ;
    end 
  end
  
  % Store color variations
  for var = fieldnames(maze.color)'
    vr.(['clr_' var{:}])  = dimColors ( vr.worlds{vr.currentWorld}.surface.colors   ...
                                      , vr.(var{:})(vr.currentWorld,:)              ...
                                      , maze.color.(var{:})                         ...
                                      );
  end
  
end
