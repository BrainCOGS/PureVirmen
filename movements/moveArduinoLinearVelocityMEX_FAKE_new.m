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
%   feet as [dX, dY] where dX is lateral and dY is anterior-posterior displacement. The orientation
%   of this displacement vector is interpreted as the rate of view angle change. The linear velocity
%   of the animal in the virtual world is computed by rotating [dX, dY] to the animal's coordinate
%   frame, i.e. a pure dY displacement (dX = 0) corresponds to moving forward/backwards along the
%   current trajectory (as defined by view angle) of the mouse.
%
%   Two different types of gain are supported for view angle velocity, depending on the value of
%   vr.scaleA. The first is a simple linear gain factor, i.e. if vr.scaleA is finite this function
%   will compute:
%       (view angle velocity) = vr.scaleA * vr.orientation / (1 second)
%
%   If vr.scaleA is set to NaN, a qualitatively determined exponential gain is used. This is
%   motivated by the fact that it is physically much more difficult for a mouse to orient its body
%   along large angles while head-fixed on top of a ball, and is therefore unable to make sharp
%   turns when a linear gain is applied (unless the gain is very large, which then makes it
%   impossible for the mouse to reliably walk in a straight line). The following code can be used to
%   visualize the exponential gain function:
%
%     figure; hold on; grid on; xlabel('Orientation (radians)'); ylabel('View angle velocity (rad/s)');
%     ori = -pi/2:0.01:pi/2; plot(ori,ori); plot(ori,sign(ori).*min( exp(1.4*abs(ori).^1.2) - 1, pi ));
%
function [velocity, rawData] = moveArduinoLinearVelocityMEX_FAKE_new(vr)

  persistent PosFromData cur_iter
  if isempty(PosFromData)
    PosFromData     = load('TrajectoryFile_1.mat');
    PosFromData.PosFromData = double(PosFromData.PosFromData);
    cur_iter        = 1;
  end

  % Obtain the displacement recorded by one sensor (here the second sensor)
%   [dy1,dx1,dY,dX,dT]= arduinoReader('get');

  dy1 = PosFromData.PosFromData(cur_iter,1);
  dx1 = PosFromData.PosFromData(cur_iter,2);
  dY  = PosFromData.PosFromData(cur_iter,3);
  dX  = PosFromData.PosFromData(cur_iter,4);
  dT  = PosFromData.PosFromData(cur_iter,5);
  cur_iter = cur_iter + 1;

  dotsPerRev        = RigParameters.sensorDotsPerRev(MovementSensor.BottomVelocity);
  vr.scaleX         = RigParameters.ballCircumference / dotsPerRev;
  vr.scaleY         = RigParameters.ballCircumference / dotsPerRev;

  rawData           = [dy1, dx1, dY, dX, dT];         % For logging

  % Send request for the readout to be used in the next iteration
%   arduinoReader('poll');

  % Special case for zero integrated Arduino time -- assume that velocity
  % is the same as in the last ViRMEn frame
  if dT == 0
    velocity        = vr.velocity;
    
  else
    dY              = -dY;                            % This is just due to the orientation of the sensor
    vr.orientation  = atan2(-dX*sign(dY), abs(dY));   % Zero along AP axis, counterclockwise is positive

    % Rotate displacement vector into animal's current coordinate frame
    R               = R2(vr.position(4));             % vr.position(4) is the current view angle in the virtual world
    dF              = sqrt(dX^2 + dY^2) * sign(dY);   % Length (including sign for forward vs. backward movement) of displacement vector
    temp            = R * [0; dF];
    dX              = temp(1);
    dY              = temp(2);
    
    % Convert Arduino sampling time dT from ms to seconds
    dT              = dT / 1000;

    % Apply scale factors to translate number of sensor dots to virtual world units
    velocity(1)     = vr.scaleX * dX / dT;
    velocity(2)     = vr.scaleY * dY / dT;
    velocity(3)     = 0;

    % Apply exponential gain function for view angle velocity if vr.scaleA is NaN
    if isnan(vr.scaleA)
      velocity(4)   = sign(vr.orientation) * min( exp(1.4*abs(vr.orientation)^1.2) - 1, pi );
    % Otherwise apply a linear gain
    else
      velocity(4)   = vr.scaleA * vr.orientation;
    end
    
    % The following should never happen but just in case
    velocity(~isfinite(velocity)) = 0;
  end

end

%% 2D rotation matrix counter-clockwise.
function R = R2(x)
  R = [cos(x) -sin(x); sin(x) cos(x)];
end

