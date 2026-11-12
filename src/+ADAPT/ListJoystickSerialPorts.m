function ports = ListJoystickSerialPorts()
%LISTJOYSTICKSERIALPORTS Include ports already attached before GUI startup.
ports = {};
if ~isempty(which('serialportlist'))
    try
        ports = cellstr(serialportlist('all'));
    catch
        % Keep manual entry and the Unix device-name fallback available.
    end
end
if isempty(ports) && isunix
    patterns = {'/dev/ttyUSB*','/dev/ttyACM*','/dev/ttyS*','/dev/cu.*'};
    for pattern = patterns
        files = dir(pattern{1});
        for index = 1:numel(files)
            ports{end+1,1} = fullfile(files(index).folder,files(index).name); %#ok<AGROW>
        end
    end
end
ports = unique(ports(:),'stable');
end
