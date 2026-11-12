function AMEDYST_main(hObject, ~)
% AMEDYST_main is the main program, calling the different tasks and
% routines, according to the paramterts defined in the GUI

setup_AMEDYST();

%% GUI : open a new one or retrive data from the current one

if nargin == 0
    AMEDYST_GUI;
    return
end

handles = guidata(hObject); % retrieve GUI data

%% MAIN : Clean the environment

clc
sca
rng('default')
rng('shuffle')

%% MAIN : Initialize the main structure

global S
S               = struct; % S is the main structure, containing everything usefull, and used everywhere
S.TimeStamp     = datestr(now, 'yyyy-mm-dd HH:MM'); % Human readable
S.TimeStampFile = datestr(now, 30                ); % to sort automatically by time of creation

S.Verbosity = 0;

%% GUI : Task selection

switch get(hObject,'Tag')

    case {'pushbutton_MEG_Task1','pushbutton_MEG_Task2'}
        % One GUI, two experiment phases, one common ADAPT engine.
        isTask2 = strcmp(get(hObject,'Tag'),'pushbutton_MEG_Task2');
        S.MEG.Phase = 1 + double(isTask2);
        S.MEG.Counterbalance = get(handles.popup_Counterbalance,'Value');
        S.MEG.FirstBreakSeconds = 300;
        if get(handles.popup_Scoring,'Value') == 1
            Task = 'ADAPT_Reward';
        else
            Task = 'ADAPT_Punishment';
        end

    case 'pushbutton_SEQ'
        Task = 'SEQ';

    otherwise
        error('AMEDYST:TaskSelection','Error in Task selection')
end

S.Task = Task;


%% GUI : Environement selection

switch get(get(handles.uipanel_Environement,'SelectedObject'),'Tag')
    case 'radiobutton_MRI'
        Environement = 'MRI';
    case 'radiobutton_Practice'
        Environement = 'Practice';
    otherwise
        warning('AMEDYST:ModeSelection','Error in Environement selection')
end

S.Environement = Environement;


%% GUI : Mode selection

switch get(get(handles.uipanel_OperationMode,'SelectedObject'),'Tag')
    case 'radiobutton_Acquisition'
        OperationMode = 'Acquisition';
    case 'radiobutton_FastDebug'
        OperationMode = 'FastDebug';
        S.Verbosity = 1;
    case 'radiobutton_RealisticDebug'
        OperationMode = 'RealisticDebug';
        S.Verbosity = 1;
    otherwise
        warning('AMEDYST:ModeSelection','Error in Mode selection')
end

S.OperationMode = OperationMode;


%% GUI : Low / High reward

LowReward = str2double(get(handles.edit_LowReward,'String'));
if isempty(LowReward)
    error('LowReward is empty')
end
S.LowReward = LowReward;

HighReward = str2double(get(handles.edit_HighReward,'String'));
if isempty(HighReward)
    error('HighReward is empty')
end
S.HighReward = HighReward;


%% GUI : Starting sign

DeviationSign = get(handles.edit_DeviationSign,'String');
if isempty(DeviationSign)
    error('DeviationSign is empty')
end
S.DeviationSign = DeviationSign;


%% GUI + MAIN : Subject ID & Run number

SubjectID = get(handles.edit_SubjectID,'String');
S.SubjectID = SubjectID;

if isempty(SubjectID)
    error('AMEDYST:SubjectIDLength','\n SubjectID is required \n')
end

% Prepare path
DataPath = [fullfile(fileparts(mfilename('fullpath')),'data',SubjectID) filesep];

if ~exist(DataPath, 'dir')
    [created, message] = mkdir(DataPath);
    if ~created
        error('AMEDYST:CreateDataFolder','Cannot create %s: %s',DataPath,message);
    end
end

% DataFile_noRun = sprintf('%s%s_%s_%s_%s', DataPath, S.TimeStampFile, SubjectID, Environement, Task );
DataFile_noRun = sprintf('%s_%s_%s', SubjectID, Environement, Task );
if isfield(S,'MEG')
    DataFile_noRun = sprintf('%s_task%d_CB%d',DataFile_noRun,S.MEG.Phase,S.MEG.Counterbalance);
    if S.MEG.Phase == 2 && strcmp(OperationMode,'Acquisition')
        S.MEG.FirstBreakSeconds = MEG.RemainingFirstBreak(DataPath);
    end
end

% Auto-incrementation of run number
% -----------------------------------------------------------------
% Fetch content of the directory
dirContent = dir(DataPath);

