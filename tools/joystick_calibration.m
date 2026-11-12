function xmin_ymin_xmax_ymax = joystick_calibration(hObject,~)
%JOYSTICK_CALIBRATION Calibrate the selected USB HID or serial PJS transport.
xmin_ymin_xmax_ymax = [];
owner = [];
if nargin>0 && ishghandle(hObject)
    owner = ancestor(hObject,'figure');
    handles = guidata(owner);
    config = ADAPT.JoystickConnectionSettings(handles);
    guiCleanup = ADAPT.LockJoystickGUI(owner); %#ok<NASGU> releases the GUI on exit
else
    config = ADAPT.JoystickConnectionSettings();
end
deviceCleanup = onCleanup(@() ADAPT.JoystickDevice('close'));
% Measure the actual ADC origin, even when an older calibration exists.
config.RawCenter = [0 0];
ADAPT.JoystickDevice('open',config);
f = figure('Name',sprintf('Joystick %s : mesurer le repos puis la course',config.Transport), ...
    'NumberTitle','off','Tag','AMEDYST_JoystickCalibration','KeyPressFcn',@keyPressed, ...
    'CloseRequestFcn',@cancelCalibration);
figureCleanup = onCleanup(@() deleteIfValid(f));
setappdata(f,'Finished',false);
setappdata(f,'Cancelled',false);
setappdata(f,'CaptureCenter',false);
centerButton = uicontrol(f,'Style','pushbutton','Units','normalized', ...
    'Position',[0.15 0.01 0.70 0.07], ...
    'String','1. Manette au repos : mesurer le centre (Espace)', ...
    'Callback',@(~,~) setappdata(f,'CaptureCenter',true));
rawAxes = subplot(1,2,1,'Parent',f);
set(rawAxes,'Position',[0.10 0.24 0.36 0.62]);
hold(rawAxes,'on');
axis(rawAxes,'equal');
axis(rawAxes,[-32768 32768 -32768 32768]);
rectangle(rawAxes,'Position',[-32768 -32768 65536 65536],'LineWidth',2);
rawTrace = plot(rawAxes,NaN,NaN,'.','Color',[0.6 0.6 0.6]);
rawPointer = plot(rawAxes,0,0,'rx','MarkerSize',10,'LineWidth',2);
centerPointer = plot(rawAxes,NaN,NaN,'g+','MarkerSize',12,'LineWidth',2);
xlabel(rawAxes,'X : droite positive');
ylabel(rawAxes,'Y : haut positif');
title(rawAxes,'Coordonnees brutes');
normalizedAxes = subplot(1,2,2,'Parent',f);
set(normalizedAxes,'Position',[0.59 0.24 0.36 0.62]);
hold(normalizedAxes,'on');
axis(normalizedAxes,'equal');
axis(normalizedAxes,[-1.1 1.1 -1.1 1.1]);
rectangle(normalizedAxes,'Position',[-1 -1 2 2],'LineWidth',2);
calPointer = plot(normalizedAxes,0,0,'rx','MarkerSize',10,'LineWidth',2);
plot(normalizedAxes,0,0,'g+','MarkerSize',12,'LineWidth',2);
title(normalizedAxes,'Mesurez d''abord le centre au repos');
xlabel(normalizedAxes,'Echap : valider. Fermer : annuler.');
minimum = [Inf Inf];
maximum = [-Inf -Inf];
history = nan(2000,2);
count = 0;
center = [NaN NaN];
centerSamples = zeros(0,2);
captureStart = [];
setappdata(f,'CalibrationReady',true);
while ishghandle(f) && ~getappdata(f,'Finished')
    raw = ADAPT.JoystickDevice('read');
    if getappdata(f,'CaptureCenter')
        setappdata(f,'CaptureCenter',false);
        center = [NaN NaN];
        centerSamples = zeros(0,2);
        captureStart = GetSecs;
        set(centerButton,'Enable','off','String','Mesure du repos : ne bougez pas...');
    end
    if ~isempty(captureStart)
        centerSamples(end+1,:) = raw; %#ok<AGROW>
        if GetSecs-captureStart>=0.6 && size(centerSamples,1)>=10
            center = median(centerSamples,1);
            minimum = center;
            maximum = center;
            history(:) = NaN;
            count = 0;
            captureStart = [];
            set(centerPointer,'XData',center(1),'YData',center(2));
            set(centerButton,'Enable','on','String','Reprendre le centre au repos (Espace)');
            title(normalizedAxes,'2. Parcourez toute la course, puis Echap');
        end
    end
    if all(isfinite(center))
        minimum = min(minimum,raw);
        maximum = max(maximum,raw);
        delta = raw-center;
        span = max(maximum-center,1);
        negative = delta<0;
        span(negative) = max(center(negative)-minimum(negative),1);
        calibrated = delta./span;
        set(calPointer,'XData',calibrated(1),'YData',calibrated(2));
    end
    count = count+1;
    history(mod(count-1,size(history,1))+1,:) = raw;
    set(rawPointer,'XData',raw(1),'YData',raw(2));
    set(rawTrace,'XData',history(:,1),'YData',history(:,2));
    drawnow;
    pause(0.01);
end
if ~ishghandle(f) || getappdata(f,'Cancelled'), return; end
% Store limits relative to the measured rest. The device applies the same
% offset for the task, so return tolerances and curve plots share this zero.
limits = [minimum-center maximum-center];
try
    ADAPT.NormalizeJoystickAxes([0 0],[0 0],limits);
catch
    error('AMEDYST:JoystickCalibrationIncomplete', ...
        ['Calibration incomplete : mesurez le centre au repos (Espace), puis ' ...
        'parcourez les deux axes de chaque cote de ce centre avant Echap.']);
end
xmin_ymin_xmax_ymax = limits;
fprintf('%s [xmin ymin xmax ymax] = [%g %g %g %g]\n',config.Transport,limits);
fprintf('Centre brut au repos = [%g %g]\n',center);
if ~isempty(owner) && ishghandle(owner)
    handles = guidata(owner);
    set(handles.edit_xmin_ymin_xmax_ymax,'String',num2str(limits));
    handles.JoystickCalibrations.(config.Transport) = num2str(limits);
    handles.JoystickCalibrationCenters.(config.Transport) = center;
    message = sprintf('Calibration %s : centre brut [%g %g].',config.Transport,center);
    set(handles.text_JoystickStatus,'String',message,'TooltipString',message, ...
        'ForegroundColor',[0 0.45 0.15]);
    guidata(owner,handles);
end
end

function keyPressed(fig,event)
if strcmp(event.Key,'escape'), setappdata(fig,'Finished',true); end
if strcmp(event.Key,'space'), setappdata(fig,'CaptureCenter',true); end
end

function cancelCalibration(fig,~)
setappdata(fig,'Cancelled',true);
setappdata(fig,'Finished',true);
end

function deleteIfValid(fig)
if ishghandle(fig), delete(fig); end
end
