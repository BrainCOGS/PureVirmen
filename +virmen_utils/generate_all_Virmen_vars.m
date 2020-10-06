function [virmen_structure, codes_files] = generate_all_Virmen_vars()
% Generate test variables for virmen
%Includes:
% Protocol file
% Trainee file
% Signal dictionary
% Command dictionary
% codes_files (codes for each of previous files)

% Start structure to send
virmen_structure = struct();

% Get a test protocol file and binarize it
protocol = virmen_utils.get_protocol_hniehE65_20180202();
virmen_structure.protocol_file = virmen_utils.struct2binary(protocol);

% Get a test trainee file and binarize it
trainee = virmen_utils.get_test_trainee_Virmen();
virmen_structure.trainee_file = virmen_utils.struct2binary(trainee);

% Generate a test command dictionary and binarize it
command_dict = ...
    comm.virmen_specific.generate_command_dictionary();
virmen_structure.command_dict = virmen_utils.struct2binary(command_dict);

% Generate a test signal dictionary and binarize it
signal_dict = ...
    comm.virmen_specific.generate_signal_dictionary();
virmen_structure.signal_dict = virmen_utils.struct2binary(signal_dict);

% Generate a code for each file sent to the virmen
codes_files = ...
    comm.virmen_specific.generate_send_codes_struct( virmen_structure );


end

