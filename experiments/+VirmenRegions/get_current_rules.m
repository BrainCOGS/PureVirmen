function current_rules = get_current_rules( region_struct, region_idx )
%UPDATE_CURRENT_RULES get rules to apply on trial
% Inputs
% region_struct  = structure with all region information
% region_idx     = index of region reached
% Outputs
% current_rules = rules to apply on current trial

region_rules       = region_struct.region_table.rules_handles(region_idx);
if isempty(region_rules{1})
    current_rules      = region_struct.whole_trial_rules_handles;
else
    current_rules      = [region_rules region_struct.regions.whole_trial_rules_handles];
end


end

