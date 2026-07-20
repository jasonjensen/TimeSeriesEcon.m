function val = read_object(dbkey, name)
%READ_OBJECT  Read one named object from an open FAME database.
%
%   v = tse.fame.read_object(dbkey, name)
%
%   Handles both series and scalar objects (fame_quick_info reports the
%   class).  Return value depends on the FAME element type:
%     precision/numeric/boolean -> tse.TSeries (series) or a scalar
%                                  double/single/logical (scalar)
%     string                    -> a string array (series) or a scalar string
%     date                      -> a tse.MIT array (series) or a scalar tse.MIT
%
%   Series/date/string with no tse container are returned as bare arrays (tse
%   has no string- or date-valued TSeries).  A date object stores its value
%   frequency in the `type` field, so `type` is a FAME frequency code rather
%   than a scalar type code.  Namelists (type HNAMEL) are not supported in this
%   version and raise an error.  Requires the CHLI loaded.
%
%   See also: tse.fame.read, tse.fame.write_object.
    info = tse.fame.CHLI.quick_info(dbkey, name);
    K = fame_constants();
    switch info.class
        case K.HSERIE
            isScalar = false;
            nobs = info.last - info.first + 1;
            r    = tse.fame.CHLI.make_range(info.freq, info.first, info.last);
        case K.HSCALA
            isScalar = true;
            nobs = 1;
            % A scalar has undefined frequency and 0:0 indices, so no valid
            % range can be built; read it with a NULL range as FAME.jl does
            % (Read.jl: do_read!(scalar) passes C_NULL).
            r    = tse.fame.CHLI.null_range();
        otherwise
            error('tseries:fame', ...
                'read_object supports series and scalar objects (%s has class %d).', ...
                name, info.class);
    end

    % Namelists (scalar of type HNAMEL) are not supported in this version: the
    % value cannot be read back under MATLAB's calllib (cfmgtnl does not return
    % the value buffer).  See the FAME namelist note in lore/FAME_INTEROP.md.
    if info.type == K.HNAMEL
        error('tseries:fame', ...
            'FAME namelists are not supported in this version (object %s).', name);
    end

    % A date-valued object stores its value frequency in the type field, so
    % type is a valid FAME frequency code (freq_from_fame succeeds).
    isDate = false;
    try
        tse.fame.freq_from_fame(info.type);
        isDate = true;
    catch
        isDate = false;
    end

    if isDate
        raw  = tse.fame.CHLI.get_dates(dbkey, name, r, nobs);
        Fval = tse.fame.freq_from_fame(info.type);
        mits(nobs, 1) = tse.MIT();
        for i = 1:nobs
            [yy, pp] = tse.fame.CHLI.index_to_yp(info.type, raw(i));
            mits(i, 1) = tse.MIT(Fval, yy, pp);
        end
        val = local_scalarize(mits, isScalar);
        return
    end

    cls = tse.fame.type_from_fame(info.type);
    switch cls
        case 'string'
            s = tse.fame.CHLI.get_strings(dbkey, name, r, nobs);
            val = local_scalarize(s, isScalar);
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

    if isScalar
        val = data(1);
    else
        [year, period] = tse.fame.CHLI.index_to_yp(info.freq, info.first);
        F = tse.fame.freq_from_fame(info.freq);
        val = tse.TSeries(tse.MIT(F, year, period), data(:));
    end
end

function v = local_scalarize(arr, isScalar)
    if isScalar
        v = arr(1);
    else
        v = arr;
    end
end
