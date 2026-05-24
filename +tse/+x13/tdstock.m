classdef tdstock < tse.x13.X13varN
%TDSTOCK  Stock trading-day regression variable.  E.g. tse.x13.tdstock(31).
    methods
        function obj = tdstock(varargin)
            obj = obj@tse.x13.X13varN(varargin{:});
        end
    end
end
