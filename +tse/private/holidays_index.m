function col = holidays_index(country, subdivision)
%HOLIDAYS_INDEX  Resolve a (country, subdivision) to its column in holidays.bin.
    J = read_holidays_json();
    names = string(J.names);
    idx   = double(J.indices);
    country = string(country);
    hasSub = any(startsWith(names, country + "|"));
    if nargin < 2 || isempty(subdivision)
        if hasSub
            dc = string(J.defaults_country);
            ds = string(J.defaults_sub);
            di = find(dc == country, 1);
            if isempty(di)
                error('tseries:noMatch', ...
                    'Country %s has subdivisions; please supply one (see tse.get_holidays_options).', country);
            end
            key = country + "|" + ds(di);
        else
            key = country;
        end
    else
        key = country + "|" + string(subdivision);
    end
    m = find(names == key, 1);
    if isempty(m)
        error('tseries:noMatch', 'Unsupported holidays selection: %s', key);
    end
    col = idx(m);
end
