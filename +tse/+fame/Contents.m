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
% Series (require the CHLI).  Read+write: precision (double), numeric
% (single), boolean (logical) as tse.TSeries.  Read-only, as bare arrays
% (tse has no container for them): string series -> string array, date
% series -> tse.MIT array.  Missing values: NaN <-> NC; NC/NA/ND -> NaN.
%   read            - read a FAME db into a struct: named objects, or the
%                     whole database by enumeration when no names are given
%   write           - write a struct of tse.TSeries into a FAME db (posts it)
%   read_object     - read one named object from an open db
%   write_object    - write a tse.TSeries into an open db
%
% Scalars: a struct field that is a plain value (double/single/logical, a
% scalar string, or a scalar tse.MIT) is written as a FAME scalar and read
% back as that value.
%
% Namelists: a non-scalar string array field is written as a FAME namelist
% and read back as a string array of names.
%
% (MVTSeries has no FAME equivalent -- out of scope.)
%
% FAME frequencies with no TimeSeriesEcon.m analogue (tenday, twicemonthly,
% bimonthly, biweekly, sub-daily, ppy/ypp, weekly_pattern) are rejected with
% a clear message, as +tse/+iris rejects BDaily.
