function vr = endVRTrial(vr, fadeToBlack)

  % Return process priority to normal
%   priority('sn');

  % Turn off world visibility and enter inter-trial interval
  if nargin < 2 || fadeToBlack
    vr.worlds{vr.currentWorld}.surface.visible(:) = false;
  end
  vr.state      = BehavioralState.InterTrial;

end
