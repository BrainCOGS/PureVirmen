function send_array_structure(tcp_client, struct2send, struct_map)
% Protocol to send structure composed of arrays by tcp
%
% Input
% tcp_client   = tcpip handle for communication
% struct2send  = structure data to send
% struct_map   = info about field order and datatype of structure
                             
%  e.g.
       % 
       %   struct2send.position   = double([1  1.5 2 ])
       %   struct2send.sensor     = uint16([0  50  100 ])
       %    
       %   struct_map = comm.utility.get_struct_map(struct2send)
       %   struct_map
       %             {{'position', 'double'}, {'sensor', 'uint16'}}
       %   send_array_structure(tcp_client, struct2send, struct_map)

% For each cell of the map, send each array
for i=1:length(struct_map)
    
    % Get array, binarize it and send it
    array2send = struct2send.(struct_map{i,1});
    % Send array as a 1d vector
    array2send = array2send(:);
    binary_array = typecast(array2send,'uint8');
    comm.tcp.send_binary_mat_file(tcp_client, binary_array);
    
end



