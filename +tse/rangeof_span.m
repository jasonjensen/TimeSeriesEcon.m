function rng = rangeof_span(varargin)
%RANGEOF_SPAN Range that covers the union of all argument ranges.
%
%   All arguments must share a single frequency (or be empty).

    if isempty(varargin)
        rng = tse.MITRange(tse.MIT(tse.Unit(),1), tse.MIT(tse.Unit(),0));
        return
    end
    haveRange = false;
    for k = 1:numel(varargin)
        r = toRange(varargin{k});
        if isempty(r)
            continue
        end
        if ~haveRange
            rng = r;
            haveRange = true;
        else
            if ~eq(rng.startMIT.frequency, r.startMIT.frequency)
                mixed_freq_error(rng.startMIT.frequency, r.startMIT.frequency);
            end
            lo = min(rng.startMIT.value, r.startMIT.value);
            hi = max(rng.stopMIT.value,  r.stopMIT.value);
            F  = rng.startMIT.frequency;
            rng = tse.MITRange(tse.MIT(F, lo), tse.MIT(F, hi));
        end
    end
    if ~haveRange
        rng = tse.MITRange(tse.MIT(tse.Unit(),1), tse.MIT(tse.Unit(),0));
    end
end

function r = toRange(x)
    if isa(x, 'tse.MITRange')
        r = x;
    elseif isa(x, 'tse.MIT')
        r = tse.MITRange(x, x);
    elseif isempty(x)
        r = [];
    else
        r = [];
    end
end
