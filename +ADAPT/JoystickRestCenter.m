function [center, stable, normalizedRange, inStartZone] = JoystickRestCenter(rawSamples, times, limits, settings, referenceCenter)
%JOYSTICKRESTCENTER Estimate zero while the participant holds the start zone.
% The reference is fixed throughout each return; the hardware-zero guard
% prevents successive accepted offsets drifting toward the travel limits.
if nargin < 5, referenceCenter = [0 0]; end
center = [NaN NaN];
normalizedRange = [NaN NaN];
stable = false;
inStartZone = false;
if isempty(rawSamples) || any(~isfinite(rawSamples(:)))
    return
end
normalized = ADAPT.NormalizeJoystickAxes(rawSamples,referenceCenter,limits);
hardwarePosition = ADAPT.NormalizeJoystickAxes(rawSamples,[0 0],limits);
inside = hypot(normalized(:,1),normalized(:,2)) <= settings.ReturnRadius & ...
    hypot(hardwarePosition(:,1),hardwarePosition(:,2)) <= settings.MaxCenterRadius;
inStartZone = inside(end);
if size(rawSamples,1) < settings.MinSamples || ...
        times(end)-times(1) < settings.StableDuration || ~all(inside)
    return
end
normalizedRange = max(normalized,[],1)-min(normalized,[],1);
if any(normalizedRange > settings.StabilityTolerance)
    return
end
center = median(rawSamples,1);
stable = true;
end
