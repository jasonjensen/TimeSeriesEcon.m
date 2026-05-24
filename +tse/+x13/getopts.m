function o = getopts(defaults, args)
%GETOPTS  Parse name-value pairs in ARGS against a DEFAULTS struct.
%
%   Returns DEFAULTS with any provided names overwritten.  Option names are
%   matched case-insensitively against the fields of DEFAULTS; an unknown name
%   or an odd number of arguments is an error.
%
%   This backs the keyword-argument handling of the tse.x13 spec constructors.
    o = defaults;
    names = fieldnames(defaults);
    if mod(numel(args), 2) ~= 0
        error('tseries:noMatch', 'X13 spec options must be given as name-value pairs.');
    end
    for i = 1:2:numel(args)
        nm = args{i};
        if ~(ischar(nm) || (isstring(nm) && isscalar(nm)))
            error('tseries:noMatch', 'X13 spec option names must be strings.');
        end
        idx = find(strcmpi(char(nm), names), 1);
        if isempty(idx)
            error('tseries:noMatch', 'Unknown X13 spec option: %s', char(nm));
        end
        o.(names{idx}) = args{i + 1};
    end
end
