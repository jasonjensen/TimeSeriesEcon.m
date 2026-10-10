function p = daec_pack(v)
%DAEC_PACK  Lay out MATLAB values the way libdaec stores them.
%
%   p = daec_pack(v) returns a struct with
%     eltype   type_t code of the elements
%     elfreq   frequency_t code (dates and durations; 0 otherwise)
%     nbytes   size of the data in bytes
%     ptr      lib.pointer to the data, column-major (a null pointer when
%              there is no data)
%     jeltype  'Bool' for logical values, else ''.  Stored as the jeltype
%              (arrays) or jtype (scalars) attribute, as TimeSeriesEcon.jl
%              does, so both languages read them back as logical/Bool.
%
%   The element layout matches TimeSeriesEcon.jl: integers keep their
%   width, logicals are 1-byte signed integers, complex values are
%   interleaved real/imaginary pairs, and strings are UTF-8, each followed
%   by a zero byte.
    e = daec_enums();
    T = e.type_t;
    p = struct('eltype', 0, 'elfreq', 0, 'nbytes', 0, 'ptr', [], 'jeltype', '');

    if isa(v, 'tse.MIT') || isa(v, 'tse.Duration')
        if isempty(v)
            error('tseries:daec', 'Cannot store an empty array of dates; its frequency is unknown.');
        end
        f = unique(double([v.frequency]));
        if numel(f) > 1
            error('tseries:daec', 'Cannot store dates of mixed frequencies.');
        end
        data = reshape([v.value], size(v));
        if isa(v, 'tse.MIT')
            p.eltype = T.type_date;
        else
            p.eltype = T.type_signed;
        end
        p.elfreq = f;
    elseif islogical(v)
        data = int8(v);
        p.eltype = T.type_signed;
        p.jeltype = 'Bool';
    elseif isinteger(v)
        data = v;
        if startsWith(class(v), 'u')
            p.eltype = T.type_unsigned;
        else
            p.eltype = T.type_signed;
        end
    elseif isfloat(v)
        if isreal(v)
            data = v;
            p.eltype = T.type_float;
        else
            data = [reshape(real(v), 1, []); reshape(imag(v), 1, [])];
            p.eltype = T.type_complex;
        end
    elseif isstring(v) || iscellstr(v) || ischar(v)
        if ischar(v)
            v = cellstr(v);
        end
        s = string(v);
        if any(ismissing(s(:)))
            error('tseries:daec', 'Cannot store missing strings.');
        end
        parts = cell(1, numel(s));
        for k = 1:numel(s)
            parts{k} = [unicode2native(char(s(k)), 'UTF-8'), uint8(0)];
        end
        data = [uint8.empty(1, 0), parts{:}];
        p.eltype = T.type_string;
    else
        error('tseries:daec', 'Cannot store values of class %s.', class(v));
    end

    if isempty(data)
        p.ptr = libpointer();
        p.nbytes = 0;
        return
    end
    switch class(data)
        case {'int8', 'uint8'},             width = 1;
        case {'int16', 'uint16'},           width = 2;
        case {'int32', 'uint32', 'single'}, width = 4;
        otherwise,                          width = 8;
    end
    p.nbytes = numel(data) * width;
    p.ptr = libpointer([class(data) 'Ptr'], data(:));
end
