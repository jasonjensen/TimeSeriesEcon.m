function out = fconvert(varargin)
%FCONVERT  Convert an MIT, MITRange, or TSeries to another frequency.
%
%   y = tse.fconvert(F_to, x, 'name', value, ...)
%   y = tse.fconvert(fn, F_to, x, ...)        % custom aggregator/disaggregator
%
%   F_to may be a tse.Frequency instance (e.g. tse.Quarterly()), a class
%   name ('Quarterly'), or an integer frequency code.  x may be an MIT, an
%   MITRange, or a TSeries.
%
%   Name-value options (subset depending on direction):
%     'method'   : higher -> 'const'(default) | 'even' | 'linear'
%                  lower  -> 'mean'(default) | 'sum' | 'min' | 'max' |
%                            'point' | 'begin' | 'end'
%     'ref'      : 'begin' | 'end'(default) | (for some MIT paths) 'middle'
%     'trim'     : 'both'(default) | 'begin' | 'end'   (ranges)
%     'round_to' : 'previous' | 'next' | 'current'     (MIT -> BDaily)
%     'skip_all_nans' / 'skip_holidays' (logical), 'holidays_map' (BDaily TSeries)
%
%   This is a port of TimeSeriesEcon.jl's fconvert (src/fconvert).

    if nargin >= 1 && isa(varargin{1}, 'function_handle')
        fn   = varargin{1};
        F_to = varargin{2};
        x    = varargin{3};
        opts = varargin(4:end);
    else
        fn   = [];
        F_to = varargin{1};
        x    = varargin{2};
        opts = varargin(3:end);
    end
    Fto = coerce_freq(F_to);

    if isa(x, 'tse.MIT')
        out = mit_convert(Fto, x, opts);
    elseif isa(x, 'tse.MITRange')
        out = range_convert(Fto, x, opts);
    elseif isa(x, 'tse.TSeries')
        out = tseries_convert(Fto, x, fn, opts);
    else
        error('tseries:noMatch', 'fconvert: unsupported input of type %s.', class(x));
    end
end

% ======================================================================
% Frequency helpers
% ======================================================================

function F = coerce_freq(x)
    if isa(x, 'tse.Frequency')
        F = x;
    elseif isnumeric(x) && isscalar(x)
        F = int2freq(int32(x));
    elseif ischar(x) || isstring(x)
        F = tse.sanitize_frequency(x);
    else
        error('tseries:noMatch', 'fconvert: cannot interpret target frequency.');
    end
end

function tf = isYP(F),  tf = isa(F, 'tse.YPFrequency'); end
function tf = isCal(F), tf = isa(F,'tse.Daily') || isa(F,'tse.BDaily') || isa(F,'tse.Weekly'); end
function n  = ppyOf(F), n = double(F.PeriodsPerYear); end

function tf = freq_eq(a, b)
    tf = strcmp(class(a), class(b)) && (double(a.endPeriod) == double(b.endPeriod));
end

function v = getopt(opts, name, default)
    v = default;
    for k = 1:2:numel(opts)-1
        if (ischar(opts{k}) || isstring(opts{k})) && strcmpi(char(opts{k}), name)
            v = opts{k+1};
            return
        end
    end
end

function v = mvals(arr)
    v = zeros(1, numel(arr));
    for i = 1:numel(arr)
        v(i) = double(arr(i).value);
    end
end

function d = isodow(dt)
    % ISO day of week: Mon=1 .. Sun=7 (MATLAB weekday: Sun=1..Sat=7).
    d = mod(weekday(dt) + 5, 7) + 1;
end

% ======================================================================
% MIT-level conversion
% ======================================================================

function out = mit_convert(F_to, m, opts)
    F_from = int2freq(m.frequency);
    ref      = getopt(opts, 'ref', 'end');
    round_to = getopt(opts, 'round_to', []);
    if freq_eq(F_to, F_from)
        out = m;
        return
    end
    if isYP(F_to) && isYP(F_from)
        out = mit_yp_to_yp(F_to, m.value, F_from, ref);
    elseif isa(F_to, 'tse.BDaily')
        if isempty(round_to), round_to = 'previous'; end
        out = mit_to_bdaily(m, ref, round_to);
    elseif isa(F_to, 'tse.Daily')
        out = mit_to_daily(F_to, m, F_from, ref);
    elseif (isYP(F_to) || isa(F_to, 'tse.Weekly'))
        % calendar or YP source -> YP/Weekly via date boundary
        d = mitToDate(m, ref);
        idx = get_out_indices(F_to, d);
        out = idx(1);
    else
        error('tseries:noMatch', 'Conversion of MIT from %s to %s not implemented.', ...
            class(F_from), class(F_to));
    end
