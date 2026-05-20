function m = bdaily(d, varargin)
%BDAILY  Construct an MIT{BDaily} from a date or date string.
%
%   m = tseries.bdaily(datetime(2022,1,3))
%   m = tseries.bdaily('2022-01-03')
%   m = tseries.bdaily('2022-01-02', 'bias', 'previous')
%   m = tseries.bdaily('2022-01-02', 'bias', 'next')
%   m = tseries.bdaily('2022-01-02', 'bias', 'nearest')
%   m = tseries.bdaily('2022-01-02', 'bias', 'strict')   % default
%   rng = tseries.bdaily('2022-01-01', '2022-01-22')     % MITRange

    if ~isempty(varargin) && (ischar(varargin{1}) || isstring(varargin{1})) ...
            && (numel(varargin) == 1 || ~strcmpi(varargin{1}, 'bias'))
        % second positional is the end date
        endDate = varargin{1};
        rng = tseries.MITRange( ...
            tseries.bdaily(d, 'bias', 'next'), ...
            tseries.bdaily(endDate, 'bias', 'previous'));
        if rng.stopMIT.value < rng.startMIT.value
            error('tseries:noMatch', ...
                'The provided range does not include any business days.');
        end
        m = rng;
        return
    end

    p = inputParser;
    addParameter(p, 'bias', 'strict');
    parse(p, varargin{:});
    bias = lower(string(p.Results.bias));

    if ischar(d) || isstring(d)
        d = datetime(string(d), 'InputFormat', 'yyyy-MM-dd');
    end
    if ~isa(d, 'datetime')
        error('tseries:noMatch', 'bdaily(d) requires a datetime, char, or string input.');
    end

    epoch = datetime(0, 12, 31);
    raw = int64(floor(days(d - epoch)));
    [numWeekends, rem_] = idivremFix(raw, int64(7));
    if rem_ < 0
        numWeekends = numWeekends - 1;
        rem_ = rem_ + 7;
    end
    adjustment = int64(0);
    if rem_ == 0       % Sunday
        if bias == "next" || bias == "nearest"
            adjustment = int64(-1);
        elseif bias == "strict"
            error('tseries:noMatch', ...
                '%s is not a valid business day, it is a Sunday.', char(d));
        end
    elseif rem_ == 6   % Saturday
        if bias == "previous" || bias == "nearest"
            adjustment = int64(1);
        elseif bias == "strict"
            error('tseries:noMatch', ...
                '%s is not a valid business day, it is a Saturday.', char(d));
        end
    end
    v = raw - int64(numWeekends * 2 + adjustment);
    m = tseries.MIT(tseries.BDaily(), v);
end

function [q, r] = idivremFix(a, b)
    q = idivide(a, b, 'fix');
    r = a - q * b;
end
