function varargout = AMEDYST_GUI
% AMEDYST_GUI is the function that creates (or bring to focus) AMEDYST GUI.
% Then, AMEDYST_main is always called to start each task. It is the
% "main" program.

% debug=1 closes previous figure and reopens it, and send the gui handles
% to base workspace.
debug = 0;

% KND: Force debug mode for me...
if contains(which('AMEDYST_GUI'),'karim.ndiaye')
    debug = 1;
end

%% Open a singleton figure, or gring the actual into focus.

% Is the GUI already open ?
figPtr = findall(0,'Tag',mfilename);

if ~isempty(figPtr) % Figure exists so brings it to the focus

    figure(figPtr);
    % Refresh profile labels when settings were edited while the menu was open.
    existingHandles = guidata(figPtr);
    if isfield(existingHandles,'popup_JoystickConversion')
        conversionLabels = joystickConversionChoices();
        if isfield(existingHandles,'JoystickProfile')
            conversionLabels{end+1} = existingHandles.JoystickProfile.Label;
        end
        set(existingHandles.popup_JoystickConversion,'String',conversionLabels);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% DEBUG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if debug
        close(figPtr); %#ok<UNRCH>
        AMEDYST_GUI;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

else % Create the figure

    clc
    rng('default')
    rng('shuffle')

    % Create a figure
    figHandle = figure( ...
        'HandleVisibility', 'off',... % close all does not close the figure
        'MenuBar'         , 'none'                   , ...
        'Toolbar'         , 'none'                   , ...
        'Name'            , mfilename                , ...
        'NumberTitle'     , 'off'                    , ...
        'Units'           , 'Pixels'                 , ...
        'Position'        , [20, 20, 700, 700] , ...
        'Tag'             , mfilename                );

    figureBGcolor = [0.9 0.9 0.9]; set(figHandle,'Color',figureBGcolor);
    buttonBGcolor = figureBGcolor - 0.1;
    editBGcolor   = [1.0 1.0 1.0];

    % Create GUI handles : pointers to access the graphic objects
    handles = guihandles(figHandle);

    %% Default values for Low reward & High reward

    handles.defaultLowRreward  = 12;
    handles.defaultHighRreward = 0;

    %% Panel proportions

    panelProp.xposP = 0.05; % xposition of panel normalized : from 0 to 1
    panelProp.wP    = 1 - panelProp.xposP * 2;

    panelProp.vect  = ...
        [1 4 2 1 2 ]; % relative proportions of each panel, from bottom to top

    panelProp.vectLength    = length(panelProp.vect);
    panelProp.vectTotal     = sum(panelProp.vect);
    panelProp.adjustedTotal = panelProp.vectTotal + 1;
    panelProp.unitWidth     = 1/panelProp.adjustedTotal;
    panelProp.interWidth    = panelProp.unitWidth/panelProp.vectLength;

    panelProp.countP = panelProp.vectLength + 1;
    panelProp.yposP  = @(countP) panelProp.unitWidth*sum(panelProp.vect(1:countP-1)) + 0.8*countP*panelProp.interWidth;

    %% Panel : Subject & Run

    p_sr.x = panelProp.xposP;
    p_sr.w = panelProp.wP;

    panelProp.countP = panelProp.countP - 1;
    p_sr.y = panelProp.yposP(panelProp.countP);
    p_sr.h = panelProp.unitWidth*panelProp.vect(panelProp.countP);

    handles.uipanel_SubjectRun = uipanel(handles.(mfilename),...
        'Title','Subject & Run',...
        'Units', 'Normalized',...
        'Position',[p_sr.x p_sr.y p_sr.w p_sr.h],...
        'BackgroundColor',figureBGcolor);

    p_sr.nbO       = 3; % Number of objects
    p_sr.Ow        = 1/(p_sr.nbO + 1); % Object width
    p_sr.countO    = 0; % Object counter
    p_sr.xposO     = @(countO) p_sr.Ow/(p_sr.nbO+1)*countO + (countO-1)*p_sr.Ow;
    p_sr.yposOmain = 0.1;
    p_sr.hOmain    = 0.6;
    p_sr.yposOhdr  = 0.7;
    p_sr.hOhdr     = 0.2;

    % ---------------------------------------------------------------------
    % Edit : Subject ID

    p_sr.countO = p_sr.countO + 1;
    e_sid.x = p_sr.xposO(p_sr.countO);
    e_sid.y = p_sr.yposOmain ;
    e_sid.w = p_sr.Ow;
    e_sid.h = p_sr.hOmain;
    handles.edit_SubjectID = uicontrol(handles.uipanel_SubjectRun,...
        'Style','edit',...
        'Units', 'Normalized',...
        'Position',[e_sid.x e_sid.y e_sid.w e_sid.h],...
        'BackgroundColor',editBGcolor,...
        'String','',...
        'Callback',@edit_SubjectID_Callback);

    % ---------------------------------------------------------------------
    % Text : Subject ID

    t_sid.x = p_sr.xposO(p_sr.countO);
    t_sid.y = p_sr.yposOhdr ;
    t_sid.w = p_sr.Ow;
    t_sid.h = p_sr.hOhdr;
    handles.text_SubjectID = uicontrol(handles.uipanel_SubjectRun,...
        'Style','text',...
        'Units', 'Normalized',...
        'Position',[t_sid.x t_sid.y t_sid.w t_sid.h],...
        'String','Subject ID',...
        'BackgroundColor',figureBGcolor);

    % ---------------------------------------------------------------------
    % Pushbutton : Check SubjectID data

    p_sr.countO = p_sr.countO + 1;
    b_csidd.x = p_sr.xposO(p_sr.countO);
    b_csidd.y = p_sr.yposOmain;
    b_csidd.w = p_sr.Ow;
    b_csidd.h = p_sr.hOmain;
    handles.pushbutton_Check_SubjectID_data = uicontrol(handles.uipanel_SubjectRun,...
        'Style','pushbutton',...
        'Units', 'Normalized',...
        'Position',[b_csidd.x b_csidd.y b_csidd.w b_csidd.h],...
        'String','Check SubjectID data',...
        'BackgroundColor',buttonBGcolor,...
        'TooltipString','Display in Command Window the content of data/(SubjectID)',...
        'Callback',@(hObject,eventdata)checkSubjectData(handles.edit_SubjectID));

    % ---------------------------------------------------------------------
    % Text : Last file name annoucer

    p_sr.countO = p_sr.countO + 1;
    t_lfna.x = p_sr.xposO(p_sr.countO);
    t_lfna.y = p_sr.yposOhdr ;
    t_lfna.w = p_sr.Ow;
    t_lfna.h = p_sr.hOhdr;
    handles.text_LastFileNameAnnouncer = uicontrol(handles.uipanel_SubjectRun,...
        'Style','text',...
        'Units', 'Normalized',...
        'Position',[t_lfna.x t_lfna.y t_lfna.w t_lfna.h],...
        'String','Last file name',...
        'BackgroundColor',figureBGcolor,...
        'Visible','Off');

    % ---------------------------------------------------------------------
    % Text : Last file name

    t_lfn.x = p_sr.xposO(p_sr.countO);
    t_lfn.y = p_sr.yposOmain ;
    t_lfn.w = p_sr.Ow;
    t_lfn.h = p_sr.hOmain;
    handles.text_LastFileName = uicontrol(handles.uipanel_SubjectRun,...
        'Style','text',...
        'Units', 'Normalized',...
        'Position',[t_lfn.x t_lfn.y t_lfn.w t_lfn.h],...
        'String','',...
        'BackgroundColor',figureBGcolor,...
        'Visible','Off');

    %% Panel : Environement

    p_env.x = panelProp.xposP;
    p_env.w = panelProp.wP;

    panelProp.countP = panelProp.countP - 1;
    p_env.y = panelProp.yposP(panelProp.countP);
    p_env.h = panelProp.unitWidth*panelProp.vect(panelProp.countP);

    handles.uipanel_Environement = uibuttongroup(handles.(mfilename),...
        'Title','Environement : key mapping',...
        'Units', 'Normalized',...
        'Position',[p_env.x p_env.y p_env.w p_env.h],...
        'BackgroundColor',figureBGcolor);

    p_env.nbO    = 2; % Number of objects
    p_env.Ow     = 1/(p_env.nbO + 1); % Object width
    p_env.countO = 0; % Object counter
    p_env.xposO  = @(countO) p_env.Ow/(p_env.nbO+1)*countO + (countO-1)*p_env.Ow;

    % ---------------------------------------------------------------------
    % RadioButton : MRI

    p_env.countO = p_env.countO + 1;
    r_mri.x   = p_env.xposO(p_env.countO);
    r_mri.y   = 0.1 ;
    r_mri.w   = p_env.Ow;
    r_mri.h   = 0.8;
    r_mri.tag = 'radiobutton_MRI';
    handles.(r_mri.tag) = uicontrol(handles.uipanel_Environement,...
        'Style','radiobutton',...
        'Units', 'Normalized',...
        'Position',[r_mri.x r_mri.y r_mri.w r_mri.h],...
        'String','MRI',...
        'TooltipString','Response buttons (fORP)',...
        'HorizontalAlignment','Center',...
        'Tag',(r_mri.tag),...
        'BackgroundColor',figureBGcolor);

    % ---------------------------------------------------------------------
    % RadioButton : Practice

    p_env.countO = p_env.countO + 1;
    r_practice.x   = p_env.xposO(p_env.countO);
    r_practice.y   = 0.1 ;
    r_practice.w   = p_env.Ow;
    r_practice.h   = 0.8;
    r_practice.tag = 'radiobutton_Practice';
    handles.(r_practice.tag) = uicontrol(handles.uipanel_Environement,...
        'Style','radiobutton',...
        'Units', 'Normalized',...
        'Position',[r_practice.x r_practice.y r_practice.w r_practice.h],...
        'String','Practice',...
        'TooltipString','keyboard keys',...
        'HorizontalAlignment','Center',...
        'Tag',(r_practice.tag),...
        'BackgroundColor',figureBGcolor);


    %% Display and optional Arduino triggers
    p_screen.x = panelProp.xposP;
    p_screen.w = panelProp.wP;
    panelProp.countP = panelProp.countP - 1;
    p_screen.y = panelProp.yposP(panelProp.countP);
    p_screen.h = panelProp.unitWidth * panelProp.vect(panelProp.countP);
    handles.uipanel_Display = uipanel(handles.(mfilename),...
        'Title','Affichage et marqueurs','Units','Normalized',...
        'Position',[p_screen.x p_screen.y p_screen.w p_screen.h],...
        'BackgroundColor',figureBGcolor);

    handles.checkbox_WindowedScreen = uicontrol(handles.uipanel_Display,...
        'Style','checkbox','Units','Normalized','Position',[0.04 0.20 0.28 0.25],...
        'String','Windowed screen','BackgroundColor',figureBGcolor);
    if debug, set(handles.checkbox_WindowedScreen,'Value',1); end

    handles.listbox_Screens = uicontrol(handles.uipanel_Display,...
        'Style','listbox','Units','Normalized','Position',[0.37 0.12 0.20 0.67],...
        'String',{'0','1','2'},...
        'TooltipString','Selectionner l ecran Psychtoolbox',...
        'CreateFcn',@populateScreens);
    handles.text_ScreenMode = uicontrol(handles.uipanel_Display,...
        'Style','text','Units','Normalized','Position',[0.37 0.80 0.22 0.15],...
        'String','Ecran','BackgroundColor',figureBGcolor);

    handles.checkbox_ParPort = uicontrol(handles.uipanel_Display,...
        'Style','checkbox','Units','Normalized','Position',[0.64 0.29 0.34 0.36],...
        'String','Marqueurs COM/Arduino',...
        'TooltipString','Activer uniquement si un Arduino pour les triggers est branche',...
        'BackgroundColor',figureBGcolor,'Value',0,...
        'Callback',@Common.Checkbox_ArduinoPort_Callback);

    %% Panel : Task : ADAPT

    %     p_tk_adapt.x = p_tk_seq.x + p_tk_seq.w + p_tk_x_spacing;
    %     p_tk_adapt.w = p_tk_seq.w*2 ;
    p_tk_adapt.x = panelProp.xposP;
    p_tk_adapt.w = panelProp.wP;


    panelProp.countP = panelProp.countP - 1;
    p_tk_adapt.y = panelProp.yposP(panelProp.countP);
    p_tk_adapt.h = panelProp.unitWidth*panelProp.vect(panelProp.countP);

    handles.uipanel_Task_ADAPT = uibuttongroup(handles.(mfilename),...
        'Title','Paradigme MEG - selectionner Tache 1 ou 2 puis lancer',...
        'Units', 'Normalized',...
        'Position',[p_tk_adapt.x p_tk_adapt.y p_tk_adapt.w p_tk_adapt.h],...
        'BackgroundColor',figureBGcolor);

    p_tk_adapt.nbO    = 5; % Number of objects
    p_tk_adapt.Ow     = 1/(p_tk_adapt.nbO + 1); % Object width
    p_tk_adapt.countO = 0; % Object counter
    p_tk_adapt.xposO  = @(countO) p_tk_adapt.Ow/(p_tk_adapt.nbO+1)*countO + (countO-1)*p_tk_adapt.Ow;

    p_tk_adapt.y_marge = 0.05;


    % ---------------------------------------------------------------------
    % Edit : Deviation signe +/-

    p_tk_adapt.countO = p_tk_adapt.countO + 1;
    e_deviation_sign.x = p_tk_adapt.xposO(p_tk_adapt.countO);
    e_deviation_sign.y = p_tk_adapt.y_marge;
    e_deviation_sign.w = p_tk_adapt.Ow;
    e_deviation_sign.h = 0.4 - p_tk_adapt.y_marge;
    handles.edit_DeviationSign = uicontrol(handles.uipanel_Task_ADAPT,...
        'Style','edit',...
        'Units', 'Normalized',...
        'Position',[e_deviation_sign.x e_deviation_sign.y e_deviation_sign.w e_deviation_sign.h],...
        'BackgroundColor',editBGcolor,...
        'String','',...
        'Callback',@edit_DeviationSign_Callback,...
        'Tooltip','can only be + or -');

    % ---------------------------------------------------------------------
    % Edit : High Reward

    p_tk_adapt.countO = p_tk_adapt.countO + 1;
    e_high_reward.x = p_tk_adapt.xposO(p_tk_adapt.countO);
    e_high_reward.y = p_tk_adapt.y_marge;
    e_high_reward.w = p_tk_adapt.Ow;
    e_high_reward.h = 0.15;
    handles.edit_HighReward = uicontrol(handles.uipanel_Task_ADAPT,...
        'Style','edit',...
        'Units', 'Normalized',...
        'Position',[e_high_reward.x e_high_reward.y e_high_reward.w e_high_reward.h],...
        'BackgroundColor',editBGcolor,...
        'String',num2str(handles.defaultHighRreward),...
        'Callback',@edit_HighReward_Callback,...
        'Tooltip','High reward (€)');


    % ---------------------------------------------------------------------
    % Edit : Low Reward

    e_low_reward.x = p_tk_adapt.xposO(p_tk_adapt.countO);
    e_low_reward.y = e_high_reward.h + e_high_reward.y + p_tk_adapt.y_marge;
    e_low_reward.w = p_tk_adapt.Ow;
    e_low_reward.h = e_high_reward.h;
    handles.edit_LowReward = uicontrol(handles.uipanel_Task_ADAPT,...
        'Style','edit',...
        'Units', 'Normalized',...
        'Position',[e_low_reward.x e_low_reward.y e_low_reward.w e_low_reward.h],...
        'BackgroundColor',editBGcolor,...
        'String',num2str(handles.defaultLowRreward),...
        'Callback',@edit_LowReward_Callback,...
        'Tooltip','Low reward (€)');


    % ---------------------------------------------------------------------
    % Pushbutton : ADAPT_HighReward

    p_tk_adapt.countO  = p_tk_adapt.countO + 1;
    b_adapt_high.x   = p_tk_adapt.xposO(p_tk_adapt.countO);
    b_adapt_high.y   = p_tk_adapt.y_marge;
    b_adapt_high.w   = p_tk_adapt.Ow*2;
    b_adapt_high.h   = e_high_reward.h;
    b_adapt_high.tag = 'pushbutton_MEG_Task1';
    handles.(b_adapt_high.tag) = uicontrol(handles.uipanel_Task_ADAPT,...
        'Style','pushbutton',...
        'Units', 'Normalized',...
        'Position',[b_adapt_high.x b_adapt_high.y b_adapt_high.w b_adapt_high.h],...
        'String','Tache 1 : Baseline',...
        'BackgroundColor',buttonBGcolor,...
        'Tag',b_adapt_high.tag,...
        'Callback',@AMEDYST_main,...
        'FontSize',8);


    % ---------------------------------------------------------------------
    % Pushbutton : ADAPT_LowReward

    b_adapt_low.x   = p_tk_adapt.xposO(p_tk_adapt.countO);
    b_adapt_low.y   = e_low_reward.y;
    b_adapt_low.w   = b_adapt_high.w;
    b_adapt_low.h   = e_high_reward.h;
    b_adapt_low.tag = 'pushbutton_MEG_Task2';
    handles.(b_adapt_low.tag) = uicontrol(handles.uipanel_Task_ADAPT,...
        'Style','pushbutton',...
        'Units', 'Normalized',...
        'Position',[b_adapt_low.x b_adapt_low.y b_adapt_low.w b_adapt_low.h],...
        'String','Tache 2 : Adaptation',...
        'BackgroundColor',buttonBGcolor,...
        'Tag',b_adapt_low.tag,...
        'Callback',@AMEDYST_main,...
        'FontSize',8);


    % ---------------------------------------------------------------------
    % Pushbutton : PLOT_ALL

    p_tk_adapt.countO  = p_tk_adapt.countO + 2;
    b_PLOT_ALL.x   = p_tk_adapt.xposO(p_tk_adapt.countO);
    b_PLOT_ALL.y   = p_tk_adapt.y_marge;
    b_PLOT_ALL.w   = p_tk_adapt.Ow;
    b_PLOT_ALL.h   = e_deviation_sign.h;
    b_PLOT_ALL.tag = 'pushbutton_PLOT_ALL';
    handles.(b_PLOT_ALL.tag) = uicontrol(handles.uipanel_Task_ADAPT,...
        'Style','pushbutton',...
        'Units', 'Normalized',...
        'Position',[b_PLOT_ALL.x b_PLOT_ALL.y b_PLOT_ALL.w b_PLOT_ALL.h],...
        'String','plot_stats',...
        'BackgroundColor',buttonBGcolor,...
        'Tag',b_PLOT_ALL.tag,...
        'Callback',@pushbutton_PLOT_ALL_GUIroutine,...
        'ButtonDownFcn',@pushbutton_PLOT_ALL_GUIroutine,...
        'FontSize',8,...
        'Tooltip','Left click : plot last data  //  Right click : open UI to load specific data');


    % Shared settings for both tasks (not a second launch menu).
    set(handles.edit_DeviationSign,'Visible','off','String','+');
    set(handles.edit_HighReward,'Visible','off');
    set(handles.edit_LowReward,'Visible','off');
    set(handles.pushbutton_PLOT_ALL,'Visible','off');
    set(handles.pushbutton_MEG_Task1,'Position',[0.04 0.06 0.28 0.15]);
    set(handles.pushbutton_MEG_Task2,'Position',[0.34 0.06 0.29 0.15]);

    handles.text_Counterbalance = uicontrol(handles.uipanel_Task_ADAPT,...
        'Style','text','Units','normalized','Position',[0.65 0.78 0.33 0.12],...
        'String','Ordre inter-participants','BackgroundColor',figureBGcolor);
    handles.popup_Counterbalance = uicontrol(handles.uipanel_Task_ADAPT,...
        'Style','popupmenu','Units','normalized','Position',[0.65 0.67 0.34 0.12],...
        'String',{'A: +30 vis / -30 sans','B: -30 vis / +30 sans',...
                  'C: -30 sans / +30 vis','D: +30 sans / -30 vis'},'Value',1);
    handles.text_Scoring = uicontrol(handles.uipanel_Task_ADAPT,...
        'Style','text','Units','normalized','Position',[0.65 0.55 0.32 0.10],...
        'String','Regle de score','BackgroundColor',figureBGcolor);
    handles.popup_Scoring = uicontrol(handles.uipanel_Task_ADAPT,...
        'Style','popupmenu','Units','normalized','Position',[0.65 0.44 0.34 0.10],...
        'String',{'Reward (historique)','Punishment (historique)'},'Value',1);
    [conversionLabels,defaultConversion] = joystickConversionChoices();
    handles.text_JoystickConversion = uicontrol(handles.uipanel_Task_ADAPT,...
        'Style','text','Units','normalized','Position',[0.65 0.32 0.34 0.09],...
        'String','Conversion en position','BackgroundColor',figureBGcolor);
    handles.popup_JoystickConversion = uicontrol(handles.uipanel_Task_ADAPT,...
        'Style','popupmenu','Units','normalized','Position',[0.65 0.21 0.34 0.11],...
        'String',conversionLabels,'Value',defaultConversion,...
        'Enable','off','TooltipString','Courbe et gain du joystick (souris inchangee)');
    %% Panel : Cursor input method

    p_cursorinput.x = panelProp.xposP;
    p_cursorinput.w = panelProp.wP*2/3;

    p_cursorinput.y = b_adapt_low.y + b_adapt_low.h + p_tk_adapt.y_marge;
    p_cursorinput.h = 1 - p_cursorinput.y - p_tk_adapt.y_marge;

    handles.uipanel_CursorInput = uibuttongroup(handles.uipanel_Task_ADAPT,...
        'Title','Cursor input method',...
        'TitlePosition','righttop',...
        'Units', 'Normalized',...
        'Position',[p_cursorinput.x p_cursorinput.y p_cursorinput.w p_cursorinput.h],...
        'BackgroundColor',figureBGcolor,...
        'SelectionChangeFcn',@uipanel_CursorInput_SelectionChangeFcn);


    p_cursorinput.nbO    = 3; % Number of objects
    p_cursorinput.Ow     = 1/(p_cursorinput.nbO + 1); % Object width
    p_cursorinput.countO = 0; % Object counter
    p_cursorinput.xposO  = @(countO) p_cursorinput.Ow/(p_cursorinput.nbO+1)*countO + (countO-1)*p_cursorinput.Ow;


    % ---------------------------------------------------------------------
    % RadioButton : Joystick

    p_cursorinput.countO = p_cursorinput.countO + 1;
    r_joystick.x   = p_cursorinput.xposO(p_cursorinput.countO);
    r_joystick.y   = 0.5;
    r_joystick.w   = p_cursorinput.Ow;
    r_joystick.h   = 0.4;
    r_joystick.tag = 'radiobutton_Joystick';
    handles.(r_joystick.tag) = uicontrol(handles.uipanel_CursorInput,...
        'Style','radiobutton',...
        'Units', 'Normalized',...
        'Position',[r_joystick.x r_joystick.y r_joystick.w r_joystick.h],...
        'String','Joystick',...
        'HorizontalAlignment','Center',...
        'Tag',r_joystick.tag,...
        'BackgroundColor',figureBGcolor,...
        'ButtonDownFcn','joymex2_test',...
        'Tooltip','Right click will open a test');


    % ---------------------------------------------------------------------
    % Pushbutton : Joystick calibration

    p_cursorinput.countO = p_cursorinput.countO + 1;
    p_joycal.x   = p_cursorinput.xposO(p_cursorinput.countO);
    p_joycal.y   = 0.5;
    p_joycal.w   = p_cursorinput.Ow;
    p_joycal.h   = 0.4;
    p_joycal.tag = 'pushbutton_JoystickCalibration';
    handles.(p_joycal.tag) = uicontrol(handles.uipanel_CursorInput,...
        'Style','pushbutton',...
        'Units', 'Normalized',...
        'Position',[p_joycal.x p_joycal.y p_joycal.w p_joycal.h],...
        'String','JCalibration',...
        'HorizontalAlignment','Center',...
        'Tag',p_joycal.tag,...
        'BackgroundColor',figureBGcolor,...
        'Callback',@joystick_calibration,...
        'Visible', 'off');


    % ---------------------------------------------------------------------
    % RadioButton : Mouse

    p_cursorinput.countO = p_cursorinput.countO + 1;
    r_mouse.x   = p_cursorinput.xposO(p_cursorinput.countO);
    r_mouse.y   = 0.5;
    r_mouse.w   = p_cursorinput.Ow;
    r_mouse.h   = 0.4;
    r_mouse.tag = 'radiobutton_Mouse';
    handles.(r_mouse.tag) = uicontrol(handles.uipanel_CursorInput,...
        'Style','radiobutton',...
        'Units', 'Normalized',...
        'Position',[r_mouse.x r_mouse.y r_mouse.w r_mouse.h],...
        'String','Mouse',...
        'HorizontalAlignment','Center',...
        'Tag',r_mouse.tag,...
        'BackgroundColor',figureBGcolor);

    % Uncheck the button : this is my way to force the user to select a method
    set(handles.uipanel_CursorInput,'SelectedObject','')


    % ---------------------------------------------------------------------
    % Checkbox : Display Feedback

    c_fb.x = 0.64;
    c_fb.y = 0.02;
    c_fb.w = 0.34;
    c_fb.h = 0.11;
    handles.checkbox_ATAPT_display_feedback = uicontrol(handles.uipanel_Task_ADAPT,...
        'Style','checkbox',...
        'Units', 'Normalized',...
        'Position',[c_fb.x c_fb.y c_fb.w c_fb.h],...
        'String','Afficher le score',...
        'HorizontalAlignment','Center',...
        'BackgroundColor',figureBGcolor,...
        'Value',1,...
        'Tooltip','Show reward probability & result');


    % ---------------------------------------------------------------------
    % edit : xmin xmax ymin ymax

    e_xymm.x = 0.1;
    e_xymm.w = 0.8;
    e_xymm.y = 0.1;
    e_xymm.h = 0.4;
    e_xymm.tag = 'edit_xmin_ymin_xmax_ymax';
    joystickDefaults = ADAPT.JoystickSettings();
    handles.(e_xymm.tag) = uicontrol(handles.uipanel_CursorInput,...
        'Style','edit',...
        'Units', 'Normalized',...
        'Position',[e_xymm.x e_xymm.y e_xymm.w e_xymm.h],...
        'BackgroundColor',editBGcolor,...
        'String',num2str(joystickDefaults.DefaultCalibration),...
        'Visible', 'off',...
        'Tooltip','Valeurs usuelles : remplacer par la calibration du jour si necessaire');


    %% Panel : Operation mode

    p_op.x = panelProp.xposP;
    p_op.w = panelProp.wP;

    panelProp.countP = panelProp.countP - 1;
    p_op.y = panelProp.yposP(panelProp.countP);
    p_op.h = panelProp.unitWidth*panelProp.vect(panelProp.countP);

    handles.uipanel_OperationMode = uibuttongroup(handles.(mfilename),...
        'Title','Operation mode',...
        'Units', 'Normalized',...
        'Position',[p_op.x p_op.y p_op.w p_op.h],...
        'BackgroundColor',figureBGcolor);

    p_op.nbO    = 3; % Number of objects
    p_op.Ow     = 1/(p_op.nbO + 1); % Object width
    p_op.countO = 0; % Object counter
    p_op.xposO  = @(countO) p_op.Ow/(p_op.nbO+1)*countO + (countO-1)*p_op.Ow;


    % ---------------------------------------------------------------------
    % RadioButton : Acquisition

    p_op.countO = p_op.countO + 1;
    r_aq.x = p_op.xposO(p_op.countO);
    r_aq.y = 0.1 ;
    r_aq.w = p_op.Ow;
    r_aq.h = 0.8;
    r_aq.tag = 'radiobutton_Acquisition';
    handles.(r_aq.tag) = uicontrol(handles.uipanel_OperationMode,...
        'Style','radiobutton',...
        'Units', 'Normalized',...
        'Position',[r_aq.x r_aq.y r_aq.w r_aq.h],...
        'String','Acquisition',...
        'TooltipString','Should be used for all the environements',...
        'HorizontalAlignment','Center',...
        'Tag',r_aq.tag,...
        'BackgroundColor',figureBGcolor);


    % ---------------------------------------------------------------------
    % RadioButton : FastDebug

    p_op.countO = p_op.countO + 1;
    r_fd.x   = p_op.xposO(p_op.countO);
    r_fd.y   = 0.1 ;
    r_fd.w   = p_op.Ow;
    r_fd.h   = 0.8;
    r_fd.tag = 'radiobutton_FastDebug';
    handles.radiobutton_FastDebug = uicontrol(handles.uipanel_OperationMode,...
        'Style','radiobutton',...
        'Units', 'Normalized',...
        'Position',[r_fd.x r_fd.y r_fd.w r_fd.h],...
        'String','FastDebug',...
        'TooltipString','Only to work on the scripts',...
        'HorizontalAlignment','Center',...
        'Tag',r_fd.tag,...
        'BackgroundColor',figureBGcolor);


    % ---------------------------------------------------------------------
    % RadioButton : RealisticDebug

    p_op.countO = p_op.countO + 1;
    r_rd.x   = p_op.xposO(p_op.countO);
    r_rd.y   = 0.1 ;
    r_rd.w   = p_op.Ow;
    r_rd.h   = 0.8;
    r_rd.tag = 'radiobutton_RealisticDebug';
    handles.(r_rd.tag) = uicontrol(handles.uipanel_OperationMode,...
        'Style','radiobutton',...
        'Units', 'Normalized',...
        'Position',[r_rd.x r_rd.y r_rd.w r_rd.h],...
        'String','RealisticDebug',...
        'TooltipString','Only to work on the scripts',...
        'HorizontalAlignment','Center',...
        'Tag',r_rd.tag,...
        'BackgroundColor',figureBGcolor);




    %% End of opening

    % IMPORTANT
    guidata(figHandle,handles)
    % After creating the figure, dont forget the line
    % guidata(figHandle,handles) . It allows smart retrive like
    % handles=guidata(hObject)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% DEBUG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if debug
        assignin('base','handles',handles) %#ok<UNRCH>
        disp(handles)
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    figPtr = figHandle;

    fprintf('\n')
    fprintf('Response buttuns (fORRP 932) : \n')
    fprintf('\n')
    fprintf('1) SEQ :\n')
    fprintf('USB \n')
    fprintf('HHSC - 2x4 - C \n')
    fprintf('HID NAR BYGRT \n')
    fprintf('\n')
    fprintf('1) ADAPT :\n')
    fprintf('USB \n')
    fprintf('TETHYX \n')
    fprintf('HID JOYSTICK \n')
    fprintf('\n')

    %% KND: Pre-set options for faster testing by me...
    if contains(which('AMEDYST_GUI'),'karim.ndiaye')
        set(findall(0,'Tag','AMEDYST_GUI'),'Position', [ 20 60 600 600]);
        set(handles.radiobutton_Mouse,'Value',1)
        set(handles.edit_SubjectID, 'String', '00')
        set(handles.edit_DeviationSign, 'String', '+')
        
    end

