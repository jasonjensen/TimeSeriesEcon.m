classdef td1coef < tse.x13.X13varRegime
%TD1COEF  One-coefficient trading-day regression variable.
    methods
        function obj = td1coef(varargin)
            obj = obj@tse.x13.X13varRegime(varargin{:});
        end
    end
end
