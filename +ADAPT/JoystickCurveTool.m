function fig = JoystickCurveTool(launcher)
%JOYSTICKCURVETOOL Interactive preview and selection of joystick response.
if nargin < 1, launcher = []; end
existing = findall(0,'Type','figure','Tag','AMEDYST_JoystickCurves');
if ~isempty(existing)
    fig = existing(1);
    if ~isempty(launcher), setappdata(fig,'Launcher',launcher); end
    figure(fig);
    return
end
settings = ADAPT.JoystickSettings();
limits = settings.DefaultCalibration;
if ~isempty(launcher) && ishghandle(launcher)
    owner = guidata(launcher);
    settings = ADAPT.SelectedJoystickSettings(owner);
    parsed = parseNumbers(get(owner.edit_xmin_ymin_xmax_ymax,'String'));
    if numel(parsed)==4, limits = parsed; end
end
if strcmp(settings.Conversion,'Linear')
    coefficient = 0;
    gain = settings.LinearGain*settings.LinearRangeRatio/settings.ExponentialRangeRatio;
else
    coefficient = settings.ExponentialCoefficient;
    gain = settings.Gains(settings.GainIndex);
end
fig = figure('Name','Courbes du joystick','Tag','AMEDYST_JoystickCurves', ...
    'NumberTitle','off','MenuBar','none','ToolBar','none','Color',[0.96 0.97 0.98], ...
    'Units','pixels','Position',[40 40 1160 780]);
setappdata(fig,'Launcher',launcher);
uicontrol(fig,'Style','text','Units','normalized','Position',[0.03 0.94 0.94 0.04], ...
    'String','Du lineaire aux mouvements fins pres du centre', ...
    'FontSize',17,'FontWeight','bold','BackgroundColor',get(fig,'Color'));
uicontrol(fig,'Style','text','Units','normalized','Position',[0.03 0.90 0.94 0.035], ...
    'String','Meme amplitude maximale : augmenter k attenue les petits mouvements. k = 0 correspond au lineaire.', ...
    'FontSize',11,'BackgroundColor',get(fig,'Color'));
label('Calibration : xmin  ymin  xmax  ymax',[0.035 0.86 0.43 0.03]);
label('Axe',[0.49 0.86 0.10 0.03]);
label('Gain commun',[0.63 0.86 0.12 0.03]);
label('Zone morte (%)',[0.79 0.86 0.17 0.03]);
controls.Calibration = editControl(num2str(limits),[0.035 0.81 0.43 0.045]);
controls.Axis = uicontrol(fig,'Style','popupmenu','Units','normalized', ...
    'Position',[0.49 0.81 0.10 0.045],'String',{'X','Y'},'Callback',@refresh);
controls.Gain = editControl(num2str(gain),[0.63 0.81 0.12 0.045]);
controls.DeadZone = editControl(num2str(settings.DeadZone*100),[0.79 0.81 0.17 0.045]);
controls.MainAxes = axes('Parent',fig,'Position',[0.085 0.315 0.565 0.43]);
controls.ZoomAxes = axes('Parent',fig,'Position',[0.75 0.50 0.215 0.245]);
controls.Info = uicontrol(fig,'Style','text','Units','normalized', ...
    'Position',[0.705 0.275 0.28 0.14],'HorizontalAlignment','left', ...
    'FontSize',11,'BackgroundColor',get(fig,'Color'));
label('Coefficient k',[0.035 0.20 0.12 0.03]);
controls.CoefficientSlider = uicontrol(fig,'Style','slider','Units','normalized', ...
    'Position',[0.16 0.20 0.39 0.03],'Min',0,'Max',12,'Value',coefficient, ...
    'SliderStep',[1/120 1/12],'Callback',@sliderChanged);
controls.Coefficient = editControl(num2str(coefficient),[0.58 0.19 0.08 0.045]);
controls.Apply = uicontrol(fig,'Style','pushbutton','Units','normalized', ...
    'Position',[0.705 0.14 0.26 0.065],'String','Appliquer ce profil a la tache', ...
    'BackgroundColor',[0.72 0.85 0.95],'FontSize',11,'Callback',@applyProfile);
