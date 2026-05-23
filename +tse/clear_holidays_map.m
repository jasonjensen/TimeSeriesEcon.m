function clear_holidays_map()
%CLEAR_HOLIDAYS_MAP  Clear the current holidays map.
%
%   See also: tse.set_holidays_map.
    tse.setoption('bdaily_holidays_map', []);
end
