function [ vr ] = inTurnRulesExec( vr )
%inTurnRulesExec Summary of this function goes here
%Code executed when turn epoch is reached by subject PoissonTowers



if isPastCrossing(vr.cross_arms, vr.position)
    %vr.BpodMod.sendEvent(6);
    vr.iArmEntry      = vr.iterFcn(vr.logger.iterationStamp());
end

end

