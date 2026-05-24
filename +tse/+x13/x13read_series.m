function out = x13read_series(file, F)
%X13READ_SERIES  Read an X13 saved series file into a TSeries or MVTSeries.
%
%   F is the tse.Frequency of the run.  Files with a single data column become a
%   TSeries; multiple columns become an MVTSeries.
    tab = sprintf('\t');
    lines = strsplit(fileread(file), newline, 'CollapseDelimiters', false);
    headers = strsplit(lines{1}, tab);
    headers = headers(2:end);
    headers = cellfun(@tse.x13.sanitize_colname, headers, 'UniformOutput', false);
    nh = numel(headers);

    s0 = strsplit(lines{3}, tab);
    lastcol = numel(s0);
    if lastcol > nh + 1 && isempty(strtrim(s0{end}))
        lastcol = lastcol - 1;
    end

    datalines = lines(3:end-1);
    n = numel(datalines);
    vals = nan(n, max(nh, 1));
    for i = 1:n
        cols = strsplit(datalines{i}, tab);
        hi = cols(2:min(lastcol, numel(cols)));
        for j = 1:numel(hi)
            v = str2double(hi{j});
            if ~isnan(v), vals(i, j) = v; end
        end
    end

    [y, p] = local_period(strtrim(s0{1}));
    start = tse.MIT(F, y, p);
    if nh > 1
        out = tse.MVTSeries(start, string(headers), vals);
    elseif nh == 0
        out = tse.TSeries(start:(start + (n - 1)));
    else
        out = tse.TSeries(start, vals(:, 1));
    end
end

function [y, p] = local_period(ps)
    C = tse.x13.x13consts();
    if numel(ps) > 2
        first3 = lower(ps(1:min(3, numel(ps))));
        if isKey(C.months_and_quarters, first3)
            p = C.months_and_quarters(first3);
            y = 1;
        else
            p = str2double(ps(end-1:end));
            y = str2double(ps(1:end-2));
        end
    else
        error('tseries:noMatch', 'Period string has an unexpected format: %s.', ps);
    end
end