end

% Available on both newly created and already open launch menus.
handles = guidata(figPtr);
if ~isfield(handles,'pushbutton_JoystickCurves') || ~ishghandle(handles.pushbutton_JoystickCurves)
    handles.pushbutton_JoystickCurves = uicontrol(handles.uipanel_Task_ADAPT, ...
        'Style','pushbutton','Units','normalized','Position',[0.04 0.27 0.59 0.15], ...
        'String','Comparer les courbes du joystick', ...
        'BackgroundColor',[0.8 0.85 0.9], ...
        'Callback',@(source,~) ADAPT.JoystickCurveTool(ancestor(source,'figure')));
    guidata(figPtr,handles);
end

if contains(which('AMEDYST_GUI'),'karim.ndiaye')
    set(findall(0,'Tag','AMEDYST_GUI'),'Position', [-1600 400 600 600])
end

if nargout > 0

    varargout{1} = guidata(figPtr);

end


end % main function


%% GUI Functions

function [labels,defaultValue] = joystickConversionChoices()
settings = ADAPT.JoystickSettings();
labels = arrayfun(@(gain) sprintf('Exponentielle k%g x%g', ...
    settings.ExponentialCoefficient,gain),settings.Gains,'UniformOutput',false);
labels{end+1} = 'Lineaire x1';
defaultValue = settings.GainIndex;
if strcmp(settings.Conversion,'Linear'), defaultValue = numel(labels); end
end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function populateScreens(hObject, ~)
% Populate Psychtoolbox screen choices without the absent +GUI library.
screens = 0;
if exist('Screen','file')
    try
        screens = Screen('Screens');
    catch err
        warning('MEG:ScreenList','Cannot enumerate screens: %s',err.message);
    end
