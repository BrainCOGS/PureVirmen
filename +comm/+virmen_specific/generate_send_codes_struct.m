function [ codes_files ] = generate_send_codes_struct( virmen_structure )
%GENERATE_SEND_CODES_STRUCT 
% generate codes_files dictionary from virmen_structure 2 send
%
% Input
% virmen_structure    = structure with all fields to send
%(e.g)
%   protocol_file:       struct with protocol file
%   signal_dictionary:   struct with signal dictionary file
%   etc ....
%
% Output
% codes_files           = code for each virmen_structure to send
%(e.g)
%   protocol_file:       1
%   signal_dictionary:   2
%   etc ....

codes_files = struct();
%Get all fields from structure
fields2send = fieldnames(virmen_structure);
fields2send = [{'no_file'}; fields2send];

% Fill code_files
for i=0:length(fields2send)-1   
    codes_files.(fields2send{i+1}) = i;
end

end

