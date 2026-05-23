function out = get_holidays_options(country)
%GET_HOLIDAYS_OPTIONS  List supported holiday countries / subdivisions.
%
%   tse.get_holidays_options()      % all supported country codes
%   tse.get_holidays_options('CA')  % subdivisions for a country
%
%   See also: tse.set_holidays_map.

    J = read_holidays_json();
    names = string(J.names);
    if nargin >= 1 && ~isempty(country)
        country = string(country);
        subs = names(startsWith(names, country + "|"));
        if isempty(subs)
            if any(names == country)
                out = country;
            else
                error('tseries:noMatch', ...
                    '%s is not a supported country. Run with no argument to list options.', country);
            end
            return
        end
        out = erase(subs, country + "|");
        return
    end
    c = strings(size(names));
    for i = 1:numel(names)
        if contains(names(i), "|")
            c(i) = extractBefore(names(i), "|");
        else
            c(i) = names(i);
        end
    end
    out = unique(c);
end
