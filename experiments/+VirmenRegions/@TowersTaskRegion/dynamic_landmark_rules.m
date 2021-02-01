function vr = dynamic_landmark_rules( vr )
% Code executed based on dynamic landmarks rules of protocol Poisson Towers
% Input/Output
% vr = virmen handle

% Landmarks are triggered only when animal is facing forward
if abs(angleMPiPi(vr.position(end))) < pi/2
    for iLM = 1:numel(vr.dynamicLandmarks)
        
        %% If the landmark is not on, check if we should turn it on
        lmarkDistance     = vr.landmarkPos{iLM} - vr.position(2);
        isTriggered       = ~vr.landmarkAppeared{iLM}                 ...
            & (lmarkDistance <= vr.landmarkVisibleAt)   ...
            ;
        if ~any(isTriggered)
            continue;
        end
        
        %% If approaching a landmark and near enough, make it visible in the next iteration
        triangles     = vr.tri_landmark{iLM}(:,isTriggered);
        vr.landmarkAppeared{iLM}(isTriggered) = true;
        vr.landmarkOnset{iLM}(isTriggered)    = vr.logger.iterationStamp();
        vr.worlds{vr.currentWorld}.surface.visible(triangles) = true;
        
    end
end

end

