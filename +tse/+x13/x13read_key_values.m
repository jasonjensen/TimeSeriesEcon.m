function ws = x13read_key_values(lines, sep)
%X13READ_KEY_VALUES  Parse an X13 key/value output file into a struct.
%
%   Each non-empty line is split on the first SEP occurrence (a regular
%   expression, default '[\t:]').  Values are parsed as integer, float, numeric
%   vector or yes/no boolean where possible, otherwise kept as text.
    if nargin < 2 || isempty(sep)
        sep = '[\t:]';
    end
    ws = struct();
    for i = 1:numel(lines)
        line = lines{i};
        if isempty(strtrim(line))
            continue
        end
        [tok, rest] = regexp(line, sep, 'match', 'split', 'once');
        if isempty(tok)
            continue
        end
        key = matlab.lang.makeValidName(strtrim(rest{1}));
        val = strtrim(rest{2});
        ws.(key) = local_parse(val);
    end
end

function v = local_parse(val)
    n = str2double(val);
    if ~isnan(n) && isscalar_numeric_string(val)
        v = n;
        return
    end
    parts = regexp(strrep(val, '*******', 'NaN'), '[\t\s]+', 'split');
    if numel(parts) > 1
        nums = str2double(parts);
        if ~any(isnan(nums) & ~strcmpi(parts, 'NaN'))
            v = nums;
            return
        end
    end
    if strcmp(val, 'no')
        v = false; return
    elseif strcmp(val, 'yes')
        v = true; return
    end
    v = val;
end

function tf = isscalar_numeric_string(s)
    tf = ~isempty(regexp(strtrim(s), '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$', 'once'));
end
