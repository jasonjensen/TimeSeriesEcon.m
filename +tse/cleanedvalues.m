function out = cleanedvalues(t, varargin)
%CLEANEDVALUES  Return values of a BDaily TSeries/MVTSeries filtered by
%holiday map or NaN removal.
%
%   v = tse.cleanedvalues(t)
%   v = tse.cleanedvalues(t, 'skip_all_nans', true)
%   v = tse.cleanedvalues(t, 'skip_holidays', true)
%   v = tse.cleanedvalues(t, 'holidays_map', map)
%
%   For a TSeries, returns a column vector.
%   For an MVTSeries, returns a matrix (rows = filtered observations).
%
%   Options (priority order: holidays_map > skip_all_nans > skip_holidays):
%     'holidays_map'   - A BDaily boolean TSeries (true = business day).
%     'skip_all_nans'  - Remove rows where value is NaN.
%     'skip_holidays'  - Use the stored holidays map from
%                        tse.getoption('bdaily_holidays_map').
%
%   See also: tse.set_holidays_map, tse.getoption.

    p = inputParser;
    addParameter(p, 'skip_all_nans', false);
    addParameter(p, 'skip_holidays', false);
    addParameter(p, 'holidays_map', []);
    parse(p, varargin{:});

    skip_all_nans = p.Results.skip_all_nans;
    skip_holidays = p.Results.skip_holidays;
    holidays_map  = p.Results.holidays_map;

    if isa(t, 'tse.MVTSeries')
        out = cleanedvalues_mvts(t, skip_all_nans, skip_holidays, holidays_map);
    elseif isa(t, 'tse.TSeries')
        out = cleanedvalues_ts(t, skip_all_nans, skip_holidays, holidays_map);
    else
        error('tse:cleanedvalues', ...
            'cleanedvalues requires a TSeries or MVTSeries input.');
    end
end

function out = cleanedvalues_ts(t, skip_all_nans, skip_holidays, holidays_map)
    if ~isa(tse.frequencyof(t), 'tse.BDaily')
        error('tse:cleanedvalues', ...
            'cleanedvalues is only supported for BDaily frequency.');
    end

    if ~isempty(holidays_map)
        out = bdvalues_ts(t, holidays_map);
    elseif skip_all_nans
        v = t.values;
        out = v(~isnan(v));
    elseif skip_holidays
        hmap = tse.getoption('bdaily_holidays_map');
        if ~isa(hmap, 'tse.TSeries')
            error('tse:cleanedvalues', ...
                ['The holidays map stored in bdaily_holidays_map is not a TSeries. ' ...
                 'You may need to load one with tse.set_holidays_map().']);
        end
        out = bdvalues_ts(t, hmap);
    else
        out = t.values;
    end
end

function out = bdvalues_ts(t, holidays_map)
    rng = tse.rangeof(t);
    slice = holidays_map(rng);
    mask = logical(slice.values);
    v = t.values;
    out = v(mask);
end

function out = cleanedvalues_mvts(t, skip_all_nans, skip_holidays, holidays_map)
    if ~isa(tse.frequencyof(t), 'tse.BDaily')
        error('tse:cleanedvalues', ...
            'cleanedvalues is only supported for BDaily frequency.');
    end

    if ~isempty(holidays_map)
        out = bdvalues_mvts(t, holidays_map);
    elseif skip_all_nans
        vals = t.values;
        % Keep rows where ALL columns are not NaN
        valid = all(~isnan(vals), 2);
        out = vals(valid, :);
    elseif skip_holidays
        hmap = tse.getoption('bdaily_holidays_map');
        if ~isa(hmap, 'tse.TSeries')
            error('tse:cleanedvalues', ...
                ['The holidays map stored in bdaily_holidays_map is not a TSeries. ' ...
                 'You may need to load one with tse.set_holidays_map().']);
        end
        out = bdvalues_mvts(t, hmap);
    else
        out = t.values;
    end
end

function out = bdvalues_mvts(t, holidays_map)
    rng = tse.rangeof(t);
    slice = holidays_map(rng);
    mask = logical(slice.values);
    vals = t.values;
    out = vals(mask, :);
end
