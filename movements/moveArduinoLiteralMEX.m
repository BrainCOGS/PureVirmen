%% ViRMEn movement function for use with the optical sensor + Arduino + MouseReader_2sensors class setup.
%
%   This function assumes that 4 specific variables have been defined in the vr object, for example
%   by calling the initializeArduinoMouse_2sensors() function in the ViRMEn initialization user code
%   section:
%     1) vr.mr:       A MouseReader_2sensors object
%     2) vr.scaleX:   factor by which to scale dX
%     3) vr.scaleY:   factor by which to scale dY
%     4) vr.scaleA:   factor by which to scale dA
%
%   This motion rule assumes that the sensor measures the displacement of the ball at the mouse's
%   feet as [dX, dY] where dX is lateral and dY is anterior-posterior displacement. The displacement
%   is taken literally as the velocity of the mouse in the virtual world, where dX is along the
%   world x-axis and dY is along the world y-axis. The orientation of this displacement vector is
%   interpreted as the new view angle of the animal in the virtual world, with the view angle
%   velocity computed such that this change in view angle is over the course of 1 second.
%
%   Two different types of gain are supported for view angle, depending on the value of vr.scaleA.
%   The first is a simple linear gain factor, i.e. if vr.scaleA is finite this function will
%   compute:
%       (view angle) = vr.scaleA * vr.orientation
%
%   If vr.scaleA is set to NaN, a qualitatively determined exponential gain is used. This is
%   motivated by the fact that it is physically much more difficult for a mouse to orient its body
%   along large angles while head-fixed on top of a ball, and is therefore unable to make sharp
%   turns when a linear gain is applied (unless the gain is very large, which then makes it
%   impossible for the mouse to reliably walk in a straight line). The following code can be used to
%   visualize the exponential gain function:
%
%     figure; hold on; grid on; xlabel('Orientation (radians)'); ylabel('View angle velocity (rad/s)');
%     ori = -pi/2:0.01:pi/2; plot(ori,ori); plot(ori,sign(ori).*min( exp(1.4*abs(ori).^1.2) - 1, pi/2 ));
%
function [velocity, rawData] = moveArduinoLiteralMEX(vr)

  % Obtain the displacement recorded by one sensor (here the second sensor)
  [dy1,dx1,dY,dX,dT]= arduinoReader('get');
  rawData           = [dy1, dx1, dY, dX, dT];         % For logging

  % Send request for the readout to be used in the next iteration
  arduinoReader('poll');

  % Special case for zero integrated Arduino time -- assume that velocity
  % is the same as in the last ViRMEn frame
  if dT == 0
    velocity        = vr.velocity;
    
  else
    dY              = -dY;                            % This is just due to the orientation of the sensor
    vr.orientation  = atan2(-dX*sign(dY), abs(dY));   % Zero along AP axis, counterclockwise is positive
    heading         = angleMPiPi(vr.position(4));     % vr.position(4) is the current view angle in the virtual world
  
    % Convert Arduino sampling time dT from ms to seconds
    dT              = dT / 1000;
  
    % Apply scale factors to translate number of sensor dots to virtual world units
    velocity(1)     = vr.scaleX * dX / dT;
    velocity(2)     = vr.scaleY * dY / dT;
    velocity(3)     = 0;
    
    % Apply exponential gain function for view angle velocity if vr.scaleA is NaN
    if isnan(vr.scaleA)
      vr.orientation= sign(vr.orientation) * min( exp(1.4*abs(vr.orientation)^1.2) - 1, pi/2 );
      velocity(4)   = (vr.orientation - heading);
    % Otherwise apply a linear gain
    else
      velocity(4)   = vr.scaleA * (vr.orientation - heading);
    end
  
    % The following should never happen but just in case
    velocity(~isfinite(velocity)) = 0;
  end
  
end
