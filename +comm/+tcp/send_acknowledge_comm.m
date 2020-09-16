function send_acknowledge_comm( tcp_client )
% Recieve an "start" comm message and send acknowledge
%
% Input
% tcp_client   = tcpip handle for communication

tic
while(tcp_client.BytesAvailable == 0 )
    time_ellapsed = toc;
    if time_ellapsed > 60
        warning('No response from tcpip server ')
    end
end
event = fread(tcp_client, tcp_client.BytesAvailable);
if event ~= 255
     error(['Problem with communication, event: ' event])
end
fwrite(tcp_client, 65);

end