end

function out = mit_yp_to_yp(F_to, mv, F_from, ref)
    mv = double(mv);
    ref_adjust = double(strcmp(ref, 'end'));
    from_month = (mv + ref_adjust) * 12 / ppyOf(F_from) - ref_adjust;
    from_month = from_month - (12 / ppyOf(F_from) - double(F_from.endPeriod));
    out_period = (from_month + ref_adjust) / (12 / ppyOf(F_to)) - ref_adjust;
    if strcmp(ref, 'end')
        op = ceil(out_period);
    else
        op = floor(out_period);
    end
    out = tse.MIT(F_to, int64(op));
end

function out = mit_to_bdaily(m, ref, round_to)
    switch round_to
        case 'previous'
            out = tse.bdaily(mitToDate(m, ref), 'bias', 'previous');
        case 'next'
            out = tse.bdaily(mitToDate(m, ref), 'bias', 'next');
        case 'current'
            d = mitToDate(m);
            wd = weekday(d);   % 1=Sun .. 7=Sat
            if wd == 1 || wd == 7
                error('tseries:noMatch', ...
                    '%s is on a weekend. Pass round_to=''previous'' or ''next''.', char(d));
            end
            out = tse.bdaily(d);
        otherwise
            error('tseries:noMatch', ...
                'round_to must be ''current'', ''previous'', or ''next''. Received: %s', round_to);
    end
end

function out = mit_to_daily(F_to, m, F_from, ref)
    if isa(F_from, 'tse.BDaily')
        mv = double(m.value);
        md = mod(mv, 5);
        if md == 0, md = 5; end
        out = tse.MIT(F_to, int64(floor((mv - 1) / 5) * 7 + md));
    else
        out = tse.daily(mitToDate(m, ref));
    end
end

% ======================================================================
% Output-index helper (date -> target-frequency MIT)
% ======================================================================

function idx = get_out_indices(F_to, dates)
    dates = reshape(dates, 1, []);
    n = numel(dates);
    idx = repmat(tse.MIT(F_to, int64(0)), 1, n);
    if isa(F_to, 'tse.Weekly')
        ed = double(F_to.endPeriod);
        for k = 1:n
            idx(k) = tse.weekly(dates(k), ed);
        end
        return
    end
    yrs = year(dates);
    mos = month(dates);
    ep = double(F_to.endPeriod);
    if isa(F_to, 'tse.Monthly')
        for k = 1:n
            idx(k) = tse.MIT(F_to, int64(yrs(k)), int64(mos(k)));
        end
    elseif isa(F_to, 'tse.Quarterly')
        mos = mos + (3 - ep); o = mos > 12; yrs(o) = yrs(o) + 1; mos(o) = mos(o) - 12;
        for k = 1:n
            idx(k) = tse.MIT(F_to, int64(yrs(k)), int64(ceil(mos(k) / 3)));
        end
    elseif isa(F_to, 'tse.HalfYearly')
        mos = mos + (6 - ep); o = mos > 12; yrs(o) = yrs(o) + 1; mos(o) = mos(o) - 12;
        for k = 1:n
            idx(k) = tse.MIT(F_to, int64(yrs(k)), int64(ceil(mos(k) / 6)));
        end
    elseif isa(F_to, 'tse.Yearly')
        mos = mos + (12 - ep); o = mos > 12; yrs(o) = yrs(o) + 1;
        for k = 1:n
            idx(k) = tse.MIT(F_to, int64(yrs(k)));
        end
    else
        error('tseries:noMatch', 'get_out_indices: unsupported target %s.', class(F_to));
    end
end

% ======================================================================
% YP parts and truncation helpers
% ======================================================================

function [to_period, from_month, to_month] = fc_parts(F_to, mv, F_from, ref)
    mv = double(mv);
    mpp_from = 12 / ppyOf(F_from);
    mpp_to   = 12 / ppyOf(F_to);
    from_adj = double(F_from.endPeriod) - mpp_from;
    to_adj   = double(F_to.endPeriod) - mpp_to;
    if strcmp(ref, 'begin')
        from_start_month = mv * mpp_from + 1 + from_adj;
        to_period = fix((from_start_month - to_adj - 1) / mpp_to);
        to_month  = to_period * mpp_to + 1 + to_adj;
        from_month = from_start_month;
    else
        from_end_month = (mv + 1) * mpp_from + from_adj;
        to_period = fix((from_end_month - to_adj - 1) / mpp_to);
        to_month  = (to_period + 1) * mpp_to + to_adj;
        from_month = from_end_month;
    end
