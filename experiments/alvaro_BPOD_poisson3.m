function code = alvaro_BPOD_poisson3
% poisson_towers   Code for the ViRMEn experiment poisson_towers.
%   code = poisson_towers   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.

  % Begin header code - DO NOT EDIT
  code.initialization = @initializationCodeFun;
  code.runtime        = @runtimeCodeFun;
  code.termination    = @terminationCodeFun;
  % End header code - DO NOT EDIT

  code.setup          = @setupTrials;

end


%%_________________________________________________________________________
% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)

  % Close previously opened communications
  comm.close_all_comm();
  
  % Initialize tcp comm with Bcontrol
  vr.tcp_client = comm.initialize_tcp( ...
      VirmenCommParameters.ipAddressBControl, ...
      VirmenCommParameters.tcpClientPort, ...
      VirmenCommParameters.networkRole, ...
      VirmenCommParameters.outputBufferSize);
  
  vr.virmen_structures = comm.virmen_specific.get_all_virmen_vars(vr.tcp_client);
          
  vr.exper.userdata.trainee = virmen_structures.trainee;
  
  % Number and sequence of trials, reward level etc.
  vr    = VirmenTowersSetup.setupTrials(vr);
  
  % test motion detection
  if RigParameters.hasDAQ
    vr  = checkSqual(vr);
  end
  
  % Standard communications lines for VR rig
  vr    = initializeVRRig(vr, vr.exper.userdata.trainee);
  
  %****** DEBUG DISPLAY ******
  vr = VirmenTowersSetup.debugDisplaySetup(vr);

  vr.act_comm   = false;
  
  %ALS fix for now, to change maze 
  vr.flagmazeChanged = 1;

    
  %***************************

end


