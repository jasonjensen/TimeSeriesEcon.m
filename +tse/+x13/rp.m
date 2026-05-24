classdef rp < tse.x13.X13varRange
%RP  Ramp regression variable spanning a date range.  E.g. tse.x13.rp(2005Q2, 2005Q4).
    methods
        function obj = rp(varargin)
            obj = obj@tse.x13.X13varRange(varargin{:});
        end
    end
end
