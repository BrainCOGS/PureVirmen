function vr = initializeGradedExperiment(vr)
% simplified initializeGradedExperiment function from tankmousevr
% Initialize some variables to start experiment
% Inputs
% vr    = virmen main structure
% Outputs
% vr    = virmen main structure

  % Don't execute the rest of the code (which can be slow) if the
  % experiment was aborted for some reason
  if vr.experimentEnded
    return;
  end

  % Make a copy of world configuration to modify
  vr.exper            = copyVirmenObject(vr.exper);

  % State flag for simulation
  vr.mazeChange       = 0;
  vr.state            = BehavioralState.SetupTrial;

end
