function handles = PrepareJoystickInputGUI(handles)
%PREPAREJOYSTICKINPUTGUI Add transport/port controls without opening devices.
panel = handles.uipanel_CursorInput;
fig = ancestor(panel,'figure');
position = get(fig,'Position');
position(3:4) = [850 850];
set(fig,'Position',position);
color = get(panel,'BackgroundColor');
set(panel,'Position',[0.04 0.44 0.59 0.52],'Title','Entree du curseur', ...
    'SelectionChangeFcn',@(source,event) ADAPT.JoystickInputCallback('select',source,event));
set(handles.radiobutton_Joystick,'Position',[0.03 0.79 0.27 0.18], ...
    'ButtonDownFcn',[],'TooltipString','Joystick USB HID ou serie PJS');
set(handles.radiobutton_Mouse,'Position',[0.32 0.79 0.24 0.18]);
set(handles.pushbutton_JoystickCalibration,'Position',[0.60 0.79 0.37 0.18], ...
    'String','Calibration','Visible','on','Enable','off');
set(handles.edit_xmin_ymin_xmax_ymax,'Position',[0.03 0.15 0.65 0.17], ...
    'Visible','on','Enable','off','FontSize',8);
handles.popup_JoystickTransport = control('popupmenu',[0.03 0.57 0.40 0.17], ...
    {'USB HID JOY','Serie PJS / 651'},'transport');
handles.popup_JoystickSerialPort = control('popupmenu',[0.46 0.57 0.37 0.17], ...
    {'Aucun port detecte'},'port');
handles.pushbutton_JoystickRefreshPorts = control('pushbutton',[0.85 0.57 0.12 0.17], ...
    'MAJ','refresh');
handles.edit_JoystickSerialPort = control('edit',[0.03 0.36 0.40 0.17], ...
    '','portedit');
set(handles.edit_JoystickSerialPort,'TooltipString','Port detecte ou saisi manuellement : COM3, /dev/ttyUSB0, /dev/cu...');
handles.popup_JoystickBaud = control('popupmenu',[0.46 0.36 0.22 0.17], ...
    {'57600','115200','38400','19200','9600'},'settings');
set(handles.popup_JoystickBaud,'TooltipString','Debit serie PJS, 8 bits, sans parite, 1 stop, sans controle de flux');
handles.pushbutton_TestJoystick = control('pushbutton',[0.71 0.36 0.26 0.17],'Tester','test');
handles.checkbox_JoystickInvertX = control('checkbox',[0.70 0.15 0.13 0.17],'Inv.X','invert');
handles.checkbox_JoystickInvertY = control('checkbox',[0.84 0.15 0.13 0.17],'Inv.Y','invert');
set(handles.checkbox_JoystickInvertY,'Value',1);
handles.text_JoystickStatus = uicontrol(panel,'Style','text','Units','normalized', ...
    'Position',[0.03 0.00 0.94 0.12],'BackgroundColor',color, ...
    'HorizontalAlignment','left','FontSize',8,'String','Selectionnez Joystick, puis USB HID ou Serie PJS.');
handles.ActiveJoystickTransport = 'USBHID';
handles.JoystickCalibrationCenters = struct('USBHID',[0 0],'SerialPJS',[0 0]);
handles.SerialAxisInversion = [false true];
handles.JoystickCalibrations.USBHID = get(handles.edit_xmin_ymin_xmax_ymax,'String');
serialDefaults = ADAPT.JoystickConnectionSettings('SerialPJS');
handles.JoystickCalibrations.SerialPJS = num2str(serialDefaults.DefaultCalibration);

    function item = control(style,position,content,action)
        item = uicontrol(panel,'Style',style,'Units','normalized','Position',position, ...
            'String',content,'BackgroundColor',color,'FontSize',8,'Enable','off', ...
            'Callback',@(source,event) ADAPT.JoystickInputCallback(action,source,event));
        if strcmp(style,'edit'), set(item,'BackgroundColor','white'); end
    end
end
