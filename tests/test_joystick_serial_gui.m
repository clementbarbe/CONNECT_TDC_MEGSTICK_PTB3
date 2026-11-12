function test_joystick_serial_gui()
%TEST_JOYSTICK_SERIAL_GUI No port opened: already attached ports are enumerated.
setup_AMEDYST();
folder = tempname;
mkdir(folder);
file = fopen(fullfile(folder,'serialportlist.m'),'w');
fprintf(file,'function ports=serialportlist(varargin)\nports=["COM7" "COM12"];\nend\n');
fclose(file);
previous = path;
cleanup = onCleanup(@() restore(previous,folder));
addpath(folder,'-begin');
clear serialportlist
handles = AMEDYST_GUI;
ports = get(handles.popup_JoystickSerialPort,'String');
assert(isequal(ports,{'COM7';'COM12'}));
assert(strcmp(get(handles.edit_JoystickSerialPort,'String'),'COM7'));
assert(strcmp(get(handles.popup_JoystickTransport,'Enable'),'off'));
set(handles.uipanel_CursorInput,'SelectedObject',handles.radiobutton_Joystick);
ADAPT.JoystickInputCallback('select',handles.uipanel_CursorInput,[]);
usbCalibration = get(handles.edit_xmin_ymin_xmax_ymax,'String');
set(handles.popup_JoystickTransport,'Value',2);
invoke(handles.popup_JoystickTransport);
handles = guidata(handles.AMEDYST_GUI);
config = ADAPT.JoystickConnectionSettings(handles);
assert(strcmp(config.Transport,'SerialPJS') && strcmp(config.Port,'COM7') && config.BaudRate==57600);
assert(strcmp(get(handles.edit_JoystickSerialPort,'Enable'),'on'));
assert(strcmp(get(handles.edit_xmin_ymin_xmax_ymax,'String'),num2str(config.DefaultCalibration)));
assert(~ADAPT.JoystickDevice('status').Open); % selecting is not connecting
set(handles.popup_JoystickSerialPort,'Value',2);
invoke(handles.popup_JoystickSerialPort);
config = ADAPT.JoystickConnectionSettings(guidata(handles.AMEDYST_GUI));
assert(strcmp(config.Port,'COM12'));
set(handles.edit_JoystickSerialPort,'String','COM31');
invoke(handles.pushbutton_JoystickRefreshPorts);
assert(strcmp(get(handles.edit_JoystickSerialPort,'String'),'COM31')); % manual path survives refresh
set(handles.checkbox_JoystickInvertX,'Value',1);
invoke(handles.checkbox_JoystickInvertX);
limits = sscanf(get(handles.edit_xmin_ymin_xmax_ymax,'String'),'%f')';
assert(isequal(limits,[-32736 -32736 32768 32768]));
set(handles.popup_JoystickTransport,'Value',1);
invoke(handles.popup_JoystickTransport);
assert(strcmp(get(handles.edit_xmin_ymin_xmax_ymax,'String'),usbCalibration));
assert(strcmp(get(handles.edit_JoystickSerialPort,'Enable'),'off'));
set(handles.popup_JoystickTransport,'Value',2);
invoke(handles.popup_JoystickTransport);
assert(isequal(sscanf(get(handles.edit_xmin_ymin_xmax_ymax,'String'),'%f')',limits));

lock = ADAPT.LockJoystickGUI(handles.AMEDYST_GUI);
assert(strcmp(get(handles.pushbutton_MEG_Task1,'Enable'),'off'));
clear lock
assert(strcmp(get(handles.pushbutton_MEG_Task1,'Enable'),'on'));
assert(strcmp(get(handles.edit_JoystickSerialPort,'Enable'),'on'));
close(handles.AMEDYST_GUI);
disp('All serial joystick menu assertions passed.');
end

function invoke(control)
callback = get(control,'Callback');
callback(control,[]);
end

function restore(previous,folder)
fig = findall(0,'Tag','AMEDYST_GUI');
if ~isempty(fig), close(fig); end
path(previous);
clear serialportlist
rmdir(folder,'s');
end
