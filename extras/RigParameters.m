classdef RigParameters
    
    properties (Constant)
        
        rig                 = 'TestAlvaro'
        simulationMode      = true             % true to run in simulation mode with human input via keyboard
        hasDAQ              = false              % false for testing on laptop
        hasSyncComm         = false             % true if digital communications should be used for synchronization (ScanImage)
        minIterationDT      = 0.01              % Minimum expected ViRMEn frame rate in seconds
        
        arduinoPort         = 'COM7'           % Arduino port as seen in the Windows Device Manager
        sensorDotsPerRev    = RigParameters.sensorCalibration()
        ballCircumference   = 63.8              % in cm
        
        toroidXFormP1       = 0.3879            % p1 parameter (slope) from poly1 fit of toroidal screen transformation
        toroidXFormP2       = 0.392            % p2 parameter (offset) from poly1 fit of toroidal screen transformation
        colorAdjustment     = [0; 0.4; 0.5]     % [R; G; B] scale factor for projector display
        soundAdjustment     = 0.2               % Scale factor for sound volume
        
        nidaqDevice         = 1                 % NI-DAQ device identifier
        nidaqPort           = 0                 % NI-DAQ port number
        nidaqLines          = [0 11]            % NI-DAQ lines for the specified port
        syncClockChannel    = 5                 % NI-DAQ digital line for I2C clock signal
        syncDataChannel     = 6                 % NI-DAQ digital line for I2C data signal
        
        rewardChannel       = 0                 % NI-DAQ digital line for turning on/off the solenoid valve
        rewardSize          = 4/1000            % in mL
        rewardDuration      = 0.05              % Valve opening duration (in seconds) for 4uL reward
        
        guiMonitor          = 1                 % use "get(0, 'Monitor');" to see which monitor, set 1 or 2 for first/second monitor
        
        laserChannel        = 1                 % NI-DAQ digital line for turning on/off the laser
        rightPuffChannel    = 2                 % NI-DAQ digital line for left air puff solenoid
        leftPuffChannel     = 3                 % NI-DAQ digital line for right air puff solenoid
        
        ipAddressBControl   = '192.168.0.22'    % ipAddress BControl computer
        tcpClientPort       = 30000             % port for tcp communication
        outputBufferSize    = 40                % byte size for virmen variables
        
        
        %% Mini VR projection parameters
        % Spherical screen radius
        proj_param_Rs           =    8;
        
        % Screen's center location relative to the animal eyes
        proj_param_xsm          =    1.814;
        proj_param_ysm          =    0;
        proj_param_zsm          =    0.47;
        
        % Mirror position relative to the animal eyes
        % Mirror position measurement is facilitated knowing that the center of
        %spherical mirror is (43.8-24.2=)19.6mm (0.77in) behind the back surface.
        proj_param_xOm          =   5.582;
        proj_param_yOm          =   0;
        proj_param_zOm          =   -6.62;
        
        % Radius of the spherical mirror (Silver coated lens LA1740-Thorlabs)
        proj_param_r            =   1.724;
        
        % Projector position relative to the mirror center
        proj_param_xP1o         =   11.1;
        proj_param_yP1o         =   0;
        proj_param_zP1o         =   -0.6;
        
        % Horizontal coordinate shift and rescaling
        proj_param_hrescaling   =   5.5;
        proj_param_hshift       =   0.000;
        
        % Vertical coordinate shift and rescaling
        proj_param_vrescaling   =   5.5;
        proj_param_vshift       =   -1.017;
        
        
    end
    
    methods (Static, Access = protected)
        
        function dotsPerRev = sensorCalibration()
            % Sensor dots per ball revolution, obtained using the calibrateBall script
            
            dotsPerRev        = nan(1, MovementSensor.count());
            dotsPerRev(MovementSensor.FrontVelocity)    = 23101/10;
            dotsPerRev(MovementSensor.BottomVelocity)   = 23101/10;
            dotsPerRev(MovementSensor.BottomPosition)   = dotsPerRev(MovementSensor.BottomVelocity);
            dotsPerRev(MovementSensor.ViewAngleLocked)  = dotsPerRev(MovementSensor.BottomVelocity);
            
            if any(isnan(dotsPerRev))
                error('RigParameters:sensorCalibration', 'Some sensor calibration data was not specified, please correct this.');
            end
            
        end
        
    end
    
end
