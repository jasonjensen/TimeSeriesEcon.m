function ts = to_tseries(t)
%TO_TSERIES  Convert a tse.TSeries or tse.MVTSeries into an IRIS tseries.
%
%   ts = tse.iris.to_tseries(t)
%
%   For an MVTSeries the column names go into the IRIS Comment property.
%   Errors on tse.BDaily (IRIS 2015 has no business-day frequency -- use
%   fconvert to Daily first).  Requires IRIS on the path.
    if ~tse.iris.isavailable()
        error('tseries:noMatch', ...
            'IRIS Toolbox is not on the path; cannot build an IRIS tseries.');
    end
    if isa(t, 'tse.TSeries')
        startD = tse.iris.to_date(tse.firstdate(t));
        ts     = tseries(startD, t.values);
    elseif isa(t, 'tse.MVTSeries')
        startD = tse.iris.to_date(tse.firstdate(t));
        names  = cellstr(t.colnames);
        ts     = tseries(startD, t.values, '', names);
    else
        error('tseries:noMatch', ...
            'to_tseries expects a tse.TSeries or tse.MVTSeries (got %s).', class(t));
    end
end
