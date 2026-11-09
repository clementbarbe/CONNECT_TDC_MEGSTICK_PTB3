function test_joystick()
%TEST_JOYSTICK Numerical regression checks; no PTB or joystick required.
setup_AMEDYST();
settings = ADAPT.JoystickSettings();
limits = [-30000 -28000 32000 31000];
center = [1300 -700];
height = 1000;

% A displaced resting point becomes zero; both endpoint spans stay intact.
p = ADAPT.NormalizeJoystickAxes([center; limits(1:2); limits(3:4)],center,limits);
assert(isequal(p,[0 0; -1 -1; 1 1]));
[x,y] = ADAPT.JoystickPosition(center,center,limits,height,settings);
assert(x==0 && y==0);
[x,y] = ADAPT.JoystickPosition(center+[100 -100],center,limits,height,settings);
assert(x==0 && y==0); % small rest jitter inside the dead zone

% Every gain is monotonic, odd, directional, and can reach the target ring.
assert(all(diff(settings.Gains)<0));
for gainIndex = 1:numel(settings.Gains)
    settings.GainIndex = gainIndex;
    previousRadius = -1;
    for fraction = linspace(0,1,101)
        raw = center + [fraction*(limits(3)-center(1)),0];
        [x,y] = ADAPT.JoystickPosition(raw,center,limits,height,settings);
        assert(x>=previousRadius && y==0);
        previousRadius = x;
        negativeRaw = center - [fraction*(center(1)-limits(1)),0];
        [negativeX,~] = ADAPT.JoystickPosition(negativeRaw,center,limits,height,settings);
        assert(abs(x+negativeX)<1e-9);
    end
    assert(abs(x-settings.Gains(gainIndex)*settings.ExponentialRangeRatio*height)<1e-9);
    assert(x >= 0.4*height); % ring at 80% of the screen height
    [x,y] = ADAPT.JoystickPosition(center+[0.3*(limits(3)-center(1)), ...
        0.4*(limits(4)-center(2))],center,limits,height,settings);
    assert(abs(y/x-4/3)<1e-10); % no distortion of the target angle
end

% The exponential curve suppresses near-center movements. Its incremental
% gain increases toward full travel; all four gains remain ordered.
radii = zeros(4,3);
for gainIndex = 1:4
    settings.GainIndex = gainIndex;
    fractions = [0.2 0.3 0.9 1];
    values = zeros(1,4);
    for index = 1:4
        raw = center + [fractions(index)*(limits(3)-center(1)),0];
        [values(index),~] = ADAPT.JoystickPosition(raw,center,limits,height,settings);
    end
    assert(values(4)-values(3) > values(2)-values(1));
    radii(gainIndex,:) = values(1:3);
end
assert(all(all(diff(radii,1,1)<0)));
settings.GainIndex = 4;
raw = center+[0.5*(limits(3)-center(1)),0];
[exponentialX,~] = ADAPT.JoystickPosition(raw,center,limits,height,settings);
settings.Conversion = 'Linear';
[linearX,~] = ADAPT.JoystickPosition(raw,center,limits,height,settings);
assert(exponentialX<linearX);
assert(abs(linearX-(0.5-settings.DeadZone)/(1-settings.DeadZone)*height/2)<1e-9);

% The new k6/x0.60 default is gentler near/mid center than the former
% k3/x0.80 profile, while the endpoint test above keeps the ring reachable.
settings.Conversion = 'Exponential';
previousSettings = settings;
previousSettings.ExponentialCoefficient = 3;
previousSettings.Gains = 0.80;
previousSettings.GainIndex = 1;
previousSettings.ExponentialRangeRatio = 0.5;
for fraction = [0.25 0.50 0.75]
    raw = center+[fraction*(limits(3)-center(1)),0];
    [newPosition,~] = ADAPT.JoystickPosition(raw,center,limits,height,settings);
    [previousPosition,~] = ADAPT.JoystickPosition(raw,center,limits,height,previousSettings);
    assert(newPosition<previousPosition);
end

% A held hand position in the start zone yields its median, rejecting
% single-sample capture, insufficient duration, and an unstable return.
times = (0:0.01:0.31)';
samples = repmat(center,numel(times),1);
samples(1,:) = center+[30 -30];
[estimated,stable] = ADAPT.JoystickRestCenter(samples,times,limits,settings.Rest);
assert(stable && isequal(estimated,center));
[~,stable] = ADAPT.JoystickRestCenter(samples(1,:),times(1),limits,settings.Rest);
assert(~stable);
[~,stable] = ADAPT.JoystickRestCenter(samples(1:10,:),times(1:10),limits,settings.Rest);
assert(~stable);
[~,stable] = ADAPT.JoystickRestCenter(repmat([24000 0],numel(times),1),times,limits,settings.Rest);
assert(~stable);
samples(1,1) = samples(1,1)+2000;
[~,stable] = ADAPT.JoystickRestCenter(samples,times,limits,settings.Rest);
assert(~stable);

% The tolerated return follows the preceding starting point. A held
% position may be off hardware zero, but repeated corrections cannot drift
% outside the absolute central guard.
heldSamples = repmat([5000 -700],numel(times),1);
[estimated,stable] = ADAPT.JoystickRestCenter(heldSamples,times,limits,settings.Rest,[4000 -700]);
assert(stable && isequal(estimated,[5000 -700]));
[~,stable,~,inStartZone] = ADAPT.JoystickRestCenter(heldSamples,times,limits,settings.Rest,[0 0]);
assert(~stable && ~inStartZone);
[~,stable,~,inStartZone] = ADAPT.JoystickRestCenter( ...
    repmat([9000 0],numel(times),1),times,limits,settings.Rest,[7000 0]);
assert(~stable && ~inStartZone);

% Invalid calibration fails before division by zero or the acquisition.
for badLimits = {[],[0 -1 1 1],[-1 -1 0 1],[-1 NaN 1 1]}
    caught = false;
    try
        ADAPT.NormalizeJoystickAxes([0 0],[0 0],badLimits{1});
    catch err
        caught = strcmp(err.identifier,'AMEDYST:JoystickCalibration');
    end
    assert(caught);
end
disp('All joystick numerical assertions passed.');
end
