
% Example use:
% Ball has circumference of 63.8 cm
% Run program, spin ball exactly 10 times about axis producing dx, kill process, read value of dx, it equals 9500
% Therefore opticalMouseUnitsPerCm = 9500/63.8

% pin = 4;
pin = 10;

mr = MouseReader(RigParameters.arduinoPort);

dx = 0;
dy = 0;

sprintf('Now running. Spin ball desired number of times along desired axis, then kill process.\n dx and dy will be stored in variables with those names.\n After, run fclose(instrfindall)')

while true
    mr.poll_mouse();
    [x, y] = mr.get_xy_change();
    dx = dx + x;
    dy = dy + y;
end

