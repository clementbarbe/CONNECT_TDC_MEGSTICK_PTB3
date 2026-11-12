function test_joystick_serial_workflow(portName,controlFile)
%TEST_JOYSTICK_SERIAL_WORKFLOW Menu, calibration and TTL on the PJS emulator.
% Requires a MATLAB display. Only use the port created by pjs_serial_emulator.py.
setup_AMEDYST();
global S AMEDYST_PJS_TTL_TEST
previousS = S;
previousPath = path;
folder = tempname;
mkdir(folder);
cleanup = onCleanup(@() finish(previousS,previousPath,folder,controlFile));
handles = AMEDYST_GUI;
set(handles.uipanel_CursorInput,'SelectedObject',handles.radiobutton_Joystick);
ADAPT.JoystickInputCallback('select',handles.uipanel_CursorInput,[]);
usbCalibration = get(handles.edit_xmin_ymin_xmax_ymax,'String');
set(handles.popup_JoystickTransport,'Value',2);
invoke(handles.popup_JoystickTransport);
set(handles.edit_JoystickSerialPort,'String',portName);
writeControl(controlFile,struct('x',0,'y',0,'trigger',false));
pause(0.03);
invoke(handles.pushbutton_TestJoystick);
assert(contains(get(handles.text_JoystickStatus,'String'),'SerialPJS OK'));
assert(~ADAPT.JoystickDevice('status').Open);

% Explore both signs of both axes, then validate using the figure's Escape
% handler. This exercises the actual calibration loop and native serialport.
steps = timer('ExecutionMode','fixedSpacing','Period',0.25,'StartDelay',0.1, ...
    'UserData',0,'TimerFcn',@(timer,~) calibrationStep(timer,controlFile,false));
