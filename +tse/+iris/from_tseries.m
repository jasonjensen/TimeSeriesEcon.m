function out = from_tseries(ts)
%FROM_TSERIES  Convert an IRIS tseries into a tse.TSeries or tse.MVTSeries.
%
%   t = tse.iris.from_tseries(iris_ts)
%
%   Single-column input -> tse.TSeries.  Multi-column input -> tse.MVTSeries,
%   with the IRIS Comment property mapped to column names (blank or duplicate
%   names are sanitised into col1...colN and made unique).
%
%   Requires IRIS on the path; see tse.iris.isavailable.
    if ~tse.iris.isavailable()
        error('tseries:noMatch', ...
            'IRIS Toolbox is not on the path; cannot read an IRIS tseries.');
    end
    if ~isa(ts, 'tseries')
        error('tseries:noMatch', 'from_tseries expects an IRIS tseries.');
    end

    startDate = startdate(ts);                 % IRIS public API
    data      = double(ts);                    % underlying matrix
    start     = tse.iris.from_date(startDate);

    sz = size(data);
    if numel(sz) > 2
        error('tseries:noMatch', ...
            'Only 2-D IRIS tseries are supported (received %d-D).', numel(sz));
    end
    if sz(2) > 1
        try
            comments = comment(ts);
        catch
            comments = {};
        end
        names = local_clean_names(comments, sz(2));
        out   = tse.MVTSeries(start, names, data);
    else
        out = tse.TSeries(start, data(:));
    end
end

function names = local_clean_names(comments, ncols)
    if ischar(comments)
        comments = {comments};
    elseif isstring(comments)
        comments = cellstr(comments);
    elseif ~iscell(comments)
        comments = {};
    end
    raw = cell(1, ncols);
    for i = 1:ncols
        if i <= numel(comments) && ~isempty(strtrim(char(comments{i})))
            raw{i} = char(comments{i});
        else
            raw{i} = sprintf('col%d', i);
        end
    end
    names = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName(raw));
end
