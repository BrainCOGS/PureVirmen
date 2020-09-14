function velocity = moveWithAutoKeyboard(vr)
% Keyboard control movement function for ViRMEn
%   Left/Right: change view angle
%   CTRL + Left/Right: move left/right
%   Up/Down: move forward/backward
%   CTRL + Up/Down: move up/down

persistent keyboardControl

% if ~isfield(keyboardControl,'forward')
if isempty(keyboardControl)
    keyboardControl.forward = 0;
    keyboardControl.rotation = 0;
    keyboardControl.sideways = 0;
    keyboardControl.vertical = 0;
    keyboardControl.autoMove = false;
end

if RigParameters.simulationMode
  linearScale = 5;
  rotationScale = 0.2;
else
  linearScale = 70;
  rotationScale = 3;
end

switch vr.keyPressed
    case 262
        if vr.modifiers == 0
            keyboardControl.rotation = -rotationScale;
        elseif vr.modifiers == 2
            keyboardControl.sideways = linearScale;
        end
    case 263
        if vr.modifiers == 0
            keyboardControl.rotation = rotationScale;
        elseif vr.modifiers == 2
            keyboardControl.sideways = -linearScale;
        end
    case 264
        if vr.modifiers == 0
            keyboardControl.forward = -linearScale;
        elseif vr.modifiers == 2
            keyboardControl.vertical = -linearScale;
        end
    case 265
        if vr.modifiers == 0
            keyboardControl.forward = linearScale;
        elseif vr.modifiers == 2
            keyboardControl.vertical = linearScale;
        end
    case 32   % space
        keyboardControl.autoMove = ~keyboardControl.autoMove;
        if keyboardControl.autoMove
            keyboardControl.forward = linearScale;
        else
            keyboardControl.forward = 0;
        end

end
switch vr.keyReleased
    case {262, 263}
        keyboardControl.rotation = 0;
        keyboardControl.sideways = 0;
    case {264, 265}
        keyboardControl.forward = 0;
        keyboardControl.vertical = 0;
end


if false && vr.scaleX == 0 && vr.scaleY == 0
  velocity  = [0 0 0 0];
else
  velocity  = [ keyboardControl.forward  * [sin(-vr.position(4)) cos(-vr.position(4))]  ...
              + keyboardControl.sideways * [cos( vr.position(4)) sin( vr.position(4))]  ...
              , keyboardControl.vertical                                                ...
              , keyboardControl.rotation                                                ...
              ];
end
