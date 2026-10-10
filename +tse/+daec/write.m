function write(path, db)
%WRITE  Replace the contents of a .daec file with a struct.
%
%   tse.daec.write('data.daec', db)
%
%   Same as tse.daec.writedb(path, db, 'append', false): the file is
%   emptied first.  See also tse.daec.writedb.
    if ~isstruct(db)
        error('tseries:noMatch', ...
            'write expects a struct database (got %s). Wrap a single series in a struct.', class(db));
    end
    tse.daec.writedb(path, db, 'append', false);
end
