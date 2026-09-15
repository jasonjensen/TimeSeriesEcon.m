function t = from_series(s)
%FROM_SERIES  Convert a DataEcon DESeries into a tse.TSeries / tse.MVTSeries.
%
%   t = tse.daec.from_series(s)
%
%   A 1-axis (range) DESeries becomes a tse.TSeries; a 2-axis (range x names)
%   DESeries becomes a tse.MVTSeries.  Delegates to DAEC.make_tse_series so
%   the same conversion is used on the read path of DEFile.
    if ~isa(s, 'DESeries')
        error('tseries:noMatch', 'from_series expects a DESeries.');
    end
    t = DAEC.make_tse_series(s.axis, s.value);
end
