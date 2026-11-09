function rawAxes = ReadJoystickAxes()
%READJOYSTICKAXES Raw ADC values in the task's right/up coordinate system.
data = joymex2('query',0);
rawAxes = [double(data.axes(1)), -double(data.axes(2))];
end