end

function tr = start_trunc_yp(ref, require, ffsm, ftsm, mpp_from, mpp_to)
    if strcmp(ref, 'end') && strcmp(require, 'single')
        tr = double(~(ffsm + (mpp_from - 1) <= ftsm + (mpp_to - 1)));
    elseif strcmp(ref, 'end')   % require all
        if ffsm == ftsm
            tr = 0;
        elseif ffsm < ftsm && ffsm + (mpp_from - 1) >= ftsm
            tr = 0;
        else
            tr = 1;
        end
    elseif strcmp(ref, 'begin') && strcmp(require, 'single')
        if ffsm == ftsm
            tr = 0;
        elseif ffsm < ftsm && ffsm + (mpp_from - 1) >= ftsm
            tr = 0;
        else
            tr = 1;
        end
    else   % begin, all
        if ffsm == ftsm
            tr = 0;
        elseif ffsm > ftsm && ffsm - (mpp_from - 1) <= ftsm
            tr = 0;
        else
            tr = 1;
        end
    end
end

function tr = end_trunc_yp(ref, require, lfem, ltem, mpp_from, mpp_to)
    if strcmp(ref, 'end')   % single and all are identical
        if lfem == ltem
            tr = 0;
        elseif lfem < ltem && lfem + (mpp_from - 1) >= ltem
            tr = 0;
        else
            tr = 1;
        end
    elseif strcmp(require, 'single')   % begin, single
        if lfem - (mpp_from - 1) >= ltem - (mpp_to - 1)
            tr = 0;
        elseif lfem - (mpp_from - 1) < ltem - (mpp_to - 1) && lfem >= ltem - (mpp_to - 1)
            tr = 0;
        else
            tr = 1;
        end
    else   % begin, all
        if lfem > ltem && lfem - (mpp_from - 1) <= ltem
            tr = 0;
        else
            tr = 1;
        end
    end
end

% ======================================================================
% MITRange conversion
% ======================================================================

function out = range_convert(F_to, rng, opts)
    F_from = int2freq(rng.frequency);
    if freq_eq(F_to, F_from)
        out = rng;
        return
    end
    trim = getopt(opts, 'trim', 'both');
    if isYP(F_to) && isYP(F_from)
        out = range_yp(F_to, rng, F_from, trim);
    elseif isa(F_to, 'tse.Daily')
        if isa(F_from, 'tse.BDaily')
            out = tse.MITRange(tse.daily(mitToDate(rng.startMIT)), ...
                               tse.daily(mitToDate(rng.stopMIT)));
        else
            out = tse.MITRange(tse.daily(mitToDate(rng.startMIT - 1) + days(1)), ...
                               tse.daily(mitToDate(rng.stopMIT)));
        end
    elseif isa(F_to, 'tse.BDaily')
        out = tse.MITRange(tse.bdaily(mitToDate(rng.startMIT - 1) + days(1), 'bias', 'next'), ...
                           tse.bdaily(mitToDate(rng.stopMIT), 'bias', 'previous'));
    elseif (isYP(F_to) || isa(F_to, 'tse.Weekly'))
        hmap = resolve_holidays(opts, F_from);
        [fi, li, ts_, te_] = using_dates_parts(F_to, rng, trim, hmap, F_from);
        out = tse.MITRange(fi + ts_, li - te_);
    else
        error('tseries:noMatch', 'Conversion of MITRange from %s to %s not implemented.', ...
            class(F_from), class(F_to));
    end
end

function out = range_yp(F_to, rng, F_from, trim)
    [fi_to_period, ffsm, ftsm] = fc_parts(F_to, rng.startMIT.value, F_from, 'begin');
    [li_to_period, lfem, ltem] = fc_parts(F_to, rng.stopMIT.value,  F_from, 'end');
    mpp_from = 12 / ppyOf(F_from);
    mpp_to   = 12 / ppyOf(F_to);
    trunc_start = 0;
    trunc_end = 0;
    if mpp_from > mpp_to   % to higher frequency
        if ~strcmp(trim, 'end')   && ftsm < ffsm,  trunc_start = 1; end
        if ~strcmp(trim, 'begin') && ltem > lfem,  trunc_end   = 1; end
    else                   % to lower frequency
        if (strcmp(trim,'begin') || strcmp(trim,'both')) ...
                && ftsm < ffsm && ftsm <= ffsm - (mpp_from - 1)
            trunc_start = 1;
        end
        if (strcmp(trim,'end') || strcmp(trim,'both')) ...
                && ltem > lfem && ltem >= lfem + mpp_from - 1
            trunc_end = 1;
        end
    end
    fi = tse.MIT(F_to, int64(fi_to_period + trunc_start));
    li = tse.MIT(F_to, int64(li_to_period - trunc_end));
    out = tse.MITRange(fi, li);
