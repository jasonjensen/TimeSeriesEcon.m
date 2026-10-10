function writedb(dest, varargin)
%WRITEDB  Write a struct to a .daec file.
%
%   tse.daec.writedb('data.daec', db)
%   tse.daec.writedb('data.daec', '/models', db)    into an existing catalog
%   tse.daec.writedb('data.daec', db, 'append', false)
%                                     empty the file first
%   tse.daec.writedb(de, db)          de from tse.daec.opendaec
%
%   Each field is stored by its value: struct fields become catalogs,
%   tse.TSeries and tse.MVTSeries keep their dates and column names,
%   tse.daec.Array keeps its axes, and numbers, strings, logicals, tse.MIT
%   and tse.Duration are stored as scalars or arrays.  A file named by path
%   is created if needed and, as in TimeSeriesEcon.jl, appended to unless
%   'append' is false.  Fields that cannot be written are skipped with a
%   warning.
%
%   See also tse.daec.readdb, tse.daec.File.
    k = find(cellfun(@isstruct, varargin), 1);
    if isempty(k)
        error('tseries:noMatch', 'writedb needs a struct to write.');
    end
    args = varargin(1:k);
    options = varargin(k+1:end);
    if isa(dest, 'tse.daec.File')
        if ~isempty(options)
            error('tseries:noMatch', 'Options apply only when writedb opens the file.');
        end
        dest.writedb(args{:});
        return
    end
    de = tse.daec.opendaec(dest, 'write', true, options{:});
    closer = onCleanup(@() de.close()); %#ok<NASGU>
    de.writedb(args{:});
end
