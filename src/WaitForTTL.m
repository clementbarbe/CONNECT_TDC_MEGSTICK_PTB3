function [ TriggerTime ] = WaitForTTL
global S

if strcmp(S.OperationMode,'Acquisition')
    
    disp('----------------------------------')
    disp('      Waiting for trigger "5("     ')
    disp('                OR                ')
    disp('      Press "Escape" to abort     ')
    disp('----------------------------------')
    disp(' ')
    
    
    % Just to be sure the user is not pushing a button before
    WaitSecs(0.200); % secondes

    serialTrigger = isfield(S,'JoystickConnection') && ...
        strcmp(S.InputMethod,'Joystick') && ...
        strcmp(S.JoystickConnection.Transport,'SerialPJS');
    if serialTrigger
        ADAPT.JoystickDevice('armtrigger');
        disp('PJS : attente du trigger serie (ou de la touche TTL).');
    end
    
    % Waiting for TTL signal
    while 1
        
        [ keyIsDown , TriggerTime, keyCode ] = KbCheck;

        if serialTrigger
            receivedTrigger = ADAPT.JoystickDevice('trigger');
            if ~isempty(receivedTrigger)
                TriggerTime = receivedTrigger;
                break
            end
        end
        
        if keyIsDown
            
            switch S.Environement
                
                case 'MRI'
                    
                    if keyCode(S.Parameters.Keybinds.TTL_t_ASCII) % || keyCode(S.Parameters.Keybinds.emulTTL_s_ASCII)
                        
                        break
                        
                    elseif keyCode(S.Parameters.Keybinds.Stop_Escape_ASCII)
                        
                        sca
                        stack = dbstack;
                        error('WaitingForTTL:Abort','\n ESCAPE key : %s aborted \n',stack.file)
                        
                    end
                    
                case 'Practice'
                    
                    if keyCode(S.Parameters.Keybinds.TTL_t_ASCII) % || keyCode(S.Parameters.Keybinds.emulTTL_s_ASCII)
                        
                        break
                        
                    elseif keyCode(S.Parameters.Keybinds.Stop_Escape_ASCII)
                        
                        sca
                        stack = dbstack;
                        error('WitingForTTL:Abort','\n ESCAPE key : %s aborted \n',stack.file)
                        
                    end
                    
            end % switch
            
        end
        
        WaitSecs('YieldSecs',0.001);
    end % while
    
    
else % in DebugMod
    
    disp('Waiting for TTL : DebugMode')
    
    TriggerTime = GetSecs;
    
end

end
