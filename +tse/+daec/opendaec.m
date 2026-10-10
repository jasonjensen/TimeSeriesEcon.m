function de = opendaec(fname, varargin)
%OPENDAEC  Open a .daec file.
%
%   de = tse.daec.opendaec('data.daec')                  read-only
%   de = tse.daec.opendaec('data.daec', 'write', true)   read and write,
%                                                        created if missing
%   Options, as in TimeSeriesEcon.jl:
%     'readonly'   (true)   'write' is its opposite and wins if both are set
%     'append'     (true)   false empties the file after opening;
%                           'truncate' is its opposite and wins
%     'overwrite'  (false)  true replaces an existing object of the same
%                           name when storing; false makes that an error
%
%   Close the file with de.close() or tse.daec.closedaec(de); it is also
%   closed when de is cleared.  See tse.daec.File for what it can do.
%
%   See also tse.daec.opendaecmem, tse.daec.readdb, tse.daec.writedb.
    opts = struct('readonly', true, 'write', [], 'append', true, ...
        'truncate', [], 'overwrite', false);
    if mod(numel(varargin), 2) ~= 0
        error('tseries:noMatch', 'Options come in name, value pairs.');
    end
    for k = 1:2:numel(varargin)
        key = lower(char(varargin{k}));
        if ~isfield(opts, key)
            error('tseries:noMatch', 'Unknown option ''%s''.', key);
        end
        opts.(key) = logical(varargin{k + 1});
    end
    readonly = opts.readonly;
    if ~isempty(opts.write)
        readonly = ~opts.write;
    end
    truncate = ~opts.append;
    if ~isempty(opts.truncate)
        truncate = opts.truncate;
    end
    if truncate && readonly
        error('tseries:noMatch', 'Cannot truncate a read-only file.');
    end
    fname = char(fname);
    if strcmp(fname, ':memory:')
        error('tseries:noMatch', 'Use tse.daec.opendaecmem for an in-memory file.');
    end
    de = tse.daec.File(fname, readonly, opts.overwrite);
    if truncate
        de.truncate();
    end
end
