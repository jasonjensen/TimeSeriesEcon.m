function val = read_object(dbkey, name)
%READ_OBJECT  Read one named series from an open FAME database.
%
%   v = tse.fame.read_object(dbkey, name)
%
%   Uses the modern FAME API (as FAME.jl does): fame_quick_info for the
%   class/type/frequency and first/last date index, then a typed range read.
%   Return value depends on the FAME element type:
%     precision/numeric/boolean -> tse.TSeries (double / single / logical)
%     string                    -> a string array (time axis not represented,
%                                  as tse has no string-valued series)
%     date                      -> a tse.MIT array (likewise a bare vector)
%
%   A date-valued series encodes its value frequency in the `type` field, so
%   `type` is a FAME frequency code rather than one of the scalar type codes.
%   Requires the CHLI loaded.
%
%   See also: tse.fame.read, tse.fame.write_object.
    info = tse.fame.CHLI.quick_info(dbkey, name);
    K = fame_constants();
    if info.class ~= K.HSERIE
        error('tseries:fame', ...
            'read_object supports series objects in this version (%s has class %d).', ...
            name, info.class);
    end
    nobs = info.last - info.first + 1;
    r    = tse.fame.CHLI.make_range(info.freq, info.first, info.last);

    % A date-valued series stores its value frequency in the type field, so
    % type is a valid FAME frequency code (freq_from_fame succeeds).
    isDateSeries = false;
    try
        tse.fame.freq_from_fame(info.type);
        isDateSeries = true;
    catch
        isDateSeries = false;
    end

    if isDateSeries
        raw  = tse.fame.CHLI.get_dates(dbkey, name, r, nobs);
        Fval = tse.fame.freq_from_fame(info.type);
        val(nobs, 1) = tse.MIT();
        for i = 1:nobs
            [yy, pp] = tse.fame.CHLI.index_to_yp(info.type, raw(i));
            val(i, 1) = tse.MIT(Fval, yy, pp);
        end
        return
    end

    cls = tse.fame.type_from_fame(info.type);
    switch cls
        case 'string'
            % tse has no string-valued series; return the bare string array.
            val = tse.fame.CHLI.get_strings(dbkey, name, r, nobs);
            return
        case 'double'
            data = tse.fame.CHLI.get_precisions(dbkey, name, r, nobs);
        case 'single'
            data = tse.fame.CHLI.get_numerics(dbkey, name, r, nobs);
        case 'logical'
            data = tse.fame.CHLI.get_booleans(dbkey, name, r, nobs);
        otherwise
            error('tseries:fame', ...
                'read_object: unsupported FAME type %d for %s.', info.type, name);
    end

    [year, period] = tse.fame.CHLI.index_to_yp(info.freq, info.first);
    F = tse.fame.freq_from_fame(info.freq);
    firstMIT = tse.MIT(F, year, period);
    val = tse.TSeries(firstMIT, data(:));
end
