function StartRecordingEyelink
global S

% Eyelink mode 'On' ?
switch S.EyelinkMode
    case 'On'
        
        % Acquisition ?
        switch S.OperationMode
            
            case 'Acquisition'
                
                Eyelink.storeELfilename( S.DataPath, S.EyelinkFile, S.DataFileName ) % security
                
                Eyelink.StartRecording( S.EyelinkFile );
                
            otherwise
                error('Task:EyelinkWithourAcquisition','\n Eyelink mode should be ''Off'' if not in Acquisition mode \n')
                
        end
        
    case 'Off'
        
         switch S.OperationMode
            
            case 'Acquisition'

                if S.Feedback

                switch S.Task
                case 'ADAPT_Reward'
                    task = 'r';
                case 'ADAPT_Punishment'
                    task = 'p';

                end
                
                else                     
                     task = 'n';
                end

                EyelinkFile_noRun = [ S.SubjectID '_' task '_' (num2str(S.RunNumber))];

                EyelinkFile = [EyelinkFile_noRun ];

                S.EyelinkFile = EyelinkFile;
                
                Eyelink.storeELfilename( S.DataPath, S.EyelinkFile, S.DataFileName ) % security
                
                Eyelink.StartRecording( S.EyelinkFile );
                
            otherwise
                error('Task:EyelinkWithourAcquisition','\n Eyelink mode should be ''Off'' if not in Acquisition mode \n')
                
        end


    otherwise
        
end

end % function
