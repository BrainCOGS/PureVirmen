%% ViRMEn movement function for use with the optical sensor + Arduino + MouseReader_2sensors class setup.
%
%   Like moveArduinoLinearVelocityMEX(), except that the view angle is restricted to be 0 until
%   the turn period (vr.iTurnEntry > 0). Exponential gain is always used, and the scaleA parameter 
%   is co-opted to instead impose a soft temporal window.
%
%     figure; hold on;
%     dt=8/1000; A=0.2*dt*100; y=0; t=0:dt:2; for i=2:numel(t); y(i)=A + (1-A)*y(i-1); end; plot(t,y)
%     dt=12/1000; A=0.2*dt*100; y=0; t=0:dt:2; for i=2:numel(t); y(i)=A + (1-A)*y(i-1); end; plot(t,y)
%
function [velocity, rawData, viewAngleLock] = moveArduinoViewPinnedMEX(vr, viewAngleLock)

  % Obtain the displacement recorded by one sensor (here the second sensor)
  [dy1,dx1,dY,dX,dT]  = arduinoReader('get');
  rawData             = [dy1, dx1, dY, dX, dT];         % For logging

  % Send request for the readout to be used in the next iteration
  arduinoReader('poll');

  % Special case for zero integrated Arduino time -- assume that velocity
  % is the same as in the last ViRMEn frame
  if dT == 0
    velocity          = vr.velocity;
    
  else
    dY                = -dY;                            % This is just due to the orientation of the sensor
    dT                = dT / 1000;                      % Convert Arduino sampling time dT from ms to seconds
%     dF                = sqrt(dX^2 + dY^2) * sign(dY);   % Length (including sign for forward vs. backward movement) of displacement vector
    dF                = dY;

    if vr.iTurnEntry > 0
      % After the cue period, gradually unlock the allowed value range of view angles
      damping         = dT * 2 / vr.scaleA;
      viewAngleLock   = damping + (1 - damping) * viewAngleLock;

      % The rest of the computation is the same
      vr.orientation  = atan2(-dX*sign(dY), abs(dY));   % Zero along AP axis, counterclockwise is positive

      % Rotate displacement vector into animal's current coordinate frame
      R               = R2(vr.position(4));             % vr.position(4) is the current view angle in the virtual world
      temp            = R * [0; dF];
      dX              = temp(1);
      dY              = temp(2);

      % Apply scale factors to translate number of sensor dots to virtual world units
      velocity(1)     = vr.scaleX * dX / dT;
      velocity(2)     = vr.scaleY * dY / dT;
      velocity(3)     = 0;

      % Apply exponential gain function for view angle velocity 
      velocity(4)     = sign(vr.orientation) * min( exp(1.4*abs(vr.orientation)^1.2) - 1, pi );
      velocity(4)     = velocity(4) * viewAngleLock;
      
    else
      % Enforce zero view angle prior to end of cue period
      viewAngleLock   = 0;

      velocity(1)     = 0;
      velocity(2)     = vr.scaleY * dF / dT;
      velocity(3)     = 0;
      velocity(4)     = -angleMPiPi(vr.position(4));
    end
    
    
    % The following should never happen but just in case
    velocity(~isfinite(velocity)) = 0;
  end

end

%% 2D rotation matrix counter-clockwise.
function R = R2(x)
  R = [cos(x) -sin(x); sin(x) cos(x)];
end

