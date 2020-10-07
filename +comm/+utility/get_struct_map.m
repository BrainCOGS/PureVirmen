function struct_map = get_struct_map( structure )
%GET_STRUCT_MAP
% Get a map of all classes "types" for all fields in a structure
% Inputs
% structure   = struct that is going to be mapped
% Outputs
% structure   = map for each field of the structure

% e.g.
%   structure.position   = double([1;  1.5; 2 ])
%   structure.sensor     = uint16([0  50  100 ];[0  50  100 ])
%
%   struct_map = comm.utility.get_struct_map(structure)
%   struct_map
%             {{'position', 'double', 3}, {'sensor', 'uint16', 2}}

% Get all fields
fields = fieldnames(structure);

% Get all types
types = cellfun(@(x) class(structure.(x)), fields, 'UniformOutput', false);

% Get dim 2 (columns) of arrays of struct
columns = cellfun(@(x) size(structure.(x),2), fields, 'UniformOutput', false);

% Merge map
struct_map = cellfun(@(x,y,z) {x,y,z}, fields, types, columns, 'UniformOutput', false);


end

