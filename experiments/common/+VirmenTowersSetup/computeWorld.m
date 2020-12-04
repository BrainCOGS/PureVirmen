%%_________________________________________________________________________
% --- (Re-)triangulate world and obtain various subsets of interest
function vr = computeWorld(vr)

  % Modify the ViRMen world to the specifications of the given maze; sets
  % vr.mazeID to the given mazeID
  [vr,~]           = VirmenTowersSetup.configureMaze(vr, vr.mazeID, vr.mainMazeID);
  %stimParameters  = VirmenTowersSetup.getStimParameters(vr);
  vr.mazeLength             = vr.lStart                                   ...
                            - vr.worlds{vr.currentWorld}.startLocation(2) ...
                            + vr.lCue                                     ...
                            + vr.lMemory                                  ...
                            + vr.lArm                                     ...
                            ;
  vr.stemLength             = vr.lCue                                     ...
                            + vr.lMemory                                  ...
                            ;

  % Specify parameters for computation of performance statistics
  % (maze specific for advancement criteria)
  %% ALSFix Statistics not needed for virmen itself %% 


  %% ALS Get crossing of important landmarks
  vr.virmen_structures.regions = VirmenTowersSetup.getCrossingsMaze(vr, vr.virmen_structures.regions);


  %% Indices of left/right turn cues
  turnCues                  = {'leftTurnCues', 'rightTurnCues'};
  vr.tri_turnCue            = getVirmenFeatures('triangles', vr, turnCues);
  vr.tri_turnHint           = getVirmenFeatures('triangles', vr, {'leftTurnHint', 'rightTurnHint'} );
  vr.vtx_turnCue            = getVirmenFeatures('vertices' , vr, turnCues);
  vr.dynamicCueNames        = {'tri_turnCue'};
  vr.choiceHintNames        = {'tri_turnHint'};
  
  %% Search through all world objects to add additional landmarks to turn hints, when available
  objects                   = vr.worlds{vr.currentWorld}.objects;
  objectNames               = fieldnames(objects.indices);
  sideNames                 = {'left', 'right'};
  vr.tri_turnHint           = num2cell(vr.tri_turnHint,2);
  for iSide = 1:numel(sideNames)
    landmarks               = ~cellfun(@isempty,regexp(objectNames, ['^' sideNames{iSide} '_landmark.+'], 'once'));
    triangles               = getVirmenFeatures('triangles', vr, objectNames(landmarks));
    if ~isempty(triangles)
      vr.tri_turnHint{iSide}= [vr.tri_turnHint{iSide}, triangles{:}];
    end
  end

  %% Visibility of hints (visual guides)
  vr.hintVisibility         = nan(size(vr.choiceHintNames));
  for iCue = 1:numel(vr.choiceHintNames)
    vr.hintVisibility(iCue) = vr.mazes(vr.mazeID).visible.(vr.choiceHintNames{iCue});
  end
  
  % HACK to deduce which triangles belong to which tower -- they seem to be
  % ordered by column from empirical tests
  vr.tri_turnCue            = reshape(vr.tri_turnCue, size(vr.tri_turnCue,1), [], vr.nCueSlots);
  vr.vtx_turnCue            = reshape(vr.vtx_turnCue, size(vr.vtx_turnCue,1), [], vr.nCueSlots);
  vr.cueBlurred             = false(size(vr.vtx_turnCue));
  

  % Cache various properties of the loaded world (maze configuration) for speed
  vr                        = cacheMazeConfig(vr);
  vr.cueIndex               = zeros(1, numel(turnCues));
  vr.slotPos                = nan(numel(Choice.all()), vr.nCueSlots);
  for iChoice = 1:numel(turnCues)
    vr.cueIndex(iChoice)    = vr.worlds{vr.currentWorld}.objects.indices.(turnCues{iChoice});
    cueObject               = vr.exper.worlds{vr.currentWorld}.objects{vr.cueIndex(iChoice)};
    vr.slotPos(iChoice,:)   = cueObject.y;
  end
  
  % Set and record template position of cues
  vr = VirmenTowersSetup.setCuesPosition(vr, turnCues);
  
  % Set and record template color of cues
  if ~isempty(vr.motionBlurRange) && ~isnan(vr.dimCue)
    vr.color_turnCue        = vr.cueColor                               ...
                            * repmat( RigParameters.colorAdjustment     ...
                                    , 1, numel(vr.vtx_turnCue));
  end
  
  %% Appearing landmarks, if any
  %ALS, code for landmarks setting in one function
  vr         = VirmenTowersSetup.setLandmarksMaze(vr, objectNames);
  %ALS, code for sky setting in one function
  vr         = VirmenTowersSetup.setSkyMaze(vr, objectNames);
  
  %% Set up Poisson stimulus train
  %% ALS i think not needed in virmen light code
%   [modified, vr.stimulusConfig] = vr.poissonStimuli.configure(lCue, stimParameters{:});
%   if modified
%     errordlg( sprintf('Stimuli parameters had to be configured for maze %d.', vr.mazeID)  ...
%                      , 'Stimulus sequences not configured', 'modal'                       ...
%             );
%     vr.experimentEnded      = true;
%     return;
%   end

end