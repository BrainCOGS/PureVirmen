function [ vr ] = inStartRulesExec( vr )
%inStartRulesExec Summary of this function goes here
%Code executed when subject is inside Start Region PoissonTowers

vr.velocity(end)    = 0;
vr.position(end)    = 0;
end

