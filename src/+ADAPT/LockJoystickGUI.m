function cleanup = LockJoystickGUI(fig)
%LOCKJOYSTICKGUI Prevent a run or transport switch while testing/calibrating.
controls = findall(fig,'Type','uicontrol');
previous = get(controls,'Enable');
if ischar(previous), previous = {previous}; end
set(controls,'Enable','off');
cleanup = onCleanup(@() restore(controls,previous));
end

function restore(controls,previous)
for index = 1:numel(controls)
    if ishghandle(controls(index)), set(controls(index),'Enable',previous{index}); end
end
end
