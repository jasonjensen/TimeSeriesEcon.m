function startup(dynarePath)
%STARTUP  Convenience wrapper to add Dynare's matlab/ folder to the path.
%
%   tse.dynare.startup()                            just report conflicts
%   tse.dynare.startup('/opt/dynare/matlab')        addpath then report
%
%   Dynare's dseries / dates classes live in the matlab/ subfolder of the
%   install.  This helper does NOT call Dynare's full configuration (that
%   sets up paths for the whole modelling toolchain via `dynare_config` /
%   `dynare myfile.mod`); for plain dseries interop, addpath is enough.
%
%   Invalidates the tse.dynare.isavailable cache after touching the path.
    if nargin >= 1 && ~isempty(dynarePath)
        if exist(dynarePath, 'dir') ~= 7
            error('tseries:noMatch', 'Dynare directory not found: %s', dynarePath);
        end
        addpath(dynarePath);
    end
    tse.dynare.isavailable('invalidate');
    if tse.dynare.isavailable()
        tse.dynare.check_conflicts();
    else
        warning(['Dynare''s dseries / dates classes are still not on the ', ...
                 'path; you may need to add dynare/matlab/.']);
    end
end