%%_________________________________________________________________________
% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)
try

  %% Handle wait times
  if vr.waitTime ~= 0
    [vr.waitStart, vr.waitTime] = processWaitTimes(vr.waitStart, vr.waitTime);
  end
  vr.prevState  = vr.state;

    
  %% Forced termination, or else do epoch-specific things
  if isinf(vr.protocol.endExperiment)
    vr.experimentEnded  = true;
  elseif vr.waitTime == 0   % Only if not in a time-out period...
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

      vr                    = VirmenTowersSetup.initializeTrialWorld(vr);
      if vr.protocol.endExperiment == true
        % Allow end of experiment only after completion of the last trial
        vr.experimentEnded  = true;
      elseif ~vr.experimentEnded
        vr.state            = BehavioralState.InitializeTrial;
        vr                  = teleportToStart(vr);
      end
      

    %========================================================================
    case BehavioralState.InitializeTrial
      % Teleport to start and send signals indicating start of trial
      vr                    = teleportToStart(vr);
      vr                    = startVRTrial(vr);
      prevDuration          = vr.logger.logStart(vr);
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
        
      %% Epoch-specific event handlers
              
      %------------------------------------------------------------------------
      % Check if animal has met the trial violation criteria
      if isViolationTrial(vr)
        %vr.BpodMod.sendEvent(10);
        vr.choice           = Choice.nil;
        vr.state            = BehavioralState.ChoiceMade;

      %------------------------------------------------------------------------
      % Check if animal has entered a choice region after it has entered an arm
      elseif vr.iArmEntry > 0
        for iChoice = 1:numel(vr.cross_choice)
          if isPastCrossing(vr.cross_choice(iChoice), vr.position)
            vr.choice       = Choice(iChoice);
            if vr.choice == 'L'
                %vr.BpodMod.sendEvent(7);
            else
                %vr.BpodMod.sendEvent(8);
            end            
            
            vr.state        = BehavioralState.ChoiceMade;
            break;
          end
        end

      %------------------------------------------------------------------------
      % Check if animal has entered the T-maze arms after the turn region
      elseif vr.iTurnEntry > 0
        if isPastCrossing(vr.cross_arms, vr.position)
          %vr.BpodMod.sendEvent(6);
          vr.iArmEntry      = vr.iterFcn(vr.logger.iterationStamp(vr));
        end

      %------------------------------------------------------------------------
      % Check if animal has entered the turn region after the memory period
      elseif vr.iMemEntry > 0
        if isPastCrossing(vr.cross_turn, vr.position)
          %vr.BpodMod.sendEvent(5);
          vr.iTurnEntry     = vr.iterFcn(vr.logger.iterationStamp(vr));
        end
        
        % Also test for entry in the arm in case there is no turn region
        if isPastCrossing(vr.cross_arms, vr.position)
          %vr.BpodMod.sendEvent(6);
          vr.iArmEntry      = vr.iterFcn(vr.logger.iterationStamp(vr));
        end
        
        % Turn single visual guide to bilateral (or invisible) after a given distance
        for iHint = 1:numel(vr.choiceHintNames)
          if      (vr.hintVisibleFrom(iHint) < 0 || vr.hintVisibleFrom(iHint) > 2)    ...
              &&  vr.stemLength - vr.position(2) <= abs(vr.hintVisibleFrom(iHint))
            triHint         = vr.(vr.choiceHintNames{iHint});
            visibility      = vr.hintVisibleFrom(iHint) < 0;
            if iscell(triHint)
              for iSide = 1:numel(triHint)
                vr.worlds{vr.currentWorld}.surface.visible(triHint{iSide})  = visibility;
              end
            else
              vr.worlds{vr.currentWorld}.surface.visible(triHint)           = visibility;
            end
            vr.hintVisibleFrom(iHint)                                       = nan;
          end
        end
        
      %------------------------------------------------------------------------
      % Check if animal has entered the memory region after the cue period
      elseif vr.iCueEntry > 0 && isPastCrossing(vr.cross_memory, vr.position)
        %vr.BpodMod.sendEvent(4);
        vr.iMemEntry        = vr.iterFcn(vr.logger.iterationStamp(vr));
        if isPastCrossing(vr.cross_turn, vr.position)
          %vr.BpodMod.sendEvent(5);
          vr.iTurnEntry     = vr.iterFcn(vr.logger.iterationStamp(vr));
        end

        % Turn off visibility of cues in memory region (instead of time-based disappearance)
        if isinf(vr.cueDuration)
          vr.worlds{vr.currentWorld}.surface.visible = vr.defaultVisibility;
        end
        
        % turn off visual guide if so desired
        if vr.mazes(vr.mazeID).turnHint_Mem
          for iHint = 1:numel(vr.choiceHintNames)
            triHint         = vr.(vr.choiceHintNames{iHint});
            if iscell(triHint)
              for iSide = 1:numel(triHint)
                vr.worlds{vr.currentWorld}.surface.visible(triHint{iSide})  = false;
              end
            else
              vr.worlds{vr.currentWorld}.surface.visible(triHint)           = false;
            end
            vr.hintVisibleFrom(iHint)                                       = nan;
          end
        end
        
      %------------------------------------------------------------------------
      % If still in the start region, do nothing
      elseif vr.iCueEntry < 1 && ~isPastCrossing(vr.cross_cue, vr.position)
        vr.velocity(end)    = 0;
        vr.position(end)    = 0;

      % If in the cue region, make cues visible when the animal is close enough
      else
        if vr.iCueEntry < 1
          %vr.BpodMod.sendEvent(3);  
          vr.iCueEntry      = vr.iterFcn(vr.logger.iterationStamp(vr));
        end
        
        % Cues are triggered only when animal is facing forward
        if abs(angleMPiPi(vr.position(end))) < pi/2

          %% Loop through cues on both sides of the maze
          for iSide = 1:numel(ChoiceExperimentStats.CHOICES)
            %% If the cue is not on, check if we should turn it on
            cueDistance     = vr.cuePos{iSide} - vr.position(2);
            isTriggered     = ~vr.cueAppeared{iSide}              ...
                            & (cueDistance <= vr.cueVisibleAt)    ...
                            ;              
            if ~any(isTriggered)
              continue;
            end
            
            %% If approaching a cue and near enough, make it visible in the next iteration
            triangles     = vr.tri_turnCue(iSide,:,isTriggered);
            vr.cueAppeared{iSide}(isTriggered)  = true;
            vr.cueOnset{iSide}(isTriggered)     = vr.logger.iterationStamp(vr);
            vr.cueTime{iSide}(isTriggered)      = vr.timeElapsed;
            if ~(vr.cueDuration < 0)            %% negative durations (but not NaNs) makes cues invisible
              vr.worlds{vr.currentWorld}.surface.visible(triangles) = true;
            end

            %% If right side tower, deliver right side puff, else left side puff 
            if RigParameters.hasDAQ && vr.puffDuration > 0
              if iSide == Choice.R
                  nidaqPulse3('ttl', vr.puffDuration);      %% puffDuration in ms, S. Bolkan uses 40ms
              else                 
                  nidaqPulse4('ttl', vr.puffDuration);
              end
            end
          end
        end
      end
      
      
      %% Time-based visibility controls
      
      %------------------------------------------------------------------------
      % If a cue is already on, turn it off if enough time has elapsed
      for iSide = 1:numel(ChoiceExperimentStats.CHOICES)
        isTurnedOff         = ( vr.timeElapsed - vr.cueTime{iSide} >= vr.cueDuration );
        if any(isTurnedOff)
          triangles         = vr.tri_turnCue(iSide,:,isTurnedOff);
          vr.cueTime{iSide}(isTurnedOff)    = nan;
          vr.cueOffset{iSide}(isTurnedOff)  = vr.logger.iterationStamp(vr);
          vr.worlds{vr.currentWorld}.surface.visible(triangles) = false;
        end
      end
      
      %% Dynamic sky colors
      if ~isempty(vr.skySwitchInterval) 
        if vr.timeElapsed - vr.prevSkySwitch >= vr.nextSkySwitch
          %% Draw a new sky color, excluding the current one
          newColor          = randi(numel(vr.skyColorCode)-1);
          if newColor >= vr.currentSkyColor
            newColor        = vr.currentSkyColor + 1;
          end
          vr.currentSkyColor= newColor;
          
          %% Apply colors
          for iSky = 1:numel(vr.clr_sky)
            for iPattern = 1:size(vr.skyColorCombo,2)
              newColor      = vr.skyColors{iSky}(vr.skyColorCombo(vr.currentSkyColor, iPattern),:);
              for iRGB = 1:numel(newColor)
                vr.worlds{vr.currentWorld}.surface.colors(iRGB,vr.clr_sky{iSky}{iPattern})   ...
                            = newColor(iRGB);
              end
            end
          end
          
          %% Record iteration and pattern of the sky
          vr.skySwitch(end+1,1) = vr.logger.iterationStamp(vr);
          vr.skySwitch(end,2)   = vr.skyColorCode(vr.currentSkyColor);
          vr.prevSkySwitch  = vr.timeElapsed;
          vr.nextSkySwitch  = vr.skySwitchInterval(1) + exprnd(vr.skySwitchInterval(2));
        end
      end
      
      
      %% Dynamic landmarks

      % Landmarks are triggered only when animal is facing forward
      if abs(angleMPiPi(vr.position(end))) < pi/2
        for iLM = 1:numel(vr.dynamicLandmarks)

          %% If the landmark is not on, check if we should turn it on
          lmarkDistance     = vr.landmarkPos{iLM} - vr.position(2);
          isTriggered       = ~vr.landmarkAppeared{iLM}                 ...
                            & (lmarkDistance <= vr.landmarkVisibleAt)   ...
                            ;
          if ~any(isTriggered)
            continue;
          end
          
          %% If approaching a landmark and near enough, make it visible in the next iteration
          triangles     = vr.tri_landmark{iLM}(:,isTriggered);
          vr.landmarkAppeared{iLM}(isTriggered) = true;
          vr.landmarkOnset{iLM}(isTriggered)    = vr.logger.iterationStamp(vr);
          vr.worlds{vr.currentWorld}.surface.visible(triangles) = true;
          
        end
      end
      

    %========================================================================
    case BehavioralState.ChoiceMade
        
      % Log the end of the trial
      vr.excessTravel = vr.logger.distanceTraveled() / vr.mazeLength - 1;
      vr.logger.logEnd(vr);

      % Handle reward/punishment and end of trial pause
      %ALS, this is done in BCOntrol
      vr.state      = BehavioralState.EndOfTrial;
      %vr = judgeVRTrial(vr);
      
      %vr.BpodMod.sendEvent(255);
      %fwrite(vr.tcp_client, 255)
      vr.act_comm = false;


    %========================================================================
    case BehavioralState.EndOfTrial
        
      % Send signals indicating end of trial and start inter-trial interval  
      vr          = endVRTrial(vr);    
      vr.iBlank   = vr.iterFcn(vr.logger.iterationStamp(vr));


    %========================================================================
    case BehavioralState.InterTrial
      % Handle input of comments etc.
      vr.logger.logExtras(vr, vr.rewardFactor);
      vr.state    = BehavioralState.SetupTrial;
      if ~RigParameters.hasDAQ
        vr.worlds{vr.currentWorld}.backgroundColor  = [0 0 0];
      end

      % Decide duration of inter trial interval
      if vr.choice == vr.trialType
        vr.waitTime       = vr.itiCorrectDur;
      else
        vr.waitTime       = vr.itiWrongDur;
      end
      
    %========================================================================
    case BehavioralState.EndOfExperiment
      vr.experimentEnded  = true;

  end
  end                     % Only if not in time-out period

  
  %% Apply motion blurring to cues
  dy                      = vr.lastDP(2) + vr.dp(2);
  vr.lastDP               = vr.dp;
  if ~isempty(vr.motionBlurRange)
    % Quantities for motion blurring
    blurredWidth          = vr.yCue + abs(dy);
    
    % Only visible cues within a given distance of the animal are blurred
    isBlurred             = false(size(vr.vtx_turnCue));
    if abs(dy) > vr.motionBlurRange(1)
      for iSide = 1:numel(vr.cuePos)
        isBlurred(iSide, :, vr.cueAppeared{iSide}                                           ...
                          & abs(vr.cuePos{iSide} - vr.position(2)) < vr.motionBlurRange(2)  ...
                          ) = true;
      end
    else
      isBlurred(:)        = false;
    end
    isReset               = vr.cueBlurred & ~isBlurred;
    vr.cueBlurred         = isBlurred;
    
    % Reset cues that are no longer blurred
    vertices            = vr.vtx_turnCue(isReset);
    if ~isempty(vertices)
      vtxOffset         = vr.template_turnCue(isReset) * vr.yCue;
      vr.worlds{vr.currentWorld}.surface.vertices(2,vertices)     ...
                        = vr.pos_turnCue(isReset) + vtxOffset;
      if ~isnan(vr.dimCue)
        vr.worlds{vr.currentWorld}.surface.colors(:,vertices)     ...
                        = vr.color_turnCue(:,1:numel(vertices));
      end
    end
    
    % Elongate cues opposite to direction of motion
    vertices            = vr.vtx_turnCue(isBlurred);
    if ~isempty(vertices)
      vtxOffset         = dy/2 + vr.template_turnCue(isBlurred) * blurredWidth;
      vr.worlds{vr.currentWorld}.surface.vertices(2,vertices)     ...
                        = vr.pos_turnCue(isBlurred) + vtxOffset;
    
      % Impose a falloff gradient if so desired
      if ~isnan(vr.dimCue)
        if abs(angleMPiPi(vr.position(end))) < pi/2
          vtxOffset     = vr.template_turnCue(isBlurred);
        else
          vtxOffset     = -vr.template_turnCue(isBlurred);
        end
        edgeLoc         = vr.yCue / blurredWidth - 0.5;
        isDimmed        = ( vtxOffset > edgeLoc );

        vtxOffset       = vtxOffset(isDimmed);
        vtxColor        = vr.cueColor                   ...
                        + (vr.dimCue - vr.cueColor)     ...
                        * (vtxOffset - edgeLoc)         ...
                        / (0.5       - edgeLoc)         ...
                        ;
        
        vr.worlds{vr.currentWorld}.surface.colors(:,vertices(isDimmed))   ...
                        = bsxfun(@times, vtxColor', RigParameters.colorAdjustment);
      end
    end
  end
  
  
  %% IMPORTANT: Log position, velocity etc. at *every* iteration
  loggingIndices        = vr.logger.logTick(vr, vr.sensorData);
  %vr.protocol.update();
 
  %vr = BPOD_signal_frames(vr);
  vr = BPOD_communication(vr);

  % Send DAQ signals for multi-computer synchronization
  updateDAQSyncSignals(vr.iterFcn(loggingIndices));
  
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
    vr.logger.save(true, vr.timeElapsed, vr.protocol.getPlots());

    %vr.exper.userdata.regiment.recordBehavior(vr.exper.userdata.trainee, log, vr.logger.newBlocks);
    %vr.exper.userdata.regiment.save();
  end

  % Standard communications shutdown
  terminateVRRig(vr);
  
  % write to google database
  %try writeTrainingDataToDatabase(log,vr); catch; warning('Problem writing to database, please check spreadsheet'); end

end

function vr = BPOD_signal_frames(vr)

if vr.act_comm
    event = vr.BpodMod.readEvent();
    if event ~= -1
        
        if char(event(1)) == 'C'
            color = event(2);
            if color == 1
                vr.countcolor = vr.countcolor + 1;
                if vr.countcolor > length(vr.colormap)
                    vr.countcolor = 1;
                end
                
                %vr.worlds{vr.currentWorld}.backgroundColor  = vr.colormap(vr.countcolor, :);
            end
            
        end
        
    end
    %vr.BpodMod.sendEvent(1);
    
end

end

function vr = BPOD_communication(vr)

if vr.act_comm
    time = single(vr.logger.currentTrial.time(vr.logger.currentIt,1));
    %time = 5.5;
    serialdata = typecast([single(vr.position(ExperimentLog.SPATIAL_COORDS)) ...
                           single(vr.velocity(ExperimentLog.SPATIAL_COORDS)) ...
                           time],'uint8');
                       
  if ~isempty(vr.sensorData)                     
   serialdata = [serialdata ...
                  typecast(vr.sensorData(ExperimentLog.SENSOR_COORDS), 'uint8')];
  else
   serialdata = [serialdata uint8(zeros(1, numel(ExperimentLog.SENSOR_COORDS)*2))];
  end
      
      
   %serialdata = [serialdata  uint8(vr.collision) uint8('\n')];
   serialdata = [serialdata  uint8(vr.collision)];
   serialdata = double(serialdata);
   %serialdata = serialdata(1:10);
   %if length(serialdata) < 39
   %    aquipapa =1
   %end
   %pause(0.02);
   fwrite(vr.tcp_client, serialdata)
    %vr.BpodMod.sendEvent(serialdata);
    %pause(0.02)
end
% if vr.act_comm
%     event = vr.BpodMod.readEvent();
%     if event ~= -1
%         
%         if char(event(1)) == 'C'
%             color = event(2);
%             if color == 1
%                 vr.countcolor = vr.countcolor + 1;
%                 if vr.countcolor > length(vr.colormap)
%                     vr.countcolor = 1;
%                 end
%                 
%                 vr.worlds{vr.currentWorld}.backgroundColor  = vr.colormap(vr.countcolor, :);
%             end
%             
%         end
%         
%     end
%     %vr.BpodMod.sendEvent(1);
%     
% end

end


