function db = read(dbname, names)
%READ  Read named series from a FAME database file into a struct of TSeries.
%
%   db = tse.fame.read('data.db', {'gdp','cpi'})
%   db = tse.fame.read('data.db', 'gdp')
%
%   `names` is required in this version -- database-wide enumeration (reading
%   every object without naming them) comes in a later step.  Each named
%   object is read via tse.fame.read_object; the struct field is the object
%   name made into a valid MATLAB field name.  Requires the CHLI to be loaded.
%
%   See also: tse.fame.write, tse.fame.read_object.
    tse.fame.CHLI.ensure_loaded();
    if nargin < 2 || isempty(names)
        error('tseries:fame', ...
            'read requires a list of object names in this version (db enumeration comes later).');
    end
    if ischar(names) || isstring(names)
        names = cellstr(names);
    end
    K = fame_constants();
    dbkey = tse.fame.CHLI.opendb(dbname, K.HRMODE);
    closer = onCleanup(@() tse.fame.CHLI.closedb(dbkey)); %#ok<NASGU>
    db = struct();
    for i = 1:numel(names)
        nm = char(names{i});
        db.(matlab.lang.makeValidName(nm)) = tse.fame.read_object(dbkey, nm);
    end
end
