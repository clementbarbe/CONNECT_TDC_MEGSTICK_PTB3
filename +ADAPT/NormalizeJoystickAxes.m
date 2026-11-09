function position = NormalizeJoystickAxes(rawAxes, center, limits)
%NORMALIZEJOYSTICKAXES Keep both calibrated endpoints after changing zero.
% rawAxes: N-by-2, center: [X Y], limits: [xmin ymin xmax ymax].
if ~isnumeric(limits) || ~isreal(limits) || numel(limits) ~= 4
    error('AMEDYST:JoystickCalibration', ...
        'Calibrez le joystick : quatre valeurs [xmin ymin xmax ymax].');
end
limits = reshape(limits,1,4);
if any(~isfinite(limits)) || any(limits(1:2) >= 0) || any(limits(3:4) <= 0)
    error('AMEDYST:JoystickCalibration', ...
        'Calibrez le joystick : [xmin ymin xmax ymax], minima < 0, maxima > 0.');
end
center = reshape(center,1,2);
if any(~isfinite(center)) || any(center <= limits(1:2)) || ...
        any(center >= limits(3:4))
    error('AMEDYST:JoystickCenter','Le repos doit etre entre les bornes calibrees.');
end
position = double(rawAxes) - center;
span = repmat(limits(3:4)-center,size(position,1),1);
negative = position < 0;
negativeSpan = repmat(center-limits(1:2),size(position,1),1);
span(negative) = negativeSpan(negative);
position = position ./ span;
end
