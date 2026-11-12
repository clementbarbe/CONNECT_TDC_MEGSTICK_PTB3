function test_joystick_serial_transport(portName,controlFile)
%TEST_JOYSTICK_SERIAL_TRANSPORT Real serialport I/O against the Python emulator.
% Never call with an arbitrary hardware port: this test controls its emitter.
setup_AMEDYST();
global S
previousS = S;
cleanup = onCleanup(@() finish(previousS,controlFile));
config = ADAPT.JoystickConnectionSettings('SerialPJS');
config.Port = portName;
config.ConnectTimeout = 0.6;
config.StaleTimeout = 0.15;
writeControl(controlFile,struct('x',321,'y',-123,'trigger',true,'fragment',true));
pause(0.03);
report = ADAPT.JoystickDevice('open',config);
assert(report.ValidStreak>=8 && report.Open);
[axes,report] = ADAPT.JoystickDevice('read');
assert(isequal(axes,[321 123]*32));
S = struct('JoystickConnection',config);
assert(isequal(ADAPT.ReadJoystickAxes(),axes));

% No new movement is required for a fresh, continuously transmitted sample.
initialCount = report.SamplesReceived;
pause(0.03);
[axes,report] = ADAPT.JoystickDevice('read');
assert(isequal(axes,[321 123]*32) && report.SamplesReceived>initialCount);
ADAPT.JoystickDevice('armtrigger');
assert(isempty(ADAPT.JoystickDevice('trigger'))); % already-high trigger is old
writeControl(controlFile,struct('x',321,'y',-123,'trigger',false));
pause(0.02);
assert(isempty(ADAPT.JoystickDevice('trigger')));
writeControl(controlFile,struct('x',321,'y',-123,'trigger',true));
pause(0.02);
assert(~isempty(ADAPT.JoystickDevice('trigger')));
assert(isempty(ADAPT.JoystickDevice('trigger'))); % a held flag is not a new edge

% Drain a queued stream to its LAST sample rather than displaying old points.
writeControl(controlFile,struct('x',900,'y',-700,'trigger',false));
pause(0.1);
axes = ADAPT.JoystickDevice('read');
assert(isequal(axes,[900 700]*32));

% A paused/disconnected stream must fail explicitly instead of freezing the
% cursor indefinitely. It is fine to cache a position between normal packets.
writeControl(controlFile,struct('paused',true));
pause(0.02);
ADAPT.JoystickDevice('read'); % consume the final in-flight bytes
pause(0.02);
assert(isequal(ADAPT.JoystickDevice('read'),axes));
pause(0.18);
caught = false;
try, ADAPT.JoystickDevice('read');
catch err, caught = strcmp(err.identifier,'AMEDYST:SerialJoystickStale'); end
assert(caught);
ADAPT.JoystickDevice('close');
assert(~ADAPT.JoystickDevice('status').Open);
ADAPT.JoystickDevice('close'); % cleanup is idempotent

% Wrong protocol: an ASCII stream must never be accepted as joystick axes,
% and failure must release the port so a correct connection can follow.
writeControl(controlFile,struct('mode','ascii'));
pause(0.02);
caught = false;
try, ADAPT.JoystickDevice('open',config);
catch err, caught = strcmp(err.identifier,'AMEDYST:SerialPJSNoFrames'); end
assert(caught && ~ADAPT.JoystickDevice('status').Open);
writeControl(controlFile,struct('x',-1024,'y',1023));
pause(0.02);
ADAPT.JoystickDevice('open',config);
assert(isequal(ADAPT.JoystickDevice('read'),[-32768 -32736]));
disp('All native serial PJS transport assertions passed.');
end

function writeControl(file,value)
handle = fopen(file,'w');
cleanup = onCleanup(@() fclose(handle));
fprintf(handle,'%s',jsonencode(value));
end

function finish(previousS,controlFile)
global S
ADAPT.JoystickDevice('close');
writeControl(controlFile,struct('x',321,'y',-123,'trigger',false));
S = previousS;
end
