function db = read(path)
%READ  Read a DataEcon .daec file into a struct of tse.* series.
%
%   db = tse.daec.read('data.daec')
%
%   Range-axis series come back as tse.TSeries, range x names series as
%   tse.MVTSeries, and nested catalogs as nested structs; other objects
%   (scalars, plain arrays, strings) come back as their native MATLAB
%   values.  Requires a loaded libdaec; call tse.daec.startup(daecPath)
%   first.
    if ~tse.daec.isavailable()
        error('tseries:noMatch', ...
            'DataEcon MATLAB classes are not on the path; cannot read a .daec file.');
    end
    if ~DAEC.isloaded()
        error('tseries:noMatch', ...
            'libdaec is not loaded; call tse.daec.startup(daecPath) before reading.');
    end
    db = DAEC.readdb(path, 'read_to_tse', true);
end
