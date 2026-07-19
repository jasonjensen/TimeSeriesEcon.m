function val = read_object(dbkey, name)
%READ_OBJECT  Read one named series from an open FAME database into a TSeries.
%
%   t = tse.fame.read_object(dbkey, name)
%
%   Uses the modern FAME API (as FAME.jl does): fame_quick_info for the
%   class/type/frequency and first/last date index, then a typed range read.
%   Supports precision (double), numeric (single), and boolean (logical)
%   series in this version.  Requires the CHLI loaded.
%
%   See also: tse.fame.read, tse.fame.write_object.
    info = tse.fame.CHLI.quick_info(dbkey, name);
    K = fame_constants();
    if info.class ~= K.HSERIE
        error('tseries:fame', ...
            'read_object supports series objects in this version (%s has class %d).', ...
            name, info.class);
    end
    cls  = tse.fame.type_from_fame(info.type);
    nobs = info.last - info.first + 1;
    r    = tse.fame.CHLI.make_range(info.freq, info.first, info.last);
    switch cls
        case 'double'
            data = tse.fame.CHLI.get_precisions(dbkey, name, r, nobs);
        case 'single'
            data = tse.fame.CHLI.get_numerics(dbkey, name, r, nobs);
        case 'logical'
            data = tse.fame.CHLI.get_booleans(dbkey, name, r, nobs);
        otherwise
            error('tseries:fame', ...
                'read_object supports precision/numeric/boolean series in this version (%s has type %d).', ...
                name, info.type);
    end
    % First MIT from the FAME first index, via (year, period) -- the inverse
    % of the write-side mapping, so the round-trip is exact.
    [year, period] = tse.fame.CHLI.index_to_yp(info.freq, info.first);
    F = tse.fame.freq_from_fame(info.freq);
    firstMIT = tse.MIT(F, year, period);
    val = tse.TSeries(firstMIT, data(:));
end
