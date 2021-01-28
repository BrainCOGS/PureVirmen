classdef BaseRegionClass < handle
    % Defines a table to name and configure all regions on a Virmen-BControl experiment 
    
    %------- Constants
    properties (Constant)
        
        REGION_PROPERTIES       = {'region_name', 'coordinate', ...
            'selector_function', 'cross',  'entry', ...
            'rules'};
        
        REGION_PROPERTIES_TYPE  = {'categorical',   'numeric',    ...
            'cell',              'cell' ,  'numeric', ...
            'cell'};
    end
    
    %------- Public data
    properties (SetAccess = protected, Transient)
        region_table
    end
    
    %________________________________________________________________________
    methods
        
        function struct_comm = get_struct_comm(obj)
            
            struct_comm.region_table = obj.region_table;
            struct_comm.region_type  = obj.REGION_TYPE;
  
        end
        
        function set_region_rules(obj, region_name, rules_list)
            % Set rule column for a specific region name
            % Inputs
            % region_name   = a string that matches a region 
            % rules_list    = list of rules to apply on that region
            
            idx_region = obj.region_table.region_name == region_name;
            if isempty(idx_region)
                warning([region_name ' was not found on region table. ' ...
                    'No rules were set'])
                return
            end
            
            obj.region_table{idx_region, 'rules'} = rules_list;
            
        end
        
        function set_rule_table(obj, rule_table)
            % Set rule column for a group of regions defined in a table
            % Inputs
            % rule_table   = table with region-rules relationship
            
            for i=1:size(rule_table,1)
                obj.set_region_rules(obj, rule_table.region{i}, rule_table.rules{i})
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

