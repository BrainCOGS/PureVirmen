function video_fullname = setupVideoFile(video_parent_path, video_ext, subject_fullname, session_number)
%SETUPVIDEOFILE Build the full output path for a video file and create its directory.
%
%   video_fullname = setupVideoFile(video_parent_path, video_ext, ...
%                                   subject_fullname, session_number)
%
%   Follows the naming convention:
%     <video_parent_path>/<userid>/<subject>/<YYYYMMDD_g#>/<subject>_<YYYYMMDD_g#><ext>
%
%   where userid is the portion of subject_fullname before the first '_'.
%   This convention is compatible with the U19 pipeline paths.
%
%   Example:
%     setupVideoFile('D:\Videos', '.mj2', 'labuser_mouse01', 2)
%     -> D:\Videos\labuser\labuser_mouse01\20240618_g2\labuser_mouse01_20240618_g2.mj2

if ~contains(subject_fullname, '_')
    userid = 'no_userid';
else
    parts  = strsplit(subject_fullname, '_');
    userid = parts{1};
end

date_str     = datestr(now, 'yyyymmdd');
session_tag  = [date_str '_g' num2str(session_number)];
filename_only = [subject_fullname '_' session_tag];
relative_dir  = fullfile(userid, subject_fullname, session_tag);

video_dir = fullfile(video_parent_path, relative_dir);
if ~isfolder(video_dir)
    mkdir(video_dir);
end

video_fullname = fullfile(video_dir, [filename_only video_ext]);

end
