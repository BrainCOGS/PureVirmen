function send_all_virmen_vars(tcp_client, codes_files, virmen_structure)
% send_all_virmen_vars,
% Send all virmen structures for the task (BControl -> Virmen)
%
% Input
% tcp_client         = tcpip handle for communication
% codes_files        = code for each virmen_structure to send
%(e.g)
%   protocol_file:       1
%   signal_dictionary:   2
%   etc ....
% virmen_structures  = Structure with all structures needed for running virmen
%(e.g)
%   protocol_file:       struct with protocol file
%   signal_dictionary:   struct with signal dictionary file
%   etc ....


%Get structure that indicate code for each type of file to be sent
tcp.comm.send_binary_mat_file(tcp_client, codes_files);


% get all fields to send form virmen_structure
files2send = fieldnames(virmen_structure);

for i=1:length(files2send)
    
    %Wait for message from Virmen machine
    next_file = tcp.comm.get_tcp_bytes(tcp_client, 1);
    % Send next file recieved
    if next_file == 2
        pause(0.05);
        %Send code of next file to send
        tcp.comm.set_tcp_bytes(tcp_client, uint8(codes_files.(files2send{i})));
        pause(0.05);
        %Send next file
        tcp.comm.send_binary_mat_file(tcp_client, virmen_structure.(files2send{i}));
    end
    
    
end


end

