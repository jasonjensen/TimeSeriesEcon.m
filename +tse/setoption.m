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
    options_db('set', key, val);
end
