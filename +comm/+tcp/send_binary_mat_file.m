function send_binary_mat_file(tcp_client, binary_file)
% Protocol to read a binary 8bit train from another computer by tcpip
%
% Input
% tcp_client   = tcpip handle for communication
% binary_file  = binary data to send (from a .mat file)


%Check if server is connected and acknowledge is sent
comm.tcp.send_acknowledge_comm(tcp_client);

%Check how many packages are to sent
buffer_size = tcp_client.OutputBufferSize;
pack_no = ceil((length(binary_file)) / buffer_size);
pause(0.015);

for i=1:pack_no

    %Get index of bytes to send
    pack_ind = [(i-1)*buffer_size+1 i*buffer_size];
    if i == pack_no      
       bin_pack = binary_file(pack_ind(1):end);
    else
       bin_pack = binary_file(pack_ind(1):pack_ind(2));
    end
    %Get size of package to send (2 bytes)
    bytes_2_send = typecast(uint16(length(bin_pack)),'uint8');
    
    %Send 2 size bytes
    comm.tcp.send_tcp_bytes(tcp_client, bytes_2_send);
    pause(0.015);
    %Send binary array package
    comm.tcp.send_tcp_bytes(tcp_client, bin_pack);
    pause(0.015);
end

%Send 0 extra bytes 2 send
comm.tcp.send_tcp_bytes(tcp_client, uint8([0 0]));

end


