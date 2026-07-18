function tf = isavailable(action)
%ISAVAILABLE  True iff the DataEcon MATLAB classes are on the path.
%
%   tf = tse.daec.isavailable()          cached check (cheap after first call)
%   tse.daec.isavailable('invalidate')   drop the cache (e.g. after addpath)
%
%   Probes for the DEDate and DAEC classes that the +tse/+daec helpers use
%   to build DataEcon dates.  Loading the native libdaec library -- required
%   for file I/O and calendar unpacking, but NOT for the raw MIT<->DEDate
%   mapping -- is handled separately by tse.daec.startup.
    persistent cached
    if nargin > 0 && (ischar(action) || isstring(action)) ...
            && strcmpi(char(action), 'invalidate')
        cached = [];
        tf = false;
        return
    end
    if isempty(cached)
        cached = exist('DEDate', 'class') == 8 && exist('DAEC', 'class') == 8;
    end
    tf = cached;
end
