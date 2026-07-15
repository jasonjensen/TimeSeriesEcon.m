function startup(irisPath)
%STARTUP  Convenience wrapper to add IRIS to the path and report conflicts.
%
%   tse.iris.startup()              just call irisstartup and check_conflicts
%   tse.iris.startup('/opt/IRIS')   addpath then irisstartup then check_conflicts
%
%   Always invalidates the tse.iris.isavailable cache after touching the path.
    if nargin >= 1 && ~isempty(irisPath)
        if exist(irisPath, 'dir') ~= 7
            error('tseries:noMatch', 'IRIS directory not found: %s', irisPath);
        end
        addpath(irisPath);
    end
    if exist('irisstartup', 'file') == 2
        irisstartup();
    end
    tse.iris.isavailable('invalidate');
    if tse.iris.isavailable()
        tse.iris.check_conflicts();
    else
        warning('IRIS Toolbox is still not on the MATLAB path after startup.');
    end
end
