function [warnings, notes, errors] = x13read_err(file)
%X13READ_ERR  Parse an X13 .err file into warning, note and error message lists.
    warnings = {}; notes = {}; errors = {};
    lines = strsplit(fileread(file), newline, 'CollapseDelimiters', false);
    collected = {};
    for i = 1:numel(lines)
        line = lines{i};
        if numel(line) >= 11 && (startsWith(line, ' WARNING:') || ...
                startsWith(line, ' ERROR:') || startsWith(line, ' NOTE:'))
            collected{end+1} = line; %#ok<AGROW>
        elseif ~isempty(collected)
            collected{end} = [collected{end} newline line];
        end
    end
    for i = 1:numel(collected)
        line = collected{i};
        if startsWith(line, ' WARNING:')
            warnings{end+1} = strtrim(line(11:end)); %#ok<AGROW>
        elseif startsWith(line, ' ERROR:')
            errors{end+1} = strtrim(line(9:end)); %#ok<AGROW>
        elseif startsWith(line, ' NOTE:')
            notes{end+1} = strtrim(line(8:end)); %#ok<AGROW>
        end
    end
end
