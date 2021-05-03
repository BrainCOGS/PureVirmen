function [vr] = setLandmarksMaze(vr, objectNames)
% set landmarks in maze

landmarkIndex             = find(~cellfun(@isempty,regexp(objectNames, 'Landmarks$', 'once')));
vr.dynamicLandmarks       = objectNames(landmarkIndex);
vr.tri_landmark           = cell(size(landmarkIndex));
vr.vtx_landmark           = cell(size(landmarkIndex));
vr.landmarkPos            = cell(size(landmarkIndex));
for iLM = 1:numel(landmarkIndex)
    %% HACK to deduce which triangles belong to which landmark
    landmarkObj             = vr.exper.worlds{vr.currentWorld}.objects{landmarkIndex(iLM)};
    nLandmarks              = numel(landmarkObj.symbolic.x);
    vr.tri_landmark{iLM}    = getVirmenFeatures('triangles', vr, vr.dynamicLandmarks{iLM});
    vr.vtx_landmark{iLM}    = getVirmenFeatures('vertices' , vr, vr.dynamicLandmarks{iLM});
    vr.tri_landmark{iLM}    = reshape(vr.tri_landmark{iLM}, [], nLandmarks);
    vr.vtx_landmark{iLM}    = reshape(vr.vtx_landmark{iLM}, [], nLandmarks);
    
    %% Cache landmark locations for speed; also apply side-specific landmark skipping for the current maze
    vr.landmarkPos{iLM}     = landmarkObj.y;
    for iSide = [-1 1]
        iMark                 = find(iSide * landmarkObj.x > 0);
        skip                  = true(size(iMark));
        skip(1:vr.landmarkSkip+1:end)     = false;
        vr.landmarkPos{iLM}(iMark(skip))  = nan;
    end
end

end

