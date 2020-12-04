function [ vr ] = inMemoryRulesExec( vr )
%inMemoryRulesExec Summary of this function goes here
%Code executed when subject is inside Memory Region PoissonTowers

%Check for turn crossing
% if isPastCrossing(vr.cross_turn, vr.position)
%     vr.BpodMod.sendEvent(5);
%     vr.iTurnEntry     = vr.iterFcn(vr.logger.iterationStamp());
% end
%
% % Also test for entry in the arm in case there is no turn region
% if isPastCrossing(vr.cross_arms, vr.position)
%     %vr.BpodMod.sendEvent(6);
%     vr.iArmEntry      = vr.iterFcn(vr.logger.iterationStamp());
% end

%First time in memory region
if vr.region_changed
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
    
else
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
    
end

