function trainee_struct = get_test_trainee_Virmen()

trainee_struct = struct();

session = struct();
for i=1:7
    session(i).start = 9;
    session(i).duration = 60;
end

trainee_struct.name = 'bpod_s2';
trainee_struct.importAge =  8;
trainee_struct.importDate =  [2020 7 27];
trainee_struct.normWeight =  20;
trainee_struct.waterAlloc =  1;
trainee_struct.rewardFactor = [[2.0, 1.5, 1.2, 1.0, 1.0, 1.2, 1.2, 1.2, ...
    1.2, 1.2, 1.4, 1.5, 1.6, 1.8, 1.8, 1.8]; ...
    [2.0, 1.5, 1.2, 1.0, 1.0, 1.2, 1.2, 1.2, ...
    1.2, 1.2, 1.4, 1.5, 1.6, 1.8, 1.8, 1.8]];
trainee_struct.isActive = 1;
trainee_struct.motionBlurRange = [];
trainee_struct.protocol = @PoissonBPODTestProtocol2;
trainee_struct.experiment = 'C:\Users\BrainCogs_Projects\tankmousevr\experiments\alvaro_BPOD_poisson2.mat';
trainee_struct.stimulusBank = 'C:\Users\BrainCogs_Projects\tankmousevr\experiments\programs\protocols\stimulus_trains_PoissonBPODTestProtocol2.mat';
trainee_struct.stimulusSet = 1;
trainee_struct.refImageFiles = {};
trainee_struct.imagingTags = {};
trainee_struct.mainMazeID = 1;
trainee_struct.autoAdvance = 1;
trainee_struct.warmupDrawMethod = {'TRIAL_DRAWING'  1};
trainee_struct.mainDrawMethod = {'TRIAL_DRAWING'  1};
trainee_struct.session = session;
trainee_struct.data = [];
trainee_struct.virmenSensor = MovementSensor(1);
trainee_struct.virmenDisplacementPerCm = 1;
trainee_struct.virmenRotationsPerRev = NaN;
trainee_struct.color = [0 0 0];
trainee_struct.sessionIndex = 1;
trainee_struct.overrideMazeID = 0;


trainee_struct.trial_

end

