function ds = to_dseries(t)
%TO_DSERIES  Convert a tse.TSeries or tse.MVTSeries into a Dynare dseries.
%
%   ds = tse.dynare.to_dseries(t)
%
%   For an MVTSeries the column names become the dseries variable names.
%   Errors on tse.BDaily (Dynare has no business-day frequency -- convert to
%   Daily first) and on tse.Unit.  Requires Dynare on the path.
    if ~tse.dynare.isavailable()
        error('tseries:noMatch', ...
            'Dynare is not on the path; cannot build a Dynare dseries.');
    end
    if isa(t, 'tse.TSeries')
        startD = tse.dynare.to_date(tse.firstdate(t));
        ds     = dseries(t.values, startD, {'data'});
    elseif isa(t, 'tse.MVTSeries')
        startD = tse.dynare.to_date(tse.firstdate(t));
        names  = cellstr(t.colnames);
        ds     = dseries(t.values, startD, names);
    else
        error('tseries:noMatch', ...
            'to_dseries expects a tse.TSeries or tse.MVTSeries (got %s).', class(t));
    end
end
