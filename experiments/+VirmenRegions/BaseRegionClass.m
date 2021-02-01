classdef BaseRegionClass < handle
    % Defines a table to name and configure all regions on a Virmen-BControl experiment 
    
    %------- Constants
    properties (Abstract = true)
        
        REGION_TYPE
        
    end
    
    
    properties (Constant)
        
        REGION_PROPERTIES       = {'region_name', 'coordinate', ...
            'selector_function', 'cross',  'entry', ...
            'rules', 'rules_handles'};
        
        REGION_PROPERTIES_TYPE  = {'categorical',   'numeric',    ...
            'cell',              'cell' ,  'numeric', ...
            'cell',  'cell'};
    end
    
    %------- Public data
    properties (SetAccess = protected, Transient)
        region_table
        whole_trial_rules
        whole_trial_rules_handles
    end
    
    %________________________________________________________________________
    methods
        
        function struct_comm = get_struct_comm(obj)
            
            struct_comm = struct();
            prop = properties(obj);
            for i=1:length(prop)
                struct_comm.(prop{i}) = obj.(prop{i});
            end
            
  
        end
        
        function set_region_rules(obj, region_name, rules_list)
            % Set rule column (function handles) for a specific region name
            % Inputs
            % region_name   = a string that matches a region 
            % rules_list    = list of rules to apply on that region
            
            idx_region = obj.region_table.region_name == region_name;
            if isempty(idx_region)
                warning([region_name ' was not found on region table. ' ...
                    'No rules were set'])
                return
            end
            
            rules_list_handles = cellfun(@(x) str2func(strcat(class(obj), '.', x)), ...
            rules_list, 'UniformOutput', false);
            
            obj.region_table{idx_region, 'rules'} = rules_list;
            obj.region_table{idx_region, 'rules_handles'} = rules_list_handles;
            
        end
        
        function set_rule_table(obj, rule_table)
            % Set rule column for a group of regions defined in a table
            % Inputs
            % rule_table   = table with region-rules relationship
            
            for i=1:size(rule_table,1)
                if ~isempty(rule_table.rules{i})
                    obj.set_region_rules(rule_table.region{i}, rule_table.rules(i))
                end
            end
        end
        
        function set_whole_trial_rules(obj,rules_list)
            % Set function handle list for rules during entire trial
            % Inputs
            % rules_list    = list of rules to apply during whole trial
            
            obj.whole_trial_rules = rules_list;
            
            if ~isempty(rules_list{1})
                obj.whole_trial_rules_handles = ...
                    cellfun(@(x) str2func(strcat(class(obj), '.', x)), ...
                    rules_list, 'UniformOutput', false);
            end
            
        end
        
        function check_existance_rules(obj)
            % Check if all functions defined for Regions exist on class
  
            %For all regions on the table
            for i=1:length(obj.region_table.rules)
                rule_region = obj.region_table.rules(i);
                %For all rules on the region
                for j=1:length(rule_region)
                    ac_rule = rule_region{j};
                    %Check if rule is method of object
                    if ~isempty(ac_rule) && ~ismethod(obj, ac_rule)
                        error([ac_rule ' is not a method of ' class(obj)])
                    end
                end
            end
            
            %Check whole trial rules
            for i=1:length(obj.whole_trial_rules)
                trial_rule = obj.whole_trial_rules{i};
                if ~ismethod(obj, trial_rule)
                    error([trial_rule ' is not a method of ' class(obj)])
                end
            end
                    
            
        end
        
    end
        
    methods(Abstract = true)
           %Abstract function to define region names and properties 
           region_table = define_regions(obj);
           
           %Abstract function to get all fields missing fields from virmen side 
           get_specific_virmen_trial_fields(obj)
        
    end
    
end