% Is there file of the previous run ?
previousRun = zeros(max(0,length(dirContent)-2),1);
for f = 3 : length(dirContent) % avoid . and ..
    runNumber = regexp(dirContent(f).name,'_run(\d+)','tokens');
    if ~isempty(runNumber) % yes there is a file
        runNumber = runNumber{1}{:};
        previousRun(f) = str2double(runNumber); % save the previous run numbers
    else % no file found
        previousRun(f) = 0; % affect zero
    end
end

LastRunNumber = max(previousRun);
% If no previous run, LastRunNumber is 0
if isempty(LastRunNumber) || isnan(LastRunNumber)
    LastRunNumber = 0;
end

RunNumber = LastRunNumber + 1;

% -----------------------------------------------------------------

switch DeviationSign
    case '+'
        sgn = 'Plus';
    case '-'
        sgn = 'Minus';
    otherwise
        error('DeviationSign')
end
if isfield(S,'MEG')
    if S.MEG.Phase == 1
        sgn = 'Zero';
    elseif ismember(S.MEG.Counterbalance,[1 4])
        sgn = 'PlusCW';
    else
        sgn = 'MinusCCW';
    end
end

%% GUI : ADAPT : Show reward ?

switch Task

    case {'ADAPT_Reward','ADAPT_Punishment'}

        Feedback = get( handles.checkbox_ATAPT_display_feedback , 'Value' );
        S.Feedback = Feedback;

end

if S.Feedback
    fdBack = 'showFB';
else
    fdBack = 'noFB';
end


% Prepare

tk = strrep(Task,'ADAPT_','');
DataFile     = sprintf('%s%s_%s_%s_%s_%s_%s_run%0.2d', DataPath, S.TimeStampFile, SubjectID, Environement(1), tk,fdBack, sgn, RunNumber );
DataFileName = sprintf(  '%s_%s_%s_%s_%s_%s_run%0.2d',           S.TimeStampFile, SubjectID, Environement(1), tk,fdBack, sgn, RunNumber  );

S.SubjectID     = SubjectID;
S.RunNumber     = RunNumber;
S.DataPath      = DataPath;
S.DataFile      = DataFile;
S.DataFileName  = DataFileName;
if isfield(S,'MEG')
    S.DataFileName = sprintf('%s_task%d_CB%d',DataFileName,S.MEG.Phase,S.MEG.Counterbalance);
    S.DataFile = [DataFile sprintf('_task%d_CB%d',S.MEG.Phase,S.MEG.Counterbalance)];
    DataFile = S.DataFile;
    DataFileName = S.DataFileName;
end


%% GUI : Parallel port ?

if get(handles.checkbox_ParPort,'Value')
    ParPort = 'Arduino';
    disp('Event triggers will be sent via COM/Arduino port.')
else
    ParPort = 'Off';
end
S.ParPort = ParPort;
joystickConnection = ADAPT.JoystickConnectionSettings(handles);
selectedInput = get(handles.uipanel_CursorInput,'SelectedObject');
if strcmp(ParPort,'Arduino') && ~isempty(selectedInput) && ...
        strcmp(get(selectedInput,'Tag'),'radiobutton_Joystick') && ...
        strcmp(joystickConnection.Transport,'SerialPJS')
    if ispc, triggerPort = 'COM4'; else, triggerPort = '/dev/ttyACM0'; end
    if strcmpi(joystickConnection.Port,triggerPort)
        error('AMEDYST:SerialPortConflict', ...
            ['Le port %s est selectionne pour le joystick et pour les marqueurs Arduino. ' ...
            'Desactivez les marqueurs ou configurez un autre port Arduino.'],triggerPort);
    end
end
S.ParPortMessages = Common.PrepareParPort;
handles.ParPort   = ParPort;


%% GUI : SEQ : visual feedback ?

switch Task

    case 'SEQ'

        switch get(get(handles.uipanel_Feedback,'SelectedObject'),'Tag')
            case 'radiobutton_FeedbackOn'
                Feedback = 'On';
            case 'radiobutton_FeedbackOff'
                Feedback = 'Off';
            otherwise
                warning('AMEDYST:Feedback','Error in Feedback')
        end
        S.Feedback = Feedback;

end

%% GUI : ADAPT : input method ?

if isempty(get(handles.uipanel_CursorInput,'SelectedObject'))
    error('Select a cursor input method')
end