end
if isempty(screens), screens = 0; end
set(hObject,'String',arrayfun(@num2str,screens(:),'UniformOutput',false), ...
    'Value',numel(screens));
end

% -------------------------------------------------------------------------
function checkSubjectData(editHandle)
% Local replacement of the missing GUI.Pushbutton_Check_SubjectID_data_Callback.
subjectID = get(editHandle,'String');
if isempty(subjectID)
    fprintf('Please enter a Subject ID first.\n');
    return
end
dataPath = fullfile(fileparts(mfilename('fullpath')),'data',subjectID);
if exist(dataPath,'dir')
    fprintf('Files for subject %s: %s\n',subjectID,dataPath);
    disp(dir(dataPath));
else
    fprintf('No data directory yet for subject %s.\n',subjectID);
end
end

function edit_SubjectID_Callback(hObject, ~)

NrChar = 2;

id_str = get(hObject,'String');

if length(id_str) ~= NrChar
    set(hObject,'String','')
    error('SubjectID must be %d chars', NrChar)
end

fprintf('SubjectID OK : %s \n', id_str)

end % function


% -------------------------------------------------------------------------
% function edit_Seqeunce_Callback(hObject, ~)
%
% NrTap = 8;
%
% sequence_str = get(hObject,'String');
%
% if length(sequence_str) ~= NrTap
%     set(hObject,'String','')
%     error('ComplexSequence must be %d non consecutive numbers', NrTap)
% end
%
% sequence_vect = (  cellstr(sequence_str')' );
% sequence_vect = cellfun(@str2double,sequence_vect);
% if any(sequence_vect > 5  |  sequence_vect < 2  |  round(sequence_vect) ~= sequence_vect)
%     set(hObject,'String','')
%     error('ComplexSequence must be numbers from 2 to 5 (positive integers)')
% end
%
% if any( diff(sequence_vect) == 0 )
%     set(hObject,'String','')
%     error('ComplexSequence not have two identical consecutive numbers')
% end
%
% fprintf('ComplexSequence OK : %s \n', sequence_str)
%
% end % function


% -----------------------------------------²--------------------------------
function uipanel_CursorInput_SelectionChangeFcn(hObject, eventdata)
handles = guidata(hObject);

% Check if joymex2 exists in the path
if isempty( which('joymex2') )
    disp('joymex2 NOT DETECTED : check https://github.com/escabe/joymex2')
    set(hObject,'SelectedObject',handles.radiobutton_Mouse);
    set(handles.pushbutton_JoystickCalibration, 'Visible', 'off')
    set(handles.edit_xmin_ymin_xmax_ymax, 'Visible', 'off')
    set(handles.popup_JoystickConversion, 'Enable', 'off')
end

try
    switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
        case 'radiobutton_Joystick'
            joymex2('open',0);
            set(handles.pushbutton_JoystickCalibration, 'Visible', 'on')
            set(handles.edit_xmin_ymin_xmax_ymax, 'Visible', 'on')
            set(handles.popup_JoystickConversion, 'Enable', 'on')
        case 'radiobutton_Mouse'
            % joymex2('close',0);
            clear joymex2 % more stable on linux than "joymex2('close',0);"
            set(handles.pushbutton_JoystickCalibration, 'Visible', 'off')
            set(handles.edit_xmin_ymin_xmax_ymax, 'Visible', 'off')
            set(handles.popup_JoystickConversion, 'Enable', 'off')
    end

catch err
    set(hObject,'SelectedObject',handles.radiobutton_Mouse);
    set(handles.pushbutton_JoystickCalibration, 'Visible', 'off')
    set(handles.edit_xmin_ymin_xmax_ymax, 'Visible', 'off')
    set(handles.popup_JoystickConversion, 'Enable', 'off')
    rethrow(err)
end

end % function


% -------------------------------------------------------------------------
function edit_HighReward_Callback(hObject, ~)
handles = guidata(hObject);

HighReward = str2double(get(hObject,'String'));

if isnumeric(HighReward) && isscalar(HighReward) && ~isnan(HighReward)
    fprintf('High reward ok : %g € \n', HighReward)
else
    set(hObject,'String',num2str(handles.defaultHighRreward))
    error('High reward must be scalar value')
end

end % function


% -------------------------------------------------------------------------
function edit_LowReward_Callback(hObject, ~)
handles = guidata(hObject);

LowReward = str2double(get(hObject,'String'));

if isnumeric(LowReward) && isscalar(LowReward) && ~isnan(LowReward)
    fprintf('Low reward ok : %g € \n', LowReward)
else
    set(hObject,'String',num2str(handles.defaultLowRreward))
    error('Low reward must be scalar value')
end

end % function


% -------------------------------------------------------------------------
function edit_DeviationSign_Callback(hObject, ~)
input = get(hObject, 'String');

switch input
    case '+'

    case '-'

    otherwise
        set(hObject,'String','')
        error('Deviation sign can only be + or -')
end

fprintf('Deviation sign is : %s \n', input)

end % function


% -------------------------------------------------------------------------
function pushbutton_PLOT_ALL_GUIroutine(~, eventdata)

switch eventdata.EventName

    case 'Action'

        global S %#ok<TLEV>

        if isempty(S)
            warning('No stats to plot')
            return
        end

        ADAPT.Stats.PLOT_ALL( S )

    case 'ButtonDown'

        % Get file
        [filename, pathname] = uigetfile(fullfile('..','data','*.mat'));

        if isnumeric(filename)
            return
        end

        % Load
        L = load(fullfile(pathname,filename));

        % Plot loaded file
        ADAPT.Stats.PLOT_ALL( L.S )
end

end % function
