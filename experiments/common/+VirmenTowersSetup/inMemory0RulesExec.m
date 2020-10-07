function [ vr ] = inMemory0RulesExec( vr )
%inMemory0RulesExec Summary of this function goes here
%Code executed when subject enters first time to Memory Region PoissonTowers

vr.iMemEntry        = vr.iterFcn(vr.logger.iterationStamp());
vr.BpodMod.sendEvent(4);

if isPastCrossing(vr.cross_turn, vr.position)
    vr.BpodMod.sendEvent(5);
    vr.iTurnEntry     = vr.iterFcn(vr.logger.iterationStamp());
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

end

