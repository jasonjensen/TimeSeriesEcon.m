function t = rec(rng, t, fn)
%REC  Recursive evaluation over an MIT range.
%
%   t = tse.rec(range, t, fn)
%
%   Two function-handle signatures are supported:
%
%     fn(s, mit)        -- legacy form.  Receives the current TSeries
%                          and the current MIT.  Uses subsref/subsasgn
%                          for indexing, so it pays object-dispatch
%                          overhead at every step.
%     fn(v, i)          -- fast form (nargin(fn) == 2 but second arg is
%                          a plain integer).  Receives the raw values
%                          vector and an integer index.  No subsref.
%
%   The library auto-selects the fast form when possible.  If you need
%   to call methods that mutate the TSeries (e.g. growth on assign),
%   use the legacy form by writing `s(k-1)` instead of `v(i-1)`.

    if ~isa(rng, 'tse.MITRange')
        error('tseries:noMatch', 'rec requires an MITRange as first argument.');
    end
    if ~isa(t, 'tse.TSeries')
        error('tseries:noMatch', 'rec requires a TSeries as second argument.');
    end
    if ~isa(fn, 'function_handle')
        error('tseries:noMatch', 'rec requires a function handle as third argument.');
    end

    fdv = t.firstdate.value;
    step = double(rng.stepSize);
    iStart = double(rng.startMIT.value - fdv) + 1;
    iEnd   = double(rng.stopMIT.value  - fdv) + 1;

    % --- fast path: in-range writes, the user-supplied lambda accepts
    %     a values vector and an integer index.  Sidesteps subsref /
    %     subsasgn entirely.
    if iStart >= 1 && iEnd <= numel(t.values) && step ~= 0
        v = t.values;
        try
            for i = iStart:step:iEnd
                v(i) = fn(v, i);
            end
            t.values = v;
            return
        catch ME %#ok<NASGU>
            % Fall through to the slow path (e.g. fn expects (s, mit)).
        end
    end

    % --- legacy / slow path: pass (TSeries, MIT) to fn.  Used when
    %     - the body writes outside the current range (growth-on-assign), OR
    %     - fn expects the (s, mit) signature.
    F = t.frequency;
    ivals = rng.startMIT.value : rng.stepSize : rng.stopMIT.value;
    for k = 1:numel(ivals)
        idx = tse.MIT(F, ivals(k));
        t(idx) = fn(t, idx);
    end
end
