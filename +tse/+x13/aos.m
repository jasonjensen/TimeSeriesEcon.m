classdef aos < tse.x13.X13varRange
%AOS  Additive-outlier sequence over a date range.  E.g. tse.x13.aos(2005Q2, 2005Q4).
    methods
        function obj = aos(varargin)
            obj = obj@tse.x13.X13varRange(varargin{:});
        end
    end
end
