function vr = setExperimentVarsTowersTask(vr)

vr.experimentVars     = [ vr.stimulusParameters                               ...
    , { 'cueDuration', 'antiFraction', 'yCue'             ...
    , 'lStart', 'lCue', 'lMemory', 'lArm'               ... for maze length
    , 'maxExcessTravel', {'puffDuration',nan}           ...
    , {'skySwitchInterval',[]}                          ...
    } ];


vr.motionBlurRange    = vr.exper.userdata.trainee.motionBlurRange;
if ~isempty(vr.motionBlurRange)
    vr.experimentVars   = [vr.experimentVars, {'cueColor', 'dimCue'}];
end

% Support for dynamic landmarks and sky, if present
objectNames           = fieldnames(vr.worlds{vr.currentWorld}.objects.indices);
if any(~cellfun(@isempty,regexp(objectNames, 'Landmarks$', 'once')))
    vr.experimentVars   = [vr.experimentVars, 'landmarkSkip', 'landmarkVisibleAt'];
end
if any(~cellfun(@isempty,regexp(objectNames, 'Sky$', 'once')))
end
