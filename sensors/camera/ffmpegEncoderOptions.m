function opts = ffmpegEncoderOptions(RigParameters, encoder)
%FFMPEGENCODEROPTIONS Encoder settings for the ffmpeg recording path.
%
%   opts = ffmpegEncoderOptions(RigParameters)
%       Settings requested by RigParameters (ffmpegEncoder, ffmpegPreset,
%       ffmpegBitrate, ffmpegCRF, ffmpegExtraArgs), with defaults.
%
%   opts = ffmpegEncoderOptions(RigParameters, 'libx264')
%       CPU fallback settings. NVENC-only presets (p1-p7, 'lossless', ...)
%       are replaced by 'fast'; ffmpegCRF is used when set, else 23.
%       ffmpegExtraArgs is kept, and the fallback preflight checks it.
%
%   Fields: encoder, preset, bitrate, crf, extraArgs.

if nargin < 2
    encoder = rigValue(RigParameters, 'ffmpegEncoder', 'h264_nvenc');
end

opts = struct();
opts.encoder   = char(encoder);
opts.preset    = char(rigValue(RigParameters, 'ffmpegPreset', 'fast'));
opts.bitrate   = char(rigValue(RigParameters, 'ffmpegBitrate', '5M'));
opts.crf       = rigValue(RigParameters, 'ffmpegCRF', 23);
opts.extraArgs = char(rigValue(RigParameters, 'ffmpegExtraArgs', ''));

x264Presets = {'ultrafast', 'superfast', 'veryfast', 'faster', 'fast', ...
               'medium', 'slow', 'slower', 'veryslow', 'placebo'};
if contains(opts.encoder, 'libx26') && ~any(strcmp(opts.preset, x264Presets))
    opts.preset = 'fast';
end

end

% -------------------------------------------------------------------------

function value = rigValue(RigParameters, name, default)
value = default;
if isprop(RigParameters, name) && ~isempty(RigParameters.(name))
    value = RigParameters.(name);
end
end
