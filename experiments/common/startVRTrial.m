function vr = startVRTrial(vr, varargin)

  % Increase process priority so that behavior is responded to inasmuch in
  % real time as possible
%   priority('sh');

  % Unfreeze movement but reset position to start
  vr        = thawArduino(vr);
  vr        = teleportToStart(vr, varargin{:});
  vr.state  = BehavioralState.WithinTrial;
  
end
