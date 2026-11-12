function cmdParts = buildFFmpegCommand(ffmpegExe, opts, width, height, fps, input, outFile)
%BUILDFFMPEGCOMMAND Build the ffmpeg argument list for Mono8 camera recording.
%
%   cmdParts = buildFFmpegCommand(ffmpegExe, opts, width, height, fps, input, outFile)
%
%   Shared by the recording launch (input = 'pipe:0') and the encoder
%   preflight (input = a raw synthetic-frame file), so the preflight tests
%   exactly the encoder, resolution, rate and options used for recording.
%
%   Inputs:
%     ffmpegExe     - path to the ffmpeg executable (see findFFmpeg)
%     opts          - encoder options struct from ffmpegEncoderOptions
%     width, height - frame size in pixels
%     fps           - input frame rate
%     input         - 'pipe:0' or path to a raw gray8 file
%     outFile       - output .mp4 path
%
%   Returns a cell array of strings, one per argument, for
%   java.lang.ProcessBuilder (no shell does word-splitting for us).

% Camera delivers single-channel Mono8 (-pix_fmt gray on input). Force a
% widely-compatible output pixel format so the .mp4 plays in standard
% players / H.264 decoders that don't accept grayscale streams.
cmdParts = { ffmpegExe, '-hide_banner', '-nostats', '-y', ...
    '-f', 'rawvideo', '-pix_fmt', 'gray', ...
    '-s', sprintf('%dx%d', width, height), '-r', num2str(fps), ...
    '-i', input, ...
    '-c:v', opts.encoder };
cmdParts = [cmdParts, encoderArgs(opts), splitArgs(opts.extraArgs), ...
            {'-pix_fmt', 'yuv420p', outFile}];

end

% -------------------------------------------------------------------------

function args = encoderArgs(opts)
%   NVENC (h264_nvenc / hevc_nvenc): bitrate control (CRF is not supported).
%   libx264 / libx265 (CPU): CRF constant-quality control.
%   Anything else: no extra args; rely on ffmpegExtraArgs.
if contains(opts.encoder, 'nvenc')
    args = {'-preset', opts.preset, '-b:v', opts.bitrate};
elseif contains(opts.encoder, 'libx264') || contains(opts.encoder, 'libx265')
    args = {'-preset', opts.preset, '-crf', sprintf('%d', round(opts.crf))};
else
    args = {};
end
end

% -------------------------------------------------------------------------

function parts = splitArgs(argStr)
% Split a whitespace-separated argument string into a cell array, dropping
% empties.
if isempty(argStr)
    parts = {};
    return;
end
parts = strsplit(strtrim(argStr));
parts = parts(~cellfun(@isempty, parts));
end
