function vr = experVariables2vr(vr)

% Function to pass and process vr.exper variables directly to vr structure
% Input
% vr     = Virmen Handle
% Output
% vr     = Virmen Handle

% Precompute maximum number of cue towers given the cue region length and
% minimum tower separation
cueMinSeparation      = str2double(vr.exper.variables.cueMinSeparation);
for iMaze = 1:numel(vr.mazes)
    vr.mazes(iMaze).variable.nCueSlots  = num2str(floor( str2double(vr.mazes(iMaze).variable.lCue)/cueMinSeparation ));
end

% Number and mixing of trials
vr.targetNumTrials    = eval(vr.exper.variables.targetNumTrials);
vr.fracDuplicated     = eval(vr.exper.variables.fracDuplicated);
vr.trialDuplication   = eval(vr.exper.variables.trialDuplication);
vr.trialDispersion    = eval(vr.exper.variables.trialDispersion);
vr.panSessionTrials   = eval(vr.exper.variables.panSessionTrials);
vr.trialType          = Choice.nil;
vr.lastDP             = [0 0 0 0];

% Nominal extents of world
vr.worldXRange        = eval(vr.exper.variables.worldXRange);
vr.worldYRange        = eval(vr.exper.variables.worldYRange);

% Trial violation criteria
vr.maxTrialDuration   = eval(vr.exper.variables.maxTrialDuration);
[vr.iterFcn,vr.iterStr] = smallestUIntStorage(vr.maxTrialDuration / RigParameters.minIterationDT);

% Logged variables
vr.sensorMode       = vr.exper.userdata.trainee.virmenSensor;

% variables for easy blocks, auto rewards etc
vr.easyBlockFlag      = false;
vr.updateReward       = true;
vr.rewardAutoUpdated  = false;
vr.numRewardDrops     = 1;


end
