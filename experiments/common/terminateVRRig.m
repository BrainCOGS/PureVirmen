function terminateVRRig(vr)

  % Delete log objects
  if isfield(vr, 'protocol')
    delete(vr.protocol);
    vr.protocol   = [];
  end
  if isfield(vr, 'logger')
    delete(vr.logger);
    vr.logger     = [];
  end


  if ~RigParameters.hasDAQ
    return;
  end

  % Terminate DAQ
  terminateDAQ(vr);

  % Close communications with Arduino 
  if vr.hasArduino
    arduinoReader('end', true);
    % delete(vr.mr);
  end

end
