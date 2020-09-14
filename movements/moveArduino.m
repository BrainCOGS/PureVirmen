%% ViRMEn movement function for use with the optical sensor + Arduino + MouseReader_1sensor class setup.
%
% This function assumes that 4 specific variables have been defined in the vr object:
% 1) vr.mr: A MouseReader object
% 2) vr.scaleX: factor by which to scale dX
% 3) vr.scaleY: factor by which to scale dY
% 4) vr.scaleA: factor by which to scale dA
%
% Example snippet of code from the main experiment file, initialization code:
%
%     vr.mr = MouseReader_1sensor('COM3');
% 
%     opticalMouseUnitsPerCm = 9500 / 63.8; % obtained using calibrateBall script
%     virmenUnitsPerCm = 1; % choosing to set a 1:1 correspondence between virmen units and centimetres in real world
%     scale = virmenUnitsPerCm / opticalMouseUnitsPerCm;
%     vr.scaleX =  scale;
%     vr.scaleY =  scale;
%     vr.scaleA = 1/60; % chosen qualitatively, determines ease of turn on ball
%
function velocity = moveArduino(vr)
  [dF, dA] = vr.mr.get_xy_change();  %F=forward=x of the mouse, A=angle=y of the mouse

  R = R2(vr.position(4));  %this is the last iteration position in Virmen world coordinates, and position(4) is the angle (A value)
                             % position(1..4)=  1=Left/right,
                             % 2=forward/backward, 3=up/down=0, 4=angle of the viewer
  temp = R*[0; dF];
  dX = temp(1);
  dY = temp(2);

  velocity(1) = vr.scaleX*dX / vr.dt;
  velocity(2) = vr.scaleY*dY / vr.dt;
  velocity(3) = 0;
  velocity(4) = vr.scaleA*dA / vr.dt;

  velocity(isnan(velocity)) = 0;
  velocity(isinf(velocity)) = 0;

  % Send request for the readout to be used in the next iteration
  vr.mr.poll_mouse();
end

function R=R2(x)
    %2D Rotation matrix counter-clockwise.
    R = [cos(x) -sin(x); sin(x) cos(x)];
end

