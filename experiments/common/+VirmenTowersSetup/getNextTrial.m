function [ vr ] = getNextTrial( vr )
%Get by tcp communication next trial for the experiment
% The trial structure should have the next fields
%cuePos
%cueCombo
%trialType

raw_data = comm.tcp.get_binary_mat_file(vr.tcp_client);
trial_structure = comm.utility.load_binary_data(raw_data);

vr.cuePos    = trial_structure.cuePos;
vr.cueCombo  = trial_structure.cueCombo;
vr.trialType  = trial_structure.trialType;

vr.nSalient = trial_structure.nSalient;
vr.nDistract = trial_structure.nDistract;

vr.mazeID = trial_structure.mazeID;
vr.mainMazeID = trial_structure.mainMazeID;


end

