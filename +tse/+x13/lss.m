classdef lss < tse.x13.X13varRange
%LSS  Level-shift sequence over a date range.  E.g. tse.x13.lss(2005Q2, 2005Q4).
    methods
        function obj = lss(varargin)
            obj = obj@tse.x13.X13varRange(varargin{:});
        end
    end
end
