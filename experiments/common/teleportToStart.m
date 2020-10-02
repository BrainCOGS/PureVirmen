function vr = teleportToStart(vr, startLocation)

  vr.dp(:)        = 0;
  vr.velocity(:)  = 0;

  if nargin < 2
    vr.position   = vr.worlds{vr.currentWorld}.startLocation;
  elseif ~isempty(startLocation)
    vr.position   = startLocation;
  end

end
