function [X,Y] = JoystickPosition(rawAxes, center, limits, screenHeight, settings)
%JOYSTICKPOSITION Convert absolute joystick deflection before any rotation.
position = ADAPT.NormalizeJoystickAxes(rawAxes,center,limits);
radius = hypot(position(:,1),position(:,2));
% A radial curve preserves direction, including diagonal movements. The
% dead zone is removed continuously and full travel always remains reachable.
fraction = max(0,min(1,(radius-settings.DeadZone)/(1-settings.DeadZone)));
switch settings.Conversion
    case 'Linear'
        amplitude = fraction;
        gain = settings.LinearGain;
        rangePixels = settings.LinearRangeRatio * screenHeight;
    case 'Exponential'
        coefficient = settings.ExponentialCoefficient;
        if coefficient == 0
            amplitude = fraction; % continuous linear limit at k=0
        else
            amplitude = expm1(coefficient*fraction)/expm1(coefficient);
        end
        gain = settings.Gains(settings.GainIndex);
        % The x0.60 profile must still reach the outer ring. Use an explicit
        % full-height reference; the linear comparison keeps its old scale.
        rangePixels = settings.ExponentialRangeRatio * screenHeight;
    otherwise
        error('AMEDYST:JoystickConversion','Conversion joystick inconnue : %s',settings.Conversion);
end
scale = zeros(size(radius));
nonzero = radius > 0;
scale(nonzero) = amplitude(nonzero) * gain * rangePixels ./ radius(nonzero);
position = position .* scale;
X = position(:,1);
Y = position(:,2);
end
