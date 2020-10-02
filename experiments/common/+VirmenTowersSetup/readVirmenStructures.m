function  [mazes, criteria, globalSettings, vr]  = readVirmenStructures(vr)
%function to set variables from virmen_structures communicated from BControl
% Input
% vr                 = virmen handle, (virmen_structures) is needed
% Output             
% mazes              = mazes structure for towers task
% criteria           = criteria structure for towers task
% globalSettings     = global settings for towers task
% vr                 = virmen handle, with extra parameters

mazes = vr.virmen_structures.protocol.mazes;
criteria = vr.virmen_structures.protocol.criteria;
globalSettings = vr.virmen_structures.protocol.globalSettings;

vr.stimulusGenerator = vr.virmen_structures.protocol.stimulusGenerator;
vr.stimulusParameters = vr.virmen_structures.protocol.stimulusParameters;
vr.inheritedVariables = vr.virmen_structures.protocol.inheritedVariables;
vr.numMazesInProtocol = vr.virmen_structures.protocol.numMazesInProtocol;