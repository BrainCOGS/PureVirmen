function virmen_structures = get_all_virmen_vars( tcp_client )
% get_all_virmen_vars,
% Keep reading structures until end_comm is sent by tcp server
%
% Input
% tcp_client         = tcpip handle for communication
%
% Output
% virmen_structures  = Structure with all structures needed for running virmen
%(e.g)
% virmen_structures = 
%   struct with fields:
%
%   protocol_file:       struct with protocol file
%   signal_dictionary:   struct with signal dictionary file
%   etc ....

virmen_structures = struct();


%Get structure that indicate code for each type of file to be sent
raw_data = comm.tcp.get_binary_mat_file(tcp_client);
codes_structure = comm.utility.load_binary_data(raw_data);
%codes_structure = get_communication_codes(tcp_client);
pause(0.05);

% get types of files 2 be sent and their corresponding binary "code"
files2sent = fieldnames(codes_structure);
file_code = cellfun(@(x)(codes_structure.(x)),files2sent);

%Create a dictionary to relate all files and codes, (e.g):
% 1 - protocol_file
% 2 - signal_dictionary, etc
files_dictionary = containers.Map(file_code,files2sent);


codes_missing = true;
while codes_missing
    pause(0.05);
    %Ask for next code structure
    comm.tcp.send_tcp_bytes(tcp_client, 2)
    pause(0.02);
    % Recieve a one code message
    code = double(comm.tcp.get_tcp_bytes(tcp_client, 1));
    if ~isKey(files_dictionary, code)
        disp(files_dictionary)
        error(['Recieved an incorrect key for file ', code]);
    end
    
    %Get name of the file to be sent
    code_value = files_dictionary(code);
    
    %If we recieve a valid code 
    if code ~= 0
        pause(0.05);
        %Read binary mat file and set it to structure
        raw_data= comm.tcp.get_binary_mat_file(tcp_client);
    
        virmen_structures.(code_value) = ...
            comm.utility.load_binary_data(raw_data)
    else
        codes_missing = false;
    end
end

end

