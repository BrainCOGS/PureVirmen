function [ vr ] = getNextTrialFromTable( vr )
%Get by tcp communication next trial for the experiment
% The trial structure should have the next fields
%cuePos
%cueCombo
%trialType

ac_trial   = vr.trialTable(vr.trial_idx_now,:);
ac_stimuli = getStimuli(ac_trial, vr.test_stimuli);
vr.trial_idx_now   = vr.trial_idx_now   + 1;

vr.cuePos    = ac_stimuli.cuePos;
vr.cueCombo  = ac_stimuli.cueCombo;
vr.trialType = ac_stimuli.trialType;

end

