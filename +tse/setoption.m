function setoption(key, val)
%SETOPTION  Set a package option.
%
%   tse.setoption('bdaily_creation_bias', 'previous')
%
%   See also: tse.getoption.
    key = char(key);
    if strcmp(key, 'bdaily_creation_bias') ...
            && ~ismember(char(val), {'strict','previous','next','nearest'})
        error('tseries:noMatch', ...
            'bdaily_creation_bias must be strict, previous, next, or nearest. Received: %s', char(val));
    end
    if strcmp(key, 'slicing_keeps_type')
        if ~(islogical(val) || isnumeric(val)) || ~isscalar(val)
            error('tseries:noMatch', 'slicing_keeps_type must be true or false.');
        end
        val = logical(val);
    end
    options_db('set', key, val);
end
