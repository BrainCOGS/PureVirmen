function raw_data = get_binary_mat_file(tcp_client)
% Protocol to read a binary train from another computer by tcpip
% Also used to send struct composed by arrays with an associated map
%
% Input
% tcp_client   = tcpip handle for communication
%
% Outputs
% struct_data  = data after loading mat file or encoding binary

% Is it a binary mat file or a struct composed by arrays
if nargin < 2
    data_type = -1;
    transfer_type = 'Binary';
else
    transfer_type = 'Struct array';
end


%Binary raw data, initialize as a uint8 variable
raw_data = uint8(1);

%Check if server is connected and acknowledge is sent
comm.tcp.get_acknowledge_comm(tcp_client);

    %Start recieving binary file
    comm_binary = 1;
    while comm_binary
        
        %Recieve num bytes sent by server (2 byte code)
        bytes_read = comm.tcp.get_tcp_bytes(tcp_client, 2);
        %Interpret in uint16 number of bytes to recieve in next message
        bytes_read = double(typecast(uint8(bytes_read),'uint16'));

        %If at least one byte is going to be sent
        if bytes_read ~= 0
            
            bytes_protocol = comm.tcp.get_tcp_bytes(tcp_client, bytes_read);
            raw_data = [raw_data; bytes_protocol];
        else
            comm_binary = 0;
        end
    end
    
    %Delete initial dummy byte
    raw_data = raw_data(2:end);
        
end
