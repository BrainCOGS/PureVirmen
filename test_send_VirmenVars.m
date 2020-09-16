
%Script to test sending initial variables from BControl - Virmen

% Start structure to send
virmen_structure = struct();

% Get a test protocol file and binarize it
protocol = virmen_utils.get_test_protocol_Virmen();
virmen_structure.protocol_file = virmen_utils.struct2binary(protocol);

% Get a test trainee file and binarize it
trainee = virmen_utils.get_test_trainee_Virmen();
virmen_structure.trainee_file = virmen_utils.struct2binary(trainee);

% Generate a test command dictionary and binarize it
command_dict = ...
    comm.virmen_specific.generate_command_dictionary();
virmen_structure.command_dict = virmen_utils.struct2binary(command_dict);

% Generate a test signal dictionary and binarize it
signal_dict = ...
    comm.virmen_specific.generate_signal_dictionary();
virmen_structure.signal_dict = virmen_utils.struct2binary(signal_dict);

% Generate a code for each file sent to the virmen
codes_files = ...
    comm.virmen_specific.generate_send_codes_struct( virmen_structure );

% Initialize tcp as a server
tcp_client = comm.tcp.initialize_tcp( ...
    '192.168.0.23', ...
    RigParameters.tcpClientPort, ...
    'server', ...
    0);


%Communicate all files to the virmen machine
try
    comm.virmen_specific.send_all_virmen_vars(tcp_client, codes_files, virmen_structure);
    fclose(tcp_client);
catch ME
    ME
    for i=1:length(ME.stack)
        ME.stack(i)
    end
    fclose(tcp_client);
end

