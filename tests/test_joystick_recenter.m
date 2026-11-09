function test_joystick_recenter()
%TEST_JOYSTICK_RECENTER Exercise the real cursor/recorders with simulated I/O.
% No display, joystick, or Psychtoolbox is used. Temporary stubs are removed.
global S prevX prevY newX newY JoystickTestIO
previousS = S;
previousCursorState = {prevX,prevY,newX,newY};
previousPath = path;
previousDirectory = pwd;
stubFolder = tempname;
mkdir(stubFolder);
cleanup = onCleanup(@() restoreEnvironment(previousS,previousCursorState, ...
    previousPath,previousDirectory,stubFolder));
writeStub(stubFolder,'Screen',{
    'function varargout = Screen(command,varargin)'
    'global JoystickTestIO'
    'varargout = {};'
    'switch command'
    'case ''TextSize'''
    'varargout = {JoystickTestIO.TextSize};'
    'if numel(varargin)>1, JoystickTestIO.TextSize=varargin{2}; end'
    'case ''Flip'''
    'JoystickTestIO.Time=JoystickTestIO.Time+0.01;'
    'assert(JoystickTestIO.Time<5,''Simulated recentering timed out.'');'
    'varargout = {JoystickTestIO.Time};'
    'case ''FillOval'''
    'if varargin{1}==1, JoystickTestIO.CursorDrawCount=JoystickTestIO.CursorDrawCount+1; end'
    'end'
    'end'});
writeStub(stubFolder,'GetSecs',{
    'function t = GetSecs()'
    'global JoystickTestIO'
    't = JoystickTestIO.Time;'
    'end'});
writeStub(stubFolder,'joymex2',{
    'function data = joymex2(varargin)'
    'global JoystickTestIO'
    'if JoystickTestIO.Time<JoystickTestIO.ReturnAt || (JoystickTestIO.Time>=JoystickTestIO.ExcursionAt && JoystickTestIO.Time<JoystickTestIO.ExcursionUntil)'
    'raw = [24000 0];'
    'else'
    'raw = JoystickTestIO.HoldPosition;'
    'end'
    'data.axes = int16([raw(1) -raw(2)]);'
    'end'});
writeStub(stubFolder,'KbCheck',{
    'function [down,t,code] = KbCheck()'
    'global JoystickTestIO'
    't = JoystickTestIO.Time;'
    'down = t>=JoystickTestIO.EscapeAt;'
    'code = false(1,256); code(27)=down;'
    'end'});
writeStub(stubFolder,'CenterRectOnPoint',{
    'function rect = CenterRectOnPoint(rect,x,y)'
    'half = (rect(3:4)-rect(1:2))/2;'
    'rect = [x-half(1) y-half(2) x+half(1) y+half(2)];'
    'end'});
writeStub(stubFolder,'DrawFormattedText',{
    'function DrawFormattedText(varargin)'
    'global JoystickTestIO'
    'JoystickTestIO.Messages{end+1} = varargin{2};'
    'end'});
for name = {'Priority','ShowCursor'}
    writeStub(stubFolder,name{1},{['function ' name{1} '(varargin)'];'end'});
end
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root,'vendor','StimTemplate-master'));
addpath(stubFolder,'-begin');
% MATLAB searches the working directory before the path; leave the project
% root so the real joymex2 binary there cannot override the simulated one.
cd(stubFolder);
clear Screen GetSecs joymex2 KbCheck CenterRectOnPoint DrawFormattedText Priority ShowCursor
assert(strcmp(which('joymex2'),fullfile(stubFolder,'joymex2.m')));
assert(strcmp(which('Screen'),fullfile(stubFolder,'Screen.m')));

S = struct;
S.InputMethod = 'Joystick';
S.Parameters.ADAPT.Joystick = ADAPT.JoystickSettings();
S.Parameters.Keybinds.Stop_Escape_ASCII = 27;
S.xmin_ymin_xmax_ymax = [-30000 -30000 30000 30000];
S.PTB.wPtr = 1;
S.PTB.oldLevel = 0;
S.Verbosity = 0;
S.Joystick.Center = [0 0];
S.Joystick.RestHistory = struct('Block',{},'Trial',{},'Onset',{}, ...
    'Duration',{},'RawCenter',{},'SampleCount',{},'NormalizedRange',{});
JoystickTestIO = struct('Time',0,'ReturnAt',1.2,'EscapeAt',Inf, ...
    'HoldPosition',[1400 -900],'TextSize',80,'CursorDrawCount',0, ...
    'ExcursionAt',Inf,'ExcursionUntil',-Inf);
