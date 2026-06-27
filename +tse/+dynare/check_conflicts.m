function info = check_conflicts(varargin)
%CHECK_CONFLICTS  Report bare names defined by both Dynare and tse / MATLAB.
%
%   info = tse.dynare.check_conflicts()
%   info = tse.dynare.check_conflicts('quiet', true)
%
%   Walks the MATLAB path looking for the bare class / function names Dynare
%   exposes at top level (dates, dseries) plus the common operator names that
%   could be shadowed.  For each one with more than one resolution it prints
%   the full list (first wins) and adds an entry to info.shadowed.
%
%   Dynare-vs-tse collisions are usually minimal because every tse helper is
%   namespaced; this is mostly useful when Dynare overlaps with MATLAB's own
%   built-ins.
    p = struct('quiet', false);
    p = tse.x13.getopts(p, varargin);
    quiet = logical(p.quiet);

    names = {'dates', 'dseries'};
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
        fprintf('No bare-name conflicts between Dynare and tse on the current path.\n');
    end
end
