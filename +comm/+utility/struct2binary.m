function binary = struct2binary( structure )
%STRUCT2BINARY tranforms structure to binary file (from mat file)
%
% Inputs
% structure = structure with data
%
% Outputs
% binary    = binary data of structure 

binary_file_name = fileparts(mfilename('fullpath'));
binary_file_name = fullfile(binary_file_name, 'raw_data.mat');

if exist(binary_file_name,'file')
    delete(binary_file_name);
end

save(binary_file_name, 'structure')

binary_file = fopen(binary_file_name);
binary = fread(binary_file);
fclose(binary_file);

end

