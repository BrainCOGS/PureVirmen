% Example use:
% Ball has circumference of 63.8 cm
% Run program, spin ball exactly 10 times about axis producing dx, kill process, read value of dx, it equals 9500
% Therefore opticalMouseUnitsPerCm = 9500/63.8

% cleanupHandler = onCleanup(@() arduinoReader('end', true));

arduinoReader('end', true);
arduinoReader('init', RigParameters.arduinoPort);
arduinoReader('poll');

dx = 0;
dy = 0;

sprintf('Now running. Spin ball desired number of times along desired axis, then kill process.\n dx and dy will be stored in variables with those names.\n After, run fclose(instrfindall)')

while true
  [dy1,dx1,dY,dX,dT]  = arduinoReader('get');
  arduinoReader('poll');
  java.lang.Thread.sleep(8);

  dx = dx + dX;
  dy = dy + dY;
end
