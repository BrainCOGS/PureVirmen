function exe = findFFmpeg()
%FINDFFMPEG Absolute path of the ffmpeg executable on PATH, or '' if absent.
%
%   java.lang.ProcessBuilder may not see PATH changes made with setenv in
%   this MATLAB session, so the recording path launches ffmpeg by the same
%   absolute path that system() resolves.

exe = '';
if ispc
    [status, out] = system('where ffmpeg');
else
    [status, out] = system('command -v ffmpeg');
end
if status ~= 0
    return;
end
lines = strtrim(strsplit(strtrim(out), {'\r\n', '\n', '\r'}));
for i = 1:numel(lines)
    if isfile(lines{i})
        exe = lines{i};
        return;
    end
end
end
