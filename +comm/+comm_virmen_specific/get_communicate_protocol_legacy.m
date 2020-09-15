function [mazes, criteria, globalSettings, vr] = get_communicate_protocol_legacy(vr, tcp_client)
% Communicate protocol legacy mode, 
% set mazes, criteria, globalsettings and some variables for vr structure
%
% Input
% vr               = virmen main structure
% tcp_client       = tcpip handle for communication
%
% Output
% mazes            = mazes structure for virmen 
% criteria         = criteria for advancing mazes structure in virmen 
% globalSettings   = golbal Settings for mazes
% vr               = virmen main structure 


%Get binary file with protocol
struct_data = comm.tcp.get_binary_mat_file(tcp_client);

%Get mazes, criteria and globalSettings structure
mazes = struct_data.mazes;
criteria = struct_data.criteria;
globalSettings = struct_data.globalSettings;

% get some variables for vr structure
vr.stimulusGenerator = struct_data.stimulusGenerator;
vr.stimulusParameters = struct_data.stimulusParameters;
vr.inheritedVariables = struct_data.inheritedVariables;
vr.numMazesInProtocol = struct_data.numMazesInProtocol;

end