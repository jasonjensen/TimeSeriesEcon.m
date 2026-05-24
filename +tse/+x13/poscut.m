function [pos, nv] = poscut(args)
%POSCUT  Split ARGS into leading positionals and trailing name-value pairs.
%
%   Positionals are the leading arguments up to the first char/string scalar
%   (which begins the name-value section).  Used by constructors that take
%   positional objects (arima, pickmdl) followed by keyword options.
    i = 1;
    while i <= numel(args)
        a = args{i};
        if ischar(a) || (isstring(a) && isscalar(a))
            break
        end
        i = i + 1;
    end
    pos = args(1:i-1);
    nv = args(i:end);
end
