function vr = motion_blurring_rules( vr )
%applyMotionBlurring
% Code executed based to apply motion blurring to objects Poisson Towers

dy                      = vr.lastDP(2) + vr.dp(2);
vr.lastDP               = vr.dp;
if ~isempty(vr.motionBlurRange)
    % Quantities for motion blurring
    blurredWidth          = vr.yCue + abs(dy);
    
    % Only visible cues within a given distance of the animal are blurred
    isBlurred             = false(size(vr.vtx_turnCue));
    if abs(dy) > vr.motionBlurRange(1)
        for iCue = 1:numel(vr.vtx_turnCue)
            isBlurred(iSide, :, vr.cueAppeared{iSide}                                           ...
                & abs(vr.cuePos{iSide} - vr.position(2)) < vr.motionBlurRange(2)  ...
                ) = true;
        end
    else
        isBlurred(:)        = false;
    end
    isReset               = vr.cueBlurred & ~isBlurred;
    vr.cueBlurred         = isBlurred;
    
    % Reset cues that are no longer blurred
    vertices            = vr.vtx_turnCue(isReset);
    if ~isempty(vertices)
        vtxOffset         = vr.template_turnCue(isReset) * vr.yCue;
        vr.worlds{vr.currentWorld}.surface.vertices(2,vertices)     ...
            = vr.pos_turnCue(isReset) + vtxOffset;
        if ~isnan(vr.dimCue)
            vr.worlds{vr.currentWorld}.surface.colors(:,vertices)     ...
                = vr.color_turnCue(:,1:numel(vertices));
        end
    end
    
    % Elongate cues opposite to direction of motion
    vertices            = vr.vtx_turnCue(isBlurred);
    if ~isempty(vertices)
        vtxOffset         = dy/2 + vr.template_turnCue(isBlurred) * blurredWidth;
        vr.worlds{vr.currentWorld}.surface.vertices(2,vertices)     ...
            = vr.pos_turnCue(isBlurred) + vtxOffset;
        
        % Impose a falloff gradient if so desired
        if ~isnan(vr.dimCue)
            if abs(angleMPiPi(vr.position(end))) < pi/2
                vtxOffset     = vr.template_turnCue(isBlurred);
            else
                vtxOffset     = -vr.template_turnCue(isBlurred);
            end
            edgeLoc         = vr.yCue / blurredWidth - 0.5;
            isDimmed        = ( vtxOffset > edgeLoc );
            
            vtxOffset       = vtxOffset(isDimmed);
            vtxColor        = vr.cueColor                   ...
                + (vr.dimCue - vr.cueColor)     ...
                * (vtxOffset - edgeLoc)         ...
                / (0.5       - edgeLoc)         ...
                ;
            
            vr.worlds{vr.currentWorld}.surface.colors(:,vertices(isDimmed))   ...
                = bsxfun(@times, vtxColor', RigParameters.colorAdjustment);
        end
    end
end

end

