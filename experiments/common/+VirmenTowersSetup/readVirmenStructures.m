function  [mazes, criteria, globalSettings, vr]  = readVirmenStructures(vr)
%function to set variables from virmen_structures communicated from BControl
% Input
% vr                 = virmen handle, (virmen_structures) is needed
% Output             
% mazes              = mazes structure for towers task
% criteria           = criteria structure for towers task
% globalSettings     = global settings for towers task
% vr                 = virmen handle, with extra parameters

mazes = vr.virmen_structures.protocol_file.mazes;
criteria = vr.virmen_structures.protocol_file.criteria;
globalSettings = vr.virmen_structures.protocol_file.globalSettings;

vr.stimulusGenerator = vr.virmen_structures.protocol_file.stimulusGenerator;
vr.stimulusParameters = vr.virmen_structures.protocol_file.stimulusParameters;
vr.inheritedVariables = vr.virmen_structures.protocol_file.inheritedVariables;
vr.numMazesInProtocol = vr.virmen_structures.protocol_file.numMazesInProtocol;