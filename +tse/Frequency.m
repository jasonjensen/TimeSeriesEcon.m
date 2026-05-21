classdef (Abstract) Frequency
    %FREQUENCY Abstract base class for all time-series frequencies.
    %
    %   Concrete subclasses include Unit, Yearly, HalfYearly, Quarterly,
    %   Monthly, Weekly, Daily, BDaily.  Subclasses that have an end-of-period
    %   marker (Yearly, HalfYearly, Quarterly, Weekly) carry it on the
    %   instance via the endPeriod property.  Subclasses without a varying
    %   end period (Unit, Monthly, Daily, BDaily) leave endPeriod at its
    %   default.
    %
    %   See also: tse.Quarterly, tse.MIT.

    properties (SetAccess = protected)
        % Set by subclass constructors; treat as immutable thereafter.
        endPeriod (1,1) double {mustBeInteger, mustBePositive} = 1
    end

    properties (Abstract, Constant)
        Name
        PeriodsPerYear
    end

    methods (Abstract)
        d = defaultEndPeriod(F)
    end

    methods
        function tf = eq(a, b)
            tf = isa(a, 'tse.Frequency') ...
                && isa(b, 'tse.Frequency') ...
                && strcmp(class(a), class(b)) ...
                && a.endPeriod == b.endPeriod;
        end

        function tf = ne(a, b)
            tf = ~eq(a, b);
        end

        function tf = lt(a, b)
            tf = a.PeriodsPerYear < b.PeriodsPerYear;
        end

        function tf = le(a, b)
            tf = lt(a, b) || eq(a, b);
        end

        function tf = gt(a, b)
            tf = b.PeriodsPerYear < a.PeriodsPerYear;
        end

        function tf = ge(a, b)
            tf = gt(a, b) || eq(a, b);
        end

        function s = char(F)
            if F.endPeriod == defaultEndPeriod(F)
                s = F.Name;
            else
                s = sprintf('%s{%d}', F.Name, F.endPeriod);
            end
        end

        function s = string(F)
            s = string(char(F));
        end

        function disp(F)
            fprintf('%s\n', char(F));
        end

        function tf = isfrequency(~)
            tf = true;
        end
    end
end