end

function [a, b, c, d, e, f] = range_yp_parts(F_to, rng, F_from)
    [a, b, c] = fc_parts(F_to, rng.startMIT.value, F_from, 'begin');
    [d, e, f] = fc_parts(F_to, rng.stopMIT.value,  F_from, 'end');
end

function [fi, li, trunc_start, trunc_end] = using_dates_parts(F_to, rng, trim, holidays_map, F_from)
    if ~ismember(trim, {'both', 'begin', 'end'})
        error('tseries:noMatch', 'trim must be ''both'', ''begin'', or ''end''. Received: %s', trim);
    end
    if ppyOf(F_to) > ppyOf(F_from)   % to higher frequency
        d1 = mitToDate(rng.startMIT - 1) + days(1);
        d2 = mitToDate(rng.stopMIT);
        out_index = get_out_indices(F_to, [d1, d2]);
        fi = out_index(1);
        li = out_index(end);
        trunc_start = 0;
        if ~strcmp(trim, 'end')
            back = mit_convert(F_from, fi, {'ref', 'begin'});
            if ~eq(back, rng.startMIT), trunc_start = 1; end
        end
        trunc_end = 0;
        if ~strcmp(trim, 'begin')
            back = mit_convert(F_from, li, {'ref', 'end'});
            if ~eq(back, rng.stopMIT), trunc_end = 1; end
        end
    else   % to lower (or similar) frequency
        if isa(F_from, 'tse.BDaily') && ~isempty(holidays_map)
            ps = rng.startMIT - 1;
            while holidays_map(ps) == 0, ps = ps - 1; end
            pe = rng.stopMIT + 1;
            while holidays_map(pe) == 0, pe = pe + 1; end
            padded = [mitToDate(ps), mitToDate(rng.startMIT), ...
                      mitToDate(rng.stopMIT), mitToDate(pe)];
        else
            padded = [mitToDate(rng.startMIT - 1), mitToDate(rng.startMIT), ...
                      mitToDate(rng.stopMIT), mitToDate(rng.stopMIT + 1)];
        end
        out_index = get_out_indices(F_to, padded);
        fi = out_index(2);
        li = out_index(3);
        trunc_start = 0;
        if ~strcmp(trim, 'end') && eq(out_index(1), out_index(2)), trunc_start = 1; end
        trunc_end = 0;
        if ~strcmp(trim, 'begin') && eq(out_index(4), out_index(3)), trunc_end = 1; end
    end
end

% ======================================================================
% TSeries conversion
% ======================================================================

function out = tseries_convert(F_to, t, fn, opts)
    F_from = int2freq(t.frequency);
    if freq_eq(F_to, F_from)
        out = t;
        return
    end
    % --- Daily <-> BDaily specials -----------------------------------
    if isa(F_to, 'tse.Daily') && isa(F_from, 'tse.BDaily')
        out = ts_bdaily_to_daily(F_to, t, getopt(opts,'method','const'), getopt(opts,'ref','end'));
        return
    end
    if isa(F_to, 'tse.BDaily') && isa(F_from, 'tse.Daily')
        out = ts_daily_to_bdaily(F_to, t);
        return
    end
    % --- to Daily / BDaily from YP or Weekly (higher) -----------------
    if (isa(F_to,'tse.Daily') || isa(F_to,'tse.BDaily')) && (isYP(F_from) || isa(F_from,'tse.Weekly'))
        out = ts_higher_to_dailybd(F_to, t, getopt(opts,'method','const'), getopt(opts,'ref','end'), fn);
        return
    end
    % --- to Weekly from YP (higher) -----------------------------------
    if isa(F_to, 'tse.Weekly') && isYP(F_from)
        out = ts_higher_to_weekly(F_to, t, getopt(opts,'method','const'), getopt(opts,'ref','end'), fn);
        return
    end
    % --- to YP / Weekly from calendar (lower) -------------------------
    if (isYP(F_to) || isa(F_to,'tse.Weekly')) && isCal(F_from)
        out = lower_calendar_dispatch(F_to, t, fn, opts);
        return
    end
    % --- YP <-> YP ----------------------------------------------------
    if isYP(F_to) && isYP(F_from)
        if ppyOf(F_to) > ppyOf(F_from)
            out = ts_higher_yp(F_to, t, getopt(opts,'method','const'), getopt(opts,'ref','end'), fn);
        else
            out = lower_yp_dispatch(F_to, t, fn, opts);
        end
        return
    end
    error('tseries:noMatch', 'Conversion of TSeries from %s to %s not implemented.', ...
        class(F_from), class(F_to));
