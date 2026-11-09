function [EXIT, StopTime] = RecenterJoystick(Cursor, BigCircle, Cross, ER, RR, SR, StartTime, event)
%RECENTERJOYSTICK Ask for an active return and stable hold, then reset zero.
% event is the current EP row, so calibration remains tied to a trial.
global S prevX prevY newX newY
settings = S.Parameters.ADAPT.Joystick;
rest = settings.Rest;
returnOnset = [];
referenceCenter = S.Joystick.Center;
rawSamples = zeros(0,2);
sampleTimes = zeros(0,1);
oldTextSize = Screen('TextSize',S.PTB.wPtr,max(18,round(Cursor.screenY*0.035)));
restoreText = onCleanup(@() Screen('TextSize',S.PTB.wPtr,oldTextSize));

while true
    [EXIT, StopTime] = Common.Interrupt(ER,RR,StartTime);
    if EXIT, return; end

    rawAxes = ADAPT.UpdateCursor(Cursor,event{6});
    sampleTime = GetSecs;
    rawSamples(end+1,:) = rawAxes;
    sampleTimes(end+1,1) = sampleTime;
    % Retain one sample before the window boundary to cover its full
    % duration even when screen refreshes are not exact multiples of it.
    first = find(sampleTimes >= sampleTime-rest.StableDuration,1);
    first = max(1,first-1);
    rawSamples = rawSamples(first:end,:);
    sampleTimes = sampleTimes(first:end);
    [center,stable,spread,inStartZone] = ADAPT.JoystickRestCenter( ...
        rawSamples,sampleTimes,S.xmin_ymin_xmax_ymax,rest,referenceCenter);
    if ~inStartZone
        % Time spent outside the start zone never counts toward the hold.
        rawSamples = zeros(0,2);
        sampleTimes = zeros(0,1);
    elseif stable
        S.Joystick.Center = center;
        % Reset both the integrated cursor and its input reference.
        % Otherwise the new origin would cause a false movement.
        [newX,newY] = ADAPT.JoystickPosition(rawAxes,center, ...
            S.xmin_ymin_xmax_ymax,Cursor.screenY,settings);
        prevX = newX;
        prevY = newY;
        Cursor.Move(0,0);
    end

    BigCircle.Draw;
    Cross.Draw;
    if inStartZone
        message = 'Restez aussi immobile que possible';
    else
        message = 'Revenez au point de depart';
    end
    DrawFormattedText(S.PTB.wPtr,message, ...
        'center',Cursor.screenY*0.65,[255 255 255]);
    Screen('DrawingFinished',S.PTB.wPtr);
    flipOnset = Screen('Flip',S.PTB.wPtr);
    SR.AddSample([flipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta]);
    if isempty(returnOnset)
        returnOnset = flipOnset;
        RR.AddEvent([{['JoystickReturn__' event{1}],returnOnset-StartTime,[]} event(4:end)]);
    end
    if stable
        RR.AddEvent([{['JoystickZero__' event{1}],flipOnset-StartTime,0} event(4:end)]);
        entry = struct('Block',event{4},'Trial',event{5}, ...
            'Onset',returnOnset-StartTime,'Duration',flipOnset-returnOnset, ...
            'RawCenter',center,'SampleCount',numel(sampleTimes), ...
            'NormalizedRange',spread);
        S.Joystick.RestHistory(end+1) = entry;
        return
    end
end
end
