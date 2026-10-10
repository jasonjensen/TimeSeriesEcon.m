function data = readdb(src, catalog)
%READDB  Read a .daec file, or one catalog in it, into a struct.
%
%   db = tse.daec.readdb('data.daec')
%   db = tse.daec.readdb('data.daec', '/models')
%   db = tse.daec.readdb(de)          de from tse.daec.opendaec
%
%   Catalogs become nested structs, with fields in name order (libdaec
%   lists catalogs by name, so field order is not kept).  Arrays with a range axis come back as
%   tse.TSeries, a range and a names axis as tse.MVTSeries, plain arrays as
%   MATLAB arrays, and other layouts as tse.daec.Array.  Scalars come back
%   as numbers (of the stored width, e.g. int32 or single), char, logical,
%   tse.MIT or tse.Duration.  Objects that fail to load are skipped with a
%   warning.
%
%   See also tse.daec.writedb, tse.daec.File.
    if isa(src, 'tse.daec.File')
        de = src;
    else
        de = tse.daec.opendaec(src);
        closer = onCleanup(@() de.close()); %#ok<NASGU>
    end
    if nargin < 2
        data = de.readdb();
    else
        data = de.readdb(catalog);
    end
end
