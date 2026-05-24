classdef sincos < tse.x13.X13var
%SINCOS  Trigonometric (sine/cosine) seasonal regression variable.
%   tse.x13.sincos([1 2 3])  ->  "sincos[1 2 3]".
    properties
        n
    end
    methods
        function obj = sincos(n)
            if nargin > 0
                obj.n = n;
            end
        end
        function s = x13str(obj)
            parts = arrayfun(@(x) sprintf('%d', double(x)), obj.n(:).', ...
                'UniformOutput', false);
            s = ['sincos[' strjoin(parts, ' ') ']'];
        end
    end
end
