function velocity = moveRandomly(vr)

linearScale = 50;
if rand() < 0.1
  rotation  = randn() * pi/4;
else
  rotation  = 0;
end

velocity    = [ linearScale * [sin(-vr.position(4)) cos(-vr.position(4))]   ...
                0                                                           ...
                rotation                                                    ...
              ];
