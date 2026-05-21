function run_benchmarks(varargin)
%RUN_BENCHMARKS  Time the tseries.m benchmark scenarios.
%
%   run_benchmarks()              run all implemented scenarios
%   run_benchmarks('only', names) run a comma-separated subset, e.g.
%                                 run_benchmarks('only', ...
%                                   'construct_tseries_qq_100,rec_ar2_100')
%   run_benchmarks('seconds', s)  time budget per scenario (default 2)
%                                 (passed to timeit via RepCount estimate)
%
%   Each scenario mirrors the Python/Julia benchmark in
%   TimeSeriesEconPy/benchmarks/compare/scenarios.py.  The SETUP cost is
%   not measured; only the RUN function is timed.
%
%   Output: a formatted table with median time (µs) printed to stdout.
%
%   Requires: the +tse package directory on MATLAB's path.
%   Run startup_tse.m first if the package is not already loaded.

    p = inputParser;
    addParameter(p, 'only',    '',  @ischar);
    addParameter(p, 'seconds', 2.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
    parse(p, varargin{:});

    onlyStr  = strtrim(p.Results.only);
    budget   = p.Results.seconds;

    % ------------------------------------------------------------------
    % 1. Build scenario registry
    % ------------------------------------------------------------------
    [SETUP, RUN, ~] = buildRegistry();
    names = fieldnames(SETUP);

    % ------------------------------------------------------------------
    % 2. Filter by --only list (if given)
    % ------------------------------------------------------------------
    if ~isempty(onlyStr)
        wanted = strsplit(onlyStr, ',');
        wanted = strtrim(wanted);
        names  = names(ismember(names, wanted));
        if isempty(names)
            fprintf('No matching scenarios found for: %s\n', onlyStr);
            return
        end
    end

    % ------------------------------------------------------------------
    % 3. Run and time each scenario
    % ------------------------------------------------------------------
    fprintf('\n%-45s  %12s\n', 'Scenario', 'Median (µs)');
    fprintf('%s\n', repmat('-', 1, 60));

    results = struct();
    for k = 1:numel(names)
        name     = names{k};
        setupFn  = SETUP.(name);
        runFn    = RUN.(name);

        % Build fixed state (not measured).
        state = setupFn();

        % Wrap RUN in a no-output closure for timeit.
        fn = @() runFn(state);

        % timeit estimates the median time per call.
        try
            tSec = timeit(fn);
            tUs  = tSec * 1e6;
            fprintf('%-45s  %12.3f\n', name, tUs);
            results.(name) = tUs;
        catch ME
            fprintf('%-45s  %12s  [ERROR: %s]\n', name, 'n/a', ME.message);
            results.(name) = NaN;
        end
    end

    fprintf('\nAll times are median µs per call (timeit).\n');
    fprintf('Budget per scenario: %.1f s total.\n', budget);
    fprintf('Run startup_tseries.m if +tseries is not on the path.\n\n');
end

% ======================================================================
% SCENARIO REGISTRY
% ======================================================================

function [SETUP, RUN, DESCRIPTION] = buildRegistry()

    % ----- Construction -----------------------------------------------

    SETUP.construct_tseries_qq_100 = @setup_construct_tseries_qq_100;
    RUN.construct_tseries_qq_100   = @run_construct_tseries_qq_100;
    DESCRIPTION.construct_tseries_qq_100 = 'TSeries(qq, arr) from length-100 vector';

    SETUP.construct_mvts_qq_100x5 = @setup_construct_mvts_qq_100x5;
    RUN.construct_mvts_qq_100x5   = @run_construct_mvts_qq_100x5;
    DESCRIPTION.construct_mvts_qq_100x5 = 'MVTSeries(qq, 5 cols, 100x5 matrix)';

    % ----- Indexing ---------------------------------------------------

    SETUP.indexing_mit_lookup_100 = @setup_indexing_mit_lookup_100;
    RUN.indexing_mit_lookup_100   = @run_indexing_mit_lookup_100;
    DESCRIPTION.indexing_mit_lookup_100 = 'Sum t(mit) over 100 MIT keys';

    SETUP.indexing_int_lookup_100 = @setup_indexing_int_lookup_100;
    RUN.indexing_int_lookup_100   = @run_indexing_int_lookup_100;
    DESCRIPTION.indexing_int_lookup_100 = 'Sum t(int) over 100 integer keys';

    SETUP.indexing_mitrange_slice = @setup_indexing_mitrange_slice;
    RUN.indexing_mitrange_slice   = @run_indexing_mitrange_slice;
    DESCRIPTION.indexing_mitrange_slice = 't(MITRange) — single 60-period slice';

    SETUP.indexing_mvts_column = @setup_indexing_mvts_column;
    RUN.indexing_mvts_column   = @run_indexing_mvts_column;
    DESCRIPTION.indexing_mvts_column = "mvts('c') — column access";

    % ----- Arithmetic -------------------------------------------------

    SETUP.arith_add_misaligned = @setup_arith_add_misaligned;
    RUN.arith_add_misaligned   = @run_arith_add_misaligned;
    DESCRIPTION.arith_add_misaligned = '100Q + 100Q with 50Q overlap';

    SETUP.arith_add_aligned = @setup_arith_add_aligned;
    RUN.arith_add_aligned   = @run_arith_add_aligned;
    DESCRIPTION.arith_add_aligned = '100Q + 100Q same range';

    SETUP.arith_mul_scalar = @setup_arith_mul_scalar;
    RUN.arith_mul_scalar   = @run_arith_mul_scalar;
    DESCRIPTION.arith_mul_scalar = 't * 2.5';

    % ----- Shift family -----------------------------------------------

    SETUP.shift_quarterly_lag1 = @setup_shift_quarterly_lag1;
    RUN.shift_quarterly_lag1   = @run_shift_quarterly_lag1;
    DESCRIPTION.shift_quarterly_lag1 = 'shift(t, -1)';

    SETUP.lead_quarterly_lag1 = @setup_lead_quarterly_lag1;
    RUN.lead_quarterly_lag1   = @run_lead_quarterly_lag1;
    DESCRIPTION.lead_quarterly_lag1 = 'lead(t, 1)';

    SETUP.diff_quarterly = @setup_diff_quarterly;
    RUN.diff_quarterly   = @run_diff_quarterly;
    DESCRIPTION.diff_quarterly = 'diff_ts(t)';

    SETUP.pct_quarterly = @setup_pct_quarterly;
    RUN.pct_quarterly   = @run_pct_quarterly;
    DESCRIPTION.pct_quarterly = 'pct(t)';

    SETUP.ytypct_quarterly_100 = @setup_ytypct_quarterly_100;
    RUN.ytypct_quarterly_100   = @run_ytypct_quarterly_100;
    DESCRIPTION.ytypct_quarterly_100 = 'ytypct(t) — year-on-year %';

    % ----- Stats ------------------------------------------------------

    SETUP.mean_quarterly_100 = @setup_mean_quarterly_100;
    RUN.mean_quarterly_100   = @run_mean_quarterly_100;
    DESCRIPTION.mean_quarterly_100 = 'mean(t)';

    SETUP.std_quarterly_100 = @setup_std_quarterly_100;
    RUN.std_quarterly_100   = @run_std_quarterly_100;
    DESCRIPTION.std_quarterly_100 = 'std(t)';

    SETUP.quantile_quarterly_100 = @setup_quantile_quarterly_100;
    RUN.quantile_quarterly_100   = @run_quantile_quarterly_100;
    DESCRIPTION.quantile_quarterly_100 = 'quantile(t.values, 0.5) — median';

    SETUP.cor_two_tseries = @setup_cor_two_tseries;
    RUN.cor_two_tseries   = @run_cor_two_tseries;
    DESCRIPTION.cor_two_tseries = 'corr(a.values, b.values) on two TSeries';

    SETUP.cov_two_tseries = @setup_cov_two_tseries;
    RUN.cov_two_tseries   = @run_cov_two_tseries;
    DESCRIPTION.cov_two_tseries = 'cov([a.values, b.values]) on two TSeries';

    SETUP.cor_mvts_5_columns = @setup_cor_mvts_5_columns;
    RUN.cor_mvts_5_columns   = @run_cor_mvts_5_columns;
    DESCRIPTION.cor_mvts_5_columns = 'corr(mvts.values) — 5x5 corr matrix';

    SETUP.cov_mvts_5_columns = @setup_cov_mvts_5_columns;
    RUN.cov_mvts_5_columns   = @run_cov_mvts_5_columns;
    DESCRIPTION.cov_mvts_5_columns = 'cov(mvts.values) — 5x5 cov matrix';

    % ----- MVTSeries axis= reductions ---------------------------------

    SETUP.mean_mvts_axis0_5cols = @setup_mean_mvts_axis0_5cols;
    RUN.mean_mvts_axis0_5cols   = @run_mean_mvts_axis0_5cols;
    DESCRIPTION.mean_mvts_axis0_5cols = "mean(mvts, 'dims', 1) — per-column (5 values)";

    SETUP.mean_mvts_axis1_100rows = @setup_mean_mvts_axis1_100rows;
    RUN.mean_mvts_axis1_100rows   = @run_mean_mvts_axis1_100rows;
    DESCRIPTION.mean_mvts_axis1_100rows = "mean(mvts, 'dims', 2) — per-row TSeries (100 rows)";

    % ----- Moving / undiff --------------------------------------------

    SETUP.moving_average_quarterly_4 = @setup_moving_average_quarterly_4;
    RUN.moving_average_quarterly_4   = @run_moving_average_quarterly_4;
    DESCRIPTION.moving_average_quarterly_4 = 'moving_average(t, 4)';

    SETUP.moving_sum_quarterly_4 = @setup_moving_sum_quarterly_4;
    RUN.moving_sum_quarterly_4   = @run_moving_sum_quarterly_4;
    DESCRIPTION.moving_sum_quarterly_4 = 'moving_sum(t, 4)';

    SETUP.undiff_quarterly = @setup_undiff_quarterly;
    RUN.undiff_quarterly   = @run_undiff_quarterly;
    DESCRIPTION.undiff_quarterly = 'undiff(t)';

    % ----- Recursion --------------------------------------------------

    SETUP.rec_ar2_100 = @setup_rec_ar2_100;
    RUN.rec_ar2_100   = @run_rec_ar2_100;
    DESCRIPTION.rec_ar2_100 = 'AR(2) over 100 quarters — rec + lambda';

    SETUP.rec_backcasting_via_lambda = @setup_rec_backcasting_via_lambda;
    RUN.rec_backcasting_via_lambda   = @run_rec_backcasting_via_lambda;
    DESCRIPTION.rec_backcasting_via_lambda = 'Backcast 100 quarters — reversed MITRange + rec';

    % ----- Various.jl helpers -----------------------------------------

    SETUP.overlay_three_tseries = @setup_overlay_three_tseries;
    RUN.overlay_three_tseries   = @run_overlay_three_tseries;
    DESCRIPTION.overlay_three_tseries = 'overlay(a, b, c) — 100Q three-way first-non-NaN';

    SETUP.reindex_tseries_100 = @setup_reindex_tseries_100;
    RUN.reindex_tseries_100   = @run_reindex_tseries_100;
    DESCRIPTION.reindex_tseries_100 = 'reindex(t, qq_from, unit_to) — 100Q label shift';

    SETUP.rangeof_tseries_drop1 = @setup_rangeof_tseries_drop1;
    RUN.rangeof_tseries_drop1   = @run_rangeof_tseries_drop1;
    DESCRIPTION.rangeof_tseries_drop1 = "rangeof(t, 'drop', 1) — 100Q";

    % ----- Linear algebra ---------------------------------------------

    SETUP.linalg_matrix_tseries_100 = @setup_linalg_matrix_tseries_100;
    RUN.linalg_matrix_tseries_100   = @run_linalg_matrix_tseries_100;
    DESCRIPTION.linalg_matrix_tseries_100 = 'A * t.values — 100x100 matrix × length-100 TSeries';

end

% ======================================================================
% CONSTRUCTION
% ======================================================================

function state = setup_construct_tseries_qq_100()
    state.start  = tse.qq(2020, 1);
    state.values = (0:99)';
end

function r = run_construct_tseries_qq_100(state)
    r = tse.TSeries(state.start, state.values);
end

% ------

function state = setup_construct_mvts_qq_100x5()
    state.start  = tse.qq(2020, 1);
    state.cols   = {'a', 'b', 'c', 'd', 'e'};
    state.values = reshape(0:499, 100, 5);
end

function r = run_construct_mvts_qq_100x5(state)
    r = tse.MVTSeries(state.start, state.cols, state.values);
end

% ======================================================================
% INDEXING
% ======================================================================

function state = setup_indexing_mit_lookup_100()
    start = tse.qq(2020, 1);
    t     = tse.TSeries(start, (0:99)');
    keys  = collect(tse.MITRange(start, start + 99));
    state.t    = t;
    state.keys = keys;
end

function r = run_indexing_mit_lookup_100(state)
    t    = state.t;
    keys = state.keys;
    s    = 0.0;
    for k = 1:numel(keys)
        s = s + double(t(keys(k)));
    end
    r = s;
end

% ------

function state = setup_indexing_int_lookup_100()
    t    = tse.TSeries(tse.qq(2020, 1), (0:99)');
    state.t    = t;
    state.keys = 1:100;
end

function r = run_indexing_int_lookup_100(state)
    t    = state.t;
    keys = state.keys;
    s    = 0.0;
    for k = keys
        s = s + double(t(k));
    end
    r = s;
end

% ------

function state = setup_indexing_mitrange_slice()
    start = tse.qq(2020, 1);
    t     = tse.TSeries(start, (0:99)');
    state.t   = t;
    state.rng = tse.MITRange(start + 20, start + 79);
end

function r = run_indexing_mitrange_slice(state)
    r = state.t(state.rng);
end

% ------

function state = setup_indexing_mvts_column()
    state.mvts = tse.MVTSeries(tse.qq(2020, 1), {'a','b','c','d','e'}, ...
                                   reshape(0:499, 100, 5));
end

function r = run_indexing_mvts_column(state)
    r = state.mvts('c');
end

% ======================================================================
% ARITHMETIC
% ======================================================================

function state = setup_arith_add_misaligned()
    % 50-period overlap: a = 2020Q1..2044Q4, b = 2032Q1..2056Q4
    state.a = tse.TSeries(tse.qq(2020, 1), (0:99)');
    state.b = tse.TSeries(tse.qq(2032, 1), (0:99)' * 0.5);
end

function r = run_arith_add_misaligned(state)
    r = state.a + state.b;
end

% ------

function state = setup_arith_add_aligned()
    start   = tse.qq(2020, 1);
    state.a = tse.TSeries(start, (0:99)');
    state.b = tse.TSeries(start, (0:99)' * 0.5);
end

function r = run_arith_add_aligned(state)
    r = state.a + state.b;
end

% ------

function state = setup_arith_mul_scalar()
    state.t = tse.TSeries(tse.qq(2020, 1), (0:99)');
end

function r = run_arith_mul_scalar(state)
    r = state.t * 2.5;
end

% ======================================================================
% SHIFT FAMILY
% ======================================================================

function state = setup_shift_quarterly_lag1()
    state.t = tse.TSeries(tse.qq(2020, 1), (0:99)');
end

function r = run_shift_quarterly_lag1(state)
    r = state.t.shift(-1);
end

% ------

function state = setup_lead_quarterly_lag1()
    state.t = tse.TSeries(tse.qq(2020, 1), (0:99)');
end

function r = run_lead_quarterly_lag1(state)
    r = state.t.lead(1);
end

% ------

function state = setup_diff_quarterly()
    state.t = tse.TSeries(tse.qq(2020, 1), (0:99)');
end

function r = run_diff_quarterly(state)
    r = state.t.diff_ts();
end

% ------

function state = setup_pct_quarterly()
    % Start at 1 to avoid divide-by-zero on first ratio.
    state.t = tse.TSeries(tse.qq(2020, 1), (1:100)');
end

function r = run_pct_quarterly(state)
    r = state.t.pct();
end

% ------

function state = setup_ytypct_quarterly_100()
    % Start at 1 to avoid divide-by-zero in year-on-year ratio.
    state.t = tse.TSeries(tse.qq(2020, 1), (1:100)');
end

function r = run_ytypct_quarterly_100(state)
    r = state.t.ytypct();
end

% ======================================================================
% STATS
% ======================================================================

function state = setup_mean_quarterly_100()
    state.t = tse.TSeries(tse.qq(2020, 1), (0:99)');
end

function r = run_mean_quarterly_100(state)
    r = state.t.mean();
end

% ------

function state = setup_std_quarterly_100()
    state.t = tse.TSeries(tse.qq(2020, 1), (0:99)');
end

function r = run_std_quarterly_100(state)
    r = state.t.std();
end

% ------

function state = setup_quantile_quarterly_100()
    rng_seed = RandStream('mt19937ar', 'Seed', 20260515);
    state.t  = tse.TSeries(tse.qq(2020, 1), randn(rng_seed, 100, 1));
end

function r = run_quantile_quarterly_100(state)
    % No tseries.quantile free function; delegate to MATLAB built-in.
    r = quantile(state.t.values, 0.5);
end

% ------

function state = setup_cor_two_tseries()
    rng_seed = RandStream('mt19937ar', 'Seed', 20260515);
    start    = tse.qq(2020, 1);
    state.a  = tse.TSeries(start, randn(rng_seed, 100, 1));
    state.b  = tse.TSeries(start, randn(rng_seed, 100, 1));
end

function r = run_cor_two_tseries(state)
    % corr(x, y) on column vectors returns a scalar correlation.
    r = corr(state.a.values, state.b.values);
end

% ------

function state = setup_cov_two_tseries()
    rng_seed = RandStream('mt19937ar', 'Seed', 20260515);
    start    = tse.qq(2020, 1);
    state.a  = tse.TSeries(start, randn(rng_seed, 100, 1));
    state.b  = tse.TSeries(start, randn(rng_seed, 100, 1));
end

function r = run_cov_two_tseries(state)
    % cov([x, y]) returns 2x2 covariance matrix (off-diagonal = covariance).
    r = cov([state.a.values, state.b.values]);
end

% ------

function state = setup_cor_mvts_5_columns()
    rng_seed  = RandStream('mt19937ar', 'Seed', 20260515);
    state.mvts = tse.MVTSeries(tse.qq(2020, 1), {'a','b','c','d','e'}, ...
                                   randn(rng_seed, 100, 5));
end

function r = run_cor_mvts_5_columns(state)
    % corr on a 100x5 matrix returns 5x5 correlation matrix.
    r = corr(state.mvts.values);
end

% ------

function state = setup_cov_mvts_5_columns()
    rng_seed  = RandStream('mt19937ar', 'Seed', 20260515);
    state.mvts = tse.MVTSeries(tse.qq(2020, 1), {'a','b','c','d','e'}, ...
                                   randn(rng_seed, 100, 5));
end

function r = run_cov_mvts_5_columns(state)
    % cov on a 100x5 matrix returns 5x5 covariance matrix.
    r = cov(state.mvts.values);
end

% ======================================================================
% MVTSERIES AXIS= REDUCTIONS
% ======================================================================

function state = setup_mean_mvts_axis0_5cols()
    rng_seed  = RandStream('mt19937ar', 'Seed', 20260518);
    state.mvts = tse.MVTSeries(tse.qq(2020, 1), {'a','b','c','d','e'}, ...
                                   randn(rng_seed, 100, 5));
end

function r = run_mean_mvts_axis0_5cols(state)
    % 'dims',1: reduce along rows -> 1x5 numeric (per-column mean).
    % Analogue of Python's mean(mvts, axis=0).
    r = state.mvts.mean('dims', 1);
end

% ------

function state = setup_mean_mvts_axis1_100rows()
    rng_seed  = RandStream('mt19937ar', 'Seed', 20260518);
    state.mvts = tse.MVTSeries(tse.qq(2020, 1), {'a','b','c','d','e'}, ...
                                   randn(rng_seed, 100, 5));
end

function r = run_mean_mvts_axis1_100rows(state)
    % 'dims',2: reduce along columns -> length-100 TSeries (per-row mean).
    % Analogue of Python's mean(mvts, axis=1).
    r = state.mvts.mean('dims', 2);
end

% ======================================================================
% MOVING / UNDIFF
% ======================================================================

function state = setup_moving_average_quarterly_4()
    state.t = tse.TSeries(tse.qq(2020, 1), (0:99)');
end

function r = run_moving_average_quarterly_4(state)
    r = state.t.moving_average(4);
end

% ------

function state = setup_moving_sum_quarterly_4()
    state.t = tse.TSeries(tse.qq(2020, 1), (0:99)');
end

function r = run_moving_sum_quarterly_4(state)
    r = state.t.moving_sum(4);
end

% ------

function state = setup_undiff_quarterly()
    state.t = tse.TSeries(tse.qq(2020, 1), (0:99)');
end

function r = run_undiff_quarterly(state)
    r = tse.undiff(state.t);
end

% ======================================================================
% RECURSION
% ======================================================================

function state = setup_rec_ar2_100()
    start  = tse.qq(2020, 1);
    target = tse.TSeries(start, zeros(102, 1));
    target(start)     = 1.0;
    target(start + 1) = 1.0;
    state.target = target;
    state.start  = start;
    state.rng    = tse.MITRange(start + 2, start + 101);
end

function r = run_rec_ar2_100(state)
    % A fresh copy of target is needed every call because rec assigns in-place
    % via value-class copy-on-write; MATLAB value semantics make `target` a
    % local copy here so each timeit repetition starts from the seed values.
    target = state.target;
    r = tse.rec(state.rng, target, @(s, k) 0.5 * s(k-1) + 0.3 * s(k-2));
end

% ------

function state = setup_rec_backcasting_via_lambda()
    % 100-step backcast: target[lastQ] = 100, walk backward:
    % target[t] = target[t+1] - 0.5.
    start  = tse.qq(2020, 1);
    n      = 100;
    target = tse.TSeries(start, zeros(n, 1));
    target(start + (n-1)) = 100.0;
    % Range: penultimate down to first (step = -1).
    state.target = target;
    state.rng    = tse.MITRange(start + (n-2), int64(-1), start);
end

function r = run_rec_backcasting_via_lambda(state)
    target = state.target;
    r = tse.rec(state.rng, target, @(s, k) s(k+1) - 0.5);
end

% ======================================================================
% VARIOUS.JL HELPERS  (overlay / reindex / rangeof)
% ======================================================================

function state = setup_overlay_three_tseries()
    arr  = (0:99)';
    a    = tse.TSeries(tse.qq(2020, 1), arr);
    a.values(1:7:end) = NaN;
    b    = tse.TSeries(tse.qq(2019, 1), repmat(100.0, 100, 1));
    b.values(1:5:end) = NaN;
    c    = tse.TSeries(tse.qq(2021, 1), repmat(200.0, 100, 1));
    state.a = a;
    state.b = b;
    state.c = c;
end

function r = run_overlay_three_tseries(state)
    r = tse.overlay(state.a, state.b, state.c);
end

% ------

function state = setup_reindex_tseries_100()
    state.t    = tse.TSeries(tse.qq(2020, 1), (0:99)');
    state.from = tse.qq(2020, 1);
    state.to   = tse.MIT(tse.Unit(), 1);
end

function r = run_reindex_tseries_100(state)
    r = tse.reindex(state.t, state.from, state.to);
end

% ------

function state = setup_rangeof_tseries_drop1()
    state.t = tse.TSeries(tse.qq(2020, 1), (0:99)');
end

function r = run_rangeof_tseries_drop1(state)
    r = tse.rangeof(state.t, 'drop', 1);
end

% ======================================================================
% LINEAR ALGEBRA
% ======================================================================

function state = setup_linalg_matrix_tseries_100()
    rng_seed = RandStream('mt19937ar', 'Seed', 20260518);
    state.A  = randn(rng_seed, 100, 100);
    state.t  = tse.TSeries(tse.qq(2020, 1), randn(rng_seed, 100, 1));
end

function r = run_linalg_matrix_tseries_100(state)
    % MATLAB uses * for matrix multiplication.
    % TSeries.mtimes strips labels and falls through to values * values.
    r = state.A * state.t;
end
