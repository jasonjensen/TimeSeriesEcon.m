function r = reindex(x, from, to, varargin)
%REINDEX  Re-anchor an MIT, MITRange, or TSeries so that `from` becomes
%`to`.  Frequencies of `from` and `to` need not match.
%
%   r = tse.reindex(MIT, from, to)
%   r = tse.reindex(MITRange, from, to)
%   r = tse.reindex(TSeries, from, to)
%   r = tse.reindex(TSeries, from, to, 'copy', true)

    p = inputParser;
    addParameter(p, 'copy', false);
    parse(p, varargin{:});
    doCopy = p.Results.copy;

    if isa(x, 'tse.MIT')
        if ~eq(x.frequency, from.frequency)
            mixed_freq_error(x.frequency, from.frequency);
        end
        r = to + int64(x.value - from.value);
        return
    end

    if isa(x, 'tse.MITRange')
        diff = int64(x.startMIT.value - from.value);
        rNew = to + diff;
        F = to.frequency;
        len = length(x);
        r = tse.MITRange(rNew, ...
            tse.MIT(F, rNew.value + int64(len - 1)));
        return
    end

    if isa(x, 'tse.TSeries')
        diff = int64(x.firstdate.value - from.value);
        newFD = to + diff;
        if doCopy
            r = tse.TSeries(newFD, x.values);
        else
            r = x;
            r.firstdate = newFD;
        end
        return
    end

    error('tseries:noMatch', 'reindex not defined for %s.', class(x));
end
