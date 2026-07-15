function iris_benchmarks(varargin)
%IRIS_BENCHMARKS  Time the run_benchmarks.m scenarios against the IRIS Toolbox.
%
%   This is the IRIS Toolbox (2015 vintage) analogue of run_benchmarks.m.  Each
%   scenario name and SETUP/RUN split mirrors the +tse version one-for-one so
%   the two timing tables can be compared directly.  Scenarios that have no
%   IRIS equivalent are listed at the bottom with [skipped] and a reason.
%
%   iris_benchmarks()                 run all implemented scenarios
%   iris_benchmarks('only', names)    run a comma-separated subset
%   iris_benchmarks('seconds', s)     time budget per scenario (default 2)
%
%   The IRIS install path is a placeholder near the top of this file — edit
%   IRIS_PATH to point at your IRIS Toolbox install (the 20150318 release,
%   https://iris.igpmn.org/).  The script calls irisstartup if it is on the
%   path, then runs each scenario inside timeit.
%
%   Notes on the 2015 API used here:
%     - tseries(start, data)            scalar series
%     - tseries(start, matrix, '', lbl) multi-column series (lbl is a cellstr
%                                       of column comments)
%     - qq/mm/yy(year, period)          numeric date codes; ranges are vectors
%     - shift, diff, pct, apct, movavg  on tseries
%     - convert(t, freq, 'method', m)   frequency conversion
%     - dbmerge / dboverlay / dbcompare for struct-as-database operations

    % ------------------------------------------------------------------
    % IRIS path (PLACEHOLDER: edit this to your install)
    % ------------------------------------------------------------------
    IRIS_PATH = '/path/to/IRIS_Tbx_20150318';

    if ~isempty(IRIS_PATH) && exist(IRIS_PATH, 'dir') == 7
        addpath(IRIS_PATH);
    end
    if exist('irisstartup', 'file') == 2
        evalc('irisstartup();');   % quiet
    elseif exist('tseries', 'class') ~= 8 && exist('tseries', 'file') ~= 2
        error('iris_benchmarks:noIris', ...
            ['IRIS Toolbox is not on the MATLAB path. Set IRIS_PATH near the ', ...
             'top of iris_benchmarks.m to point at your install (e.g. the ', ...
             '2015-03-18 release from https://iris.igpmn.org/).']);
    end

    p = inputParser;
    addParameter(p, 'only',    '',  @ischar);
    addParameter(p, 'seconds', 2.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
    parse(p, varargin{:});
    onlyStr = strtrim(p.Results.only);
    budget  = p.Results.seconds;

    [SETUP, RUN, SKIPPED] = buildRegistry();
    names = fieldnames(SETUP);

    if ~isempty(onlyStr)
        wanted = strtrim(strsplit(onlyStr, ','));
        names  = names(ismember(names, wanted));
        if isempty(names)
            fprintf('No matching scenarios found for: %s\n', onlyStr);
            return
        end
    end

    fprintf('\n%-45s  %12s\n', 'Scenario', 'Median (us)');
    fprintf('%s\n', repmat('-', 1, 60));

    for k = 1:numel(names)
        name    = names{k};
        setupFn = SETUP.(name);
        runFn   = RUN.(name);
        try
            state = setupFn();
        catch ME
            fprintf('%-45s  %12s  [SETUP ERROR: %s]\n', name, 'n/a', ME.message);
            continue
        end
        fn = @() runFn(state);
        try
            tSec = timeit(fn);
            fprintf('%-45s  %12.3f\n', name, tSec * 1e6);
        catch ME
            fprintf('%-45s  %12s  [RUN ERROR: %s]\n', name, 'n/a', ME.message);
        end
    end

    for k = 1:numel(SKIPPED)
        fprintf('%-45s  %12s  [%s]\n', SKIPPED(k).name, 'skipped', SKIPPED(k).reason);
    end

    fprintf('\nAll times are median us per call (timeit).\n');
    fprintf('Budget per scenario: %.1f s total.\n', budget);
    fprintf('Edit IRIS_PATH near the top of iris_benchmarks.m to point at your install.\n\n');
end

% ======================================================================
% SCENARIO REGISTRY
% ======================================================================
function [SETUP, RUN, SKIPPED] = buildRegistry()
    SETUP = struct(); RUN = struct();

    % --- CONSTRUCTION -------------------------------------------------
    SETUP.construct_tseries_qq_100 = @setup_construct_tseries_qq_100;
    RUN.construct_tseries_qq_100   = @run_construct_tseries_qq_100;

    SETUP.construct_mvts_qq_100x5  = @setup_construct_mvts_qq_100x5;
    RUN.construct_mvts_qq_100x5    = @run_construct_mvts_qq_100x5;

    % --- INDEXING -----------------------------------------------------
    SETUP.indexing_mit_lookup_100   = @setup_indexing_mit_lookup_100;
    RUN.indexing_mit_lookup_100     = @run_indexing_mit_lookup_100;

    SETUP.indexing_int_lookup_100   = @setup_indexing_int_lookup_100;
    RUN.indexing_int_lookup_100     = @run_indexing_int_lookup_100;

    SETUP.indexing_mitrange_slice   = @setup_indexing_mitrange_slice;
    RUN.indexing_mitrange_slice     = @run_indexing_mitrange_slice;

    SETUP.indexing_mvts_column      = @setup_indexing_mvts_column;
    RUN.indexing_mvts_column        = @run_indexing_mvts_column;

    SETUP.indexing_lookup_100_api   = @setup_indexing_lookup_100_api;
    RUN.indexing_lookup_100_api     = @run_indexing_lookup_100_api;

    % --- ARITHMETIC ---------------------------------------------------
    SETUP.arith_add_misaligned = @setup_arith_add_misaligned;
    RUN.arith_add_misaligned   = @run_arith_add_misaligned;

    SETUP.arith_add_aligned    = @setup_arith_add_aligned;
    RUN.arith_add_aligned      = @run_arith_add_aligned;

    SETUP.arith_mul_scalar     = @setup_arith_mul_scalar;
    RUN.arith_mul_scalar       = @run_arith_mul_scalar;

    % --- SHIFT / DIFF / PCT -------------------------------------------
    SETUP.shift_quarterly_lag1 = @setup_shift_quarterly_lag1;
    RUN.shift_quarterly_lag1   = @run_shift_quarterly_lag1;

    SETUP.lead_quarterly_lag1  = @setup_lead_quarterly_lag1;
    RUN.lead_quarterly_lag1    = @run_lead_quarterly_lag1;

    SETUP.diff_quarterly       = @setup_diff_quarterly;
    RUN.diff_quarterly         = @run_diff_quarterly;

    SETUP.pct_quarterly        = @setup_pct_quarterly;
    RUN.pct_quarterly          = @run_pct_quarterly;

    SETUP.ytypct_quarterly_100 = @setup_ytypct_quarterly_100;
    RUN.ytypct_quarterly_100   = @run_ytypct_quarterly_100;

    % --- REDUCTIONS ---------------------------------------------------
    SETUP.mean_quarterly_100      = @setup_mean_quarterly_100;
    RUN.mean_quarterly_100        = @run_mean_quarterly_100;

    SETUP.std_quarterly_100       = @setup_std_quarterly_100;
    RUN.std_quarterly_100         = @run_std_quarterly_100;

    SETUP.quantile_quarterly_100  = @setup_quantile_quarterly_100;
    RUN.quantile_quarterly_100    = @run_quantile_quarterly_100;

    SETUP.cor_two_tseries         = @setup_cor_two_tseries;
    RUN.cor_two_tseries           = @run_cor_two_tseries;

    SETUP.cov_two_tseries         = @setup_cov_two_tseries;
    RUN.cov_two_tseries           = @run_cov_two_tseries;

    SETUP.cor_mvts_5_columns      = @setup_cor_mvts_5_columns;
    RUN.cor_mvts_5_columns        = @run_cor_mvts_5_columns;

    SETUP.cov_mvts_5_columns      = @setup_cov_mvts_5_columns;
    RUN.cov_mvts_5_columns        = @run_cov_mvts_5_columns;

    % --- MVTS AXIS REDUCTIONS -----------------------------------------
    SETUP.mean_mvts_axis0_5cols   = @setup_mean_mvts_axis0_5cols;
    RUN.mean_mvts_axis0_5cols     = @run_mean_mvts_axis0_5cols;

    SETUP.mean_mvts_axis1_100rows = @setup_mean_mvts_axis1_100rows;
    RUN.mean_mvts_axis1_100rows   = @run_mean_mvts_axis1_100rows;

    % --- MOVING / UNDIFF ----------------------------------------------
    SETUP.moving_average_quarterly_4 = @setup_moving_average_quarterly_4;
    RUN.moving_average_quarterly_4   = @run_moving_average_quarterly_4;

    SETUP.moving_sum_quarterly_4     = @setup_moving_sum_quarterly_4;
    RUN.moving_sum_quarterly_4       = @run_moving_sum_quarterly_4;

    SETUP.undiff_quarterly           = @setup_undiff_quarterly;
    RUN.undiff_quarterly             = @run_undiff_quarterly;

    % --- RECURSION (manual loop in IRIS) ------------------------------
    SETUP.rec_ar2_100                = @setup_rec_ar2_100;
    RUN.rec_ar2_100                  = @run_rec_ar2_100;

    SETUP.rec_backcasting_via_lambda = @setup_rec_backcasting_via_lambda;
    RUN.rec_backcasting_via_lambda   = @run_rec_backcasting_via_lambda;

    % --- RANGEOF ------------------------------------------------------
    SETUP.rangeof_tseries_drop1      = @setup_rangeof_tseries_drop1;
    RUN.rangeof_tseries_drop1        = @run_rangeof_tseries_drop1;

    % --- LINEAR ALGEBRA -----------------------------------------------
    SETUP.linalg_matrix_tseries_100  = @setup_linalg_matrix_tseries_100;
    RUN.linalg_matrix_tseries_100    = @run_linalg_matrix_tseries_100;

    % --- FREQUENCY CONVERSION -----------------------------------------
    SETUP.fconvert_qq_to_yy_mean   = @setup_fconvert_qq_to_yy_mean;
    RUN.fconvert_qq_to_yy_mean     = @run_fconvert_qq_to_yy_mean;

    SETUP.fconvert_qq_to_yy_sum    = @setup_fconvert_qq_to_yy_sum;
    RUN.fconvert_qq_to_yy_sum      = @run_fconvert_qq_to_yy_sum;

    SETUP.fconvert_yy_to_qq_const  = @setup_fconvert_yy_to_qq_const;
    RUN.fconvert_yy_to_qq_const    = @run_fconvert_yy_to_qq_const;

    SETUP.fconvert_yy_to_qq_linear = @setup_fconvert_yy_to_qq_linear;
    RUN.fconvert_yy_to_qq_linear   = @run_fconvert_yy_to_qq_linear;

    SETUP.fconvert_yy_to_qq_even   = @setup_fconvert_yy_to_qq_even;
    RUN.fconvert_yy_to_qq_even     = @run_fconvert_yy_to_qq_even;

    SETUP.fconvert_mm_to_qq_mean   = @setup_fconvert_mm_to_qq_mean;
    RUN.fconvert_mm_to_qq_mean     = @run_fconvert_mm_to_qq_mean;

    % --- MIXED-FREQUENCY PIPELINES ------------------------------------
    SETUP.mixed_freq_qq_minus_mm_mean    = @setup_mixed_freq_qq_minus_mm_mean;
    RUN.mixed_freq_qq_minus_mm_mean      = @run_mixed_freq_qq_minus_mm_mean;

    SETUP.mixed_freq_pipeline_three_freq = @setup_mixed_freq_pipeline_three_freq;
    RUN.mixed_freq_pipeline_three_freq   = @run_mixed_freq_pipeline_three_freq;

    % --- WORKSPACE (database) -----------------------------------------
    SETUP.workspace_merge_5_series        = @setup_workspace_merge_5_series;
    RUN.workspace_merge_5_series          = @run_workspace_merge_5_series;

    SETUP.workspace_filter_5_series       = @setup_workspace_filter_5_series;
    RUN.workspace_filter_5_series         = @run_workspace_filter_5_series;

    SETUP.compare_workspaces_equal_5_keys  = @setup_compare_workspaces_equal_5_keys;
    RUN.compare_workspaces_equal_5_keys    = @run_compare_workspaces_equal_5_keys;

    SETUP.compare_workspaces_differ_5_keys = @setup_compare_workspaces_differ_5_keys;
    RUN.compare_workspaces_differ_5_keys   = @run_compare_workspaces_differ_5_keys;

    % ------------------------------------------------------------------
    % Scenarios IRIS 2015 cannot express directly
    % ------------------------------------------------------------------
    SKIPPED = struct('name', {}, 'reason', {});
    SKIPPED(end+1) = struct( ...
        'name',   'overlay_three_tseries', ...
        'reason', 'no single-series NaN overlay in IRIS 2015 (dboverlay is database-only)');
    SKIPPED(end+1) = struct( ...
        'name',   'reindex_tseries_100', ...
        'reason', 'no equivalent to reindex (re-label start to a different frequency) in IRIS 2015');
end

% ======================================================================
% CONSTRUCTION
% ======================================================================
function state = setup_construct_tseries_qq_100()
    state.start = qq(2020, 1);
    state.data  = (0:99)';
end

function r = run_construct_tseries_qq_100(state)
    r = tseries(state.start, state.data);
end

% ------

function state = setup_construct_mvts_qq_100x5()
    state.start  = qq(2020, 1);
    state.matrix = reshape(0:499, 100, 5);
    state.labels = {'a','b','c','d','e'};
end

function r = run_construct_mvts_qq_100x5(state)
    % IRIS multi-column tseries: matrix + per-column comment cellstr.
    r = tseries(state.start, state.matrix, '', state.labels);
end

% ======================================================================
% INDEXING
% ======================================================================
function state = setup_indexing_mit_lookup_100()
    start      = qq(2020, 1);
    state.t    = tseries(start, (0:99)');
    state.keys = start:(start + 99);   % numeric IRIS date vector
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
    state.t    = tseries(qq(2020, 1), (0:99)');
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
    start    = qq(2020, 1);
    state.t  = tseries(start, (0:99)');
    state.rng = (start + 20):(start + 79);
end

function r = run_indexing_mitrange_slice(state)
    r = state.t(state.rng);
end

% ------

function state = setup_indexing_mvts_column()
    state.t = tseries(qq(2020, 1), reshape(0:499, 100, 5), '', ...
                      {'a','b','c','d','e'});
end

function r = run_indexing_mvts_column(state)
    % IRIS 2015: select the 3rd column ('c') via integer column index.
    r = state.t(:, 3);
end

% ------

function state = setup_indexing_lookup_100_api()
    start = qq(2020, 1);
    state.t    = tseries(start, (0:99)');
    state.keys = start:(start + 99);
end

function r = run_indexing_lookup_100_api(state)
    % Vectorised lookup: indexing a tseries with a date vector returns the
    % numeric data column directly.
    r = state.t(state.keys);
end

% ======================================================================
% ARITHMETIC
% ======================================================================
function state = setup_arith_add_misaligned()
    state.a = tseries(qq(2020, 1), (0:99)');
    state.b = tseries(qq(2032, 1), (0:99)' * 0.5);
end

function r = run_arith_add_misaligned(state)
    r = state.a + state.b;
end

% ------

function state = setup_arith_add_aligned()
    start   = qq(2020, 1);
    state.a = tseries(start, (0:99)');
    state.b = tseries(start, (0:99)' * 0.5);
end

function r = run_arith_add_aligned(state)
    r = state.a + state.b;
end

% ------

function state = setup_arith_mul_scalar()
    state.t = tseries(qq(2020, 1), (0:99)');
end

function r = run_arith_mul_scalar(state)
    r = state.t * 2.0;
end

% ======================================================================
% SHIFT / DIFF / PCT
% ======================================================================
function state = setup_shift_quarterly_lag1()
    state.t = tseries(qq(2020, 1), (0:99)');
end

function r = run_shift_quarterly_lag1(state)
    r = shift(state.t, -1);
end

% ------

function state = setup_lead_quarterly_lag1()
    state.t = tseries(qq(2020, 1), (0:99)');
end

function r = run_lead_quarterly_lag1(state)
    r = shift(state.t, 1);
end

% ------

function state = setup_diff_quarterly()
    state.t = tseries(qq(2020, 1), (0:99)');
end

function r = run_diff_quarterly(state)
    r = diff(state.t);
end

% ------

function state = setup_pct_quarterly()
    state.t = tseries(qq(2020, 1), (1:100)');
end

function r = run_pct_quarterly(state)
    r = pct(state.t);
end

% ------

function state = setup_ytypct_quarterly_100()
    state.t = tseries(qq(2020, 1), (1:100)');
end

function r = run_ytypct_quarterly_100(state)
    % Year-over-year on a quarterly series = lag-4 percent change.
    r = pct(state.t, -4);
end

% ======================================================================
% REDUCTIONS
% ======================================================================
function state = setup_mean_quarterly_100()
    state.t = tseries(qq(2020, 1), (0:99)');
end

function r = run_mean_quarterly_100(state)
    r = mean(state.t);
end

% ------

function state = setup_std_quarterly_100()
    state.t = tseries(qq(2020, 1), (0:99)');
end

function r = run_std_quarterly_100(state)
    r = std(state.t);
end

% ------

function state = setup_quantile_quarterly_100()
    rng_seed = RandStream('mt19937ar', 'Seed', 20260515);
    state.t  = tseries(qq(2020, 1), randn(rng_seed, 100, 1));
end

function r = run_quantile_quarterly_100(state)
    % IRIS has no quantile method on tseries; delegate to MATLAB built-in.
    r = quantile(double(state.t), 0.5);
end

% ------

function state = setup_cor_two_tseries()
    rng_seed = RandStream('mt19937ar', 'Seed', 20260515);
    start    = qq(2020, 1);
    state.a  = tseries(start, randn(rng_seed, 100, 1));
    state.b  = tseries(start, randn(rng_seed, 100, 1));
end

function r = run_cor_two_tseries(state)
    r = corr(double(state.a), double(state.b));
end

% ------

function state = setup_cov_two_tseries()
    rng_seed = RandStream('mt19937ar', 'Seed', 20260515);
    start    = qq(2020, 1);
    state.a  = tseries(start, randn(rng_seed, 100, 1));
    state.b  = tseries(start, randn(rng_seed, 100, 1));
end

function r = run_cov_two_tseries(state)
    r = cov([double(state.a), double(state.b)]);
end

% ------

function state = setup_cor_mvts_5_columns()
    rng_seed = RandStream('mt19937ar', 'Seed', 20260515);
    state.t  = tseries(qq(2020, 1), randn(rng_seed, 100, 5), '', ...
                       {'a','b','c','d','e'});
end

function r = run_cor_mvts_5_columns(state)
    r = corr(double(state.t));
end

% ------

function state = setup_cov_mvts_5_columns()
    rng_seed = RandStream('mt19937ar', 'Seed', 20260515);
    state.t  = tseries(qq(2020, 1), randn(rng_seed, 100, 5), '', ...
                       {'a','b','c','d','e'});
end

function r = run_cov_mvts_5_columns(state)
    r = cov(double(state.t));
end

% ======================================================================
% MVTS AXIS REDUCTIONS
% ======================================================================
function state = setup_mean_mvts_axis0_5cols()
    rng_seed = RandStream('mt19937ar', 'Seed', 20260518);
    state.t  = tseries(qq(2020, 1), randn(rng_seed, 100, 5), '', ...
                       {'a','b','c','d','e'});
end

function r = run_mean_mvts_axis0_5cols(state)
    % mean over time -> 1x5 row of per-column means (analogue of axis=0).
    r = mean(state.t);
end

% ------

function state = setup_mean_mvts_axis1_100rows()
    rng_seed = RandStream('mt19937ar', 'Seed', 20260518);
    state.t  = tseries(qq(2020, 1), randn(rng_seed, 100, 5), '', ...
                       {'a','b','c','d','e'});
end

function r = run_mean_mvts_axis1_100rows(state)
    % Per-row mean (analogue of axis=1).  IRIS 2015 does not expose a 'dims'
    % argument on tseries/mean, so build a fresh single-column tseries from
    % the row-wise mean of the underlying matrix.
    d = double(state.t);
    r = tseries(startdate(state.t), mean(d, 2));
end

% ======================================================================
% MOVING / UNDIFF
% ======================================================================
function state = setup_moving_average_quarterly_4()
    state.t = tseries(qq(2020, 1), (0:99)');
end

function r = run_moving_average_quarterly_4(state)
    % Trailing 4-quarter moving average; in IRIS 2015 a negative window
    % length asks for a backward-looking window.
    r = movavg(state.t, -4);
end

% ------

function state = setup_moving_sum_quarterly_4()
    state.t = tseries(qq(2020, 1), (0:99)');
end

function r = run_moving_sum_quarterly_4(state)
    % IRIS 2015 has movsum on tseries; if your install lacks it, replace
    % with movavg(t, -4) * 4 (same numeric result).
    r = movsum(state.t, -4);
end

% ------

function state = setup_undiff_quarterly()
    state.t = tseries(qq(2020, 1), (0:99)');
end

function r = run_undiff_quarterly(state)
    % Undiff = cumulative sum of the differences.  In IRIS, cumsum on a
    % tseries does the same job (the anchor here is the implicit zero of
    % cumsum, matching the tse.undiff(t) default).
    r = cumsum(state.t);
end

% ======================================================================
% RECURSION  (no tse.rec equivalent in IRIS -- manual loop)
% ======================================================================
function state = setup_rec_ar2_100()
    start  = qq(2020, 1);
    n      = 102;
    data   = zeros(n, 1);
    data(1) = 1.0;
    data(2) = 1.0;
    state.target_data = data;
    state.start       = start;
    state.rng         = (start + 2):(start + 101);
end

function r = run_rec_ar2_100(state)
    % Re-seed the target each call so timeit reps are comparable.
    target = tseries(state.start, state.target_data);
    rng    = state.rng;
    for i = 1:numel(rng)
        k = rng(i);
        target(k) = 0.5 * target(k - 1) + 0.3 * target(k - 2);
    end
    r = target;
end

% ------

function state = setup_rec_backcasting_via_lambda()
    start = qq(2020, 1);
    n     = 100;
    data  = zeros(n, 1);
    data(end) = 100.0;
    state.target_data = data;
    state.start       = start;
    state.rng         = (start + (n-2)):-1:start;
end

function r = run_rec_backcasting_via_lambda(state)
    target = tseries(state.start, state.target_data);
    rng    = state.rng;
    for i = 1:numel(rng)
        k = rng(i);
        target(k) = target(k + 1) - 0.5;
    end
    r = target;
end

% ======================================================================
% RANGEOF / LINALG
% ======================================================================
function state = setup_rangeof_tseries_drop1()
    state.t = tseries(qq(2020, 1), (0:99)');
end

function r = run_rangeof_tseries_drop1(state)
    % range(t) returns the full numeric date vector; drop the first period.
    rng = range(state.t);
    r   = rng(2:end);
end

% ------

function state = setup_linalg_matrix_tseries_100()
    rng_seed = RandStream('mt19937ar', 'Seed', 20260518);
    state.A  = randn(rng_seed, 100, 100);
    state.t  = tseries(qq(2020, 1), randn(rng_seed, 100, 1));
end

function r = run_linalg_matrix_tseries_100(state)
    % A * tseries falls through to A * data in IRIS.
    r = state.A * state.t;
end

% ======================================================================
% FREQUENCY CONVERSION
% ======================================================================
function state = setup_fconvert_qq_to_yy_mean()
    state.t = tseries(qq(2020, 1), (0:99)');
end

function r = run_fconvert_qq_to_yy_mean(state)
    r = convert(state.t, 1, 'method', 'mean');   % target freq 1 = yearly
end

% ------

function state = setup_fconvert_qq_to_yy_sum()
    state.t = tseries(qq(2020, 1), (0:99)');
end

function r = run_fconvert_qq_to_yy_sum(state)
    r = convert(state.t, 1, 'method', 'sum');
end

% ------

function state = setup_fconvert_yy_to_qq_const()
    state.t = tseries(yy(2020), (0:24)');
end

function r = run_fconvert_yy_to_qq_const(state)
    % "Const" = repeat each annual value across its four quarters.  IRIS
    % calls this 'flat' (carry the value forward).
    r = convert(state.t, 4, 'method', 'flat');
end

% ------

function state = setup_fconvert_yy_to_qq_linear()
    state.t = tseries(yy(2020), (0:24)');
end

function r = run_fconvert_yy_to_qq_linear(state)
    r = convert(state.t, 4, 'method', 'linear');
end

% ------

function state = setup_fconvert_yy_to_qq_even()
    state.t = tseries(yy(2020), (0:24)');
end

function r = run_fconvert_yy_to_qq_even(state)
    % "Even" = each quarter gets value / 4 (sum-preserving spread).  IRIS
    % 2015 has no single method name for this; emulate by scaling first.
    r = convert(state.t / 4, 4, 'method', 'flat');
end

% ------

function state = setup_fconvert_mm_to_qq_mean()
    state.t = tseries(mm(2020, 1), (0:119)');
end

function r = run_fconvert_mm_to_qq_mean(state)
    r = convert(state.t, 4, 'method', 'mean');
end

% ======================================================================
% MIXED-FREQUENCY PIPELINES
% ======================================================================
function state = setup_mixed_freq_qq_minus_mm_mean()
    state.gdp = tseries(qq(2020, 1), (0:99)');
    state.cpi = tseries(mm(2020, 1), (0:299)');
end

function r = run_mixed_freq_qq_minus_mm_mean(state)
    r = state.gdp - convert(state.cpi, 4, 'method', 'mean');
end

% ------

function state = setup_mixed_freq_pipeline_three_freq()
    state.unemp = tseries(yy(2020),     (0:24)');
    state.gdp   = tseries(qq(2020, 1),  (0:99)');
    state.cpi   = tseries(mm(2020, 1),  (0:299)');
end

function r = run_mixed_freq_pipeline_three_freq(state)
    r = convert(state.unemp, 4, 'method', 'flat') ...
        + state.gdp ...
        + convert(state.cpi, 4, 'method', 'mean');
end

% ======================================================================
% WORKSPACE (struct-as-database)
% ======================================================================
function state = setup_workspace_merge_5_series()
    start = qq(2020, 1);
    arr   = (0:39)';
    w1 = struct(); w2 = struct();
    for name = {'a','b','c','d','e'}
        w1.(name{1}) = tseries(start, arr);
    end
    for name = {'f','g','h','i','j'}
        w2.(name{1}) = tseries(start, arr);
    end
    state.w1 = w1; state.w2 = w2;
end

function r = run_workspace_merge_5_series(state)
    r = dbmerge(state.w1, state.w2);
end

% ------

function state = setup_workspace_filter_5_series()
    start = qq(2020, 1);
    arr   = (0:39)';
    w = struct();
    for name = {'a','b','c','d','e','f','g','h','i','j'}
        w.(name{1}) = tseries(start, arr);
    end
    state.w    = w;
    state.keep = {'a','b','c','d','e'};
end

function r = run_workspace_filter_5_series(state)
    % No dbfilter in IRIS 2015 -- copy the kept fields into a fresh struct.
    r = struct();
    for k = 1:numel(state.keep)
        r.(state.keep{k}) = state.w.(state.keep{k});
    end
end

% ------

function state = setup_compare_workspaces_equal_5_keys()
    start = qq(2020, 1);
    arr   = (0:99)';
    w1 = struct(); w2 = struct();
    for name = {'a','b','c','d','e'}
        w1.(name{1}) = tseries(start, arr);
        w2.(name{1}) = tseries(start, arr);
    end
    state.w1 = w1; state.w2 = w2;
end

function r = run_compare_workspaces_equal_5_keys(state)
    r = dbcompare(state.w1, state.w2);
end

% ------

function state = setup_compare_workspaces_differ_5_keys()
    start = qq(2020, 1);
    arr   = (0:99)';
    w1 = struct(); w2 = struct();
    for name = {'a','b','c','d','e'}
        w1.(name{1}) = tseries(start, arr);
        w2.(name{1}) = tseries(start, arr);
    end
    % Position 50 differs in 'c'.
    w2.c(start + 49) = -999.0;
    state.w1 = w1; state.w2 = w2;
end

function r = run_compare_workspaces_differ_5_keys(state)
    r = dbcompare(state.w1, state.w2);
end
