function varargout = JoystickDevice(action, config)
%JOYSTICKDEVICE Own only this application's USB or serial joystick connection.
% The serial client buffers an already running stream; reads consume all
% available frames and expose the newest position, never a delayed FIFO point.
persistent state port
if isempty(state), state = newState(ADAPT.JoystickConnectionSettings()); end
switch lower(action)
    case 'open'
        ADAPT.JoystickDevice('close');
        state = newState(config);
        try
            if strcmp(config.Transport,'USBHID')
                if isempty(which('joymex2'))
                    error('AMEDYST:USBJoystickMissing','joymex2 introuvable : selectionnez USB HID ou Serie PJS selon votre branchement.');
                end
                joymex2('open',0);
                state.Open = true;
                ADAPT.JoystickDevice('read');
            elseif strcmp(config.Transport,'SerialPJS')
                if isempty(config.Port)
                    error('AMEDYST:SerialPortRequired','Selectionnez le port du joystick (COM... ou /dev/...) dans le menu.');
                end
                if isempty(which('serialport'))
                    error('AMEDYST:SerialUnavailable','Le mode serie necessite serialport (MATLAB R2019b ou plus recent).');
                end
                port = serialport(config.Port,config.BaudRate,'DataBits',8, ...
                    'Parity','none','StopBits',1,'FlowControl','none','Timeout',0.1);
                state.Open = true;
                flush(port,'input');
                deadline = GetSecs+config.ConnectTimeout;
                while GetSecs<deadline && state.ValidStreak<config.MinSyncFrames
                    ingest();
                    if state.ValidStreak<config.MinSyncFrames, pause(0.002); end
                end
                if state.ValidStreak<config.MinSyncFrames
                    error('AMEDYST:SerialPJSNoFrames', ...
                        ['Aucune suite de trames PJS valide sur %s a %d bauds (%d octets recus). ' ...
                        'Verifiez le mode PJS/651, le cable serie du fORP et le debit. ' ...
                        'Le simple cable USB HID ne devient pas un port COM.'], ...
                        config.Port,config.BaudRate,state.BytesReceived);
                end
            else
                error('AMEDYST:JoystickTransport','Transport joystick inconnu : %s',config.Transport);
            end
        catch err
            ADAPT.JoystickDevice('close');
            if startsWith(err.identifier,'AMEDYST:'), rethrow(err); end
            error('AMEDYST:JoystickOpen','Impossible d''ouvrir le joystick %s %s : %s', ...
                config.Transport,config.Port,err.message);
        end
        varargout{1} = snapshot();

    case 'read'
        if strcmp(state.Config.Transport,'SerialPJS')
            requireOpen();
            ingest();
            if GetSecs-state.LastSampleTime>state.Config.StaleTimeout
                error('AMEDYST:SerialJoystickStale', ...
                    'Le flux PJS de %s ne fournit plus de trames valides depuis %.2f s. Verifiez le cable et le mode 651.', ...
                    state.Config.Port,GetSecs-state.LastSampleTime);
            end
        else
            % Legacy direct queries remain compatible with the simulated USB
            % device used in the hardware-free task tests.
            data = joymex2('query',0);
            state.LastAxes = [double(data.axes(1)), -double(data.axes(2))]-state.Config.RawCenter;
            state.LastSampleTime = GetSecs;
            state.SamplesReceived = state.SamplesReceived+1;
        end
        varargout{1} = state.LastAxes;
        if nargout>1, varargout{2} = snapshot(); end

    case 'armtrigger'
        requireOpen();
        ingest(); % discard past edges, including data from before task start
        state.PendingTrigger = [];

    case 'trigger'
        ADAPT.JoystickDevice('read');
        varargout{1} = state.PendingTrigger;
        state.PendingTrigger = [];

    case 'status'
        varargout{1} = snapshot();

    case 'close'
        if ~isempty(port)
            try
                delete(port);
            catch
                % A disconnected device may already have invalidated its handle.
            end
            port = [];
        end
        if state.Open && strcmp(state.Config.Transport,'USBHID')
            clear joymex2
        end
        state.Open = false;
    otherwise
        error('AMEDYST:JoystickAction','Commande joystick inconnue : %s',action);
end

    function requireOpen()
        if ~state.Open || isempty(port)
            error('AMEDYST:SerialJoystickClosed','Le joystick serie n''est pas connecte. Relancez le test ou la tache.');
        end
    end

    function ingest()
        try
            count = port.NumBytesAvailable;
            if count==0, return; end
            % Read exactly the available bytes: there is no blocking wait for
            % an ASCII line, terminator, or a new joystick movement.
            bytes = read(port,count,'uint8');
        catch err
            error('AMEDYST:SerialJoystickRead','Lecture du joystick %s impossible : %s',state.Config.Port,err.message);
        end
        receivedAt = GetSecs;
        state.BytesReceived = state.BytesReceived+numel(bytes);
        [frames,state.PendingBytes,info] = ADAPT.DecodePJS(bytes,state.PendingBytes);
        state.DiscardedBytes = state.DiscardedBytes+info.DiscardedBytes;
        count = size(frames.Axes,1);
        if count==0
            if info.DiscardedBytes>0, state.ValidStreak = 0; end
            return
        end
        if info.LeadingDiscarded==0 && info.Continuous
            state.ValidStreak = state.ValidStreak+count;
        else
            state.ValidStreak = info.LastRunLength;
        end
        state.SamplesReceived = state.SamplesReceived+count;
        axes = frames.Axes(end,:)*state.Config.Scale;
        if state.Config.InvertX, axes(1) = -axes(1); end
        if state.Config.InvertY, axes(2) = -axes(2); end
        state.LastAxes = axes-state.Config.RawCenter;
        state.LastButtons = frames.Buttons(end,:);
        state.LastSampleTime = receivedAt;
        rising = frames.Trigger & ~[state.LastTriggerLevel; frames.Trigger(1:end-1)];
        if any(rising)
            % These are HOST reception times, not hardware timestamps. Decode
            % every packet so even a short pulse between flips is detected.
            state.TriggerTimes = [state.TriggerTimes; repmat(receivedAt,sum(rising),1)];
            state.PendingTrigger = receivedAt;
        end
        state.LastTriggerLevel = frames.Trigger(end);
    end

    function report = snapshot()
        report = rmfield(state,{'PendingBytes','PendingTrigger','LastTriggerLevel'});
    end
end

function state = newState(config)
state = struct('Config',config,'Open',false,'LastAxes',[NaN NaN], ...
    'LastButtons',[false false],'LastSampleTime',-Inf,'SamplesReceived',0, ...
    'BytesReceived',0,'DiscardedBytes',0,'ValidStreak',0, ...
    'PendingBytes',uint8([]),'LastTriggerLevel',false, ...
    'PendingTrigger',[],'TriggerTimes',zeros(0,1));
end
