% ViRMEn movement function that reads from an existing trajectory file
function [velocity, rawData] = moveByRecordedData(vr)

  persistent data index
  if isempty(data)
    data            = load('TrajectoryFile_t12_16.mat');
    data.pos        = double(data.pos);
    data.pos(:,end) = -data.pos(:,end) * pi/180;
    index           = 1;
  end

  % Special case for movement freeze
  rawData           = [0 0 0 0 0];
  if (vr.scaleX == 0 && vr.scaleY == 0) || (vr.trialType == Choice.nil)
    velocity        = [0 0 0 0];
    return;
  end
  
  % Sanity check for frozen stimuli
  if ~isequal(vr.cuePos{Choice.L}, data.cuePos_L) || ~isequal(vr.cuePos{Choice.R}, data.cuePos_R)
    error('moveByRecordedData:sanity', 'Cue positions for current trial does not match frozen stimuli.');
  end
  
  % Use displacement to next position
  if index < size(data.pos,1)
    index           = index + 1;
  else
    index           = 1;
  end

  displacement      = data.pos(index,:) - vr.position([1:2,end]);
  velocity          = [displacement(1:2), 0, displacement(end)] / vr.dt;
  
  
  %{
  % Locate current position by closest distance
  distance          = bsxfun(@minus, vr.position(1:2), data.pos(:,1:2));
  distance2         = sum(distance.^2, 2);
  [~,iBest]         = min(distance2);
  
  % Define velocity using displacement vector to next position
  if iBest < size(data.pos,1)
    displacement    = data.pos(iBest+1,:) - vr.position(:,[1:2,end]);
    velocity        = [displacement(1:2), 0, displacement(end)] / vr.dt;
  else
    velocity        = [0 0 0 0];
    index           = 0;
  end

  % The following should never happen but just in case
  velocity(~isfinite(velocity)) = 0;
  rawData           = [0 0 0 0 0];
  %}

end
