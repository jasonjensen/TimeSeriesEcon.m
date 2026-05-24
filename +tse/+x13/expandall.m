function v = expandall(v, allList)
%EXPANDALL  Expand a print/save value of 'all' into its full list.
%
%   Mirrors the Julia behaviour where print=:all or save=:all is replaced by the
%   spec-specific list of every available table.  ALLLIST is a cellstr.
    isAll = (ischar(v) && strcmp(v, 'all')) || ...
            (iscell(v) && isscalar(v) && ischar(v{1}) && strcmp(v{1}, 'all'));
    if isAll
        v = allList;
    end
end
