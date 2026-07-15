function tf = isavailable(action)
%ISAVAILABLE  True iff the IRIS Toolbox is on the MATLAB path.
%
%   tf = tse.iris.isavailable()             cached check (cheap after first call)
%   tse.iris.isavailable('invalidate')      drop the cache (e.g. after addpath)
%
%   Detection probes for IRIS's public date decoder dat2ypf, which is present
%   in all 2015+ vintages of the toolbox.
    persistent cached
    if nargin > 0 && (ischar(action) || isstring(action)) ...
            && strcmpi(char(action), 'invalidate')
        cached = [];
        tf = false;
        return
    end
    if isempty(cached)
        cached = exist('dat2ypf', 'file') == 2;
    end
    tf = cached;
end
