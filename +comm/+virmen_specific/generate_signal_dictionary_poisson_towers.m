function signal_dictionary = generate_signal_dictionary_poisson_towers()
% generate_signal_dictionary 
% signal dictionary definition for Virmen states -> BPOD
% Output
% signal_dictionary    = struct with two dictionaries 
%                        virmen_dict & bcontrol_dict 
%                        maps Virmen "states" to codes
%(e.g) signal_dictionary.virmen_dict
%, map current state -> code to send
%{     'state1':  1
%      'state2':  2
% etc }
%(e.g) signal_dictionary.bcontrol_dicr
% map current code recieved -> state from virmen
%{     1: 'state1'
%      2: 'state2'
% etc }

% Write all Virmen states that will send a signal to Bcontrol
virmen_states     = {
    'trialViolation', ...
    'inCue', ...
    'inMemory', ...
    'inArms'
    };
    
% Set a code 1:n for each of the virmen states  
codes = 1:length(virmen_states);

%Construct both (virmen and bcontrol) dictionaries:
signal_dictionary.virmen_dict   = containers.Map(virmen_states,codes);
signal_dictionary.bcontrol_dict = containers.Map(codes,virmen_states);

    
end

