%% Enumeration constants for identifying optical sensors.
classdef MovementSensor < uint8
  
  enumeration
    BottomVelocity  (1)
    BottomPosition  (2)
    FrontVelocity   (3)
    ViewAngleLocked (4)
  end
  
  methods (Static)
    
    function num = count()
      num = numel(enumeration('MovementSensor'));
    end
    
    function fcn = rule(sensor)
      
      switch sensor
        case MovementSensor.BottomVelocity
          fcn   = @moveArduinoLinearVelocityMEX;
        case MovementSensor.BottomPosition
          fcn   = @moveArduinoLiteralMEX;
        case MovementSensor.FrontVelocity
          fcn   = @moveArduino;
        case MovementSensor.ViewAngleLocked
          fcn   = @moveArduinoViewPinnedMEX;
        otherwise
          error('MovementSensor:rule', 'Unsupported movement sensor type "%s".', char(sensor));
      end
      
    end
    
  end
  
end
