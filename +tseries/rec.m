function t = rec(rng, t, fn)
%REC  Recursive evaluation over an MIT range.
%
%   t = tseries.rec(range, t, @(t, idx) ...)
%
%   This is the MATLAB replacement for Julia's @rec macro.  The third
%   argument is a function handle that receives the current TSeries `t`
%   and the current MIT `idx`, and returns the new value to be stored
%   at `t(idx)`.
%
%   Example: Fibonacci.
%       t = tseries.TSeries(tseries.MIT(tseries.Unit(),1));
%       t(tseries.MIT(tseries.Unit(),1)) = 1;
%       t(tseries.MIT(tseries.Unit(),2)) = 1;
%       t = tseries.rec(tseries.MIT(tseries.Unit(),3):tseries.MIT(tseries.Unit(),10), ...
%                       t, @(s,k) s(k-1) + s(k-2));
%
%   For each MIT in `range`, the body is evaluated and the result is
%   stored at that date.  Growth-on-assign rules apply, so writing past
%   the current last date extends the series.

    if ~isa(rng, 'tseries.MITRange')
        error('tseries:noMatch', 'rec requires an MITRange as first argument.');
    end
    if ~isa(t, 'tseries.TSeries')
        error('tseries:noMatch', 'rec requires a TSeries as second argument.');
    end
    if ~isa(fn, 'function_handle')
        error('tseries:noMatch', 'rec requires a function handle as third argument.');
    end
    for k = 1:length(rng)
        idx = rng(k);
        t(idx) = fn(t, idx);
    end
end
