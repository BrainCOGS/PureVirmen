function [ stimParameters ] = getStimParameters( vr )
%GETSTIMPARAMETERS Summary of this function goes here
%   Detailed explanation goes here

  if nargout > 2
    stimParameters      = cell(size(vr.stimulusParameters));
    for iParam = 1:numel(vr.stimulusParameters)
      stimParameters{iParam}  = vr.(vr.stimulusParameters{iParam});
    end
  end

end