JoystickTestIO.Messages = {};
cursor = Dot(10,[255 255 255],[0 0 0],500,500,1000,1000);
cursor.LinkToWindowPtr(1);
% Distinct drawing identifiers distinguish the cursor from the background
% shapes, so the final calibration frame cannot briefly display the cursor.
bigCircle = Dot(800,[50 50 50],[255 255 255],500,500,1000,1000);
bigCircle.LinkToWindowPtr(2);
cross = Dot(20,[255 255 255],[255 255 255],500,500,1000,1000);
cross.LinkToWindowPtr(3);
[newX,newY] = ADAPT.QueryJoystickData(1000,1000);
prevX = newX;
prevY = newY;
cursor.Move(newX,newY);
header = arrayfun(@(i) sprintf('column%d',i),1:12,'UniformOutput',false);
ER = EventRecorder(header,20);
RR = EventRecorder(header,20);
SR = SampleRecorder({'time','X','Y','R','Theta'},500);
event = {'Deviation',0,5,3,1,30,60,3.5,1,0,1,0};

% Remain at the ring, actively return near the start and hold the stick.
[exitFlag,stopTime] = ADAPT.RecenterJoystick(cursor,bigCircle,cross,ER,RR,SR,0,event);
assert(~exitFlag && isempty(stopTime));
assert(isequal(S.Joystick.Center,JoystickTestIO.HoldPosition));
assert(cursor.X==0 && cursor.Y==0 && prevX==0 && prevY==0);
assert(JoystickTestIO.TextSize==80); % drawing settings restored
assert(JoystickTestIO.CursorDrawCount==0); % no flash during the return/hold instruction
assert(any(strcmp(JoystickTestIO.Messages,'Revenez au point de depart')));
assert(any(strcmp(JoystickTestIO.Messages,'Restez aussi immobile que possible')));
assert(S.Joystick.RestHistory(1).Duration>=1.5);
assert(S.Joystick.RestHistory(1).Trial==1 && S.Joystick.RestHistory(1).Block==3);
assert(RR.EventCount==2 && SR.SampleCount>0);
assert(strcmp(RR.Data{1,1},'JoystickReturn__Deviation'));
assert(strcmp(RR.Data{2,1},'JoystickZero__Deviation'));
ADAPT.UpdateCursor(cursor,30);
assert(cursor.X==0 && cursor.Y==0); % no false increment after resetting zero

% A second held start can drift in the opposite direction, without a jump.
JoystickTestIO.HoldPosition = [-1200 800];
event{5} = 2;
ADAPT.RecenterJoystick(cursor,bigCircle,cross,ER,RR,SR,0,event);
assert(isequal(S.Joystick.Center,JoystickTestIO.HoldPosition));
assert(numel(S.Joystick.RestHistory)==2);
assert(S.Joystick.RestHistory(2).Duration>=0.3-1e-9);
assert(S.Joystick.RestHistory(2).Duration<0.5); % no fixed release delay
ADAPT.UpdateCursor(cursor,-30);
assert(cursor.X==0 && cursor.Y==0);

% Leaving the tolerated start zone resets the hold, even if the preceding
% samples there were stable. Acceptance requires a full new 300 ms window.
JoystickTestIO.ExcursionAt = JoystickTestIO.Time+0.15;
JoystickTestIO.ExcursionUntil = JoystickTestIO.Time+0.20;
event{5} = 3;
ADAPT.RecenterJoystick(cursor,bigCircle,cross,ER,RR,SR,0,event);
assert(JoystickTestIO.Time>=JoystickTestIO.ExcursionUntil+0.3);
assert(numel(S.Joystick.RestHistory)==3);

% Escape during a held movement stops the wait and preserves the last zero.
previousCenter = S.Joystick.Center;
JoystickTestIO.ReturnAt = Inf;
JoystickTestIO.EscapeAt = JoystickTestIO.Time+0.1;
[exitFlag,stopTime] = ADAPT.RecenterJoystick(cursor,bigCircle,cross,ER,RR,SR,0,event);
assert(exitFlag && ~isempty(stopTime));
assert(isequal(S.Joystick.Center,previousCenter));
assert(numel(S.Joystick.RestHistory)==3 && JoystickTestIO.TextSize==80);
assert(JoystickTestIO.CursorDrawCount==0);
clear cleanup
disp('All joystick recentering integration assertions passed.');
end

function writeStub(folder,name,lines)
fid = fopen(fullfile(folder,[name '.m']),'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',lines{:});
end

function restoreEnvironment(previousS,previousCursorState,previousPath,previousDirectory,folder)
global S prevX prevY newX newY
S = previousS;
[prevX,prevY,newX,newY] = previousCursorState{:};
cd(previousDirectory);
path(previousPath);
clear Screen GetSecs joymex2 KbCheck CenterRectOnPoint DrawFormattedText Priority ShowCursor
rmdir(folder,'s');
end