end

% ---------- YP -> YP, to higher --------------------------------------

function out = ts_higher_yp(F_to, t, method, ref, fn)
    F_from = int2freq(t.frequency);
    np = floor(ppyOf(F_to) / ppyOf(F_from));
    fi = higher_get_fi(F_to, t.firstdate, F_from, ref);
    v = t.values;
    if ~isempty(fn)
        ret = fn(v, repmat(np, numel(v), 1));
        out = tse.TSeries(fi, ret(:));
        return
    end
    switch method
        case 'const'
            out = tse.TSeries(fi, repelem(v, np));
        case 'even'
            out = tse.TSeries(fi, repelem(v / np, np));
        case 'linear'
            out = tse.TSeries(fi, fc_linear_uneven(v, repmat(np, numel(v), 1), ref));
        otherwise
            error('tseries:noMatch', 'Conversion method not available: %s.', method);
    end
end

function fi = higher_get_fi(F_to, first_mit, F_from, ref)
    [fi_to_period, ffsm, ftsm] = fc_parts(F_to, first_mit.value, F_from, 'begin');
    mpp_to = 12 / ppyOf(F_to);
    if strcmp(ref, 'end')
        fi_to_end_month = ftsm + mpp_to - 1;
        trunc_start = double(fi_to_end_month < ffsm);
    else
        trunc_start = double(ftsm < ffsm);
    end
    fi = tse.MIT(F_to, int64(fi_to_period + trunc_start));
end

% ---------- YP -> YP, to lower / similar -----------------------------

function out = lower_yp_dispatch(F_to, t, fn, opts)
    method = getopt(opts, 'method', 'mean');
    ref    = getopt(opts, 'ref', 'end');
    if ~isempty(fn)
        out = ts_lower_yp(F_to, t, fn, ref);
        return
    end
    switch method
        case 'mean',  out = ts_lower_yp(F_to, t, @mean, ref);
        case 'sum',   out = ts_lower_yp(F_to, t, @sum,  ref);
        case 'min',   out = ts_lower_yp(F_to, t, @min,  ref);
        case 'max',   out = ts_lower_yp(F_to, t, @max,  ref);
        case 'point', out = ts_lower_yp_point(F_to, t, ref);
        case 'end',   out = ts_lower_yp_point(F_to, t, 'end');
        case 'begin', out = ts_lower_yp_point(F_to, t, 'begin');
        otherwise
            error('tseries:noMatch', 'Conversion method not available: %s.', method);
    end
end

function out = ts_lower_yp(F_to, t, aggregator, ref)
    F_from = int2freq(t.frequency);
    mpp_from = 12 / ppyOf(F_from);
    mpp_to   = 12 / ppyOf(F_to);
    np = floor(ppyOf(F_from) / ppyOf(F_to));
    rng = rangeof(t);
    [fi_to_period, ffsm, ftsm, li_to_period, lfem, ltem] = range_yp_parts(F_to, rng, F_from);
    trunc_start = start_trunc_yp(ref, 'all', ffsm, ftsm, mpp_from, mpp_to);
    trunc_end   = end_trunc_yp(ref, 'all', lfem, ltem, mpp_from, mpp_to);
    fi = tse.MIT(F_to, int64(fi_to_period + trunc_start));
    li = tse.MIT(F_to, int64(li_to_period - trunc_end));
    out_range = tse.MITRange(fi, li);
    L = length(out_range);
    fi_trunc_adj = (trunc_start == 1) * mpp_to;
    begin_adj = double(strcmp(ref, 'begin')) * (mpp_from - 1);
    months_mis = ftsm - ffsm + fi_trunc_adj + begin_adj;
    pom = floor(months_mis / mpp_from);
    start_index = 1 + pom;
    end_index = start_index + np * L - 1;
    vals = t.values(start_index:end_index);
    M = reshape(vals, np, []);
    ret = zeros(size(M, 2), 1);
    for c = 1:size(M, 2)
        ret(c) = aggregator(M(:, c));
    end
    out = tse.TSeries(fi, ret(1:L));
