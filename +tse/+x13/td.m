classdef td < tse.x13.X13varRegime
%TD  Trading-day regression variable, optionally with a regime change.
%   tse.x13.td()  ->  "td";  tse.x13.td(2007Q1)  ->  "td/2007.1/".
    methods
        function obj = td(varargin)
            obj = obj@tse.x13.X13varRegime(varargin{:});
        end
    end
end
