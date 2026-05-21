% tseries  - MATLAB port of TimeSeriesEcon.jl
%
% Frequencies
%   Frequency           - Abstract base class
%   CalendarFrequency   - Abstract: calendar-aligned
%   YPFrequency         - Abstract: year-period
%   Unit, Yearly, HalfYearly, Quarterly, Monthly, Weekly, Daily, BDaily
%
% Moments and durations
%   MIT                 - Moment in time
%   Duration            - Distance between two MITs
%   MITRange            - Inclusive range of MITs
%
% MIT constructors
%   qq(y,p)             - Quarterly
%   mm(y,p)             - Monthly
%   yy(y[,p])           - Yearly
%   daily(d)            - Daily from datetime / string
%   bdaily(d,...)       - Business daily with optional 'bias'
%   weekly(d[,end])     - Weekly
%   weekly_from_iso(y,p)- Weekly from ISO (year, week)
%
% Inspection
%   frequencyof(x)      - Frequency of MIT/Duration/MITRange/Frequency
%   year(m), period(m)  - Year and period of an MIT (YP only)
%   mit2yp(m)           - [year, period] for an MIT
%   ppy(x)              - Periods per year
%   endperiod(x)        - End-of-period marker
%   sanitize_frequency  - Canonical Frequency instance from name
%   rangeof_span(...)   - Union of input ranges
%
% Frequency predicates
%   isyearly, ishalfyearly, isquarterly, ismonthly,
%   isweekly, isdaily, isbdaily