switch get(get(handles.uipanel_CursorInput,'SelectedObject'),'Tag')
    case 'radiobutton_Joystick'
        InputMethod = 'Joystick';
        xmin_ymin_xmax_ymax = str2num( get(handles.edit_xmin_ymin_xmax_ymax, 'String') );
        % Validate the range before opening the acquisition window/device.
        ADAPT.NormalizeJoystickAxes([0 0],[0 0],xmin_ymin_xmax_ymax);
    case 'radiobutton_Mouse'
        InputMethod = 'Mouse';
        xmin_ymin_xmax_ymax = str2num( get(handles.edit_xmin_ymin_xmax_ymax, 'String') );
    otherwise
        warning('AMEDYST:InputMethod','Error in InputMethod')
end

S.InputMethod = InputMethod;
S.JoystickConnection = joystickConnection;
S.xmin_ymin_xmax_ymax = xmin_ymin_xmax_ymax;

%% MAIN : Security : NEVER overwrite a file
% If erasing a file is needed, we need to do it manually

if exist([DataFile '.mat'], 'file') || exist([DataFile '_OUT.mat'],'file') || ...
        exist([DataFile '_SR.mat'],'file') || exist([DataFile '_SPM.mat'],'file')
    error('MATLAB:FileAlreadyExists','Run data already exists: %s',DataFile);
end


%% MAIN : Get stimulation parameters

S.Parameters = GetParameters;
S.Joystick.Center = [0 0];
S.Joystick.RestHistory = struct('Block',{},'Trial',{},'Onset',{}, ...
    'Duration',{},'RawCenter',{},'SampleCount',{},'NormalizedRange',{});
S.Parameters.ADAPT.Joystick = ADAPT.SelectedJoystickSettings(handles);

% Screen mode selection
AvalableDisplays = get(handles.listbox_Screens,'String');
SelectedDisplay = get(handles.listbox_Screens,'Value');
S.ScreenID = str2double( AvalableDisplays(SelectedDisplay) );


%% GUI : Windowed screen ?
switch get(handles.checkbox_WindowedScreen,'Value')
    case 1
        WindowedMode = 'On';
    case 0
        WindowedMode = 'Off';
    otherwise
        warning('AMEDYST:WindowedScreen','Error in WindowedScreen')
end

S.WindowedMode = WindowedMode;


%% MAIN : Dependencies before opening Psychtoolbox/fullscreen
% Load the local, original StimTemplate installation, if present.
% Installation is explicit: run setup_StimTemplate once (online).
localStimTemplate = fullfile(fileparts(mfilename('fullpath')), ...
    'vendor', 'StimTemplate-master');
if exist(fullfile(localStimTemplate,'@EventPlanning','EventPlanning.m'),'file') == 2
    addpath(localStimTemplate);
    rehash;
end
requiredClasses = {'EventPlanning','EventRecorder','SampleRecorder','KbLogger'};
missingClasses = requiredClasses(cellfun(@(c) ...
    exist(c,'class') ~= 8 && exist(c,'file') == 0, requiredClasses));
if ~isempty(missingClasses)
    error('MEG:MissingStimTemplate', [ ...
        'Classes StimTemplate manquantes : %s.\n' ...
        'Dans le dossier du projet, executez une fois : setup_StimTemplate\n' ...
        'Une connexion Internet est necessaire pour ce telechargement.\n' ...
        'Installation manuelle : https://github.com/benoitberanger/StimTemplate'], ...
        strjoin(missingClasses,', '));
end

%% MAIN : Validate the connected joystick before fullscreen / trigger waiting
if strcmp(S.InputMethod,'Joystick')
    joystickCleanup = onCleanup(@() ADAPT.JoystickDevice('close'));
    S.Joystick.ConnectionInfo = ADAPT.JoystickDevice('open',S.JoystickConnection);
end

%% MAIN : Open PTB window & sound

S.PTB = StartPTB;
if isfield(S,'MEG')
    try
        S = MEG.ApplyDisplayGeometry(S);
    catch err
        sca;
        Priority(0);
        rethrow(err);
    end
end

try
    Screen('TextBounds',S.PTB.wPtr,' ')
catch
    sca
    Screen('Preference','TextRenderer', 0);
    warning('Failback to legacy\nOS Text Renderer')
    S.PTB = StartPTB;
    if isfield(S,'MEG'), S = MEG.ApplyDisplayGeometry(S); end
    DrawFormattedText(S.PTB.wPtr,'Failback to legacy\nOS Text Renderer','center','center')
    Screen(S.PTB.wPtr,'flip')
end

% KND
if contains(which("AMEDYST_main"),'karim.ndiaye')
    S.Verbosity = 1;
    fprintf('On Karim''s computers we force verbose mode (S.Verbosity=1)');
end


%% MAIN : Task run


