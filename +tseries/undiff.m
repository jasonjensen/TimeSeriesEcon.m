function r = undiff(dvar, varargin)
%UNDIFF  Inverse of diff_ts.  Equivalent to Julia's `undiff`.
%
%   r = tseries.undiff(dvar)                        anchor = (firstdate(dvar)-1, 0)
%   r = tseries.undiff(dvar, anchorValue)           anchor at firstdate(dvar)-1
%   r = tseries.undiff(dvar, anchorMIT, anchorValue)
%
%   `dvar` is a TSeries (presumably the output of diff_ts(x)).  The
%   anchor specifies a known (date, value) pair so we can recover the
%   level series.  If only the value is provided, the date defaults to
%   `firstdate(dvar) - 1`.

    if ~isa(dvar, 'tseries.TSeries')
        error('tseries:noMatch', 'undiff first argument must be a TSeries.');
    end

    switch numel(varargin)
        case 0
            anchorDate = dvar.firstdate - 1;
            anchorVal  = zeros(1, 1, class(dvar.values));
        case 1
            v = varargin{1};
            if isa(v, 'tseries.TSeries')
                anchorDate = dvar.firstdate - 1;
                anchorVal  = v(anchorDate);
            elseif isnumeric(v)
                anchorDate = dvar.firstdate - 1;
                anchorVal  = v;
            else
                error('tseries:noMatch', 'Unsupported undiff signature.');
            end
        case 2
            anchorDate = varargin{1};
            v = varargin{2};
            if isa(v, 'tseries.TSeries')
                anchorVal = v(anchorDate);
            else
                anchorVal = v;
            end
        otherwise
            error('tseries:noMatch', 'undiff takes at most 3 args.');
    end

    cls = class(dvar.values);
    rng = tseries.rangeof(dvar);
    if ~ismember(rng, anchorDate)
        if anchorDate.value > tseries.lastdate(dvar).value
            ext = dvar.firstdate : anchorDate;
        else
            ext = anchorDate : tseries.lastdate(dvar);
        end
        dvar = tseries.overlay(ext, dvar, tseries.TSeries(ext, 0));
    end

    out = tseries.TSeries(tseries.rangeof(dvar), 0);
    out.values = cumsum(dvar.values);
    correction = double(anchorVal) - double(out(anchorDate));
    out.values = out.values + correction;
    r = out;
    r.values = cast(r.values, cls);
end
