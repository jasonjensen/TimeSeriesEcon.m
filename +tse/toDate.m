function d = toDate(m, ref)
%TODATE  Convert a calendar-frequency MIT to a MATLAB datetime.
%
%   d = tse.toDate(m)              % last day of the MIT period
%   d = tse.toDate(m, 'begin')     % first day of the MIT period
    if nargin < 2
        ref = 'end';
    end
    d = mitToDate(m, ref);
end
