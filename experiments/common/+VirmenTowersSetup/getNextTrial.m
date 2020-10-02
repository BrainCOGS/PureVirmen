function [ vr ] = getNextTrial( vr )
%Get by tcp communication next trial for the experiment
% The trial structure should have the next fields
%cuePos
%cueCombo
%trialType

trial_structure = comm.tcp.get_binary_mat_file(vr.tcp_client);

vr.cuePos    = trial_structure.cuePos;
vr.cueCombo  = trial_structure.cueCombo;
%vr.trialType = trial_structure.trialType;

end

