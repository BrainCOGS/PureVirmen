function tcp_set_bytes( tcp_client, bytes_send )
% Wrtie bytes to tcp
%
% Inputs
% tcp_client       = tcpip handle for communication
% bytes_read       = number of bytes to read in next package

% Send bytes to tcp
fwrite(tcp_client, bytes_send);


end

