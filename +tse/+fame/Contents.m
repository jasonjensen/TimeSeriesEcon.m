% TSE.FAME  Interop helpers between TimeSeriesEcon.m and FAME databases.
%
% Read and write FAME time-series databases from MATLAB, using the FAME HLI
% (Host Language Interface) shared library via loadlibrary / calllib.  No
% MEX compilation is required at user install time: the loadlibrary
% prototype is committed to the repo.  Users only need
%
%   - a working FAME install with libhli reachable from the process
%     (LD_LIBRARY_PATH on Linux/macOS, PATH on Windows), the same way
%     FAME's own CLI expects it,
%   - and this package on the MATLAB path.
%
% Availability and lifecycle
%   isavailable      - true iff libhli can be loaded (lazy load)
%   startup          - explicit load + cfmini
%   shutdown         - cfmfin + unloadlibrary
%   regenerate_proto - maintainer helper: regenerate private/hli_proto.m
%                       from $FAME/hli(/64)/fame.h (requires a compiler)
%
% Frequency and dates                              [phase 2 -- not yet built]
%   freq_to_fame, freq_from_fame, from_index, to_index
%
% Database, series read / write                    [phases 3-5 -- not yet built]
%   opendb, Database, list, info, read, write, del, rename
%
% See FAME_INTEROP_PLAN.md for the full design; the phases roll out one
% commit at a time.
