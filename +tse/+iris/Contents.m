% TSE.IRIS  Interop helpers between TimeSeriesEcon.m and the IRIS Toolbox.
%
% Round-trip conversions between IRIS tseries / dates / databases and the
% tse.* equivalents.  Nothing else in +tse/ depends on IRIS being installed;
% these helpers only check for it at call time.
%
% Availability
%   isavailable    - true iff IRIS Toolbox is on the path (cached)
%   startup        - addpath + irisstartup + check_conflicts wrapper
%   check_conflicts- list bare names shadowed by both libraries
%
% Frequency
%   freq_to_iris   - tse.Frequency -> IRIS freq code (1, 2, 4, 12, 52, 365, 0)
%   freq_from_iris - IRIS freq code -> tse.Frequency instance
%
% Dates and ranges
%   from_date      - IRIS date double -> tse.MIT
%   to_date        - tse.MIT -> IRIS date double
%   from_range     - IRIS date vector -> tse.MITRange
%   to_range       - tse.MITRange -> IRIS date vector
%
% Series and databases
%   from_tseries   - IRIS tseries -> tse.TSeries / tse.MVTSeries
%   to_tseries     - tse.TSeries / tse.MVTSeries -> IRIS tseries
%   from_db        - struct of IRIS tseries -> struct of tse.* series
%   to_db          - struct of tse.* series -> struct of IRIS tseries
%
% Not supported:
%   IRIS Toolbox 2015 has no business-day frequency; to_tseries on a BDaily
%   tse series errors with a clear message (convert to Daily first).
