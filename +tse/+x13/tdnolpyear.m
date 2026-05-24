classdef tdnolpyear < tse.x13.X13varRegime
%TDNOLPYEAR  Trading-day regression variable without a leap-year effect.
    methods
        function obj = tdnolpyear(varargin)
            obj = obj@tse.x13.X13varRegime(varargin{:});
        end
    end
end
