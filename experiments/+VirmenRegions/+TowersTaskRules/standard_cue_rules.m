function vr = standard_cue_rules( vr )
% Function to be performed on cue part of the maze
% Input/Output
% vr = virmen handle

% Cues are triggered only when animal is facing forward
if abs(angleMPiPi(vr.position(end))) < pi/2
    
    %% Loop through cues on both sides of the maze
    for iCue = 1:numel(vr.vtx_turnCue)
        %% If the cue is not on, check if we should turn it on
        cueDistance     = vr.trial_info.cue_pos_cell{iCue} - vr.position(2);
        isTriggered     = ~vr.cueAppeared{iCue}              ...
            & (cueDistance <= vr.cueVisibleAt)    ...
            ;
        if ~any(isTriggered)
            continue;
        end
        
        %% If approaching a cue and near enough, make it visible in the next iteration
        triangles     = vr.tri_turnCue{iCue}(:,isTriggered);
        vr.cueAppeared{iCue}(isTriggered)  = true;
        vr.cueOnset{iCue}(isTriggered)     = vr.logger.iterationStamp();
        vr.cueTime{iCue}(isTriggered)      = vr.timeElapsed;
        if ~(vr.cueDuration < 0)            %% negative durations (but not NaNs) makes cues invisible
            vr.worlds{vr.currentWorld}.surface.visible(triangles) = true;
        end
        
    end
end

end

