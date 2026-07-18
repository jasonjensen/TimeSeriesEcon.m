% TSE.FAME  Interop helpers between TimeSeriesEcon.m and FAME databases.
%
% Read and write FAME (.db) time-series databases from TimeSeriesEcon.m,
% modelled on the Bank of Canada's FAME.jl package and built on the FAME
% CHLI (C Host Language Interface).  Nothing else in +tse/ depends on FAME
% being installed; these helpers only reach for the CHLI at call time.
%
% Unlike the IRIS and DataEcon bridges (which wrap MATLAB-level toolboxes),
% FAME is reached through its C library, so a small singleton loader class
% (tse.fame.CHLI, added in a later step) owns loadlibrary/calllib.
%
% Frequency and type mapping (pure MATLAB; no CHLI needed) -- IMPLEMENTED
%   freq_to_fame    - tse.Frequency -> FAME frequency code
%   freq_from_fame  - FAME frequency code -> tse.Frequency
%   type_to_fame    - MATLAB value  -> FAME type code (numeric/precision/...)
%   type_from_fame  - FAME type code -> MATLAB class
%
% CHLI loader and dates (require the CHLI; startup loads it) -- IMPLEMENTED
%   CHLI            - singleton loader: loadlibrary/calllib, cfmini, errors
%   isavailable     - true iff the CHLI is loaded
%   startup         - load the chli library and initialise it
%   to_date         - tse.MIT      -> FAME date index (constant-offset method)
%   from_date       - FAME date index -> tse.MIT
%   to_range        - tse.MITRange -> FAME range descriptor {freq,first,last}
%   from_range      - FAME range descriptor -> tse.MITRange
%
% Planned in later steps (each grounded in FAME.jl + the CHLI reference):
%   to_series / from_series     - tse.TSeries / tse.MVTSeries <-> FAME series
%   read / write                - open a FAME db and read/write a struct of
%                                 tse.* series (all FAME types: precision,
%                                 numeric, boolean, string, date; scalars and
%                                 namelists)
%   to_db / from_db             - in-memory struct conversion
%
% FAME frequencies with no TimeSeriesEcon.m analogue (tenday, twicemonthly,
% bimonthly, biweekly, sub-daily, ppy/ypp, weekly_pattern) are rejected with
% a clear message, as +tse/+iris rejects BDaily.
