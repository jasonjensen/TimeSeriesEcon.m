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
% Dates (this layer needs no native library)
%   to_date        - tse.MIT   -> DataEcon DEDate
%   from_date      - DataEcon DEDate -> tse.MIT
%
% Series, ranges, and databases are added in later steps of the integration
% (to_series / from_series, to_range / from_range, read / write, to_db /
% from_db).
