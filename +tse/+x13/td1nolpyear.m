classdef td1nolpyear < tse.x13.X13varRegime
%TD1NOLPYEAR  One-coefficient trading-day variable without a leap-year effect.
    methods
        function obj = td1nolpyear(varargin)
            obj = obj@tse.x13.X13varRegime(varargin{:});
        end
    end
end
