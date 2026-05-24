classdef so < tse.x13.X13varMIT
%SO  Seasonal-outlier regression variable at a date.  E.g. tse.x13.so(2007Q1).
    methods
        function obj = so(varargin)
            obj = obj@tse.x13.X13varMIT(varargin{:});
        end
    end
end
