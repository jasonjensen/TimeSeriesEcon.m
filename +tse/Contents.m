% tse  -  TimeSeriesEcon.m: time-series data types for macroeconomics
%
%   A MATLAB port of TimeSeriesEcon.jl (Bank of Canada).  The package is
%   built around three ideas: a moment in time (MIT), a univariate time
%   series (TSeries), and a multivariate time series (MVTSeries).  Call
%   everything through the package prefix, e.g. tse.qq(2020, 1), or add
%   `import tse.*` at the top of a script.
%
% Frequencies (classes)
%   Frequency           - Abstract base class for all frequencies
%   CalendarFrequency   - Abstract: calendar-aligned frequencies
%   YPFrequency         - Abstract: year-period frequencies
%   Unit                - Non-calendar integer frequency
%   Yearly              - 1 period/year   (end month 1..12, default 12)
%   HalfYearly          - 2 periods/year  (end month 1..6,  default 6)
%   Quarterly           - 4 periods/year  (end month 1..3,  default 3)
%   Monthly             - 12 periods/year
%   Weekly              - end-of-week day 1..7 (default 7 = Sunday)
%   Daily               - every calendar day
%   BDaily              - business days (excludes Sat/Sun)
%
% Moments, durations, ranges (classes)
%   MIT                 - Moment in time of a given frequency
%   Duration            - Signed distance between two MITs
%   MITRange            - Inclusive, evenly-spaced range of MITs
%
% Time-series containers (classes)
%   TSeries             - Univariate time series indexed by MIT
%   MVTSeries           - Multivariate time series (MIT rows x named cols)
%
% MIT constructors (functions)
%   qq(y, p)            - Quarterly MIT
%   mm(y, p)            - Monthly MIT
%   yy(y[, p])          - Yearly MIT
%   day(d[, d2])        - Daily MIT or range, from datetime/string
%   bday(d, ...)        - Business-daily MIT or range ('bias' option)
%   week(d[, endDay])   - Weekly MIT
%   weekly_from_iso(y,p)- Weekly{7} MIT from ISO (year, week)
%
% Inspection
%   frequencyof(x)      - Frequency of an MIT/Duration/range/series
%   year(m), period(m)  - Year / period of a YP-frequency MIT
%   mit2yp(m)           - [year, period] of an MIT
%   ppy(x)              - Periods per year
%   endperiod(x)        - End-of-period marker (end month / end day)
%   sanitize_frequency  - Canonical Frequency instance from a name
%   firstdate(x)        - First MIT of a series / range
%   lastdate(x)         - Last MIT of a series / range
%   rangeof(x, ...)     - Stored range of a series ('drop' option)
%   rangeof_span(...)   - Range covering the union of inputs
%   toDate(m[, ref])    - Calendar date of a calendar-frequency MIT
%   LinearIndices(x)    - 1:numel(x) index vector
%
% Frequency predicates
%   isyearly, ishalfyearly, isquarterly, ismonthly,
%   isweekly, isdaily, isbdaily, istypenan
%
% Transforms and helpers (functions)
%   fconvert            - Convert MIT/range/series to another frequency
%   diff_ts             - Difference of a TSeries (Julia diff convention)
%   undiff              - Inverse of diff_ts (cumulative sum)
%   lookup              - Vectorised gather of values at MIT keys
%   overlay             - First-valid-wins composition of series
%   reindex             - Re-anchor a series so `from` maps to `to`
%   strip_ts            - Drop leading/trailing NaNs
%   rec                 - Recursive (loop) evaluation over a range
%   compare_ts          - Compare two series / values with tolerance
%   extend_series       - Pad to the period boundaries of another frequency
%   trim_series         - Trim to a frequency-aligned subrange
%   cleanedvalues       - Holiday/NaN-filtered values of a BDaily series
%   typenan / istypenan - Type-appropriate not-a-number sentinel
%
% TSeries / MVTSeries methods (call as t.method(...) or method(t,...))
%   shift, lag, lead, cumsum, diff_ts, pct, apct, ytypct,
%   moving_average, moving_sum, mean, std, var, median, sum, min, max,
%   plot, rangeof, firstdate, lastdate
%
% Options and holidays
%   getoption / setoption          - Read / set a package option
%   set_holidays_map(country[,sub]) - Load a BDaily holiday calendar
%   get_holidays_options([country]) - List supported countries / subdivisions
%   clear_holidays_map             - Clear the current holiday calendar
%
% Documentation
%   See the docs/ folder for tutorials and a reference manual, and
%   docs/design/migration_from_julia.md for a Julia -> MATLAB idiom map.
%
% Not included
%   X-13ARIMA-SEATS (x13) and DataEcon file I/O are out of scope.