switch Task

    case 'SEQ'
        TaskData = SEQ.Task;

    case {'ADAPT_Reward','ADAPT_Punishment'}
        TaskData = ADAPT.Task;

    otherwise
        error('AMEDYST:Task','Task ?')
end


if strcmp(S.InputMethod,'Joystick')
    S.Joystick.ConnectionInfo = ADAPT.JoystickDevice('status');
    ADAPT.JoystickDevice('close');
end
S.TaskData = TaskData;
% A recovery file is written immediately after the task finishes, before
% output conversion, SPM analysis or optional plots can fail.
save(S.DataFile,'S');
if isfield(S,'MEG') && size(TaskData.SR.Data,1)>2
    intervals = diff(TaskData.SR.Data(:,1));
    intervals = intervals(intervals>0);
    if ~isempty(intervals)
        S.MEG.MedianLoggedHz = 1/median(intervals);
        if S.MEG.MedianLoggedHz < 130
            warning('MEG:LoggedRate','Logged trajectories: %.1f Hz (target 140 Hz).',S.MEG.MedianLoggedHz);
        end
    end
end
% Preserve the original recorders, but never overwrite DataSR/DataOUT in cwd.
% Raw files and CSV live alongside the phase-labelled .mat acquisition file.
if ~exist(S.DataPath,'dir'), mkdir(S.DataPath); end
if isfield(TaskData,'SR')
    srD = TaskData.SR.Data;
    save([S.DataFile '_SR.mat'],'srD');
end
if isfield(TaskData,'OutRecorder')
    outD = TaskData.OutRecorder.Data;
    save([S.DataFile '_OUT.mat'],'outD');
    csvfile = fullfile(S.DataPath,[S.DataFileName,'.csv']);
    trajectory_to_CSV(TaskData.SR,TaskData.EP,csvfile);
end

%% MAIN : Always save a recovery snapshot (Acquisition and Debug)
save(fullfile(S.DataPath,'LastS.mat'),'S');


%% MAIN : Close PTB
sca;
Priority( 0 );


%% MAIN : SPM data organization
[ names , onsets , durations ] = SPMnod;


%% MAIN : perform stats computation

if strcmp(Task,'SEQ')

    printResults(S.TaskData.ER)

elseif any(strcmp(Task,{'ADAPT_Reward','ADAPT_Punishment'}))

    if ~isempty(S.TaskData.OutRecorder.Data)

        S.Stats.evolution_RT_TT_inBlock            = ADAPT.Stats.evolution_RT_TT_inBlock;
        S.Stats.   global_RT_TT_inBlock            = ADAPT.Stats.   global_RT_TT_inBlock;
        S.Stats.evolution_AUC_inBlock              = ADAPT.Stats.evolution_AUC_inBlock;
        S.Stats.   global_AUC_inBlock              = ADAPT.Stats.   global_AUC_inBlock;

        % Plot
        switch OperationMode
            case 'Acquisition'
            case 'FastDebug'
                ADAPT.Stats.PLOT_ALL( S )
            case 'RealisticDebug'
                % ADAPT.Stats.PLOT_ALL( S )
        end % switch

    end
    if S.Verbosity
       % fprintf('Total reward for this run : %g € \n', S.TaskData.Parameters.TotalReward);
    end

end


%% MAIN : Saving data strucure


save(DataFile, 'S', 'names', 'onsets', 'durations');
save([DataFile '_SPM'], 'names', 'onsets', 'durations');
if strcmp(S.OperationMode,'Acquisition') && isfield(S,'MEG') && S.MEG.Phase == 1 && ...
        sum(S.TaskData.OutRecorder.Data(:,1)==1) == 48 && ...
        sum(S.TaskData.OutRecorder.Data(:,1)==2) == 48
    baselineFinishedAt = now; %#ok<NASGU>
    save(fullfile(S.DataPath,'last_baseline_end.mat'),'baselineFinishedAt');
end


%% MAIN : Send S and SPM nod to workspace

assignin('base', 'S'        , S        );
assignin('base', 'names'    , names    );
assignin('base', 'onsets'   , onsets   );
assignin('base', 'durations', durations);


%% MAIN + GUI : Ready for another run

set(handles.text_LastFileNameAnnouncer, 'Visible','on'                             )
set(handles.text_LastFileName         , 'Visible','on'                             )
set(handles.text_LastFileName         , 'String' , DataFile(length(DataPath)+1:end))

WaitSecs(0.100);
pause(0.100);
fprintf('\n')
fprintf('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ \n')
fprintf('  Ready for another session   \n')
fprintf('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ \n')

end % function
