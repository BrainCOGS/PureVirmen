function code = alvaro_BPOD_poisson3
% poisson_towers   Code for the ViRMEn experiment poisson_towers.
%   code = poisson_towers   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.

% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime        = @runtimeCodeFun;
code.termination    = @terminationCodeFun;
% End header code - DO NOT EDIT

%code.setup          = @setupTrials;

end


%_________________________________________________________________________
% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)

% Close previously opened communications
comm.close_all_comm();

%Initialize Serial Module BPOD
vr.BpodMod = PCBPODModule('COM3');
event = vr.BpodMod.readEvent()

% Initialize tcp comm with Bcontrol
  vr.tcp_client = comm.tcp.initialize_tcp( ...
      VirmenCommParameters.ipAddressBControl, ...
      VirmenCommParameters.tcpClientPort, ...
      VirmenCommParameters.networkRole, ...
      VirmenCommParameters.outputBufferSize);

  pause(0.5);
  vr.virmen_structures = comm.virmen_specific.get_all_virmen_vars(vr.tcp_client);
  
%Code when we want to test it alone...  
%save('C:\Users\BrainCogs_Projects\ViRMEn_BPOD\+virmen_utils\virmen_structures_test.mat', ...
%   'virmen_structures');
% test_virmen_struct = load('C:\Users\BrainCogs_Projects\ViRMEn_BPOD\+virmen_utils\virmen_structures_test.mat');
% test_virmen_struct.virmen_structures.protocol_file = ...
%     virmen_utils.get_protocol_hniehE65_20180202();
%vr.virmen_structures = test_virmen_struct.virmen_structures;


%vr.virmen_structures.trainee_file.mainMazeID = 4;

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
                vr.state              = BehavioralState.WithinTrial;
                vr.act_comm = true;
                vr                    = teleportToStart(vr);
                
                
                %========================================================================
            case BehavioralState.WithinTrial
                
                % Epoch-specific event handlers
                
                vr.trial_region = VirmenTowersSetup.getRegionMaze(vr);
                
                switch vr.trial_region
                    % Check if animal has met the trial violation criteria
                    case  Region.Violation
                        %vr.BpodMod.sendEvent(10);
                        vr = VirmenTowersSetup.violationRulesExec(vr);
                        
                        % Check if animal has entered a choice region after it has entered an arm
                    case Region.InArm
                        vr = VirmenTowersSetup.inArmRulesExec(vr);
                        
                        % Check if animal has entered the T-maze arms after the turn region
                    case Region.InTurn
                        vr = VirmenTowersSetup.inTurnRulesExec(vr);
                        
                        % Check if animal has entered the turn region after the memory period
                    case Region.InMemory
                        vr = VirmenTowersSetup.inMemoryRulesExec(vr);
                        
                        % Check if animal has entered the memory region after the cue period
                    case Region.InMemoryZero
                        vr = VirmenTowersSetup.inMemory0RulesExec(vr);
                        
                        % If still in the start region, do nothing
                    case Region.InStart
                        vr = VirmenTowersSetup.inStartRulesExec(vr);
                        
                        % If in the cue region, make cues visible when the animal is close enough
                    case Region.InCues
                        vr = VirmenTowersSetup.inCuesRulesExec(vr);
                end
                
                % Time-based visibility controls
                vr = VirmenTowersSetup.timeBasedRulesExec(vr);
                
                % Dynamic sky colors
                vr = VirmenTowersSetup.dynamicSkyRulesExec(vr);
                
                % Dynamic landmarks
                vr = VirmenTowersSetup.dynamicLandmarksRulesExec(vr);
                
                % Apply motion blurring to cues
                vr = VirmenTowersSetup.applyMotionBlurring(vr);
                
                %========================================================================
            case BehavioralState.ChoiceMade
                
                % Log the end of the trial
                position_vec = vr.logger.currentTrial.position(1:vr.logger.iterationStamp(), :);
                vr.excessTravel = calculateExcessTravel(...
                                        distanceTraveled(position_vec), vr.mazeLength);
                vr.logger.logEnd();
                
                trial_comm = vr.logger.getTrialSendComm();
                trial_bin = virmen_utils.struct2binary(trial_comm); 
                comm.tcp.send_binary_mat_file(vr.tcp_client, trial_bin)
                
                %Send info from past trial
                                
                % Handle reward/punishment and end of trial pause
                %ALS, this is done in BControl
                vr.state      = BehavioralState.EndOfTrial;
                %vr = judgeVRTrial(vr);
                
                %vr.BpodMod.sendEvent(255);
                %fwrite(vr.tcp_client, 255)
                vr.act_comm = false;
                
                
                %========================================================================
            case BehavioralState.EndOfTrial
                
                % Send signals indicating end of trial and start inter-trial interval
                vr          = endVRTrial(vr);
                vr.iBlank   = vr.iterFcn(vr.logger.iterationStamp());
                
                
                %========================================================================
            case BehavioralState.InterTrial
                % Handle input of comments etc.
                vr.logger.logExtras(vr);
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
    %vr.protocol.update();
    
    %vr = BPOD_signal_frames(vr);
    %vr = comm.tcp.trial_tcp_data(vr);
    
    % Send DAQ signals for multi-computer synchronization
    %updateDAQSyncSignals(vr.iterFcn(loggingIndices));
    
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
    vr.logger.save(vr.timeElapsed);
    
end

% Standard communications shutdown
terminateVRRig(vr);

% write to google database
%try writeTrainingDataToDatabase(log,vr); catch; warning('Problem writing to database, please check spreadsheet'); end

end






