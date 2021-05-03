function [ vr ] = getNextTrial( vr )
%Get by tcp communication next trial for the experiment
% The trial structure should have the next fields
%cuePos
%cueCombo
%trialType

raw_data = comm.tcp.get_binary_mat_file(vr.tcp_client);
trial_structure = comm.utility.load_binary_data(raw_data);

vr.complete_trial_info = trial_structure;

vr.cuePos    = trial_structure.cuePos;
vr.cueCombo  = trial_structure.cueCombo;
vr.trialType  = trial_structure.trialType;

vr.nSalient = trial_structure.nSalient;
vr.nDistract = trial_structure.nDistract;

vr.mazeID = trial_structure.maze_id;
vr.mainMazeID = trial_structure.main_maze_id;
vr.mazeChanged = trial_structure.maze_changed;
vr.experimentEnded = trial_structure.experiment_ended;


end

