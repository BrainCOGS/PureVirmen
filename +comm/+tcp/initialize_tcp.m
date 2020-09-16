function [tcp_client] = initialize_tcp(ipadress, port, role, outputbuffersize)
% Initialize tcpip as a client of Bcontrol computer
%
% Inputs
% ipadress         = ipaddress of Bcontrol machine
% port             = network port open for communication
% outputbuffersize = buffer size for virmen variables sent each frame
% role             = client : Virmen machine
%                  = server : Bcontrol machine
%
% Outputs
% tcp_client       = handle for tcp communication


%Open tcp and set configuration
tcp_client = tcpip(ipadress, port, 'NetworkRole', role);
if outputbuffersize > 0
    tcp_client.OutputBufferSize = outputbuffersize;
end
fopen(tcp_client);

% If there is "garbage bytes" in buffer, read them to clean buffer
if tcp_client.BytesAvailable > 0
    fread(tcp_client, tcp_client.BytesAvailable);
end

end

