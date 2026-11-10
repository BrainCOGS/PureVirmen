function checkCameraRigParameters()
%CHECKCAMERARIGPARAMETERS Validate RigParameters for video acquisition.
%
%   Throws an error listing any missing properties required by
%   startVideoAcquisition / configureSingleCamera.

required = {'video_parent_path', 'video_ext', 'video_acquisition_rate', 'video_gain'};

missing = {};
for i = 1:length(required)
    if ~isprop(RigParameters, required{i})
        missing{end+1} = required{i}; %#ok<AGROW>
    end
end

if ~isempty(missing)
    error('PureVirmen:missingRigParameters', ...
        'Missing required RigParameters for video acquisition: %s\n', ...
        strjoin(missing, ', '));
end

end
