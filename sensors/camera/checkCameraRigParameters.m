function checkCameraRigParameters()
%CHECKCAMERARIGPARAMETERS Validate RigParameters for video acquisition.
%
%   Throws an error listing any missing properties required by
%   startVideoAcquisition / configureSingleCamera.
%
%   When RigParameters.useFFmpeg is true, also checks that ffmpegEncoder is
%   set and that ffmpeg is available on the system PATH (warns and does not
%   error if ffmpeg is missing — configureSingleCamera will fall back to
%   VideoWriter automatically).

required = {'video_parent_path', 'video_ext', 'video_acquisition_rate', 'video_gain'};

missing = {};
for i = 1:length(required)
    if ~isprop(RigParameters, required{i})
        missing{end+1} = required{i}; %#ok<AGROW>
    end
end

if ~isempty(missing)
    error('PureVirmen:missingRigParameters', ...
        'Missing required RigParameters for video acquisition: %s', ...
        strjoin(missing, ', '));
end

% ffmpeg-specific checks
if isprop(RigParameters, 'useFFmpeg') && RigParameters.useFFmpeg

    if ~isprop(RigParameters, 'ffmpegEncoder') || isempty(RigParameters.ffmpegEncoder)
        error('PureVirmen:missingRigParameters', ...
            ['RigParameters.ffmpegEncoder must be set when useFFmpeg = true.\n' ...
             'Use ''h264_nvenc'' (NVIDIA GPU) or ''libx264'' (CPU).']);
    end

    [status, ~] = system('ffmpeg -version');
    if status ~= 0
        warning('PureVirmen:noFFmpeg', ...
            ['ffmpeg not found on system PATH. ' ...
             'Recording will fall back to VideoWriter (Motion JPEG 2000). ' ...
             'To use ffmpeg, install it and ensure it is on the PATH.']);
    end

end

end
