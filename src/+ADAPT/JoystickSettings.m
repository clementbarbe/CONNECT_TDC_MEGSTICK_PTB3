function settings = JoystickSettings()
%JOYSTICKSETTINGS Shared defaults for the launch menu and the task.
settings.Conversion = 'Exponential'; % 'Exponential' or 'Linear'
settings.Gains = [0.75 0.70 0.65 0.60]; % largest to smallest
settings.GainIndex = 4;                % default: x0.60
settings.ExponentialCoefficient = 6;
settings.ExponentialRangeRatio = 1; % output reference: window height, before gain
settings.LinearGain = 1;
settings.LinearRangeRatio = 0.5; % legacy linear scale; adjustable by the curve tool
settings.DefaultCalibration = [-29376 -31482 27242 30784];
settings.DeadZone = 0.02;           % fraction of calibrated travel
settings.Rest.ReturnRadius = 0.15; % tolerated distance from the preceding starting point
settings.Rest.StableDuration = 0.3; % seconds held near the starting point
settings.Rest.MinSamples = 5;
settings.Rest.StabilityTolerance = 0.02; % peak-to-peak, per axis; small hand tremor allowed
settings.Rest.MaxCenterRadius = 0.25; % absolute guard against accumulated zero drift
end
