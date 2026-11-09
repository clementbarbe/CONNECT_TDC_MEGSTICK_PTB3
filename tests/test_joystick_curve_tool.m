function test_joystick_curve_tool(previewPath)
%TEST_JOYSTICK_CURVE_TOOL Real MATLAB graphics, simulated launcher, no PTB.
if nargin < 1, previewPath = ''; end
launcher = figure('Visible','off','Name','Curve test launcher');
cleanup = onCleanup(@() closeWindows(launcher));
owner.popup_JoystickConversion = uicontrol(launcher,'Style','popupmenu', ...
    'String',{'Exp1','Exp2','Exp3','Exp4','Linear'},'Value',4);
owner.edit_xmin_ymin_xmax_ymax = uicontrol(launcher,'Style','edit', ...
    'String','-29376 -31482 27242 30784');
guidata(launcher,owner);
fig = ADAPT.JoystickCurveTool(launcher);
controls = getappdata(fig,'CurveHandles');
data = getappdata(fig,'CurveData');
assert(isequal(data.Coefficients,[0 1 2 4 6 8]));
assert(strcmp(get(controls.Apply,'Enable'),'on'));

set(controls.Axis,'Value',2);
invoke(controls.Axis);
data = getappdata(fig,'CurveData');
assert(data.Raw(1)==-31482 && data.Raw(end)==30784);

% Apply a linear profile with the SAME maximum excursion as the plotted
% exponential family, rather than silently reverting to the legacy scale.
set(controls.Coefficient,'String','0');
set(controls.Gain,'String','0.55');
set(controls.DeadZone,'String','4');
invoke(controls.Coefficient);
invoke(controls.Apply);
owner = guidata(launcher);
profile = ADAPT.SelectedJoystickSettings(owner);
assert(strcmp(profile.Conversion,'Linear'));
assert(profile.LinearGain==0.55 && profile.LinearRangeRatio==1 && profile.DeadZone==0.04);
assert(get(owner.popup_JoystickConversion,'Value')==6);
data = getappdata(fig,'CurveData');
raw = zeros(numel(data.Raw),2);
raw(:,2) = data.Raw;
[~,actual] = ADAPT.JoystickPosition(raw,[0 0],data.Limits,100,profile);
assert(max(abs(actual-data.Response(:,1)))<1e-10);

% Applying an exponential also reaches acquisition through the shared menu
% resolver; choosing a preset again restores the original preset settings.
set(controls.Coefficient,'String','4');
set(controls.Gain,'String','0.65');
invoke(controls.Apply);
owner = guidata(launcher);
profile = ADAPT.SelectedJoystickSettings(owner);
assert(strcmp(profile.Conversion,'Exponential') && profile.ExponentialCoefficient==4);
assert(profile.Gains==0.65);
set(owner.popup_JoystickConversion,'Value',5);
legacy = ADAPT.SelectedJoystickSettings(owner);
assert(strcmp(legacy.Conversion,'Linear') && legacy.LinearGain==1 && legacy.LinearRangeRatio==0.5);
set(owner.popup_JoystickConversion,'Value',6);

% Invalid input cannot apply stale settings, and insufficient excursion is
% visible in the plot but cannot be applied to an unreachable trial.
set(controls.Calibration,'String','0 -1 1 1');
invoke(controls.Calibration);
assert(strcmp(get(controls.Apply,'Enable'),'off'));
invoke(controls.Apply);
owner = guidata(launcher);
assert(owner.JoystickProfile.ExponentialCoefficient==4);
set(controls.Calibration,'String','-29376 -31482 27242 30784');
set(controls.Gain,'String','0.1');
invoke(controls.Gain);
assert(strcmp(get(controls.Apply,'Enable'),'off'));

set(controls.Gain,'String','0.6');
set(controls.DeadZone,'String','2');
set(controls.Coefficient,'String','6');
invoke(controls.Coefficient);
if ~isempty(previewPath)
    drawnow;
    frame = getframe(fig);
    imwrite(frame.cdata,previewPath);
end
assert(ADAPT.JoystickCurveTool(launcher)==fig); % reuse the comparison window
clear cleanup
disp('All joystick curve tool graphics assertions passed.');
end

function invoke(control)
callback = get(control,'Callback');
callback(control,[]);
end

function closeWindows(launcher)
tool = findall(0,'Type','figure','Tag','AMEDYST_JoystickCurves');
if ~isempty(tool), close(tool); end
if ishghandle(launcher), close(launcher); end
end
