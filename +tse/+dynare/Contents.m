% TSE.DYNARE  Interop helpers between TimeSeriesEcon.m and Dynare's dseries.
%
% Round-trip conversions between Dynare dseries / dates / databases and the
% tse.* equivalents.  Nothing else in +tse/ depends on Dynare being installed;
% these helpers only check for it at call time.
%
% Availability
%   isavailable      - true iff Dynare's dseries / dates classes are on the path
%   startup          - addpath + check_conflicts wrapper
%   check_conflicts  - list bare names shadowed by both libraries
%
% Frequency
%   freq_to_dynare   - tse.Frequency -> Dynare freq code (1, 2, 4, 12, 52, 365)
%   freq_from_dynare - Dynare freq code -> tse.Frequency instance
%
% Dates and ranges
%   from_date        - 1-element Dynare dates -> tse.MIT
%   to_date          - tse.MIT -> 1-element Dynare dates
%   from_range       - multi-element Dynare dates -> tse.MITRange
%   to_range         - tse.MITRange -> Dynare dates (contiguous)
%
% Series and databases
%   from_dseries     - Dynare dseries -> tse.TSeries / tse.MVTSeries
%   to_dseries       - tse.TSeries / tse.MVTSeries -> Dynare dseries
%   from_db          - struct of Dynare dseries -> struct of tse.* series
%   to_db            - struct of tse.* series -> struct of Dynare dseries
%
% Not supported:
%   Dynare's dates has no business-day frequency; to_dseries on a BDaily tse
%   series errors with a clear message (convert to Daily first).
