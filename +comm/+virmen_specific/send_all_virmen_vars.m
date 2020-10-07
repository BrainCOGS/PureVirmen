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
codes_binary = virmen_utils.struct2binary(codes_files);
comm.tcp.send_binary_mat_file(tcp_client, codes_binary);


% get all fields to send form virmen_structure
files2send = fieldnames(virmen_structure);

for i=1:length(files2send)
    
    %Wait for message from Virmen machine
    next_file = comm.tcp.get_tcp_bytes(tcp_client, 1);
    % Send next file recieved
    if next_file == 2
        pause(0.05);
        %Send code of next file to send
        files2send{i}
        codes_files
        ac_code = codes_files.(files2send{i})
        ac_file = virmen_structure.(files2send{i});
        comm.tcp.send_tcp_bytes(tcp_client, uint8(ac_code));
        pause(0.05);
        %Send next file
        comm.tcp.send_binary_mat_file(tcp_client, ac_file);
    end
    
    
end


%Send 0 when finished 
comm.tcp.send_tcp_bytes(tcp_client, uint8(0));

%Exit ok after sending last message
comm.tcp.get_tcp_bytes(tcp_client, 1);

end

