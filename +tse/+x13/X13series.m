classdef X13series
%X13SERIES  The series spec: the data and how X13 should read it.  Build with tse.x13.series.
    properties
        appendbcst = tse.x13.X13default()
        appendfcst = tse.x13.X13default()
        comptype = tse.x13.X13default()
        compwt = tse.x13.X13default()
        data = tse.x13.X13default()
        decimals = tse.x13.X13default()
        file = tse.x13.X13default()
        format = tse.x13.X13default()
        modelspan = tse.x13.X13default()
        name = tse.x13.X13default()
        period = tse.x13.X13default()
        precision = tse.x13.X13default()
        print = tse.x13.X13default()
        save = tse.x13.X13default()
        span = tse.x13.X13default()
        start = tse.x13.X13default()
        title = tse.x13.X13default()
        type = tse.x13.X13default()
        divpower = tse.x13.X13default()
        missingcode = tse.x13.X13default()
        missingval = tse.x13.X13default()
        saveprecision = tse.x13.X13default()
        trimzero = tse.x13.X13default()
    end
    methods
        function F = frequencyof(obj)
            F = tse.frequencyof(obj.data);
        end
    end
end
