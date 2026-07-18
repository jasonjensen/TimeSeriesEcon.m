function val = read_object(dbkey, name)
%READ_OBJECT  Read one named series from an open FAME database into a TSeries.
%
%   t = tse.fame.read_object(dbkey, name)
%
%   dbkey is an open database key (see tse.fame.CHLI.opendb).  This step
%   supports precision (double) and numeric (single) series; other classes /
%   types raise a clear error and are added in a later step.  Missing FAME
%   values come back as NaN.
%
%   See also: tse.fame.read, tse.fame.write_object.
    info = tse.fame.CHLI.whatis(dbkey, name);
    K = fame_constants();
    if info.class ~= K.HSERIE
        error('tseries:fame', ...
            'read_object supports series objects in this version (%s has class %d).', ...
            name, info.class);
    end
    cls = tse.fame.type_from_fame(info.type);
    if ~ismember(cls, {'double', 'single'})
        error('tseries:fame', ...
            'read_object supports precision/numeric series in this version (%s has type %d).', ...
            name, info.type);
    end
    [range, nobs] = tse.fame.CHLI.makerange(info.freq, info.fyear, info.fprd, info.lyear, info.lprd);
    data = tse.fame.CHLI.readrange(dbkey, name, range, nobs, cls);
    % Rebuild the first MIT from (freq, year, period) -- the inverse of the
    % mit2yp used on write, so the round-trip is exact.
    F = tse.fame.freq_from_fame(info.freq);
    firstMIT = tse.MIT(F, info.fyear, info.fprd);
    val = tse.TSeries(firstMIT, data(:));
end
