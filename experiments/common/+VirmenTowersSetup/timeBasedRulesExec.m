function [ vr ] = timeBasedRulesExec( vr )
%timeBasedRulesExec
% Code executed based on time parameters of protocol Poisson Towers

% If a cue is already on, turn it off if enough time has elapsed
for iSide = 1:numel(Choice.all())
    isTurnedOff         = ( vr.timeElapsed - vr.cueTime{iSide} >= vr.cueDuration );
    if any(isTurnedOff)
        triangles         = vr.tri_turnCue(iSide,:,isTurnedOff);
        vr.cueTime{iSide}(isTurnedOff)    = nan;
        vr.cueOffset{iSide}(isTurnedOff)  = vr.logger.iterationStamp();
        vr.worlds{vr.currentWorld}.surface.visible(triangles) = false;
    end
end

end

