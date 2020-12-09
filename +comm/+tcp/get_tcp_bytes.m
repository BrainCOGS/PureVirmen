function [ bytes ] = get_tcp_bytes( tcp_client, bytes_read )
% Get how many bytes are going to be sent in next package
%
% Inputs
% tcp_client       = tcpip handle for communication
% bytes_read       = number of bytes to read in next package
% Outputs
% bytes            = bytes recieved by client


%Recieve num bytes sent by server
tic
while (tcp_client.BytesAvailable < bytes_read)
    time_ellapsed = toc;
    if time_ellapsed > 10
        error('There was an error in the tcp communication')
    end
end

%Read recieved bytes
bytes = fread(tcp_client, bytes_read);

end

