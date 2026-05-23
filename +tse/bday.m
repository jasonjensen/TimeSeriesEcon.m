function m = bday(d, varargin)
%BDAY  Construct a business-daily (BDaily) MIT (or range) from a date.
%
%   Business days exclude Saturdays and Sundays.  The 'bias' option chooses
%   what happens when the input date falls on a weekend.
%
%   m = tse.bday(datetime(2022,1,3))
%   m = tse.bday('2022-01-03')
%   m = tse.bday('2022-01-02', 'bias', 'previous')
%   m = tse.bday('2022-01-02', 'bias', 'next')
%   m = tse.bday('2022-01-02', 'bias', 'nearest')
%   m = tse.bday('2022-01-02', 'bias', 'strict')   % default
%   rng = tse.bday('2022-01-01', '2022-01-22')     % MITRange

    if ~isempty(varargin) && (ischar(varargin{1}) || isstring(varargin{1})) ...
            && (numel(varargin) == 1 || ~strcmpi(varargin{1}, 'bias'))
        % second positional is the end date
        endDate = varargin{1};
        rng = tse.MITRange( ...
            tse.bday(d, 'bias', 'next'), ...
            tse.bday(endDate, 'bias', 'previous'));
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
        error('tseries:noMatch', 'bday(d) requires a datetime, char, or string input.');
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
    m = tse.MIT(tse.BDaily(), v);
end

function [q, r] = idivremFix(a, b)
    q = idivide(a, b, 'fix');
    r = a - q * b;
end
