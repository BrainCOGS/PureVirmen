function cam = videoinput(varargin) %#ok<INUSD>
%VIDEOINPUT Test double: shadows IMAQ's videoinput with a VirtualCamera.
%   Only shadows the toolbox when the Image Acquisition Toolbox folders are
%   off the path, as testFFmpegEncoderFallback arranges.
cam = VirtualCamera;
end
