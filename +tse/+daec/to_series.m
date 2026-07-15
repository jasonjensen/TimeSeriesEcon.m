function s = to_series(t)
%TO_SERIES  Convert a tse.TSeries / tse.MVTSeries into a DataEcon DESeries.
%
%   s = tse.daec.to_series(t)
%
%   A TSeries becomes a 1-axis DESeries (a range axis built from firstdate);
%   an MVTSeries becomes a 2-axis DESeries (range x names, the column names
%   forming the second axis).  The range axis needs no date conversion --
%   tse.MIT and DEDate share the same (frequency, value) encoding.
    if ~tse.daec.isavailable()
        error('tseries:noMatch', ...
            'DataEcon MATLAB classes are not on the path; cannot build a DESeries.');
    end
    if isa(t, 'tse.TSeries')
        ax = DEAxis(tse.daec.to_date(t.firstdate), size(t.values, 1));
        s  = DESeries(ax, t.values);
    elseif isa(t, 'tse.MVTSeries')
        ax1 = DEAxis(tse.daec.to_date(t.firstdate), size(t.values, 1));
        ax2 = DEAxis(cellstr(t.colnames));
        s   = DESeries([ax1, ax2], t.values);
    else
        error('tseries:noMatch', ...
            'to_series expects a tse.TSeries or tse.MVTSeries (got %s).', class(t));
    end
end
