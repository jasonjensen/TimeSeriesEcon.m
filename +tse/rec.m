function t = rec(rng, t, fn, varargin)
%REC  Recursive evaluation over an MIT range.
%
%   t = tse.rec(range, t, fn)
%   t = tse.rec(range, t, fn, 'fast', true)
%
%   By default fn is called as fn(s, mit): it receives the current TSeries
%   and the current MIT, so every index inside fn (on s or on any other
%   series) is a date.  This is always correct.
%
%   With 'fast', true, fn is called as fn(v, i): it receives the raw values
%   vector of t and a plain integer position.  This skips object dispatch
%   at every step and is much faster for tight AR-style loops, but i is a
%   position in t, NOT a date.  Only use it when fn reads nothing but v:
%   indexing another TSeries with i, or comparing i with an MIT, gives
%   wrong results without an error.  The target is grown first if the
%   range reaches outside it.
%
%   Because TSeries is a value type, reassign the result: t = rec(...).

    if ~isa(rng, 'tse.MITRange')
        error('tseries:noMatch', 'rec requires an MITRange as first argument.');
    end
    if ~isa(t, 'tse.TSeries')
        error('tseries:noMatch', 'rec requires a TSeries as second argument.');
    end
    if ~isa(fn, 'function_handle')
        error('tseries:noMatch', 'rec requires a function handle as third argument.');
    end
    fast = false;
    if ~isempty(varargin)
        if numel(varargin) ~= 2 || ~(ischar(varargin{1}) || isstring(varargin{1})) ...
                || ~strcmpi(varargin{1}, 'fast')
            error('tseries:noMatch', 'rec accepts only the option ''fast'', true|false.');
        end
        fast = logical(varargin{2});
    end
    if isempty(rng)
        return
    end
    if rng.frequency ~= t.frequency
        mixed_freq_error(rng.frequency, t.frequency);
    end

    step = double(rng.stepSize);
    ivals = rng.startMIT.value : rng.stepSize : rng.stopMIT.value;

    if fast
        % Grow the target so every visited position exists.  The new
        % entries are NaN, exactly as growth-on-assign would leave them.
        F = t.frequency;
        lo = min(ivals); hi = max(ivals);
        if lo < t.firstdate.value
            t(tse.MIT(F, lo)) = tse.typenan(class(t.values));
        end
        lastv = t.firstdate.value + int64(numel(t.values)) - 1;
        if hi > lastv
            t(tse.MIT(F, hi)) = tse.typenan(class(t.values));
        end
        fdv = t.firstdate.value;
        iStart = double(rng.startMIT.value - fdv) + 1;
        iStop  = double(ivals(end) - fdv) + 1;
        v = t.values;
        for i = iStart:step:iStop
            v(i) = fn(v, i);
        end
        t.values = v;
        return
    end

    F = t.frequency;
    for k = 1:numel(ivals)
        idx = tse.MIT(F, ivals(k));
        t(idx) = fn(t, idx);
    end
end
