classdef tc < tse.x13.X13varMIT
%TC  Temporary-change regression variable at a date.  E.g. tse.x13.tc(2007Q1).
    methods
        function obj = tc(varargin)
            obj = obj@tse.x13.X13varMIT(varargin{:});
        end
    end
end
