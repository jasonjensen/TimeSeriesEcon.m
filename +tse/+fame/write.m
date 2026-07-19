function write(dbname, db, mode)
%WRITE  Write a struct of tse.TSeries into a FAME database file.
%
%   tse.fame.write('data.db', db)            overwrite (HOMODE)
%   tse.fame.write('data.db', db, mode)      explicit FAME access mode
%
%   Each field of `db` is stored under the field name: a tse.TSeries becomes
%   a FAME series; a scalar value (double/single/logical, a scalar string, or
%   a scalar tse.MIT) becomes a FAME scalar.  Anything else is skipped with a
%   warning.  The database is posted before closing.  Requires the CHLI to be
%   loaded (tse.fame.startup).
%
%   See also: tse.fame.read, tse.fame.write_object.
    if ~isstruct(db)
        error('tseries:noMatch', 'write expects a struct database (got %s).', class(db));
    end
    tse.fame.CHLI.ensure_loaded();
    K = fame_constants();
    if nargin < 3 || isempty(mode)
        mode = K.HOMODE;
    end
    dbkey = tse.fame.CHLI.opendb(dbname, mode);
    closer = onCleanup(@() tse.fame.CHLI.closedb(dbkey)); %#ok<NASGU>
    fns = fieldnames(db);
    for i = 1:numel(fns)
        v = db.(fns{i});
        if isa(v, 'tse.TSeries')
            tse.fame.write_object(dbkey, fns{i}, v);
        elseif (isstring(v) || iscellstr(v)) && ~isscalar(v)
            local_write_namelist(dbkey, fns{i}, v);   % a list of names
        elseif local_is_scalar(v)
            local_write_scalar(dbkey, fns{i}, v);
        else
            warning('tseries:fame', ...
                'Skipping field %s (unsupported type %s in this version).', fns{i}, class(v));
        end
    end
    tse.fame.CHLI.postdb(dbkey);
end

function local_write_namelist(dbkey, name, v)
    K = fame_constants();
    tse.fame.CHLI.newobj(dbkey, name, K.HSCALA, K.HUNDFT, K.HNAMEL, K.HBSDAY, K.HOBUND);
    str = strjoin(cellstr(string(v(:))), ', ');
    tse.fame.CHLI.write_namelist(dbkey, name, str);
end

function tf = local_is_scalar(v)
    tf = (isa(v, 'tse.MIT') && isscalar(v)) ...
      || ((isnumeric(v) || islogical(v)) && isscalar(v)) ...
      || (isstring(v) && isscalar(v)) ...
      || ischar(v);
end

function local_write_scalar(dbkey, name, v)
    K = fame_constants();
    % A FAME scalar has no time axis; frequency is undefined.
    if isa(v, 'tse.MIT')
        valfreq  = tse.fame.freq_to_fame(tse.frequencyof(v));
        type     = valfreq;                 % date scalar: type = value freq
        observed = K.HOBUND;
    elseif isstring(v) || ischar(v)
        type = K.HSTRNG;  observed = K.HOBUND;
    elseif islogical(v)
        type = K.HBOOLN;  observed = K.HOBUND;
    elseif isa(v, 'single')
        type = K.HNUMRC;  observed = K.HOBSUM;
    else
        type = K.HPRECN;  observed = K.HOBSUM;
    end
    tse.fame.CHLI.newobj(dbkey, name, K.HSCALA, K.HUNDFT, type, K.HBSDAY, observed);

    if isa(v, 'tse.MIT')
        yp  = tse.mit2yp(v);
        idx = tse.fame.CHLI.yp_to_index(valfreq, yp(1), yp(2));
        tse.fame.CHLI.write_dates(dbkey, name, [], valfreq, int64(idx));
    elseif isstring(v) || ischar(v)
        tse.fame.CHLI.write_strings(dbkey, name, [], string(v));
    elseif islogical(v)
        tse.fame.CHLI.write_booleans(dbkey, name, [], v);
    elseif isa(v, 'single')
        tse.fame.CHLI.write_numerics(dbkey, name, [], v);
    else
        tse.fame.CHLI.write_precisions(dbkey, name, [], v);
    end
end
