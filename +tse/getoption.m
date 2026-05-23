function v = getoption(key)
%GETOPTION  Return the current value of a package option.
%
%   v = tse.getoption('bdaily_holidays_map')
%
%   See also: tse.setoption.
    v = options_db('get', key);
end
