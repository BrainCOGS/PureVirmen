classdef TowersTaskRegion < VirmenRegions.BaseRegionClass
% Define Region properties as well as rules to apply during maze navigation
    
    properties
           REGION_TYPE             = 'Linear';
    end
    
    methods
        
        function obj = TowersTaskRegion()
            
            obj.region_table = obj.define_regions();
            obj.region_table = VirmenBControl.utils.convert_type_table_columns(...
                obj.region_table, obj.REGION_PROPERTIES_TYPE);
            
        end
        
        function region_table = define_regions(obj)
            
            %Define an empty table
            region_prop = obj.REGION_PROPERTIES;
            region_table = array2table(cell(0,length(region_prop)), ...
                'VariableNames', region_prop);
            
            % User can modify this definitions
            % Defines properties for each one of the fields,
            %_____________________________region_name__coordinate___selector_function___cross___entry__rules__rules_handles
            region_table(end+1,:) = table({'start'},       {2},     {@min},            {NaN},   {NaN},  {''}, {''});
            region_table(end+1,:) = table({'cue'},         {2},     {@min},            {NaN},   {NaN},  {''}, {''});
            region_table(end+1,:) = table({'memory'},      {2},     {@min},            {NaN},   {NaN},  {''}, {''});
            region_table(end+1,:) = table({'turn'},        {2},     {@min},            {NaN},   {NaN},  {''}, {''});
            region_table(end+1,:) = table({'arms'},        {2},     {@min},            {NaN},   {NaN},  {''}, {''});
            region_table(end+1,:) = table({'choiceL'},     {1},     {@minabs},         {NaN},   {NaN},  {''}, {''});
            region_table(end+1,:) = table({'choiceR'},     {1},     {@minabs},         {NaN},   {NaN},  {''}, {''});
            
        end
        
    end
    
    %Static methods are used to rules to apply during navigation
    methods(Static = true)
       
        % Rules that are applied during a specific region of maze
        vr = standard_start_rules(vr);
        vr = standard_cue_rules(vr);
        vr = standard_memory_rules(vr);
        vr = standard_turn_rules(vr);
        vr = standard_arm_rules(vr);
        vr = standard_violation_rules(vr);
        
        % Rules that are applied during all trial
        vr = motion_blurring_rules(vr);
        vr = time_based_rules(vr);
        vr = dynamic_landmark_rules(vr);
        vr = dynamic_sky_rules(vr);
        
    end
end

