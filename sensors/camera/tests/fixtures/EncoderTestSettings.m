classdef EncoderTestSettings
    properties
        useFFmpeg = true
        video_acquisition_rate = 30
        video_gain = 0
        ffmpegEncoder = 'libx264'
        ffmpegPreset = 'fast'
        ffmpegCRF = 18
    end
end
