function JoystickInputCallback(action, source, event) %#ok<INUSD>
%JOYSTICKINPUTCALLBACK GUI settings only; devices open on test/calibration/run.
fig = ancestor(source,'figure');
handles = guidata(fig);
switch action
    case 'refresh'
        ports = ADAPT.ListJoystickSerialPorts();
        current = strtrim(get(handles.edit_JoystickSerialPort,'String'));
        if isempty(ports)
            set(handles.popup_JoystickSerialPort,'String',{'Aucun port detecte'},'Value',1);
        else
            selected = find(strcmp(ports,current),1);
            if isempty(selected), selected = 1; end
            set(handles.popup_JoystickSerialPort,'String',ports,'Value',selected);
            if isempty(current), set(handles.edit_JoystickSerialPort,'String',ports{selected}); end
        end
    case 'port'
        ports = get(handles.popup_JoystickSerialPort,'String');
        selected = ports{get(handles.popup_JoystickSerialPort,'Value')};
        if ~strcmp(selected,'Aucun port detecte')
            set(handles.edit_JoystickSerialPort,'String',selected);
        end
    case 'transport'
        old = handles.ActiveJoystickTransport;
        handles.JoystickCalibrations.(old) = get(handles.edit_xmin_ymin_xmax_ymax,'String');
        config = ADAPT.JoystickConnectionSettings(handles);
        handles.ActiveJoystickTransport = config.Transport;
        set(handles.edit_xmin_ymin_xmax_ymax,'String',handles.JoystickCalibrations.(config.Transport));
        ADAPT.JoystickDevice('close');
    case 'invert'
        config = ADAPT.JoystickConnectionSettings(handles);
        changed = [config.InvertX config.InvertY] ~= handles.SerialAxisInversion;
        if isfield(handles,'JoystickCalibrationCenters') && ...
                isfield(handles.JoystickCalibrationCenters,'SerialPJS')
            center = handles.JoystickCalibrationCenters.SerialPJS;
            center(changed) = -center(changed);
            handles.JoystickCalibrationCenters.SerialPJS = center;
        end
        limits = sscanf(get(handles.edit_xmin_ymin_xmax_ymax,'String'),'%f')';
        if numel(limits)==4
            for axis = find(changed)
                limits([axis axis+2]) = -limits([axis+2 axis]);
            end
            set(handles.edit_xmin_ymin_xmax_ymax,'String',num2str(limits));
        end
        handles.SerialAxisInversion = [config.InvertX config.InvertY];
    case 'test'
        set(handles.text_JoystickStatus,'String','Connexion et verification du flux...','ForegroundColor',[0 0 0]);
        drawnow;
        cleanup = ADAPT.LockJoystickGUI(fig); %#ok<NASGU> releases the GUI on exit
        deviceCleanup = onCleanup(@() ADAPT.JoystickDevice('close'));
        try
            config = ADAPT.JoystickConnectionSettings(handles);
            ADAPT.JoystickDevice('open',config);
            timer = tic;
            while toc(timer)<0.5
                [axes,report] = ADAPT.JoystickDevice('read');
                pause(0.005);
            end
            message = sprintf('%s OK : X=%d Y=%d, %d positions.', ...
                config.Transport,axes(1),axes(2),report.SamplesReceived);
            color = [0 0.45 0.15];
        catch err
            message = err.message;
            color = [0.7 0.1 0.1];
        end
        clear deviceCleanup cleanup
        if ishghandle(fig)
            set(handles.text_JoystickStatus,'String',message,'TooltipString',message,'ForegroundColor',color);
        end
        return
end
selected = get(handles.uipanel_CursorInput,'SelectedObject');
isJoystick = ~isempty(selected) && strcmp(get(selected,'Tag'),'radiobutton_Joystick');
isSerial = get(handles.popup_JoystickTransport,'Value')==2;
set([handles.popup_JoystickTransport handles.pushbutton_JoystickCalibration ...
    handles.edit_xmin_ymin_xmax_ymax handles.popup_JoystickConversion ...
    handles.pushbutton_TestJoystick],'Enable',enabled(isJoystick));
set([handles.popup_JoystickSerialPort handles.pushbutton_JoystickRefreshPorts ...
    handles.edit_JoystickSerialPort handles.popup_JoystickBaud ...
    handles.checkbox_JoystickInvertX handles.checkbox_JoystickInvertY], ...
    'Enable',enabled(isJoystick && isSerial));
if isSerial
    message = 'PJS 651 : choisissez le port, puis Tester et Calibration.';
else
    message = 'USB HID JOY : branchez le joystick, puis Calibration.';
end
set(handles.text_JoystickStatus,'String',message,'TooltipString',message,'ForegroundColor',[0 0 0]);
guidata(fig,handles);
end

function result = enabled(value)
if value, result = 'on'; else, result = 'off'; end
end
