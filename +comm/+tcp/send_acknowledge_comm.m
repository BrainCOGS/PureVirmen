function send_acknowledge_comm( tcp_client )
% Recieve an "start" comm message and send acknowledge
%
% Input
% tcp_client   = tcpip handle for communication

while(tcp_client.BytesAvailable == 0 )
end
event = fread(tcp_client, tcp_client.BytesAvailable);
if event ~= 255
     error(['Problem with communication, event: ' event])
end
fwrite(tcp_client, 65);

end

