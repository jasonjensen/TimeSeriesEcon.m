function tf = isavailable(action)
%ISAVAILABLE  True iff Dynare's dseries / dates classes are on the MATLAB path.
%
%   tf = tse.dynare.isavailable()             cached check
%   tse.dynare.isavailable('invalidate')      drop the cache (e.g. after addpath)
%
%   Probes for both classes (dseries and dates) so that converters can rely on
%   either being constructible.
    persistent cached
    if nargin > 0 && (ischar(action) || isstring(action)) ...
            && strcmpi(char(action), 'invalidate')
        cached = [];
        tf = false;
        return
    end
    if isempty(cached)
        cached = (exist('dseries', 'class') == 8 || exist('dseries', 'file') == 2) ...
              && (exist('dates',   'class') == 8 || exist('dates',   'file') == 2);
    end
    tf = cached;
end
