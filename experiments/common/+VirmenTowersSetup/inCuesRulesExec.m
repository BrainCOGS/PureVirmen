function [ vr ] = inCuesRulesExec( vr )
%inMemoryRulesExec Summary of this function goes here
%Code executed when subject is inside Cue Region PoissonTowers

if vr.iCueEntry < 1
    %vr.BpodMod.sendEvent(3);
    vr.iCueEntry      = vr.iterFcn(vr.logger.iterationStamp());
end

% Cues are triggered only when animal is facing forward
if abs(angleMPiPi(vr.position(end))) < pi/2
    
    %% Loop through cues on both sides of the maze
    for iSide = 1:numel(Choice.all())
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
        vr.cueOnset{iSide}(isTriggered)     = vr.logger.iterationStamp();
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

