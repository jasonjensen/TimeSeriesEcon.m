function v = daec_unpack(ptr, eltype, elfreq, nbytes, n)
%DAEC_UNPACK  Copy n stored elements out of libdaec memory.
%
%   v = daec_unpack(ptr, eltype, elfreq, nbytes, n) returns an n-by-1
%   column.  ptr is the value pointer from a scalar_t, tseries_t,
%   mvtseries_t or ndtseries_t, which libdaec keeps valid only until the
%   next library call, so unpack before calling anything else.
%
%   The element width is nbytes / n, as in TimeSeriesEcon.jl: a float of 4
%   bytes reads as single, an integer of 4 bytes as int32, and so on.
%   Dates read as tse.MIT and integers with a frequency as tse.Duration;
%   both need 8 bytes per element, and no other type takes a frequency.
%
%   Reading retypes ptr in place (setdatatype), which is safe because each
%   value pointer is read once.
    e = daec_enums();
    T = e.type_t;
    eltype = daec_code('type_t', eltype);
    elfreq = daec_code('frequency_t', elfreq);
    nbytes = double(nbytes);
    n = double(n);
    if elfreq ~= 0 && ~ismember(eltype, [T.type_date T.type_signed])
        error('tseries:daec', 'Elements of type %d cannot have a frequency.', eltype);
    end

    switch eltype
        case T.type_string
            v = strings(n, 1);
            if n == 0
                return
            end
            bytes = readPointer(ptr, 'uint8', nbytes);
            stops = find(bytes == 0);
            if numel(stops) ~= n || stops(end) ~= nbytes
                error('tseries:daec', ['Expected %d zero-terminated strings ' ...
                    'in %d bytes.'], n, nbytes);
            end
            start = 1;
            for k = 1:n
                b = reshape(bytes(start:stops(k)-1), 1, []);
                v(k) = string(native2unicode(b, 'UTF-8'));
                if ~isequal(reshape(unicode2native(char(v(k)), 'UTF-8'), 1, []), b)
                    error('tseries:daec', 'String %d is not valid UTF-8.', k);
                end
                start = stops(k) + 1;
            end
        case T.type_date
            elementWidth(nbytes, n, 8, 8);
            v = toDates(@tse.MIT, elfreq, readPointer(ptr, 'int64', n), n);
        case {T.type_signed, T.type_unsigned}
            if eltype == T.type_signed && elfreq ~= 0
                elementWidth(nbytes, n, 8, 8);
                v = toDates(@tse.Duration, elfreq, readPointer(ptr, 'int64', n), n);
                return
            end
            sign = 'int';
            if eltype == T.type_unsigned
                sign = 'uint';
            end
            width = elementWidth(nbytes, n, 8, [1 2 4 8]);
            v = readPointer(ptr, sprintf('%s%d', sign, 8 * width), n);
        case T.type_float
            width = elementWidth(nbytes, n, 8, [4 8]);
            v = readPointer(ptr, floatClass(width), n);
        case T.type_complex
            width = elementWidth(nbytes, n, 16, [8 16]);
            x = readPointer(ptr, floatClass(width / 2), 2 * n);
            v = complex(x(1:2:end), x(2:2:end));
        otherwise
            error('tseries:daec', 'Cannot read elements of type %d.', eltype);
    end
end

function x = readPointer(ptr, cls, count)
    if count == 0
        x = zeros(0, 1, cls);
        return
    end
    if ~isa(ptr, 'lib.pointer') || isNull(ptr)
        error('tseries:daec', 'libdaec returned no data.');
    end
    setdatatype(ptr, [cls 'Ptr'], count, 1);
    x = reshape(ptr.Value, [], 1);
end

function width = elementWidth(nbytes, n, default, allowed)
    if n == 0
        width = default;
        return
    end
    width = nbytes / n;
    if ~ismember(width, allowed)
        error('tseries:daec', 'Cannot read elements of %g bytes.', width);
    end
end

function cls = floatClass(width)
    if width == 4
        cls = 'single';
    else
        cls = 'double';
    end
end

function v = toDates(ctor, freq, codes, n)
    if n == 0
        v = repmat(ctor(freq, 0), 0, 1);
        return
    end
    v = repmat(ctor(freq, codes(1)), n, 1);
    for k = 2:n
        v(k) = ctor(freq, codes(k));
    end
end
