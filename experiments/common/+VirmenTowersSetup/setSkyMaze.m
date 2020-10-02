function [vr] = setSkyMaze(vr, objectNames)

%% Variable sky, if any
skyIndex                  = find(~cellfun(@isempty,regexp(objectNames, 'Sky$', 'once')));
vr.dynamicSky             = objectNames(skyIndex);
vr.tri_sky                = cell(size(skyIndex));
vr.vtx_sky                = cell(size(skyIndex));
vr.clr_sky                = cell(size(skyIndex));
vr.skyColors              = cell(size(skyIndex));
for iSky = 1:numel(skyIndex)
    %% Deduce which triangles belong to which color
    vr.tri_sky{iSky}        = getVirmenFeatures('triangles', vr, vr.dynamicSky{iSky});
    vr.vtx_sky{iSky}        = getVirmenFeatures('vertices' , vr, vr.dynamicSky{iSky});
    skyColors               = vr.worlds{vr.currentWorld}.surface.colors(:,vr.vtx_sky{iSky})';
    hasColor                = ~any(isnan(skyColors), 2);
    vtxIndex                = vr.vtx_sky{iSky};
    vtxIndex                = vtxIndex(hasColor);
    [vr.skyColors{iSky}, ~, iColor]                                   ...
        = unique(skyColors(hasColor,:), 'rows');
    vr.clr_sky{iSky}        = arrayfun(@(x) vtxIndex(iColor == x), 1:size(vr.skyColors{iSky},1), 'UniformOutput', false);
end

if isempty(skyIndex)
    vr.skySwitchInterval    = [];
else
    %% HACK : Assume that all skies have the same number of colors, to reduce number of combinations
    nColors                 = unique(cellfun(@(x) size(x,1), vr.skyColors));
    assert( numel(nColors) == 1 );
    
    %% Construct all possible permutations of sky colors, for switching
    vr.skyColorCombo        = perms(1:nColors);
    vr.skyColorCode         = sum(bsxfun(@times, perms(1:nColors), 10.^(nColors-1:-1:0)), 2);
    vr.currentSkyColor      = find(all(bsxfun(@eq, vr.skyColorCombo, 1:nColors), 2));
end

end

