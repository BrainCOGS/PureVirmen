function command_dictionary = generate_command_dictionary_poisson_towers()
% get_command_dictionary 
% command dictionary definition for BControl commands -> Virmen
% Output
% command_dictionary     = struct with two dictionaries 
%                        virmen_dict & bcontrol_dict 
%                        maps Bcontrol Commands to codes
%(e.g) command_dictionary.bcontrol_dict
%, map current command -> code to send
%{     'command1':  1
%      'command2':  2
% etc }
%(e.g) signal_dictionary.virmen_dict
% map current code recieved -> command from Bcontrol
%{     1: 'command1'
%      2: 'command2'
% etc }

% Write all BControl commands that will be sent to control Virmen trials
bcontrol_commands     = {
    'teleportStart', ...
    'visibilityOff', ...
    'visibilityOn', ...
    'changeBackground'
    };
    
% Set a code 1:n for each of the bcontrol commands 
codes = 1:length(bcontrol_commands);

%Construct both (virmen and bcontrol) dictionaries:
command_dictionary.bcontrol_dict   = containers.Map(bcontrol_commands,codes);
command_dictionary.virmen_dict     = containers.Map(codes,bcontrol_commands);

    
codes_cell = num2cell(codes);
command_dictionary.struct_format   = cell2struct(codes_cell,bcontrol_commands(:),2);


end

