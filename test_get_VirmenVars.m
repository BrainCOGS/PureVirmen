
  vr.tcp_client = comm.tcp.initialize_tcp( ...
      '192.168.0.22', ...
      RigParameters.tcpClientPort, ...
      'client', ...
      40);
  
  
try  
    virmen_structures = comm.virmen_specific.get_all_virmen_vars(tcp_client, codes_files, virmen_structure);
    fclose(tcp_client);
catch ME
    ME
    fclose(tcp_client);
end
    