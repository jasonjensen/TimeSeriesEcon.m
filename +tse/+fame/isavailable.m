function tf = isavailable(action)
%ISAVAILABLE  True iff the FAME HLI shared library can be loaded.
%
%   tf = tse.fame.isavailable()             cached; loads libhli on first call
%   tse.fame.isavailable('invalidate')      drops the cached result
%
%   Attempts loadlibrary('hli', @hli_proto) once and caches the outcome so
%   subsequent calls are cheap.  Returns false with a warning (that hints at
%   LD_LIBRARY_PATH / PATH) when the loader cannot resolve the library.
%   Idempotent: if libhli is already loaded the check is a no-op.
    persistent cached
    if nargin > 0 && (ischar(action) || isstring(action)) ...
            && strcmpi(char(action), 'invalidate')
        cached = [];
        tf = false;
        return
    end
    if ~isempty(cached)
        tf = cached;
        return
    end
    if libisloaded('hli')
        cached = true;
        tf = true;
        return
    end
    try
        loadlibrary('hli', @hli_proto);   % resolved via private/ folder
        cached = true;
    catch err
        warning('tseries:noMatch', ...
            ['loadlibrary(''hli'', @hli_proto) failed: %s\n', ...
             'Is libhli reachable via LD_LIBRARY_PATH (Linux/macOS) or PATH ', ...
             '(Windows)?  FAME''s own CLI would need the same setting.'], ...
            err.message);
        cached = false;
    end
    tf = cached;
end
