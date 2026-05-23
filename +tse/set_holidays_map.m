function set_holidays_map(country, subdivision)
%SET_HOLIDAYS_MAP  Load a country/subdivision holidays calendar.
%
%   tse.set_holidays_map('CA')          % default subdivision (ON)
%   tse.set_holidays_map('CA', 'QC')
%
%   Stores a BDaily boolean TSeries (true = non-holiday business day,
%   spanning 1970-01-01 .. 2049-12-31) in the 'bdaily_holidays_map' option,
%   used by fconvert's skip_holidays path.
%
%   Holiday calendars are produced with the python-holidays library and
%   bundled from TimeSeriesEcon.jl (data/holidays.bin).
%
%   See also: tse.get_holidays_options, tse.clear_holidays_map.

    if nargin < 2
        subdivision = [];
    end
    col = holidays_index(country, subdivision);
    ts  = build_holidays_map(col);
    tse.setoption('bdaily_holidays_map', ts);
end
