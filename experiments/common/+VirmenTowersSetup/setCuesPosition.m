function [vr] = setCuesPosition(vr, turnCues)
%Cues position for maze

vr.template_turnCue       = nan(size(vr.vtx_turnCue));
for iSide = 1:numel(turnCues)
    cueIndex                = vr.worlds{vr.currentWorld}.objects.indices.(turnCues{iSide});
    vertices                = vr.vtx_turnCue(iSide, :, :);
    vtxLoc                  = vr.worlds{vr.currentWorld}.surface.vertices(2,vertices);
    vtxLoc                  = reshape(vtxLoc, size(vertices));
    cueLoc                  = vr.exper.worlds{vr.currentWorld}.objects{cueIndex}.y;
    if ~isempty(vr.motionBlurRange)
        cueWidth              = vr.exper.worlds{vr.currentWorld}.objects{cueIndex}.height;
    else
        cueWidth              = 1;
    end
    
    vr.template_turnCue(iSide,:,:)  ...
        = bsxfun(@minus, vtxLoc, shiftdim(cueLoc,-1)) / cueWidth;
end

end

