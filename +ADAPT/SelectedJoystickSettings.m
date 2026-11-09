function settings = SelectedJoystickSettings(handles)
%SELECTEDJOYSTICKSETTINGS Resolve the menu choice or the applied curve profile.
settings = ADAPT.JoystickSettings();
index = get(handles.popup_JoystickConversion,'Value');
if isfield(handles,'JoystickProfile') && index == numel(settings.Gains)+2
    settings = handles.JoystickProfile;
elseif index <= numel(settings.Gains)
    settings.Conversion = 'Exponential';
    settings.GainIndex = index;
else
    settings.Conversion = 'Linear';
end
end
