function tf = isdefault(v)
%ISDEFAULT  True if V is an unset X13 spec field (a tse.x13.X13default sentinel).
%
%   See also: tse.x13.X13default.
    tf = isa(v, 'tse.x13.X13default');
end
