function ts = extend_series(F_to, ts, varargin)
%EXTEND_SERIES  Pad a series to the period boundaries of another frequency.
%
%   y = tse.extend_series(F_to, ts, 'direction', d, 'method', m)
%
%   Pads the ends of `ts` so that they reach the start/end of the periods
%   (in frequency F_to) into which the current endpoints fall.  Mirrors
%   TimeSeriesEcon.jl extend_series.
%
%   'direction' : 'both' (default) | 'begin' | 'end'
%   'method'    : 'mean' (default) — fill with the mean of the existing
%                 values in the affected output period; or
%                 'end'  — fill with the nearest existing endpoint value.

    p = inputParser;
    addParameter(p, 'direction', 'both');
    addParameter(p, 'method', 'mean');
    parse(p, varargin{:});
    direction = char(p.Results.direction);
    method    = char(p.Results.method);

    if ~isa(F_to, 'tse.Frequency')
        F_to = tse.sanitize_frequency(F_to);
    end

    switch direction
        case 'both'
            ts = extend_one(F_to, ts, 'begin', method);
            ts = extend_one(F_to, ts, 'end', method);
        case {'begin', 'end'}
            ts = extend_one(F_to, ts, direction, method);
        otherwise
            error('tseries:noMatch', 'direction must be both, begin, or end.');
    end
end

function ts = extend_one(F_to, ts, direction, method)
    F_from = int2freq(ts.frequency);
    rng = rangeof(ts);
    if strcmp(direction, 'begin')
        first_out = tse.fconvert(F_to, rng.startMIT);
        desired   = tse.fconvert(F_from, first_out, 'ref', 'begin');
        aff = tse.MITRange(desired, rng.startMIT - 1);
        if length(aff) < 1, return; end
        if strcmp(method, 'end')
            fillval = ts(aff.startMIT + 1);
        else
            basis = intersect(tse.fconvert(F_from, tse.MITRange(first_out, first_out)), rng);
            fillval = mean(tse.lookup(ts, basis));
        end
        ts(aff) = fillval;
    else   % end
        last_out = tse.fconvert(F_to, rng.stopMIT);
        desired  = tse.fconvert(F_from, last_out, 'ref', 'end');
        aff = tse.MITRange(rng.stopMIT + 1, desired);
        if length(aff) < 1, return; end
        if strcmp(method, 'end')
            fillval = ts(aff.startMIT - 1);
        else
            basis = intersect(tse.fconvert(F_from, tse.MITRange(last_out, last_out)), rng);
            fillval = mean(tse.lookup(ts, basis));
        end
        ts(aff) = fillval;
    end
end
