classdef seasonal < tse.x13.X13varRegime
%SEASONAL  Fixed-seasonal regression variable, optionally with a regime change.
    methods
        function obj = seasonal(varargin)
            obj = obj@tse.x13.X13varRegime(varargin{:});
        end
    end
end
