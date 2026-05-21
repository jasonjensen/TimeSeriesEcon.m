function m = daily(d, varargin) %#ok<INUSD>
%DAILY  Construct an MIT{Daily} from a date or date string.
%
%   m = tse.daily(datetime(2022,1,1))
%   m = tse.daily('2022-01-01')
%   rng = tse.daily('2022-01-01', '2022-01-31')   % returns MITRange

    if nargin >= 2
        rng = tse.MITRange(tse.daily(d), tse.daily(varargin{1}));
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
    m = tse.MIT(tse.Daily(), raw);
end
