function code = BPOD_poisson_final
% poisson_towers   Code for the ViRMEn experiment poisson_towers.
%   code = poisson_towers   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.

% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime        = @runtimeCodeFun;
code.termination    = @terminationCodeFun;
% End header code - DO NOT EDIT

end

%_________________________________________________________________________
% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)

% Close previously opened communications
comm.close_all_comm();

%Initialize Serial Module BPOD
vr.BpodMod = PCBPODModule('COM3');

% Initialize tcp comm with Bcontrol
  vr.tcp_client = comm.tcp.initialize_tcp( ...
      VirmenCommParameters.ipAddressBControl, ...
      VirmenCommParameters.tcpClientPort, ...
      VirmenCommParameters.networkRole, ...
      VirmenCommParameters.outputBufferSize);

  pause(0.5);
  vr.virmen_structures = comm.virmen_specific.get_all_virmen_vars(vr.tcp_client);
  
vr.exper.userdata.trainee = vr.virmen_structures.trainee;

% Number and sequence of trials, reward level etc.
vr    = VirmenTowersSetup.setupTrials(vr);

% test motion detection
if RigParameters.hasDAQ
    vr  = checkSqual(vr);
end

% Standard communications lines for VR rig
vr    = initializeVRRig(vr, vr.virmen_structures.protocol_file);

%****** DEBUG DISPLAY ******
vr = VirmenTowersSetup.debugDisplaySetup(vr);

vr.act_comm   = false;

%ALS fix for now, to change maze
vr.flagmazeChanged = 1;
vr.waitTime        = 0;

%ALS
%just for now
%virmen_past_session = load('C:\Users\BrainCogs_Projects\ViRMEn_BPOD\+virmen_utils\virmen_test_session.mat');
%vr.trial_idx_now  = 1;
%vr.test_stimuli   = virmen_past_session.test_stimuli;
%vr.trialTable     = virmen_past_session.trialsTable;
%***************************

end

