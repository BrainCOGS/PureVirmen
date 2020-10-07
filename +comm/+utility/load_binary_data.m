function [ struct_data ] = load_binary_data( raw_data )
%LOAD_BINARY_DATA 
% Load a file from binary data received
% Inputs
% raw_data     = binary data of a mat file received from tcp 
% Outputs
% struct_data  = structure after loading mat file


%Get current directory and raw data placeholder file
current_directory = fileparts(mfilename('fullpath'));
raw_data_file     = fullfile(current_directory, 'raw_data.mat');

%If file exist, delete it
if exist(raw_data_file, 'file')
    delete(raw_data_file);
end

%Open empty file to write binary info
file_handler = fopen(raw_data_file, 'w');
fwrite(file_handler, raw_data);
fclose(file_handler);

%Get structured data loading binary
struct_data = load(raw_data_file);
struct_data = struct_data.structure;

end

