function v = configureSingleCamera(RigParameters, video_filename)
%CONFIGURESINGLECAMERA Configure a single FLIR camera for disk-logged recording.
%
%   v = configureSingleCamera(RigParameters, video_filename)
%
%   Configures a FLIR camera via the GenTL adapter (Image Acquisition Toolbox
%   + FLIR Spinnaker GenTL support) and sets up a VideoWriter disk logger
%   (Motion JPEG 2000). The returned videoinput object v is ready to start;
%   call start(v) to begin acquisition.
%
%   Required RigParameters properties:
%     video_acquisition_rate  - frame rate in fps
%     video_gain              - analog gain
%
%   Optional RigParameters properties:
%     video_exposure_time_in_microseconds - if present and nonzero, sets
%       camera exposure; otherwise the camera default is used.
%
%   Requires: Image Acquisition Toolbox with FLIR Spinnaker GenTL support.
%   Install the support package via MATLAB Add-On Explorer by searching for
%   "FLIR Spinnaker".

imaqreset;
v   = videoinput('gentl', 1, 'Mono8');
src = getselectedsource(v);

src.AcquisitionFrameRateEnable = 'true';
src.AcquisitionFrameRate       = RigParameters.video_acquisition_rate;

if isprop(RigParameters, 'video_exposure_time_in_microseconds') && ...
        RigParameters.video_exposure_time_in_microseconds
    src.ExposureTime = RigParameters.video_exposure_time_in_microseconds;
end

src.Gain = RigParameters.video_gain;

v.FramesPerTrigger = Inf;
v.TriggerRepeat    = Inf;

logfile              = VideoWriter(video_filename, 'Motion JPEG 2000');
logfile.MJ2BitDepth  = 8;
logfile.FrameRate    = RigParameters.video_acquisition_rate;

v.LoggingMode = 'disk';
v.DiskLogger  = logfile;

end
