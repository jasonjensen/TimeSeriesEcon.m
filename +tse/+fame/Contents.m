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
% Series read/write (require the CHLI) -- precision, numeric, boolean, string
%   read            - read a FAME db into a struct: named objects, or the
%                     whole database by enumeration when no names are given
%   write           - write a struct of tse.TSeries into a FAME db (posts it)
%   read_object     - read one named series from an open db  -> tse.TSeries
%   write_object    - write a tse.TSeries into an open db
%
% Missing values: NaN <-> FAME NC on write; NC/NA/ND -> NaN on read.
%
% Planned in later steps (each grounded in FAME.jl + the CHLI reference):
%   - date-valued series, and scalar / namelist objects
%   - weekly series (year/period reconstruction via the ISO-week path)
%   (MVTSeries has no FAME equivalent, so it is out of scope.)
%
% FAME frequencies with no TimeSeriesEcon.m analogue (tenday, twicemonthly,
% bimonthly, biweekly, sub-daily, ppy/ypp, weekly_pattern) are rejected with
% a clear message, as +tse/+iris rejects BDaily.