end

function out = ts_lower_yp_point(F_to, t, ref)
    F_from = int2freq(t.frequency);
    mpp_from = 12 / ppyOf(F_from);
    mpp_to   = 12 / ppyOf(F_to);
    np = floor(ppyOf(F_from) / ppyOf(F_to));
    rng = rangeof(t);
    [fi_to_period, ffsm, ftsm, li_to_period, lfem, ltem] = range_yp_parts(F_to, rng, F_from);
    trunc_start = start_trunc_yp(ref, 'single', ffsm, ftsm, mpp_from, mpp_to);
    trunc_end   = end_trunc_yp(ref, 'single', lfem, ltem, mpp_from, mpp_to);
    fi = tse.MIT(F_to, int64(fi_to_period + trunc_start));
    li = tse.MIT(F_to, int64(li_to_period - trunc_end));
    out_range = tse.MITRange(fi, li);
    L = length(out_range);
    fi_trunc_adj = (trunc_start == 1) * mpp_to;
    if strcmp(ref, 'end')
        fi_from_end_month = ffsm + mpp_from - 1;
        fi_to_end_month   = ftsm + mpp_to - 1;
        months_mis = fi_to_end_month - fi_from_end_month + fi_trunc_adj;
    else
        months_mis = ftsm - ffsm + fi_trunc_adj;
    end
    pom = floor(months_mis / mpp_from);
    cand = (1 + pom):np:numel(t.values);
    cand = cand(cand > 0);
    indices = cand(1:L);
    ret = t.values(indices);
    out = tse.TSeries(fi, ret(:));
end

% ---------- calendar -> YP / Weekly, to lower ------------------------

function out = lower_calendar_dispatch(F_to, t, fn, opts)
    method = getopt(opts, 'method', 'mean');
    ref    = getopt(opts, 'ref', 'end');
    skip_all_nans = getopt(opts, 'skip_all_nans', false);
    hmap = resolve_holidays(opts, int2freq(t.frequency));
    if ~isempty(fn)
        out = ts_lower_cal(F_to, t, fn, ref, false, skip_all_nans, hmap);
        return
    end
    isPoint = false;
    switch method
        case 'mean', agg = @mean;
        case 'sum',  agg = @sum;
        case 'min',  agg = @min;
        case 'max',  agg = @max;
        case 'point'
            isPoint = true;
            if strcmp(ref, 'begin'), agg = @(x) x(1); else, agg = @(x) x(end); ref = 'end'; end
        case 'end'
            isPoint = true; agg = @(x) x(end); ref = 'end';
        case 'begin'
            isPoint = true; agg = @(x) x(1); ref = 'begin';
        otherwise
            error('tseries:noMatch', 'Conversion method not available: %s.', method);
    end
    out = ts_lower_cal(F_to, t, agg, ref, isPoint, skip_all_nans, hmap);
end

function out = ts_lower_cal(F_to, t, aggregator, ref, isPoint, skip_all_nans, holidays_map)
    F_from = int2freq(t.frequency);
    rng = rangeof(t);
    mits = collect(rng);
    n = numel(mits);
    v = t.values;
    % per-period reference dates
    dates = NaT(1, n);
    if isa(F_from, 'tse.Daily') || isa(F_from, 'tse.BDaily')
        for i = 1:n, dates(i) = mitToDate(mits(i)); end
    else   % Weekly
        if ~isPoint
            for i = 1:n, dates(i) = mitToDate(mits(i), ref); end
        else
            for i = 1:n, dates(i) = mitToDate(mits(i)); end
        end
    end
    % holiday keep-mask (BDaily only)
    keep = true(n, 1);
    if isa(F_from, 'tse.BDaily') && ~isempty(holidays_map)
        for i = 1:n, keep(i) = logical(holidays_map(mits(i))); end
    end
    if isPoint, trim = ref; else, trim = 'both'; end
    [fi, li, trunc_start, trunc_end] = using_dates_parts(F_to, rng, trim, holidays_map, F_from);
    out_index = get_out_indices(F_to, dates(keep));
    if isa(F_from, 'tse.Weekly')
        fi = out_index(1);
        li = out_index(end);
    end
    oi = mvals(out_index);
    vk = v(keep);
    targets = unique(oi);
    ret = zeros(numel(targets), 1);
    for i = 1:numel(targets)
        grp = vk(oi == targets(i));
        if skip_all_nans
            grp = grp(~isnan(grp));
            if isempty(grp), grp = NaN; end
        end
        ret(i) = aggregator(grp);
    end
    nret = numel(ret);
    sel = (1 + trunc_start):(nret - trunc_end);
    out = tse.TSeries(fi + trunc_start, ret(sel));
