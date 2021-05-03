function [vr] = drawCueSequenceMin(vr)
%ALS adjust cue position in maze given the cuePos, already given
  % Common storage
  
  %vr.cuePos                 = cell(size(Choice.all()));
  vr.cueOnset               = cell(size(vr.vtx_turnCue));
  vr.cueOffset              = cell(size(vr.vtx_turnCue));
  vr.cueTime                = cell(size(vr.vtx_turnCue));     % Redundant w.r.t. cueOnset, but useful for checking duration
  vr.cueAppeared            = cell(size(vr.vtx_turnCue));

  vr.landmarkAppeared       = cellfun(@(x) false(size(x)), vr.landmarkPos, 'UniformOutput', false);
  vr.landmarkOnset          = cellfun(@(x) zeros(size(x), vr.iterStr), vr.landmarkPos, 'UniformOutput', false);
  
  %ALS why is this in here ??
  if ~isempty(vr.skySwitchInterval)
    vr.prevSkySwitch        = vr.timeElapsed;
    vr.nextSkySwitch        = vr.skySwitchInterval(1) + exprnd(vr.skySwitchInterval(2));
    vr.skySwitch            = vr.iterFcn([1, vr.skyColorCode(vr.currentSkyColor)]);
  end
  
  % Get displacement for each cue in the cueObject
  vr.pos_turnCue            = cell(size(vr.vtx_turnCue));
  for iCue = 1:numel(vr.vtx_turnCue)
    % Get current cue 
    current_cues = vr.trial_info.cue_pos_cell{iCue};
    cueDisplacement  = zeros(1, vr.maxNumCues); 
    %Set displacement for current cue
    cueDisplacement(1:numel(current_cues)) = current_cues;
    %The rest of the cues will be set in a position outside the maze
    cueDisplacement(numel(current_cues)+1:end) = 100000;
    
    
    vr.pos_turnCue{iCue}   = repmat(cueDisplacement, size(vr.vtx_turnCue{iCue},1), 1);
    
    vr.cueOnset{iCue}      = zeros(size(current_cues), vr.iterStr);
    vr.cueOffset{iCue}     = zeros(size(current_cues), vr.iterStr);
    vr.cueTime{iCue}       = nan(size(current_cues));
    vr.cueAppeared{iCue}   = false(size(current_cues));
  end

  % Reposition cues according to the drawn positions
  
  for i=1:numel(vr.vtx_turnCue)
  vr.worlds{vr.currentWorld}.surface.vertices(2,vr.vtx_turnCue{i}) ...
                            = vr.template_turnCue{i}(:) + vr.pos_turnCue{i}(:);
  end


end

