function shutdown()
%SHUTDOWN  Finalise the FAME HLI and unload the shared library.
%
%   tse.fame.shutdown()
%
%   Calls cfmfin (no-op if the HLI was never initialised) and then
%   unloadlibrary('hli').  Also invalidates tse.fame.isavailable's cache so
%   the next call re-probes.  Safe to call more than once.
    if libisloaded('hli')
        status = int32(0);
        pStatus = libpointer('int32Ptr', status);
        try
            calllib('hli', 'cfmfin', pStatus);
        catch
            % cfmfin can complain if the HLI was never initialised; ignore.
        end
        try
            unloadlibrary('hli');
        catch
            % likely already unloaded; ignore.
        end
    end
    tse.fame.isavailable('invalidate');
end
