

virmen_structure = struct();

protocol = virmen_utils.get_test_protocol_Virmen();
virmen_structure.protocol_file = virmen_utils.struct2binary(protocol);

trainee = virmen_utils.get_test_trainee_Virmen();
virmen_structure.trainee_file = virmen_utils.struct2binary(trainee);

code_files = ...
    comm.comm_virmen_specific.generate_send_codes_struct( virmen_structure );


  vr.tcp_client = comm.tcp.initialize_tcp( ...
      '192.168.0.23', ...
      RigParameters.tcpClientPort, ...
      'server', ...
      0);
  
send_all_virmen_vars(tcp_client, codes_files, virmen_structure);