end

% ---------- YP / Weekly -> Daily / BDaily, to higher -----------------

function out = ts_higher_to_dailybd(F_to, t, method, ref, fn)
    isBD = isa(F_to, 'tse.BDaily');
    rng = rangeof(t);
    mits = collect(rng);
    n = numel(mits);
    if isBD
        fi = tse.bdaily(mitToDate(t.firstdate, 'begin'), 'bias', 'next');
        li = tse.bdaily(mitToDate(rng.stopMIT), 'bias', 'previous');
    else
        fi = tse.daily(mitToDate(t.firstdate, 'begin'));
        li = tse.daily(mitToDate(rng.stopMIT));
    end
    opp = zeros(n, 1);
    for i = 1:n
        if isBD
            a = tse.bdaily(mitToDate(mits(i), 'end'),   'bias', 'previous');
            b = tse.bdaily(mitToDate(mits(i), 'begin'), 'bias', 'next');
        else
            a = tse.daily(mitToDate(mits(i), 'end'));
            b = tse.daily(mitToDate(mits(i), 'begin'));
        end
        opp(i) = double(a.value - b.value) + 1;
    end
    v = t.values;
    if ~isempty(fn)
        ret = fn(v, opp);
    else
        switch method
            case 'const',  ret = fc_repeat_uneven(v, opp);
            case 'even',   ret = fc_divide_uneven(v, opp);
            case 'linear', ret = fc_linear_uneven(v, opp, ref);
            otherwise
                error('tseries:noMatch', 'Conversion method not available: %s.', method);
        end
    end
    out = tse.TSeries(fi, ret(:));
end

% ---------- YP -> Weekly, to higher ----------------------------------

function out = ts_higher_to_weekly(F_to, t, method, ref, fn)
    rng = rangeof(t);
    F_from = int2freq(t.frequency);
    [fi, li, trunc_start, trunc_end] = using_dates_parts(F_to, rng, ref, [], F_from);
    dates = higher_weekly_dates(F_to, t, ref);
    out_indices = get_out_indices(F_to, dates);
    oi = mvals(out_indices);
    opp = diff(oi(:));
    v = t.values;
    if ~isempty(fn)
        ret = fn(v, opp);
    else
        switch method
            case 'const',  ret = fc_repeat_uneven(v, opp);
            case 'even',   ret = fc_divide_uneven(v, opp);
            case 'linear', ret = fc_linear_uneven(v, opp, ref);
            otherwise
                error('tseries:noMatch', 'Conversion method not available: %s.', method);
        end
    end
    out_range = tse.MITRange(fi + trunc_start, li - trunc_end);
    L = length(out_range);
    ret2 = ret(1 + trunc_start:end);
    out = tse.TSeries(fi + trunc_start, ret2(1:L));
end

function dates = higher_weekly_dates(F_to, t, ref)
    rng = rangeof(t);
    mits = collect(rng);
    n = numel(mits);
    if strcmp(ref, 'end')
        dates = NaT(1, n);
        for i = 1:n, dates(i) = mitToDate(mits(i)); end
        dates(1:end-1) = dates(1:end-1) + days(1);
        if isodow(dates(end)) == double(F_to.endPeriod)
            dates(end) = dates(end) + days(1);
        end
        dates = [mitToDate(t.firstdate, 'begin'), dates];
    else
        dates = NaT(1, n);
        for i = 1:n, dates(i) = mitToDate(mits(i)); end
        first_date = mitToDate(t.firstdate, 'begin');
        dates = [first_date - days(7), dates];
    end
end

% ---------- BDaily -> Daily ------------------------------------------

