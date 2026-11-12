function rawAxes = ReadJoystickAxes()
%READJOYSTICKAXES ADC axes in the right/up task frame, relative to measured rest.
global S
if isstruct(S) && isfield(S,'JoystickConnection')
    rawAxes = ADAPT.JoystickDevice('read');
else
    data = joymex2('query',0);
    rawAxes = [double(data.axes(1)), -double(data.axes(2))];
end
end
