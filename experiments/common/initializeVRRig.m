function vr = initializeVRRig(vr, config)

  % Load calibration parameters for the current rig
  for param = properties(RigParameters)'
    if ~ischar(RigParameters.(param{:}))
      exper.variables.(param{:})  = num2str(RigParameters.(param{:}));
    end
  end

  % Displacement/rotational gain
  if nargin > 1
    for field = fieldnames(config)'
      if strncmp(field{:}, 'virmen', 6)
        vr.(field{:})           = config.(field{:});
      end
    end
  else
    vr.virmenDisplacementPerCm  = 1;
    vr.virmenRotationsPerRev    = 1/2.5;
    vr.virmenSensor             = MovementSensor.BottomVelocity;
  end
  
  if isfield(vr, 'protocol')
    vr.protocol.log('Movement function is %s with rotational gain 1/%.3g.', char(vr.exper.movementFunction), 1/vr.virmenRotationsPerRev);
  end


  %ALS, clean only Arduino or serila comm
  %  Clean up any open lines e.g. from ViRMEn crashes
  %openInstr = instrfindall;
  %if ~isempty(openInstr)
  %  fclose(openInstr);
  %end

  % Initialize communications with Arduino 
  vr.hasArduino   = RigParameters.hasDAQ && ~isempty(regexp(func2str(vr.exper.movementFunction), '^moveArduino', 'once'));
  if vr.hasArduino
    %vr = initializeArduinoMouse(vr, vr.virmenDisplacementPerCm, vr.virmenRotationsPerRev, vr.virmenSensor);
    vr = initializeArduinoReader(vr, vr.virmenDisplacementPerCm, vr.virmenRotationsPerRev, vr.virmenSensor);
  else
    vr.mr           = struct('last_displacement', {[-1 -1 -1 -1 -1]});
    vr.scaleX       = 1;
    vr.scaleY       = 1;
    vr.scaleA       = 1;
    vr.velScaleXYA  = [vr.scaleX, vr.scaleY, vr.scaleA];
  end
  
  % Store scale factors in order to be able to turn off velocity later
  vr.velScaleXYA  = [vr.scaleX, vr.scaleY, vr.scaleA];

  % Initialize DAQ inputs and outputs
  vr = initializeDAQ(vr);

end
