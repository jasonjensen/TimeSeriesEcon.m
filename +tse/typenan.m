function v = typenan(T)
%TYPENAN  Sentinel "not-a-number" value for the given type.
%
%   typenan('double')  -> NaN
%   typenan('single')  -> single(NaN)
%   typenan('int32')   -> intmax('int32')
%   typenan('logical') -> false

    if isa(T, 'function_handle')
        T = func2str(T);
    end
    if ischar(T) || isstring(T)
        T = char(T);
        switch T
            case 'double', v = NaN;
            case 'single', v = single(NaN);
            case 'logical', v = false;
            otherwise
                if startsWith(T, 'int') || startsWith(T, 'uint')
                    v = intmax(T);
                else
                    v = NaN;
                end
        end
    elseif isnumeric(T) || islogical(T)
        v = tse.typenan(class(T));
    else
        v = NaN;
    end
end
