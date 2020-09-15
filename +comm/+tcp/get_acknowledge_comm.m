function get_acknowledge_comm( tcp_client )
% Send communication start message and wait for acknowledge tcp
%
% Input
% tcp_client   = tcpip handle for communication


% Send 255 to start communication
fwrite(tcp_client, 255);
% Wait one minute for response from other computer
tic
while (tcp_client.BytesAvailable == 0)
    time_ellapsed = toc;
    if time_ellapsed > 60
        warning('No response from tcpip server ')
    elseif time_ellapsed > 300
        error('No response from tcpip server at all. Cancel transfer')
    end
end

%Check if acknowledge was sent successfully
ack = fread(tcp_client, tcp_client.BytesAvailable);
if ack ~= 65
    error('Acknowledge not recieved')
end

end

