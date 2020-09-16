

virmen_structure = struct();

protocol = virmen_utils.get_test_protocol_Virmen();
virmen_structure.protocol_file = virmen_utils.struct2binary(protocol);

trainee = virmen_utils.get_test_trainee_Virmen();
virmen_structure.trainee_file = virmen_utils.struct2binary(trainee);

command_dict = ...
    comm.virmen_specific.generate_command_dictionary_poisson_towers();
virmen_structure.command_dict = virmen_utils.struct2binary(command_dict);

signal_dict = ...
    comm.virmen_specific.generate_signal_dictionary_poisson_towers();
virmen_structure.signal_dict = virmen_utils.struct2binary(signal_dict);



codes_files = ...
    comm.virmen_specific.generate_send_codes_struct( virmen_structure );

  tcp_client = comm.tcp.initialize_tcp( ...
      '192.168.0.23', ...
      RigParameters.tcpClientPort, ...
      'server', ...
      0);

  
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

