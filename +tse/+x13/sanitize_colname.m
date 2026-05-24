function s = sanitize_colname(s)
%SANITIZE_COLNAME  Replace whitespace, '-' and '.' runs in a column name with '_'.
    s = regexprep(char(s), '[\s\-\.]+', '_');
end
