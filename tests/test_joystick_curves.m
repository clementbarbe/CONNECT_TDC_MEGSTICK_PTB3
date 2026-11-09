function test_joystick_curves()
%TEST_JOYSTICK_CURVES Equal-amplitude families use the actual task converter.
setup_AMEDYST();
settings = ADAPT.JoystickSettings();
limits = [-29376 -31482 27242 30784];
coefficients = [0 1 2 4 6 8];
xData = ADAPT.JoystickCurveData(limits,1,settings,coefficients,0.6);
yData = ADAPT.JoystickCurveData(limits,2,settings,coefficients,0.6);
assert(xData.Raw(1)==limits(1) && xData.Raw(end)==limits(3));
assert(yData.Raw(1)==limits(2) && yData.Raw(end)==limits(4));
assert(max(abs(xData.Response-yData.Response),[],'all')<1e-10);
assert(max(abs(xData.Response(end,:)-60))<1e-10);
assert(max(abs(xData.Response(1,:)+60))<1e-10);
assert(all(xData.Response(abs(xData.Normalized)<=settings.DeadZone,:)==0,'all'));
positive = xData.Normalized>settings.DeadZone & xData.Normalized<0.99;
assert(all(diff(xData.Response(positive,:),1,2)<0,'all'));
assert(all(diff(xData.Response,1,1)>=-1e-10,'all'));

% Vectorized drawing data and scalar acquisition queries agree, including
% simultaneous X/Y deflections and the zero point.
raw = [0 0; limits(1) 0; limits(3) 0; 0 limits(2); 0 limits(4); 3000 -4000];
for mode = {'Linear','Exponential'}
    settings.Conversion = mode{1};
    [x,y] = ADAPT.JoystickPosition(raw,[0 0],limits,1000,settings);
    for sample = 1:size(raw,1)
        [scalarX,scalarY] = ADAPT.JoystickPosition(raw(sample,:),[0 0],limits,1000,settings);
        assert(abs(x(sample)-scalarX)<1e-10 && abs(y(sample)-scalarY)<1e-10);
    end
end
settings.ExponentialCoefficient = 0;
[x,y] = ADAPT.JoystickPosition(raw,[0 0],limits,1000,settings);
settings.Conversion = 'Linear';
settings.LinearGain = settings.Gains(settings.GainIndex);
settings.LinearRangeRatio = settings.ExponentialRangeRatio;
[linearX,linearY] = ADAPT.JoystickPosition(raw,[0 0],limits,1000,settings);
assert(max(abs(x-linearX))<1e-10 && max(abs(y-linearY))<1e-10);
disp('All joystick curve family assertions passed.');
end
