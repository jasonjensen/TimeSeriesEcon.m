function startup(daecPath)
%STARTUP  Add the DataEcon MATLAB classes to the path and load libdaec.
%
%   tse.daec.startup()               (re)load libdaec, assuming the DataEcon
%                                    matlab/ folder is already on the path
%   tse.daec.startup('/path/DataEcon/matlab')
%                                    addpath that folder first, then load
%
%   Always invalidates the tse.daec.isavailable cache after touching the
%   path.  A failure to load the native library is reported as a warning,
%   not an error, because the MIT<->DEDate date mapping still works without
%   it -- only file I/O and calendar unpacking need the library.
    if nargin >= 1 && ~isempty(daecPath)
        if exist(daecPath, 'dir') ~= 7
            error('tseries:noMatch', 'DataEcon matlab directory not found: %s', daecPath);
        end
        addpath(daecPath);
    end
    tse.daec.isavailable('invalidate');
    if ~tse.daec.isavailable()
        warning('DataEcon MATLAB classes are not on the path after startup.');
        return
    end
    try
        DAEC.load();
    catch e
        warning('DataEcon classes found but libdaec failed to load: %s', e.message);
    end
end
