function v = daec_assemble(objType, axes, values, jeltype)
%DAEC_ASSEMBLE  The MATLAB value for a stored array.
%
%   Plain axes give a plain array (one axis gives a column), one range axis
%   gives a tse.TSeries, and a range axis followed by a names axis gives a
%   tse.MVTSeries.  A stored range (type_range) gives a tse.MITRange, or
%   1:n for a plain axis.  Anything else, such as names-by-dates or a 3-d
%   array with a range axis, gives a tse.daec.Array.
%
%   jeltype 'Bool' turns stored 0 and 1 back into logicals.
    e = daec_enums();
    if strcmp(jeltype, 'Bool') && isnumeric(values)
        values = daec_bool(values);
    end
    lens = [axes.length];
    kinds = [axes.kind];
    if daec_code('type_t', objType) == e.type_t.type_range && numel(axes) == 1
        if kinds == "range"
            v = axes(1).range;
        else
            v = 1:lens;
        end
        return
    end
    if numel(lens) == 1
        values = reshape(values, [], 1);
    else
        values = reshape(values, lens);
    end
    numericValues = isnumeric(values) || islogical(values);
    if all(kinds == "plain")
        v = values;
    elseif numericValues && isequal(kinds, "range")
        v = tse.TSeries(axes(1).firstdate(), values);
        v.values = keepComplex(v.values, values);
    elseif numericValues && isequal(kinds, ["range" "names"])
        v = tse.MVTSeries(axes(1).firstdate(), axes(2).names, values);
        v.values = keepComplex(v.values, values);
    else
        v = tse.daec.Array(axes, values);
    end
end

function v = keepComplex(v, source)
% Indexing drops the complex flag of values whose imaginary parts are all
% zero; keep it so that a stored complex series reads back complex.
    if ~isreal(source) && isreal(v)
        v = complex(v);
    end
end
