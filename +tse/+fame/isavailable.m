function tf = isavailable(~)
%ISAVAILABLE  True iff the FAME CHLI is currently loaded.
%
%   tf = tse.fame.isavailable()
%
%   Because FAME is reached through a C library (not a MATLAB toolbox),
%   "available" means the CHLI has been loaded via tse.fame.startup.  The
%   optional argument is accepted and ignored for symmetry with the other
%   interop packages' isavailable helpers.
%
%   See also: tse.fame.startup, tse.fame.CHLI.
    tf = tse.fame.CHLI.isloaded();
end
