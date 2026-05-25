% TSE.X13  X-13ARIMA-SEATS spec building, serialisation and results.
%
% A faithful MATLAB port of the X13 module of TimeSeriesEcon.jl.  It exposes the
% X13-ARIMA-SEATS spec interface as MATLAB objects, serialises them to the .spc
% format (respecting X13's strict line-length limit), runs the x13as binary, and
% returns the results as TSeries/MVTSeries and structs.
%
% Building a spec
%   newspec        - create a spec from a TSeries, X13series, or frequency
%   series         - the series spec (data + reading options)
%   arima          - the arima spec           ArimaSpec / ArimaModel - model factors
%   automdl        - automatic model choice   pickmdl - model from a candidate list
%   regression     - regression spec          x11 / x11regression - X11 adjustment
%   transform      - transform spec           seats - SEATS adjustment
%   estimate check forecast force history identify metadata outlier
%   slidingspans spectrum   - the remaining specs
%
%   Each constructor also accepts a spec as its first argument to set that
%   subspec in place, e.g. tse.x13.arima(spec, model) (the Julia "name!" form).
%
% Regression variables (tokens for the variables argument)
%   ao ls tc so            - single-date outliers
%   aos lss rp qd qi tl    - date-range regressors
%   td tdnolpyear td1coef td1nolpyear lpyear lom loq seasonal - regime variables
%   tdstock tdstock1coef easter labor thank sceaster easterstock sincos
%   M Q H                  - fuzzy period markers   Span - a (possibly open) span
%
% Serialising and running
%   x13write       - serialise a spec to the .spc string (test=true) or a file
%   run            - run x13as and collect results (needs tse.setoption x13path)
%   deseasonalize  - convenience: default X11 seasonal adjustment of a TSeries
%   X13result / descriptions - the result object and a listing of its outputs
%   cleanup        - remove leftover temporary run folders
%
% Symbol vs string convention: pass Julia "symbols" as char (e.g. 'mult') and
% Julia "strings" (name/title/file/format) as double-quoted strings ("My GDP").
%
% Not ported: the X13as binary itself (set its path via tse.setoption('x13path', ...)).
