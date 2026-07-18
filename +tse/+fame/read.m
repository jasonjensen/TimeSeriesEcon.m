function db = read(dbname, names)
%READ  Read series from a FAME database file into a struct of TSeries.
%
%   db = tse.fame.read('data.db')                read every object
%   db = tse.fame.read('data.db', {'gdp','cpi'}) read the named objects
%   db = tse.fame.read('data.db', 'gdp')
%
%   With no name list, the whole database is enumerated (fame_*_wildcard).
%   Each struct field is the object name made into a valid MATLAB field
%   name.  Objects this version cannot read (non-series, or types other than
%   precision/numeric) are skipped with a warning.  Requires the CHLI loaded.
%
%   See also: tse.fame.write, tse.fame.read_object.
    tse.fame.CHLI.ensure_loaded();
    K = fame_constants();
    dbkey = tse.fame.CHLI.opendb(dbname, K.HRMODE);
    closer = onCleanup(@() tse.fame.CHLI.closedb(dbkey)); %#ok<NASGU>

    if nargin < 2 || isempty(names)
        objs  = tse.fame.CHLI.list_objects(dbkey);
        names = {objs.name};
    elseif ischar(names) || isstring(names)
        names = cellstr(names);
    end

    db = struct();
    for i = 1:numel(names)
        nm = char(names{i});
        try
            db.(matlab.lang.makeValidName(nm)) = tse.fame.read_object(dbkey, nm);
        catch e
            warning('tseries:fame', 'Skipping object "%s": %s', nm, e.message);
        end
    end
end
