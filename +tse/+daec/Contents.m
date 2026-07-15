% TSE.DAEC  Interop helpers between TimeSeriesEcon.m and DataEcon (.daec).
%
% Round-trip conversions between DataEcon's MATLAB classes (DEDate, DESeries,
% DEFile) and the tse.* equivalents.  Nothing else in +tse/ depends on
% DataEcon being installed; these helpers only check for it at call time.
%
% Unlike the IRIS bridge, no frequency remapping is needed: DataEcon is the C
% backend for TimeSeriesEcon.jl, and tse's MATLAB port matches it bit-for-bit
% -- the tse frequency codes ARE DataEcon's frequency_t enum, and both store
% dates as the same rata die / period-since-epoch integer.  So MIT<->DEDate is
% the identity on (frequency, value); only file I/O needs the native libdaec.
%
% Availability
%   isavailable    - true iff the DataEcon MATLAB classes are on the path
%   startup        - addpath the DataEcon matlab/ folder and load libdaec
%
% Dates and ranges (these layers need no native library)
%   to_date        - tse.MIT      -> DataEcon DEDate
%   from_date      - DataEcon DEDate -> tse.MIT
%   to_range       - tse.MITRange -> DataEcon range DEAxis
%   from_range     - DataEcon range DEAxis -> tse.MITRange
%
% Series (object conversion needs no native library; only file I/O does)
%   to_series      - tse.TSeries / tse.MVTSeries -> DataEcon DESeries
%   from_series    - DataEcon DESeries -> tse.TSeries / tse.MVTSeries
%
% File I/O and database helpers (read / write, to_db / from_db) are added in
% the next step of the integration; those wrap DEFile and require libdaec.
