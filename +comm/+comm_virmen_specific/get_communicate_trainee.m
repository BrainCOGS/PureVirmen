function trainee  = get_communicate_trainee(tcp_client)
% Communicate trainee structure (Old virmen
%
% Input
% tcp_client   = tcpip handle for communication
%
% Output
% trainee      = trainee structure for Old Virmen Protocols 

% get a binary file -> structure
struct_data = comm.tcp.get_binary_mat_file(tcp_client);

%trainee structure has a "trainee_struct" structure 
%trainee = struct();
trainee = struct_data.trainee_struct;
% fields = fieldnames(struct_data.trainee_struct);
% %copy all fields from trainee_struct
% for i=1:length(fields)
%     trainee.(fields{i}) = ...
%         struct_data.trainee_struct.(fields{i});
% end

end
