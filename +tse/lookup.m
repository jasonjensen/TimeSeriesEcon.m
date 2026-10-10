function out = lookup(t, keys)
%LOOKUP  Vectorised gather of values at the given MIT keys.
%
%   out = tse.lookup(t, mitArray)
%
%   Returns t.values(...) for each MIT in `mitArray`, in one vectorised
%   operation.  Frequencies must match; all keys must be in range.  Use
%   this instead of a Python-style scalar-loop of `t(mit_k)` calls.
%
%   `keys` can be:
%     * an MIT array (1xN or Nx1)
%     * an MITRange
%
%   Returns a column vector of values of the same numeric type as
%   t.values.

    if ~isa(t, 'tse.TSeries')
        error('tseries:noMatch', 'lookup requires a TSeries as first argument.');
    end

    if isa(keys, 'tse.MITRange')
        if keys.frequency ~= t.frequency
            mixed_freq_error(keys.frequency, t.frequency);
        end
        ks = range_positions(keys, t.firstdate.value, numel(t.values));
        out = reshape(t.values(ks), [], 1);
        return
    end

    if isa(keys, 'tse.MIT')
        n = numel(keys);
        if n == 0
            out = zeros(0, 1, class(t.values));
            return
        end
        % Validate frequencies + collect int64 values without per-element subsref.
        fdv = t.firstdate.value;
        % Use a loop here, but it's a few µs total vs the alternative which
        % is calling t(mit) repeatedly (~30 µs each).
        offsets = zeros(n, 1, 'int64');
        for k = 1:n
            mk = keys(k);
            if mk.frequency ~= t.frequency
                mixed_freq_error(mk.frequency, t.frequency);
            end
            offsets(k) = mk.value;
        end
        idx = offsets - fdv + 1;
        if any(idx < 1) || any(idx > numel(t.values))
            error('tseries:bounds', 'lookup key(s) out of range.');
        end
        out = t.values(idx);
        return
    end

    error('tseries:noMatch', 'lookup keys must be an MIT array or MITRange.');
end
