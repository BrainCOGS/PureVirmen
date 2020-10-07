function [ vr ] = inMemoryRulesExec( vr )
%inMemoryRulesExec Summary of this function goes here
%Code executed when subject is inside Memory Region PoissonTowers

%Check for turn crossing
if isPastCrossing(vr.cross_turn, vr.position)
    vr.BpodMod.sendEvent(5);
    vr.iTurnEntry     = vr.iterFcn(vr.logger.iterationStamp());
end

% Also test for entry in the arm in case there is no turn region
if isPastCrossing(vr.cross_arms, vr.position)
    %vr.BpodMod.sendEvent(6);
    vr.iArmEntry      = vr.iterFcn(vr.logger.iterationStamp());
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

end

