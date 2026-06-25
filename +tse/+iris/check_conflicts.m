function info = check_conflicts(varargin)
%CHECK_CONFLICTS  Report bare names defined by both IRIS and tse.
%
%   info = tse.iris.check_conflicts()
%   info = tse.iris.check_conflicts('quiet', true)
%
%   Walks the MATLAB path looking for the bare date-helper names that IRIS
%   exposes at top level (qq, mm, yy, ww, hh, dd, zz).  For each one with
%   more than one resolution it prints the full list (first wins) and adds
%   an entry to info.shadowed.
%
%   The returned struct has:
%       info.shadowed  - cell array of structs with fields .name and .paths
%
%   This is informational; it does not change the path.  Path order is what
%   determines which one wins (IRIS-first is the normal arrangement).
    p = struct('quiet', false);
    p = tse.x13.getopts(p, varargin);   % reuse the X13 name-value parser
    quiet = logical(p.quiet);

    names = {'qq','mm','yy','ww','hh','dd','zz'};
    info  = struct('shadowed', {{}});

    for i = 1:numel(names)
        nm = names{i};
        locs = which(nm, '-all');
        if ischar(locs), locs = {locs}; end
        locs = locs(~cellfun('isempty', locs));
        if numel(locs) > 1
            entry = struct('name', nm, 'paths', {locs});
            info.shadowed{end+1} = entry; %#ok<AGROW>
            if ~quiet
                fprintf('%s (first wins):\n', nm);
                for j = 1:numel(locs)
                    fprintf('    %s\n', locs{j});
                end
            end
        end
    end

    if ~quiet && isempty(info.shadowed)
        fprintf('No bare-name conflicts between IRIS and tse on the current path.\n');
    end
end
