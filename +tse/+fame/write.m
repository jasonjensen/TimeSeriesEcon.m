function write(dbname, db, mode)
%WRITE  Write a struct of tse.TSeries into a FAME database file.
%
%   tse.fame.write('data.db', db)            overwrite (HOMODE)
%   tse.fame.write('data.db', db, mode)      explicit FAME access mode
%
%   Each field of `db` that is a tse.TSeries is stored as a FAME series under
%   the field name; other fields are skipped with a warning (broader type
%   support comes in a later step).  The database is posted before closing.
%   Requires the CHLI to be loaded (tse.fame.startup).
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
        else
            warning('tseries:fame', ...
                'Skipping field %s (unsupported type %s in this version).', fns{i}, class(v));
        end
    end
    tse.fame.CHLI.postdb(dbkey);
end
