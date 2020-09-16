function codes_structure  = get_communication_codes(tcp_client)
% get_communication_codes,
% This codes "tells" virmen which type of variable is going to be sent by tcp
% This is the first file sent through tcp from Bcontrol -> Virmen
%
% Input
% tcp_client         = tcpip handle for communication
%
% Output
% codes_structure    = Structure with codes for reading specific variables
%(e.g)
% codes_structure = 
%   struct with fields:
%
%   end_comm:            0 -- when recieving "zero" no more variables are sent
%   protocol_file:       1 -- When recieving "one" a protocol file is next
%   signal_dictionary:   2 -- When recieving "two" a signal_dictionary is next
%   etc ....

% get a binary file -> structure
struct_data = comm.tcp.get_binary_mat_file(tcp_client);

%trainee structure has a "trainee_struct" structure 
%trainee = struct();
codes_structure = struct_data.codes_structure;
% fields = fieldnames(struct_data.trainee_struct);
% %copy all fields from trainee_struct
% for i=1:length(fields)
%     trainee.(fields{i}) = ...
%         struct_data.trainee_struct.(fields{i});
% end

end
