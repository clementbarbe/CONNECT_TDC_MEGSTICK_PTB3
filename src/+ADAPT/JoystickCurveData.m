function data = JoystickCurveData(limits, axisIndex, settings, coefficients, gain)
%JOYSTICKCURVEDATA Use the task converter for equal-amplitude comparisons.
% Positions are percentages of window height; no PTB or joystick is needed.
ADAPT.NormalizeJoystickAxes([0 0],[0 0],limits);
limits = reshape(limits,1,4);
validateattributes(axisIndex,{'numeric'},{'scalar','integer','>=',1,'<=',2});
validateattributes(coefficients,{'numeric'},{'vector','nonempty','real','finite','>=',0,'<=',12});
validateattributes(gain,{'numeric'},{'scalar','real','finite','positive','<=',2});
validateattributes(settings.DeadZone,{'numeric'},{'scalar','real','finite','>=',0,'<',1});
normalized = linspace(-1,1,1001)';
raw = zeros(numel(normalized),2);
raw(:,axisIndex) = max(normalized,0)*limits(axisIndex+2) + ...
    min(normalized,0)*(-limits(axisIndex));
response = zeros(numel(normalized),numel(coefficients));
for index = 1:numel(coefficients)
    profile = settings;
    profile.Gains = gain;
    profile.GainIndex = 1;
    profile.ExponentialCoefficient = coefficients(index);
    if coefficients(index) == 0
        profile.Conversion = 'Linear';
        profile.LinearGain = gain;
        profile.LinearRangeRatio = settings.ExponentialRangeRatio;
    else
        profile.Conversion = 'Exponential';
    end
    [x,y] = ADAPT.JoystickPosition(raw,[0 0],limits,100,profile);
    if axisIndex == 1, response(:,index) = x;
    else, response(:,index) = y; end
end
data = struct('Raw',raw(:,axisIndex),'Normalized',normalized, ...
    'Response',response,'Coefficients',coefficients,'Gain',gain,'Limits',limits);
end