timerCleanup = onCleanup(@() deleteTimer(steps));
start(steps);
limits = joystick_calibration(handles.pushbutton_JoystickCalibration,[]);
clear timerCleanup
assert(isequal(limits,[-900 -800 900 800]*32));
assert(~ADAPT.JoystickDevice('status').Open);
handles = guidata(handles.AMEDYST_GUI);
assert(strcmp(handles.JoystickCalibrations.USBHID,usbCalibration));
assert(isequal(sscanf(get(handles.edit_xmin_ymin_xmax_ymax,'String'),'%f')',limits));
assert(strcmp(get(handles.pushbutton_MEG_Task1,'Enable'),'on'));

% The real reported failure: both inverted ADC axes stay negative, with a
% nonzero rest in the middle of their range. Calibration must cover all four
% normalized quadrants and the task must subtract exactly that measured rest.
set(handles.checkbox_JoystickInvertX,'Value',1);
invoke(handles.checkbox_JoystickInvertX);
writeControl(controlFile,struct('x',450,'y',500));
pause(0.03);
steps = timer('ExecutionMode','fixedSpacing','Period',0.25,'StartDelay',0.1, ...
    'UserData',0,'TimerFcn',@(timer,~) calibrationStep(timer,controlFile,false,true));
timerCleanup = onCleanup(@() deleteTimer(steps));
start(steps);
limits = joystick_calibration(handles.pushbutton_JoystickCalibration,[]);
clear timerCleanup
assert(isequal(limits,[-450 -500 450 500]*32));
handles = guidata(handles.AMEDYST_GUI);
config = ADAPT.JoystickConnectionSettings(handles);
assert(isequal(config.RawCenter,[-450 -500]*32));
assert(strcmp(handles.JoystickCalibrations.USBHID,usbCalibration));
writeControl(controlFile,struct('x',450,'y',500));
pause(0.03);
ADAPT.JoystickDevice('open',config);
S = struct('JoystickConnection',config);
assert(isequal(ADAPT.ReadJoystickAxes(),[0 0]));
points = [0 0; 900 1000; 0 1000; 900 0];
expected = [1 1; -1 -1; 1 -1; -1 1];
for index = 1:size(points,1)
    writeControl(controlFile,struct('x',points(index,1),'y',points(index,2)));
    pause(0.03);
    normalized = ADAPT.NormalizeJoystickAxes(ADAPT.ReadJoystickAxes(),[0 0],limits);
    assert(isequal(normalized,expected(index,:)));
end
ADAPT.JoystickDevice('close');
% Orientation changes must transform the measured center as well as limits.
set(handles.checkbox_JoystickInvertX,'Value',0);
invoke(handles.checkbox_JoystickInvertX);
assert(isequal(ADAPT.JoystickConnectionSettings(guidata(handles.AMEDYST_GUI)).RawCenter,[450 -500]*32));
set(handles.checkbox_JoystickInvertX,'Value',1);
invoke(handles.checkbox_JoystickInvertX);

% Closing a second calibration cancels without overwriting the first one.
steps = timer('ExecutionMode','fixedSpacing','Period',0.25,'StartDelay',0.1, ...
    'UserData',0,'TimerFcn',@(timer,~) calibrationStep(timer,controlFile,true));
timerCleanup = onCleanup(@() deleteTimer(steps));
start(steps);
assert(isempty(joystick_calibration(handles.pushbutton_JoystickCalibration,[])));
clear timerCleanup
assert(isequal(sscanf(get(handles.edit_xmin_ymin_xmax_ymax,'String'),'%f')',limits));
assert(~ADAPT.JoystickDevice('status').Open);
assert(strcmp(get(handles.edit_JoystickSerialPort,'Enable'),'on'));
close(handles.AMEDYST_GUI);

% No physical keyboard or scanner is involved. KbCheck only changes the
% emitter's flag after WaitForTTL has armed; the real serial reader must see
% the resulting edge. An already high flag before waiting must be ignored.
file = fopen(fullfile(folder,'KbCheck.m'),'w');
fprintf(file,'%s\n', ...
    'function [down,secs,codes]=KbCheck(varargin)', ...
    'global AMEDYST_PJS_TTL_TEST', ...
    'secs=GetSecs; down=false; codes=zeros(1,256);', ...
    'elapsed=secs-AMEDYST_PJS_TTL_TEST.Begin;', ...
    'if elapsed>3, error(''AMEDYST:TestTTLTimeout'',''Serial TTL was not detected.''); end', ...
    'stage=AMEDYST_PJS_TTL_TEST.Stage;', ...
    'if (stage==0 && elapsed>0.25) || (stage==1 && elapsed>0.4)', ...
    '  f=fopen(AMEDYST_PJS_TTL_TEST.Control,''w'');', ...
    '  fprintf(f,''%s'',jsonencode(struct(''trigger'',stage==1))); fclose(f);', ...
    '  AMEDYST_PJS_TTL_TEST.Stage=stage+1;', ...
    'end', ...
    'end');
fclose(file);
addpath(folder,'-begin');
clear KbCheck
config = ADAPT.JoystickConnectionSettings('SerialPJS');
config.Port = portName;
writeControl(controlFile,struct('trigger',true));
pause(0.03);
ADAPT.JoystickDevice('open',config);
S = struct('OperationMode','Acquisition','InputMethod','Joystick', ...
    'Environement','MRI','JoystickConnection',config);
S.Parameters.Keybinds = struct('TTL_t_ASCII',3,'Stop_Escape_ASCII',27);
AMEDYST_PJS_TTL_TEST = struct('Begin',GetSecs,'Stage',0,'Control',controlFile);
triggerTime = WaitForTTL();
assert(triggerTime>=AMEDYST_PJS_TTL_TEST.Begin+0.4);
assert(AMEDYST_PJS_TTL_TEST.Stage==2);
report = ADAPT.JoystickDevice('status');
assert(report.TriggerTimes(end)==triggerTime);
disp('All native serial menu, calibration and TTL assertions passed.');
end

function calibrationStep(timer,controlFile,cancel,unipolar)
if nargin<4, unipolar = false; end
fig = findall(0,'Tag','AMEDYST_JoystickCalibration');
if isempty(fig) || ~isappdata(fig,'CalibrationReady'), return; end
step = get(timer,'UserData')+1;
set(timer,'UserData',step);
if cancel
    close(fig);
    stop(timer);
elseif step<=5
    if step==1
        keypress = get(fig,'KeyPressFcn');
        keypress(fig,struct('Key','space'));
    end
elseif step<=17
    if unipolar, points = [0 0; 900 1000; 0 1000; 900 0];
    else, points = [-900 -800; 900 800; -900 800; 900 -800]; end
    point = points(mod(step-6,size(points,1))+1,:);
    writeControl(controlFile,struct('x',point(1),'y',point(2)));
else
    keypress = get(fig,'KeyPressFcn');
    keypress(fig,struct('Key','escape'));
    stop(timer);
end
end

function invoke(control)
callback = get(control,'Callback');
callback(control,[]);
end

function writeControl(file,value)
handle = fopen(file,'w');
cleanup = onCleanup(@() fclose(handle));
fprintf(handle,'%s',jsonencode(value));
end

function deleteTimer(timer)
if isvalid(timer), stop(timer); delete(timer); end
end

function finish(previousS,previousPath,folder,controlFile)
global S AMEDYST_PJS_TTL_TEST
ADAPT.JoystickDevice('close');
fig = findall(0,'Tag','AMEDYST_GUI');
if ~isempty(fig), delete(fig); end
fig = findall(0,'Tag','AMEDYST_JoystickCalibration');
if ~isempty(fig), delete(fig); end
writeControl(controlFile,struct('x',321,'y',-123,'trigger',false));
path(previousPath);
clear KbCheck
rmdir(folder,'s');
S = previousS;
AMEDYST_PJS_TTL_TEST = [];
end
