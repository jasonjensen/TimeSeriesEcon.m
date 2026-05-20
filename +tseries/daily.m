function m = daily(d, varargin) %#ok<INUSD>
%DAILY  Construct an MIT{Daily} from a date or date string.
%
%   m = tseries.daily(datetime(2022,1,1))
%   m = tseries.daily('2022-01-01')
%   rng = tseries.daily('2022-01-01', '2022-01-31')   % returns MITRange

    if nargin >= 2
        rng = tseries.MITRange(tseries.daily(d), tseries.daily(varargin{1}));
        m = rng;
        return
    end
    if ischar(d) || isstring(d)
        d = datetime(string(d), 'InputFormat', 'yyyy-MM-dd');
    end
    if ~isa(d, 'datetime')
        error('tseries:noMatch', 'daily(d) requires a datetime, char, or string input.');
    end
    raw = dateToDailyValue(d);
    m = tseries.MIT(tseries.Daily(), raw);
end