% ______________________________________________________________________
% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)
try
    
    % Handle wait times
    %   if vr.waitTime ~= 0
    %     [vr.waitStart, vr.waitTime] = processWaitTimes(vr.waitStart, vr.waitTime);
    %   end
    vr.prevState  = vr.state;
    
    
    % Forced termination, or else do epoch-specific things
    %if isinf(vr.protocol.endExperiment)
    %  vr.experimentEnded  = true;
    if vr.waitTime == 0   % Only if not in a time-out period...
        switch vr.state           % ... take action depending on the simulation state
            
            %========================================================================
            case BehavioralState.SetupTrial
                % Configure world for the trial; this is done separately from
                % StartOfTrial as it can take a long time and we want to teleport the
                % animal back to the start location only after this has been completed
                % and the Virmen engine can do whatever behind-the-scenes magic. If we
                % try to merge this step with StartOfTrial, animal motion can
                % accumulate during initialization and result in an artifact where the
                % animal is suddenly displaced forward upon start of world display.
                
                
                vr                    = VirmenTowersSetup.getNextTrial(vr);
                vr                    = VirmenTowersSetup.initializeTrialWorld(vr);
                %if vr.protocol.endExperiment == true
                % Allow end of experiment only after completion of the last trial
                %  vr.experimentEnded  = true;
                if ~vr.experimentEnded
                    vr.state            = BehavioralState.InitializeTrial;
                    vr                  = teleportToStart(vr);
                end
                
                
                %========================================================================
            case BehavioralState.InitializeTrial
                % Teleport to start and send signals indicating start of trial
                
                event = -1;
                s = 0;
                while event == -1
                    event = vr.BpodMod.readEvent();
                    pause(0.2);
                    disp(event);
                    s = s+1;
                    disp(['Wait start: ' num2str(s)]);
                end
                
                vr.act_comm           = true;
                
                vr                    = teleportToStart(vr);
                vr                    = startVRTrial(vr);
                vr.logger.logStart(vr);
                %vr.protocol.recordTrialDuration(prevDuration);
                
                % Make the world visible
                vr.state              = BehavioralState.StartOfTrial;
                vr.worlds{vr.currentWorld}.surface.visible = vr.defaultVisibility;
                
                
                %========================================================================
            case BehavioralState.StartOfTrial
                % We keep the animal at the start of the track for the first iteration of the trial where
                % the world is actually visible. This is only as a safety factor in case the first rendering
                % (caching) of the world graphics makes the previous iteration take unusually long, in which
                % case displacement is accumulated without the animal actually responding to anything.
                vr.trial_region_idx   = 1;
                vr.current_rules      = vr.virmen_structures.regions.region_table{vr.trial_region_idx, 'rules'};
                vr.state              = BehavioralState.WithinTrial;
                vr.act_comm           = true;
                vr                    = teleportToStart(vr);
                
                
                %========================================================================
            case BehavioralState.WithinTrial
                
                
                if isViolationTrial(vr)
                    s = 0;
                    
                else
                % Get region changes
                [vr.region_changed, vr.trial_region_idx]  = ...
                    VirmenTowersSetup.getRegionMaze(...
                    vr.virmen_structures.regions, vr.trial_region_idx, vr.position);
                
                % Save entry on region structure
                if vr.region_changed
                    vr.virmen_structures.regions.region_table{vr.trial_region_idx, 'entry'} = ...
                        vr.iterFcn(vr.logger.iterationStamp());
                    vr.current_rules      = ...
                        vr.virmen_structures.regions.region_table{vr.trial_region_idx, 'rules'};
                end
                
                apply_rules(vr.current_rules, vr);
                
                end
                
                
                %========================================================================
            case BehavioralState.ChoiceMade
                
                % Log the end of the trial                     
                % Store last variables to the currentTrial
                vr.logger.logEnd();
                vr.logger.logExtras(vr);
                
                % Send trial info to BControl
                trial_comm = vr.logger.getTrialSendComm();
                trial_bin = virmen_utils.struct2binary(trial_comm); 
                comm.tcp.send_binary_mat_file(vr.tcp_client, trial_bin)
                                                
                % Handle reward/punishment and end of trial pause
                %ALS, this is done in BControl
                vr.state      = BehavioralState.EndOfTrial;
                vr.act_comm = false;
                
                
                %========================================================================
            case BehavioralState.EndOfTrial
                
                % Send signals indicating end of trial and start inter-trial interval
                vr          = endVRTrial(vr);
                vr.iBlank   = vr.iterFcn(vr.logger.iterationStamp());
                
                
                %========================================================================
            case BehavioralState.InterTrial
                % Handle input of comments etc.
                
                vr.state    = BehavioralState.SetupTrial;
                if ~RigParameters.hasDAQ
                    vr.worlds{vr.currentWorld}.backgroundColor  = [0 0 0];
                end
                
                % Decide duration of inter trial interval
                %ALS, virmen does not decide waitTime
                vr.waitTime  = 0;
                
                %========================================================================
            case BehavioralState.EndOfExperiment
                vr.experimentEnded  = true;
                
        end
    end                     % Only if not in time-out period
    
    
    % IMPORTANT: Log position, velocity etc. at *every* iteration
    vr.logger.logTick(vr, vr.sensorData);
    
    %****** DEBUG DISPLAY ******
    if ~RigParameters.hasDAQ && ~RigParameters.simulationMode
        vr.text(1).string   = num2str(vr.cueCombo(1,:));
        vr.text(2).string   = num2str(vr.cueCombo(2,:));
        vr.text(3).string   = num2str(vr.cuePos{1}, '%4.0f ');
        vr.text(4).string   = num2str(vr.cuePos{2}, '%4.0f ');
    end
    %***************************
    
catch err
    displayException(err);
    keyboard
    vr.experimentEnded    = true;
end
end

%%_________________________________________________________________________
% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)

% Stop user control via statistics display
%fclose(vr.tcp_client);
%vr.protocol.stop();

% Log various pieces of information
if isfield(vr, 'logger') && ~isempty(vr.logger.logFile)
    % Save via logger first to discard empty records
    vr.logger.save();
    
end

% Standard communications shutdown
terminateVRRig(vr);

% write to google database
%try writeTrainingDataToDatabase(log,vr); catch; warning('Problem writing to database, please check spreadsheet'); end

end






