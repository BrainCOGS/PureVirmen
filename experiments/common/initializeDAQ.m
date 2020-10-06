function vr = initializeDAQ(vr)

  % Reset DAQ in case it is still in use
  daqreset;

  % Digital input/output lines used for reward delivery etc.
  if RigParameters.hasDAQ
    nidaqPulse('end');
    nidaqPulse('init', RigParameters.nidaqDevice, RigParameters.nidaqPort, RigParameters.rewardChannel);
    
    if isprop(RigParameters,'rightPuffChannel') 
        nidaqPulse3('end');
        nidaqPulse3('init', RigParameters.nidaqDevice, RigParameters.nidaqPort, RigParameters.rightPuffChannel); % airpuff
    end
    if isprop(RigParameters,'leftPuffChannel') 
        nidaqPulse4('end');
        nidaqPulse4('init', RigParameters.nidaqDevice, RigParameters.nidaqPort, RigParameters.leftPuffChannel); % airpuff
    end
    if isprop(RigParameters,'laserChannel') 
        nidaqPulse2('end');
        nidaqPulse2('init', RigParameters.nidaqDevice, RigParameters.nidaqPort, RigParameters.laserChannel); % airpuff
    end
  end

  % ScanImage synchronization
  if RigParameters.hasSyncComm
    nidaqI2C('end');
    nidaqI2C('init', RigParameters.nidaqDevice, RigParameters.nidaqPort, RigParameters.syncClockChannel, RigParameters.syncDataChannel);
  end

end