function out = ts_bdaily_to_daily(F_to, t, method, ref)
    fi = mit_convert(F_to, t.firstdate, {});
    li = mit_convert(F_to, lastdate(t), {});
    outlen = double(li.value - fi.value) + 1;
    ts = tse.TSeries(tse.MITRange(fi, li), nan(outlen, 1));
    rng = rangeof(t);
    mits = collect(rng);
    n = numel(mits);
    dows = zeros(1, n);
    outd = repmat(tse.MIT(F_to, int64(0)), 1, n);
    for i = 1:n
        d = mitToDate(mits(i));
        dows(i) = isodow(d);
        outd(i) = tse.daily(d);
    end
    for i = 1:n
        ts(outd(i)) = t.values(i);
    end
    if strcmp(method, 'even')
        out = ts;
        return
    end
    if strcmp(method, 'const')
        if strcmp(ref, 'end')
            mon = outd(dows == 1);
            if ~isempty(mon) && eq(mon(1), fi), mon = mon(2:end); end
            for j = 1:numel(mon)
                val = ts(mon(j));
                ts(mon(j) - 2) = val;
                ts(mon(j) - 1) = val;
            end
        else
            fri = outd(dows == 5);
            if ~isempty(fri) && eq(fri(end), li), fri = fri(1:end-1); end
            for j = 1:numel(fri)
                val = ts(fri(j));
                ts(fri(j) + 1) = val;
                ts(fri(j) + 2) = val;
            end
        end
    elseif strcmp(method, 'linear')
        mon = outd(dows == 1);
        fri = outd(dows == 5);
        if ~isempty(mon) && eq(mon(1), fi), mon = mon(2:end); end
        if ~isempty(fri) && eq(fri(end), li), fri = fri(1:end-1); end
        m = min(numel(mon), numel(fri));
        for j = 1:m
            diffv = ts(mon(j)) - ts(fri(j));
            base = ts(fri(j));
            ts(fri(j) + 1) = base + (1/3) * diffv;
            ts(fri(j) + 2) = base + (2/3) * diffv;
        end
    else
        error('tseries:noMatch', 'Conversion method not available: %s.', method);
    end
    out = ts;
end

% ---------- Daily -> BDaily ------------------------------------------

function out = ts_daily_to_bdaily(F_to, t)
    fi = mit_convert(F_to, t.firstdate, {'round_to', 'next'});
    L = numel(t.values);
    first_day = isodow(mitToDate(t.firstdate));
    if first_day == 7, saturday = 7; else, saturday = 7 - first_day; end
    if first_day == 7, sunday = 1; else, sunday = saturday + 1; end
    week = true(1, 7);
    week([saturday, sunday]) = false;
    reps = ceil(L / 7);
    outmap = repmat(week, 1, reps);
    outmap = outmap(1:L);
    out = tse.TSeries(fi, t.values(outmap));
end

% ======================================================================
% Uneven repeat / divide / linear (port of fconvert_helpers.jl)
% ======================================================================

function outv = fc_repeat_uneven(x, inner)
    inner = double(inner(:));
    x = x(:);
    outv = zeros(sum(inner), 1);
    pos = 1;
    for i = 1:numel(x)
        outv(pos:pos + inner(i) - 1) = x(i);
        pos = pos + inner(i);
    end
end

function outv = fc_divide_uneven(x, inner)
    inner = double(inner(:));
    x = x(:);
    outv = zeros(sum(inner), 1);
    pos = 1;
    for i = 1:numel(x)
        outv(pos:pos + inner(i) - 1) = x(i) / inner(i);
        pos = pos + inner(i);
    end
end

function outv = fc_linear_uneven(x, lens, ref)
    lens = double(lens(:));
    x = x(:);
    n = numel(x);
    outv = zeros(sum(lens), 1);
    ci = 1;
    if strcmp(ref, 'end')
        for i = 1:n
            if i == 1
                step = (x(2) - x(1)) / lens(2);
                vals = linspace(x(1) - lens(1) * step, x(1), lens(1) + 1)';
                outv(ci:ci + lens(1) - 1) = vals(2:end);
            else
                vals = linspace(x(i-1), x(i), lens(i) + 1)';
                outv(ci:ci + lens(i) - 1) = vals(2:end);
            end
            ci = ci + lens(i);
        end
    else   % begin
        for i = 1:n
            if i == n
                step = (x(n) - x(n-1)) / lens(n-1);
                vals = linspace(x(n), x(n) + lens(n) * step, lens(n) + 1)';
                outv(ci:ci + lens(n) - 1) = vals(1:end-1);
            else
                vals = linspace(x(i), x(i+1), lens(i) + 1)';
                outv(ci:ci + lens(i) - 1) = vals(1:end-1);
            end
            ci = ci + lens(i);
        end
    end
end

% ======================================================================
% Holidays option resolution
% ======================================================================

function hmap = resolve_holidays(opts, F_from)
    hmap = getopt(opts, 'holidays_map', []);
    skip_holidays = getopt(opts, 'skip_holidays', false);
    if isempty(hmap) && skip_holidays && isa(F_from, 'tse.BDaily')
        hmap = tse.getoption('bdaily_holidays_map');
    end
end
