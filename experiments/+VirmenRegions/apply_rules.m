function vr = apply_rules(vr, current_rules)
% Function that applies all current virtual rules given for the maze
% Input
% vr             = virmen_handle
% current_rules  = list of handles of functions to rules to apply

% Go through all handles and call them
for i=1:length(current_rules)
    
    ac_rule = current_rules{i};
    %Rules have always vr as input and output
    vr = ac_rule(vr);
end

end

