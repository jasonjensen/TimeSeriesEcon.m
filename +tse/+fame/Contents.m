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
% Planned in later steps (each grounded in FAME.jl + the CHLI reference):
%   CHLI            - singleton loader: loadlibrary/calllib, init, error checks
%   isavailable / startup       - gate on the CHLI being loadable
%   to_date / from_date         - tse.MIT <-> FAME date index (via the CHLI)
%   to_range / from_range       - tse.MITRange <-> FAME range
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
