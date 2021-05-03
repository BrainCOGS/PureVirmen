function vr = time_based_rules( vr )
% Code executed based on time parameters of protocol Poisson Towers
% Input/Output
% vr = virmen handle

% If a cue is already on, turn it off if enough time has elapsed
for iCue = 1:numel(vr.vtx_turnCue)
    isTurnedOff         = ( vr.timeElapsed - vr.cueTime{iCue} >= vr.cueDuration );
    if any(isTurnedOff)
        triangles         = vr.tri_turnCue{iCue}(:,isTurnedOff);
        vr.cueTime{iCue}(isTurnedOff)    = nan;
        vr.cueOffset{iCue}(isTurnedOff)  = vr.logger.iterationStamp();
        vr.worlds{vr.currentWorld}.surface.visible(triangles) = false;
    end
end

end

