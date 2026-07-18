function startup()
%STARTUP  Load the FAME HLI library and initialise it.
%
%   tse.fame.startup()
%
%   Explicit counterpart to tse.fame.isavailable's lazy load: forces
%   loadlibrary and calls cfmini so the HLI is ready for use.  Errors if
%   the library cannot be loaded or if cfmini reports a non-zero status.
%
%   Pair with tse.fame.shutdown() to release the HLI at end of session.
    if ~tse.fame.isavailable()
        error('tseries:noMatch', ...
            'Cannot load libhli; see the warning above for details.');
    end
    status = int32(0);
    pStatus = libpointer('int32Ptr', status);
    calllib('hli', 'cfmini', pStatus);
    if pStatus.Value ~= 0
        error('tseries:noMatch', ...
            'cfmini failed with FAME status code %d.', pStatus.Value);
    end
end
