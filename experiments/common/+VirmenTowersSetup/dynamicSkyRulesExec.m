function [ vr ] = dynamicSkyRulesExec( vr )
%dynamicSkyRulesExec
% Code executed based on dynamic Sky Rules of protocol Poisson Towers

if ~isempty(vr.skySwitchInterval)
    if vr.timeElapsed - vr.prevSkySwitch >= vr.nextSkySwitch
        %% Draw a new sky color, excluding the current one
        newColor          = randi(numel(vr.skyColorCode)-1);
        if newColor >= vr.currentSkyColor
            newColor        = vr.currentSkyColor + 1;
        end
        vr.currentSkyColor= newColor;
        
        %% Apply colors
        for iSky = 1:numel(vr.clr_sky)
            for iPattern = 1:size(vr.skyColorCombo,2)
                newColor      = vr.skyColors{iSky}(vr.skyColorCombo(vr.currentSkyColor, iPattern),:);
                for iRGB = 1:numel(newColor)
                    vr.worlds{vr.currentWorld}.surface.colors(iRGB,vr.clr_sky{iSky}{iPattern})   ...
                        = newColor(iRGB);
                end
            end
        end
        
        %% Record iteration and pattern of the sky
        vr.skySwitch(end+1,1) = vr.logger.iterationStamp();
        vr.skySwitch(end,2)   = vr.skyColorCode(vr.currentSkyColor);
        vr.prevSkySwitch  = vr.timeElapsed;
        vr.nextSkySwitch  = vr.skySwitchInterval(1) + exprnd(vr.skySwitchInterval(2));
    end
    
end

end

