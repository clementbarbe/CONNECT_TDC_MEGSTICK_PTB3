function paradigm = BuildParadigm(phase, counterbalance, mode, firstBreakSeconds)
%BUILDParadigm Single source of truth for both parts of the MEG experiment.
% Columns: event, rotation (deg), trials, reward flag, cursor visible,
%          absolute block number, familiarisation flag, pause before (s).
% Rotation convention: positive = clockwise on screen.
if nargin < 4, firstBreakSeconds = 300; end
if ~ismember(phase,[1 2]), error('MEG:Phase','Phase must be 1 or 2.'); end
if ~ismember(counterbalance,1:4), error('MEG:Order','Counterbalance must be 1..4.'); end
if ~ischar(mode), error('MEG:Mode','Mode must be a char vector.'); end

switch mode
    case {'Acquisition','RealisticDebug'}
        trials = 48;
        familiarisationTrials = 4;
        longBreak = 300;
    case 'FastDebug'
        trials = 4;
        familiarisationTrials = 4;
        longBreak = 0;
        firstBreakSeconds = 0;
    otherwise
        error('MEG:Mode','Unsupported mode: %s',mode);
end

% Cross counterbalancing from the four diagrams on page 2 of the protocol.
%   1: +30 visible first, -30 invisible second
%   2: -30 visible first, +30 invisible second
%   3: -30 invisible first, +30 visible second
%   4: +30 invisible first, -30 visible second
rotationFirst  = [30 -30 -30 30];
visibilityFirst = [1 1 0 0];
rotationSecond = -rotationFirst;
visibilitySecond = 1 - visibilityFirst;
i = counterbalance;

if phase == 1
    paradigm = {
        'Direct_Pre'       0   familiarisationTrials 0 1 0 1 0;
        'Direct_Pre'       0   trials                 0 1 1 0 0;
        'No_vision'        0   trials                 0 0 2 0 10
    };
else
    paradigm = {
        eventName(rotationFirst(i),visibilityFirst(i)) rotationFirst(i)  trials 1 visibilityFirst(i) 3 0 max(0,firstBreakSeconds);
        eventName(rotationFirst(i),visibilityFirst(i)) rotationFirst(i)  trials 1 visibilityFirst(i) 4 0 10;
        'Direct_Pre'                                0  trials 0 1 5 0 10;
        eventName(rotationSecond(i),visibilitySecond(i)) rotationSecond(i) trials 1 visibilitySecond(i) 6 0 longBreak;
        eventName(rotationSecond(i),visibilitySecond(i)) rotationSecond(i) trials 1 visibilitySecond(i) 7 0 10;
        'Direct_Pre'                                0  trials 0 1 8 0 10
    };
end
end

function name = eventName(rotation, visible)
if rotation == 0 && visible
    name = 'Direct_Pre';
elseif ~visible
    name = 'No_vision';
else
    name = 'Deviation';
end
end
