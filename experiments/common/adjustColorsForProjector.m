function vr = adjustColorsForProjector(vr)

  % Required luminosity adjustments for projector
  for i = 1:length(vr.worlds)
    vr.worlds{i}.surface.colors   = bsxfun(@times, RigParameters.colorAdjustment, vr.worlds{i}.surface.colors);
  end

end
