function struct_data = get_array_structure(tcp_client, struct_map)
% Protocol to receive structure composed of arrays by tcp
%
% Input
% tcp_client   = tcpip handle for communication
% struct_map   = info about field order and datatype of structure
%
% Outputs
% struct_data  = data after decoding whole structure

%  e.g.
%
%   struct2send.position   = double([1  1.5 2 ])
%   struct2send.sensor     = uint16([0  50  100 ])
%
%   struct_map = comm.utility.get_struct_map(struct2send)
%   struct_map
%             {{'position', 'double'}, {'sensor', 'uint16'}}
%   receivedstruct = get_array_structure(tcp_client, struct_map)

struct_data = struct();
% For each cell of the map, send each array
for i=1:length(struct_map)
    
    % Get struct_map data
    field_name      = struct_map{i,1};
    data_type       = struct_map{i,2};
    columns_matrix  = struct_map{i,3};
    
    % Get raw data, decode it, and reshape it based on #columns
    raw_data        = comm.tcp.get_binary_mat_file(tcp_client);
    vector_data     = typecast(raw_data,data_type);
    rows_matrix     = length(vector_data) / columns_matrix;
    matrix_data     = reshape(vector_data, [rows_matrix, columns_matrix]);
    
    struct_data.(field_name) = matrix_data;
    
end


end


