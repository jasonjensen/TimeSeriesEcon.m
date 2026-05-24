function t = regvartype(v)
%REGVARTYPE  Type tag of a regression variable: the char itself for a symbol,
%   or the bare class name for an X13var object (e.g. 'td' for tse.x13.td(...)).
    if ischar(v) || isstring(v)
        t = char(v);
    elseif isa(v, 'tse.x13.X13var')
        t = v.shortname();
    else
        t = '';
    end
end
