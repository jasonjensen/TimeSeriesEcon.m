function ws = x13read_workspace_table(lines)
%X13READ_WORKSPACE_TABLE  Parse a tab-separated X13 table into a struct of columns.
%
%   The first line holds tab-separated headers; data begins on the third line.
%   Each column is parsed to numeric where possible, otherwise kept as a cellstr.
    tab = sprintf('\t');
    if ~isempty(lines) && isempty(strtrim(lines{end}))
        lines = lines(1:end-1);
    end
    headers = strsplit(strtrim(lines{1}), tab);
    headers = cellfun(@tse.x13.sanitize_colname, headers, 'UniformOutput', false);
    nh = numel(headers);
    n = max(numel(lines) - 2, 0);
    cols = repmat({repmat({''}, n, 1)}, 1, nh);
    for i = 1:n
        line = lines{i + 2};
        if isempty(strtrim(line))
            continue
        end
        vals = strsplit(line, tab);
        for j = 1:min(numel(vals), nh)
            cols{j}{i} = vals{j};
        end
    end
    ws = struct();
    for j = 1:nh
        nums = str2double(cols{j});
        if ~any(isnan(nums) & ~strcmpi(cols{j}, 'NaN'))
            ws.(matlab.lang.makeValidName(headers{j})) = nums;
        else
            ws.(matlab.lang.makeValidName(headers{j})) = cols{j};
        end
    end
end
