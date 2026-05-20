function d = toDate(m, ref)
%TODATE  Convert a calendar-frequency MIT to a MATLAB datetime.
%
%   d = tseries.toDate(m)              % last day of the MIT period
%   d = tseries.toDate(m, 'begin')     % first day of the MIT period
    if nargin < 2
        ref = 'end';
    end
    d = mitToDate(m, ref);
end
