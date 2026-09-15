function write(path, db)
%WRITE  Write a database of tse.* series to a DataEcon .daec file.
%
%   tse.daec.write('data.daec', db)
%
%   db is a struct whose fields are tse.TSeries / tse.MVTSeries (and/or
%   plain scalars, vectors, matrices, strings, or nested structs -- DataEcon
%   stores those too).  The file is truncated and rewritten.  Requires a
%   loaded libdaec; call tse.daec.startup(daecPath) first.
    if ~tse.daec.isavailable()
        error('tseries:noMatch', ...
            'DataEcon MATLAB classes are not on the path; cannot write a .daec file.');
    end
    if ~DAEC.isloaded()
        error('tseries:noMatch', ...
            'libdaec is not loaded; call tse.daec.startup(daecPath) before writing.');
    end
    if ~isstruct(db)
        error('tseries:noMatch', ...
            'write expects a struct database (got %s). Wrap a single series in a struct.', class(db));
    end
    DAEC.writedb(path, db);
end