uicontrol(fig,'Style','text','Units','normalized','Position',[0.035 0.10 0.63 0.055], ...
    'String','Les valeurs brutes tiennent compte de chaque demi-course calibree. Le zero est recentre entre les essais.', ...
    'HorizontalAlignment','left','FontSize',10,'BackgroundColor',get(fig,'Color'));
controls.Status = uicontrol(fig,'Style','text','Units','normalized', ...
    'Position',[0.035 0.025 0.93 0.05],'HorizontalAlignment','left', ...
    'FontSize',11,'BackgroundColor',get(fig,'Color'));
setappdata(fig,'CurveHandles',controls);
refresh();

    function label(content,position)
        uicontrol(fig,'Style','text','Units','normalized','Position',position, ...
            'String',content,'HorizontalAlignment','left','FontSize',10, ...
            'BackgroundColor',get(fig,'Color'));
    end

    function control = editControl(content,position)
        control = uicontrol(fig,'Style','edit','Units','normalized', ...
            'Position',position,'String',content,'BackgroundColor','white', ...
            'FontSize',11,'Callback',@refresh);
    end

    function sliderChanged(~,~)
        set(controls.Coefficient,'String',sprintf('%.2f',get(controls.CoefficientSlider,'Value')));
        refresh();
    end

    function valid = refresh(varargin)
        valid = false;
        try
            calibration = parseNumbers(get(controls.Calibration,'String'));
            k = str2double(get(controls.Coefficient,'String'));
            commonGain = str2double(get(controls.Gain,'String'));
            deadZone = str2double(get(controls.DeadZone,'String'))/100;
            validateattributes(k,{'numeric'},{'scalar','real','finite','>=',0,'<=',12});
            previewSettings = settings;
            previewSettings.DeadZone = deadZone;
            coefficients = unique([0 1 2 4 6 8 k]);
            data = ADAPT.JoystickCurveData(calibration,get(controls.Axis,'Value'), ...
                previewSettings,coefficients,commonGain);
            set(controls.CoefficientSlider,'Value',k);
            colors = lines(numel(coefficients));
            colors(1,:) = [0.12 0.12 0.12];
            cla(controls.MainAxes);
            cla(controls.ZoomAxes);
            hold(controls.MainAxes,'on');
            hold(controls.ZoomAxes,'on');
            plotted = gobjects(1,numel(coefficients));
            names = cell(1,numel(coefficients));
            for curve = 1:numel(coefficients)
                if coefficients(curve)==0, names{curve} = 'Lineaire (k=0)';
                else, names{curve} = sprintf('Exponentielle k=%g',coefficients(curve)); end
                width = 1.6;
                if coefficients(curve)==k
                    width = 3.4;
                    names{curve} = [names{curve} ' - choisi'];
                end
                plotted(curve) = plot(controls.MainAxes,data.Raw,data.Response(:,curve), ...
                    'Color',colors(curve,:),'LineWidth',width);
                plot(controls.ZoomAxes,data.Raw,data.Response(:,curve), ...
                    'Color',colors(curve,:),'LineWidth',width);
            end
            yline(controls.MainAxes,40,':','Cercle ~40 %', ...
                'Color',[0.45 0.45 0.45],'HandleVisibility','off');
            yline(controls.MainAxes,-40,':','HandleVisibility','off','Color',[0.45 0.45 0.45]);
            xlabel(controls.MainAxes,'Position brute du joystick (unites de calibration)');
            ylabel(controls.MainAxes,'Position du curseur (% de la hauteur de fenetre)');
            title(controls.MainAxes,'Comparaison a gain et amplitude identiques');
            legend(controls.MainAxes,plotted,names,'Location','northwest','FontSize',9);
            xlim(controls.MainAxes,[min(data.Raw) max(data.Raw)]);
            maximum = commonGain*settings.ExponentialRangeRatio*100;
            ylim(controls.MainAxes,[-1 1]*max(45,maximum*1.08));
            xlim(controls.ZoomAxes,[min(data.Raw) max(data.Raw)]*0.15);
            ylim(controls.ZoomAxes,[-1 1]*max(0.1,maximum*0.15));
            xlabel(controls.ZoomAxes,'Valeurs brutes');
            ylabel(controls.ZoomAxes,'% hauteur');
            title(controls.ZoomAxes,'Zoom : 15 % autour du centre');
            grid(controls.MainAxes,'on');
            grid(controls.ZoomAxes,'on');
            set([controls.MainAxes controls.ZoomAxes],'FontSize',10);
            selected = find(coefficients==k,1);
            at10 = find(abs(data.Normalized-0.1)<1e-9,1);
            at20 = find(abs(data.Normalized-0.2)<1e-9,1);
            set(controls.Info,'String',sprintf([ ...
                'Profil choisi : k=%g, gain x%g\n\n' ...
                'A 10 %% de course : %.3f %% de hauteur\n' ...
                'A 20 %% de course : %.3f %% de hauteur\n' ...
                'Amplitude maximale : %.1f %%'], ...
                k,commonGain,data.Response(at10,selected),data.Response(at20,selected),maximum));
            profile = settings;
            profile.DeadZone = deadZone;
            profile.Gains = commonGain;
            profile.GainIndex = 1;
            profile.ExponentialCoefficient = k;
            profile.LinearGain = commonGain;
            profile.LinearRangeRatio = settings.ExponentialRangeRatio;
            if k==0
                profile.Conversion = 'Linear';
                profile.Label = sprintf('Personnalise : lineaire x%g',commonGain);
            else
                profile.Conversion = 'Exponential';
                profile.Label = sprintf('Personnalise : k%g x%g',k,commonGain);
            end
            setappdata(fig,'CurveData',data);
            setappdata(fig,'CurveSettings',profile);
            set(controls.Apply,'Enable','on');
            if maximum<40
                set(controls.Apply,'Enable','off');
                status('Amplitude trop faible pour atteindre le cercle (~40 % de hauteur).',[0.7 0.15 0.1]);
            else
                status('Ajustez la courbe puis appliquez le profil choisi au prochain lancement.',[0.2 0.3 0.4]);
            end
            valid = true;
        catch err
            set(controls.Apply,'Enable','off');
            status(['Valeurs a corriger : ' err.message],[0.7 0.15 0.1]);
        end
        drawnow;
    end

    function applyProfile(~,~)
        if ~refresh() || strcmp(get(controls.Apply,'Enable'),'off'), return; end
        parent = getappdata(fig,'Launcher');
        if isempty(parent) || ~ishghandle(parent)
            status('Ouvrez AMEDYST_main puis cet outil depuis le menu pour appliquer le profil.',[0.7 0.15 0.1]);
            return
        end
        owner = guidata(parent);
        profile = getappdata(fig,'CurveSettings');
        defaults = ADAPT.JoystickSettings();
        labels = get(owner.popup_JoystickConversion,'String');
        if ischar(labels), labels = cellstr(labels); end
        labels = labels(1:numel(defaults.Gains)+1);
        labels{end+1} = profile.Label;
        set(owner.popup_JoystickConversion,'String',labels,'Value',numel(labels));
        data = getappdata(fig,'CurveData');
        set(owner.edit_xmin_ymin_xmax_ymax,'String',num2str(data.Limits));
        owner.JoystickProfile = profile;
        guidata(parent,owner);
        status(['Profil applique au menu : ' profile.Label],[0.1 0.45 0.25]);
    end

    function status(message,color)
        set(controls.Status,'String',message,'ForegroundColor',color);
    end
end

function numbers = parseNumbers(value)
value = regexprep(value,'[\[\],;]',' ');
numbers = str2double(strsplit(strtrim(value)));
end
