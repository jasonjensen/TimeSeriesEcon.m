function s = rangestr(a, b)
%RANGESTR  Format an MIT range as "(first, last)" for an X13 spec file.
%
%   rangestr(mit1, mit2) or rangestr(mitrange).
%
%   See also: tse.x13.mitstr.
    if nargin == 1
        b = tse.lastdate(a);
        a = tse.firstdate(a);
    end
    s = ['(' tse.x13.mitstr(a) ', ' tse.x13.mitstr(b) ')'];
end
