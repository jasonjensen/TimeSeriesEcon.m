function out = from_dseries(ds)
%FROM_DSERIES  Convert a Dynare dseries into a tse.TSeries or tse.MVTSeries.
%
%   t = tse.dynare.from_dseries(ds)
%
%   Single-variable input -> tse.TSeries.  Multi-variable input -> tse.MVTSeries,
%   with ds.name mapped to column names (blank/duplicate names are sanitised
%   into col1...colN and made unique).
%
%   Requires Dynare on the path; see tse.dynare.isavailable.
    if ~tse.dynare.isavailable()
        error('tseries:noMatch', ...
            'Dynare is not on the path; cannot read a Dynare dseries.');
    end
    if ~isa(ds, 'dseries')
        error('tseries:noMatch', 'from_dseries expects a Dynare dseries.');
    end

    start = tse.dynare.from_date(ds.dates(1));
    data  = ds.data;
    sz    = size(data);
    if numel(sz) > 2
        error('tseries:noMatch', ...
            'Only 2-D Dynare dseries are supported (received %d-D).', numel(sz));
    end
    if sz(2) > 1
        names = local_clean_names(ds.name, sz(2));
        out   = tse.MVTSeries(start, names, data);
    else
        out = tse.TSeries(start, data(:));
    end
end

function names = local_clean_names(raw, ncols)
    if ischar(raw)
        raw = {raw};
    elseif isstring(raw)
        raw = cellstr(raw);
    elseif ~iscell(raw)
        raw = {};
    end
    out = cell(1, ncols);
    for i = 1:ncols
        if i <= numel(raw) && ~isempty(strtrim(char(raw{i})))
            out{i} = char(raw{i});
        else
            out{i} = sprintf('col%d', i);
        end
    end
    names = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName(out));
end
