function [vr] = setCuesPosition(vr, turnCues)
%Cues position for maze 
% Set vertices locations "y" position from all towers to 0.


vr.template_turnCue       = cell(size(vr.vtx_turnCue));
for iCue = 1:numel(turnCues)
    cueIndex                = vr.worlds{vr.currentWorld}.objects.indices.(turnCues{iCue});
    vertices                = vr.vtx_turnCue{iCue};
    % y position only (dim # 2)
    vtxLoc                  = vr.worlds{vr.currentWorld}.surface.vertices(2,vertices);
    vtxLoc                  = reshape(vtxLoc, size(vertices));
    cueLoc                  = vr.exper.worlds{vr.currentWorld}.objects{cueIndex}.y;
    if ~isempty(vr.motionBlurRange)
        cueWidth              = vr.exper.worlds{vr.currentWorld}.objects{cueIndex}.height;
    else
        cueWidth              = 1;
    end
    
    vr.template_turnCue{iCue}  ...
        = bsxfun(@minus, vtxLoc, cueLoc) / cueWidth;
end

end

