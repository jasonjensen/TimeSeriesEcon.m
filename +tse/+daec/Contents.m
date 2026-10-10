% TSE.DAEC  Read and write DataEcon (.daec) files.
%
% .daec files are SQLite databases written by DataEcon, the library behind
% TimeSeriesEcon.jl's DataEcon module and tsecon.dataecon in Python, so a
% file written here reads there and back.  The library ships with tse for
% Windows, Linux and macOS; nothing else needs installing.
%
% The tse frequency codes ARE DataEcon's frequency_t enum, and both store
% dates as the same integer, so dates need no conversion.
%
% Files (the names follow TimeSeriesEcon.jl)
%   readdb         - read a file, or a catalog in it, into a struct
%   writedb        - write a struct to a file
%   opendaec       - open a file as a tse.daec.File, for finer control
%   opendaecmem    - open an in-memory file
%   closedaec      - close a file
%   File           - an open file: catalogs, attributes, store_*/load_*
%   read, write    - readdb, and writedb into an emptied file
%
% Arrays in any layout
%   Axis           - one dimension: plain, a date range, or names
%   Array          - values with one Axis per dimension, in any order
%
% Native library (bundled for Windows, Linux and macOS; see
% private/bin/README.md)
%   version        - version of the libdaec in use
%
% Interop with DataEcon's own MATLAB classes (DEDate, DEAxis, DESeries),
% which need DataEcon's matlab/ folder on the path
%   isavailable    - true iff the DataEcon MATLAB classes are on the path
%   startup        - addpath the DataEcon matlab/ folder and load its libdaec
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
% Databases (in-memory struct conversion; no native library)
%   to_db          - struct of tse.* series -> struct of DESeries
%   from_db        - struct of DESeries -> struct of tse.* series
%
