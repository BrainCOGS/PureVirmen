%%_________________________________________________________________________
% Get cue object, store in in vr as a cell
function vr = getCueObject(vr)


  %% Indices of left/right turn cues
  turnCues                  = fieldnames(vr.complete_trial_info.cue_pos);
  vr.tri_turnCue            = getVirmenFeatures('triangles', vr, turnCues);
  vr.vtx_turnCue            = getVirmenFeatures('vertices' , vr, turnCues);
  vr.dynamicCueNames        = {'tri_turnCue'};
  
  % Set trial as 
  vr.trial_info.cue_pos_cell = cell(length(turnCues),1);
  for i=1:length(turnCues)
    vr.trial_info.cue_pos_cell{i} = vr.complete_trial_info.cue_pos.(turnCues{i});
  end
  
  % HACK to deduce which triangles belong to which tower -- they seem to be
  % ordered by column from empirical tests
  % Cue object = cell (nCueObjects,1) 
  % each cue   = array (triangles, maxNumCues) 
  vr.tri_turnCue            = cellfun(@(x) reshape(x, [],  vr.maxNumCues), vr.tri_turnCue, 'un', 0);
  vr.vtx_turnCue            = cellfun(@(x) reshape(x, [],  vr.maxNumCues), vr.vtx_turnCue, 'un', 0);
  
  % Same size as cueObject, with falses (noCue has been blurred)
  vr.cueBlurred             = cellfun(@(x) false(1,size(x,2)), vr.vtx_turnCue, 'un', 0);
  vr.cueBlurred             = cell2mat(vr.cueBlurred);

  
  % Cache various properties of the loaded world (maze configuration) for speed
  vr                        = cacheMazeConfig(vr);
  vr.cueIndex               = zeros(1, numel(turnCues));
  vr.slotPos                = nan(numel(turnCues), vr.maxNumCues);
  for iChoice = 1:numel(turnCues)
    vr.cueIndex(iChoice)    = vr.worlds{vr.currentWorld}.objects.indices.(turnCues{iChoice});
    cueObject               = vr.exper.worlds{vr.currentWorld}.objects{vr.cueIndex(iChoice)};
    vr.slotPos(iChoice,:)   = cueObject.y;
  end
  
  % Set and record template position of cues
  vr = VirmenTowersSetupNewCues.setCuesPosition(vr, turnCues);
  
  % Set and record template color of cues
  if ~isempty(vr.motionBlurRange) && ~isnan(vr.dimCue)
    vr.color_turnCue        = vr.cueColor                               ...
                            * repmat( RigParameters.colorAdjustment     ...
                                    , 1, numel(vr.vtx_turnCue));
  end
  

end