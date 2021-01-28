function [vr] = drawCueSequenceMin(vr)
%ALS adjust cue position in maze given the cuePos, already given
  % Common storage
  
  %vr.cuePos                 = cell(size(Choice.all()));
  vr.cueOnset               = cell(size(Choice.all()));
  vr.cueOffset              = cell(size(Choice.all()));
  vr.cueTime                = cell(size(Choice.all()));     % Redundant w.r.t. cueOnset, but useful for checking duration
  vr.cueAppeared            = cell(size(Choice.all()));

  vr.landmarkAppeared       = cellfun(@(x) false(size(x)), vr.landmarkPos, 'UniformOutput', false);
  vr.landmarkOnset          = cellfun(@(x) zeros(size(x), vr.iterStr), vr.landmarkPos, 'UniformOutput', false);
  
  %ALS why is this in here ??
  if ~isempty(vr.skySwitchInterval)
    vr.prevSkySwitch        = vr.timeElapsed;
    vr.nextSkySwitch        = vr.skySwitchInterval(1) + exprnd(vr.skySwitchInterval(2));
    vr.skySwitch            = vr.iterFcn([1, vr.skyColorCode(vr.currentSkyColor)]);
  end
  
  % Initialize times at which cues were turned on
  cueDisplacement           = zeros(numel(vr.cuePos), 1, vr.nCueSlots);
  for iSide = 1:numel(vr.cuePos)
    cueDisplacement(iSide,:,1:numel(vr.cuePos{iSide}))  = vr.cuePos{iSide};

    vr.cueOnset{iSide}      = zeros(size(vr.cuePos{iSide}), vr.iterStr);
    vr.cueOffset{iSide}     = zeros(size(vr.cuePos{iSide}), vr.iterStr);
    vr.cueTime{iSide}       = nan(size(vr.cuePos{iSide}));
    vr.cueAppeared{iSide}   = false(size(vr.cuePos{iSide}));
  end

  % Reposition cues according to the drawn positions
  vr.pos_turnCue            = repmat(cueDisplacement, 1, size(vr.vtx_turnCue,2), 1);
  
  disp('vr.cuePos')
  disp(vr.cuePos);
  
  disp('cueMinSeparation');
  disp(str2double(vr.exper.variables.cueMinSeparation));
  
  disp('lCue')
  disp(str2double(vr.mazes(1).variable.lCue))
  
  disp('vr.nCueSlots');
  disp(vr.nCueSlots);
  
  disp('size(cueDisplacement)')
  disp(size(cueDisplacement))
  
  disp('size(vr.vtx_turnCue,2)')
  disp(size(vr.vtx_turnCue,2))
  
  disp('size(vr.pos_turnCue)')
  disp(size(vr.pos_turnCue))
  
  disp('size(vr.template_turnCue)')
  disp(size(vr.template_turnCue))
  
  disp('size(vr.vtx_turnCue)')
  disp(size(vr.vtx_turnCue))
  
  vr.worlds{vr.currentWorld}.surface.vertices(2,vr.vtx_turnCue) ...
                            = vr.template_turnCue(:) + vr.pos_turnCue(:);


end

