function c = daec_code(kind, v)
%DAEC_CODE  Numeric value of a libdaec enum.
%
%   calllib returns enum fields as their names, and several names share a
%   value (type_integer and type_signed, the weekly and end-month
%   frequencies), so compare codes, never names.
%
%   c = daec_code('type_t', 'type_signed')     % 1
%   c = daec_code('frequency_t', 65)           % 65
    if isnumeric(v)
        c = double(v);
        return
    end
    e = daec_enums();
    table = e.(kind);
    v = char(v);
    if ~isfield(table, v)
        error('tseries:daec', 'Unknown %s value ''%s''.', kind, v);
    end
    c = table.(v);
end
