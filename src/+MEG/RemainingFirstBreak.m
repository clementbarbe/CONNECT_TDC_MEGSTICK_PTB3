function seconds = RemainingFirstBreak(dataPath)
%REMAININGFIRSTBREAK Enforce a total of 300 s after task 1 completion.
seconds = 300;
marker = fullfile(dataPath,'last_baseline_end.mat');
if exist(marker,'file')
    saved = load(marker,'baselineFinishedAt');
    if isfield(saved,'baselineFinishedAt')
        elapsedSeconds = (now-saved.baselineFinishedAt)*86400;
        if elapsedSeconds >= 0 && elapsedSeconds <= 7200
            seconds = max(0,300-elapsedSeconds);
        else
            warning('MEG:OldBaseline','Baseline stamp is not from the same recent session; enforcing a full pause.');
        end
    end
else
    warning('MEG:NoBaseline','No completed baseline found: full 5-min break before task 2.');
end
end
