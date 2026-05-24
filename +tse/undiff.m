function r = undiff(dvar, varargin)
%UNDIFF  Inverse of diff.  Equivalent to Julia's `undiff`.
%
%   r = tse.undiff(dvar)                        anchor = (firstdate(dvar)-1, 0)
%   r = tse.undiff(dvar, anchorValue)           anchor at firstdate(dvar)-1
%   r = tse.undiff(dvar, anchorMIT, anchorValue)
%
%   `dvar` is a TSeries (presumably the output of diff(x)).  The
%   anchor specifies a known (date, value) pair so we can recover the
%   level series.  If only the value is provided, the date defaults to
%   `firstdate(dvar) - 1`.

    if ~isa(dvar, 'tse.TSeries')
        error('tseries:noMatch', 'undiff first argument must be a TSeries.');
    end

    F   = dvar.frequency;
    fdv = dvar.firstdate.value;
    n   = numel(dvar.values);
    cls = class(dvar.values);

    switch numel(varargin)
        case 0
            % default anchor: firstdate(dvar)-1, value 0
            anchorVal = cast(0, cls);
            anchorOff = -1;   % offset from firstdate, in same frequency
        case 1
            v = varargin{1};
            if isa(v, 'tse.TSeries')
                if v.frequency ~= F
                    mixed_freq_error(v.frequency, F);
                end
                anchorOff = -1;
                ad = fdv + int64(anchorOff);
                kv = double(ad - v.firstdate.value) + 1;
                if kv < 1 || kv > numel(v.values)
                    error('tseries:bounds', 'anchor TSeries does not cover the anchor date.');
                end
                anchorVal = v.values(kv);
            elseif isnumeric(v)
                anchorOff = -1;
                anchorVal = cast(v, cls);
            else
                error('tseries:noMatch', 'Unsupported undiff signature.');
            end
        case 2
            ad = varargin{1};
            v  = varargin{2};
            if ~isa(ad, 'tse.MIT') || ad.frequency ~= F
                mixed_freq_error( ...
                    (isa(ad,'tse.MIT')) * ad.frequency + (~isa(ad,'tse.MIT')) * 11, ...
                    F);
            end
            anchorOff = double(ad.value - fdv);
            if isa(v, 'tse.TSeries')
                if v.frequency ~= F
                    mixed_freq_error(v.frequency, F);
                end
                kv = double(ad.value - v.firstdate.value) + 1;
                if kv < 1 || kv > numel(v.values)
                    error('tseries:bounds', 'anchor TSeries does not cover the anchor date.');
                end
                anchorVal = v.values(kv);
            elseif isnumeric(v)
                anchorVal = cast(v, cls);
            else
                error('tseries:noMatch', 'Unsupported undiff signature.');
            end
        otherwise
            error('tseries:noMatch', 'undiff takes at most 3 args.');
    end

    % Build the working values vector.  If the anchor date falls outside
    % rangeof(dvar) we extend with zeros on either side.
    if anchorOff >= 0 && anchorOff < n
        % Anchor is inside the existing range.  Work range = rangeof(dvar).
        v = double(dvar.values);
        outFirst = fdv;
        kAnchor  = anchorOff + 1;
    elseif anchorOff < 0
        % Anchor is before firstdate.  Extend with zeros at the front.
        pad = -anchorOff;
        v = [zeros(pad, 1); double(dvar.values)];
        outFirst = fdv + int64(anchorOff);
        kAnchor  = 1;          % anchor sits at first position now
    else
        % Anchor is past lastdate.  Extend with zeros at the back.
        extra = anchorOff - n + 1;
        v = [double(dvar.values); zeros(extra, 1)];
        outFirst = fdv;
        kAnchor  = anchorOff + 1;
    end

    out = cumsum(v);
    out = out + (double(anchorVal) - out(kAnchor));
    r = tse.TSeries(tse.MIT(F, outFirst), cast(out, cls));
end
