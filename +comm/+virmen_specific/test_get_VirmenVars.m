
%Script to test recieving initial variables by Virmen from BControl

%Initialize tcp client
tcp_client = comm.tcp.initialize_tcp( ...
      VirmenCommParameters.ipAddressBControl, ...
      VirmenCommParameters.tcpClientPort, ...
      VirmenCommParameters.networkRole, ...
      VirmenCommParameters.outputBufferSize);

% Recieve all files from BControl machine
try
    virmen_structures = comm.virmen_specific.get_all_virmen_vars(tcp_client);
    fclose(tcp_client);
catch ME
    ME
    for i=1:length(ME.stack)
        ME.stack(i)
    end
    fclose(tcp_client);
end

