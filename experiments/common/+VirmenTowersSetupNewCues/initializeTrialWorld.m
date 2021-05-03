% --- Modify the world for the next trial
function vr = initializeTrialWorld(vr)

  % ALS Get mazeChanged from BControl
 % vr.mazeChanged = 1;
  %vr.mazeID = 4;

  if vr.mazeChanged
    %vr.flagmazeChanged = 0;
    vr                      = VirmenTowersSetupNewCues.computeWorld(vr);
    %Based on trial info get all cue positions in a cell
    vr                      = VirmenTowersSetupNewCues.getCueObject(vr);
    
    % The recomputed world should remain invisible until after the ITI
    vr.worlds{vr.currentWorld}.surface.visible(:) = false;

  % Adjust the reward level and trial drawing method
  % ALS updateRweord and DrawMethod in BCONTROL
  end

  % ALS trial type etc, decided in BControl
  % Select a trial type, i.e. whether the correct choice is left or right
%   [success, vr.trialProb]   = vr.protocol.drawTrial(vr.mazeID, [-vr.lStart, vr.lCue + vr.lMemory + 40]);
%   if isempty(vr.forcedIndex)
%     vr.experimentEnded      = ~success;
%     vr.trialType            = Choice(vr.protocol);
%   else
%     vr.trialProb            = nan;
%     vr.trialType            = vr.forcedTypes(vr.forcedIndex);
%     vr.forcedIndex          = mod(vr.forcedIndex, numel(vr.forcedTrials)) + 1;
%   end
%   vr.wrongChoice            = setdiff(ChoiceExperimentStats.CHOICES, vr.trialType);

  % Flags for animal's progress through the maze
  vr.iCueEntry              = vr.iterFcn(0);
  vr.iMemEntry              = vr.iterFcn(0);
  vr.iTurnEntry             = vr.iterFcn(0);
  vr.iArmEntry              = vr.iterFcn(0);
  vr.iBlank                 = vr.iterFcn(0);

  % Cue presence on right and wrong sides
  vr      = VirmenTowersSetupNewCues.drawCueSequenceMin(vr);
  
  % Visibility range of visual guides
  vr.hintVisibleFrom        = vr.hintVisibility;
  
  % Modify ViRMen world object visibilities and colors 
  vr                        = VirmenTowersSetupNewCues.configureCues(vr);
  
  % automatically adjust reward if necessary
  % ALS, BControl side
  %vr                        = autoAdjustReward(vr);

end
