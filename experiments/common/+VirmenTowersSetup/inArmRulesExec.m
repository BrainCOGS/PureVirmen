function [ vr ] = inArmRulesExec( vr )
%INARMRULESEXEC
% Code executed when subject is in an Arm (choice) in Poisson Towers 

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
end

