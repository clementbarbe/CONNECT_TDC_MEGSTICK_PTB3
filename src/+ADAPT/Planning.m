function [EP, Parameters] = Planning()
%PLANNING Shared event schedule for Baseline (task 1) and Adaptation (task 2).
% All numeric column indexes used by existing ADAPT.Task / recorders are
% preserved; new flags have been APPENDED to the original event headers.
global S

Parameters.TargetAngles = [20 60 120 160];
Parameters.AnglesError = [0 10 20 30 360];
Parameters.RewardNoteDuration = 1.0;
Parameters.PausePostMotor = 0.2;
% Actual endpoint -> next-trial interval; ADAPT.Task uses a real-time
% deadline, so reward presentation and the active return/hold are included.
Parameters.MinPauseBetweenTrials = 3.5;
Parameters.MaxPauseBetweenTrials = 4.5;
Parameters.PausePreMotor_Min = 0;
Parameters.PausePreMotor_Max = 0;
Parameters.TravelMaxDuration = 0.600;
Parameters.TravelMinDuration = 0.100;
Parameters.TrialMaxDuration = 4;
Parameters.TimeSpentOnTargetToValidate = 0.200;
Parameters.ShowRewardDuration = 0;
Parameters.PauseBetweenBlocks = 10;

switch S.Task
    case 'ADAPT_Reward'
        Parameters.Points = [3 2 1 0];
        Parameters.HitTarget = 4;
        Parameters.Puni = '+';
        S.Parameters.TextColor = [0 255 0];
    case 'ADAPT_Punishment'
        Parameters.Points = [-1 -2 -3 -4];
        Parameters.HitTarget = 0;
        Parameters.Puni = '';
        S.Parameters.TextColor = [255 0 0];
    otherwise
        error('MEG:Task','Expected ADAPT_Reward or ADAPT_Punishment');
end

Paradigm = MEG.BuildParadigm(S.MEG.Phase,S.MEG.Counterbalance, ...
    S.OperationMode,S.MEG.FirstBreakSeconds);

header = {'event_name','onset(s)','duration(s)','Block#','Trial#', ...
    'Deviation(°)','Target angle (°)','Variable pause duration (s)', ...
    'RewardPunishment','Premotor baseline (s)', ...
    'Visual cursor feedback (0/1)','Familiarisation (0/1)'};
EP = EventPlanning(header);
EP.AddStartTime('StartTime',0);
NextOnset = @(planning) planning.Data{end,2} + planning.Data{end,3};
trial_counter = 0;
NrTargets = numel(Parameters.TargetAngles);

for row = 1:size(Paradigm,1)
    pauseBefore = Paradigm{row,8};
    if pauseBefore > 0
        EP.AddPlanning([{'PauseTime',NextOnset(EP),pauseBefore}, ...
            repmat({[]},1,length(header)-3)]);
    end
    % Separate pseudo-random permutations guarantee one of each of the
    % four target directions per consecutive four trials (each block).
    angleList = [];
    for trial = 1:Paradigm{row,3}
        if isempty(angleList), angleList = Shuffle(1:NrTargets); end
        angle = Parameters.TargetAngles(angleList(end));
        angleList(end) = [];
        trial_counter = trial_counter + 1;
        trialJitter = Parameters.MinPauseBetweenTrials + ...
            (Parameters.MaxPauseBetweenTrials-Parameters.MinPauseBetweenTrials)*rand;
        preMotor = Parameters.PausePreMotor_Min + ...
            (Parameters.PausePreMotor_Max-Parameters.PausePreMotor_Min)*rand;
        estimatedDuration = trialJitter + Parameters.RewardNoteDuration + ...
            preMotor + 2*Parameters.TrialMaxDuration + ...
            Parameters.PausePostMotor + Parameters.ShowRewardDuration;
        EP.AddPlanning({Paradigm{row,1},NextOnset(EP),estimatedDuration, ...
            Paradigm{row,6},trial_counter,Paradigm{row,2},angle,trialJitter, ...
            Paradigm{row,4},preMotor,Paradigm{row,5},Paradigm{row,7}});
    end
end
EP.AddStopTime('StopTime',NextOnset(EP));
Parameters.Paradigm = Paradigm;
Parameters.NrTrials = trial_counter;
Parameters.Counterbalance = S.MEG.Counterbalance;
Parameters.Phase = S.MEG.Phase;
end
