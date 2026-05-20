function d = dateOfYearJan1(y)
%DATEOFYEARJAN1 Return January 1 of the given (proleptic Gregorian) year.
    d = datetime(double(y), 1, 1);
end
