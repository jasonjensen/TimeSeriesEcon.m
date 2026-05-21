function tf = istypenan(x)
%ISTYPENAN  Return true if x represents the "not-a-number" sentinel for
%its type.

    if isempty(x)
        tf = false;
        return
    end
    if isa(x, 'double') || isa(x, 'single')
        tf = isnan(x);
    elseif islogical(x)
        tf = false;
    elseif isnumeric(x)
        tf = (x == intmax(class(x)));
    else
        tf = false;
    end
end
