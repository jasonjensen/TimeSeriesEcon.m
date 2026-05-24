function s = juliafloat(x)
%JULIAFLOAT  Format a double the way Julia's string(::Float64) does.
%
%   Integer-valued numbers keep a trailing ".0" (e.g. 4 -> "4.0"); other
%   numbers use the shortest decimal that round-trips (e.g. 0.05, 0.0001).  This
%   matches the spec strings produced by the Julia X13 module.
    x = double(x);
    if isnan(x)
        s = 'NaN';
        return
    end
    if isinf(x)
        if x > 0, s = 'Inf'; else, s = '-Inf'; end
        return
    end
    if x == floor(x) && abs(x) < 1e15
        s = sprintf('%.1f', x);
        return
    end
    s = sprintf('%.17g', x);
    for p = 1:17
        cand = sprintf('%.*g', p, x);
        if str2double(cand) == x
            s = cand;
            break
        end
    end
    if isempty(strfind(s, '.')) && isempty(strfind(lower(s), 'e')) %#ok<STREMP>
        s = [s '.0'];
    end
end
