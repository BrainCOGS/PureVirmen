% --- Trial and reward configuration
function vr = setupTrials(vr)

  % Initialize standard state control variables
  vr    = VirmenTowersSetupNewCues.initializeGradedExperiment(vr);

  %Read virmen_structures communicated from BControl
  [mazes, criteria, globalSettings, vr] = VirmenTowersSetupNewCues.readVirmenStructures(vr);
  
  %Processes the definition for a sequence of progressively more difficult mazes.
  vr  = VirmenTowersSetupNewCues.prepareMazes(vr, mazes, criteria, globalSettings);
  vr.shapingProtocol    = @test;
  
  %Mainly change vr.exper variables to vr.
  vr = VirmenTowersSetupNewCues.experVariables2vr(vr);

  % The following variables are refreshed (assigned under the vr struct) each time a different maze level is loaded
  % vr.stimulusParameters is set in the protocol and includes e.g. cueVisibleAt
  % Maze variables are named experimentVars
  vr = VirmenTowersSetupNewCues.setExperimentVarsTowersTask(vr);
        
  % Initialize mazes variables (BControl should communicate which maze next)
  %ALS to do BCONTROL Should now this info
  vr = VirmenTowersSetupNewCues.setInitialMaze(vr);

    % Configuration for logging etc.  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
  %ALS cfg logging can be stored in Bcontrol
  % info to store, minimum (position, velocity, sensor, collision)
  
  % Protocol-specific stimulus trains, some identical across sessions  
  % Stimulus bank loading not needed anymore %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % Logging of experimental data
  if ~vr.experimentEnded
    %ALS, just for now a path to save log
    timestr = datestr(now(), 'YYYY-mm-dd HH_MM');
    filePath  = ['user1\subject1\' timestr];  
    
    % Table with all field info for Towers Task
    fieldInfo = VirmenBControl.field_definition.TowersTaskFields;
    
    %Define object to log data
    vr.logger           = ExperimentLogVirmen(filePath, fieldInfo);
  end
  
  vr.prevIndices = [0 0 0];
  
end