function v = dateToDailyValue(d)
%DATETODAILYVALUE Map a datetime to MIT{Daily} raw integer value.
%
%   Julia defines _d0 = Date(1,1,1) - Day(1) (i.e. 0000-12-31) and stores
%   the daily value as days since _d0.  Date(2022,1,1) ↦ 738156.

    epoch = datetime(0, 12, 31);
    v = int64(floor(days(d - epoch)));
end
