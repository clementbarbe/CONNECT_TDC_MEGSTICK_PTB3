function config = JoystickConnectionSettings(handles)
%JOYSTICKCONNECTIONSETTINGS Hardware transport, independent of response curves.
config = struct('Transport','USBHID','Port','','BaudRate',57600, ...
    'ConnectTimeout',3,'StaleTimeout',0.5,'MinSyncFrames',8, ...
    'Scale',32,'InvertX',false,'InvertY',true,'RawCenter',[0 0]);
if nargin>0 && ischar(handles)
    config.Transport = handles;
elseif nargin>0 && isfield(handles,'popup_JoystickTransport')
    if get(handles.popup_JoystickTransport,'Value')==2
        config.Transport = 'SerialPJS';
    end
    config.Port = strtrim(get(handles.edit_JoystickSerialPort,'String'));
    rates = get(handles.popup_JoystickBaud,'String');
    config.BaudRate = str2double(rates{get(handles.popup_JoystickBaud,'Value')});
    config.InvertX = logical(get(handles.checkbox_JoystickInvertX,'Value'));
    config.InvertY = logical(get(handles.checkbox_JoystickInvertY,'Value'));
    if isfield(handles,'JoystickCalibrationCenters') && ...
            isfield(handles.JoystickCalibrationCenters,config.Transport)
        config.RawCenter = handles.JoystickCalibrationCenters.(config.Transport);
    end
end
if strcmp(config.Transport,'SerialPJS')
    limits = [-1024 -1024 1023 1023]*config.Scale;
    if config.InvertX, limits([1 3]) = -limits([3 1]); end
    if config.InvertY, limits([2 4]) = -limits([4 2]); end
    config.DefaultCalibration = limits;
else
    defaults = ADAPT.JoystickSettings();
    config.DefaultCalibration = defaults.DefaultCalibration;
end
end
