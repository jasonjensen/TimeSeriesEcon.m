function res = run(spec, varargin)
%RUN  Run X13-ARIMA-SEATS on a spec and collect the results.
%
%   res = tse.x13.run(spec)
%   res = tse.x13.run(spec, 'verbose', false, 'allow_errors', false)
%   res = tse.x13.run(specString, freq, ...)
%
%   The x13as executable is located via tse.getoption('x13path'); set it with
%   tse.setoption('x13path', '/path/to/x13as').  Unlike the Julia package there
%   is no bundled binary, so this option must be set.
%
%   Returns a tse.x13.X13result whose series/tables/text/other structs hold the
%   loaded outputs.  See also: tse.x13.X13result, tse.x13.descriptions.
    if ischar(spec) || isstring(spec)
        if isempty(varargin) || ~isa(varargin{1}, 'tse.Frequency')
            error('tseries:noMatch', 'run(specString, freq, ...) requires a frequency.');
        end
        freq = varargin{1};
        varargin(1) = [];
        s = tse.x13.newspec(freq);
        s.string = char(spec);
        s.folder = tse.x13.x13tempdir();
        fid = fopen(fullfile(s.folder, 'spec.spc'), 'w');
        fprintf(fid, '%s\n', s.string);
        fclose(fid);
        spec = s;
        F = freq;
    else
        tse.x13.x13write(spec);
        F = tse.frequencyof(spec.series.data);
    end

    p = struct('verbose', true, 'allow_errors', false, 'load', 'all');
    p = tse.x13.getopts(p, varargin);

    folder = char(spec.folder);
    gpath = fullfile(folder, 'graphics');
    if ~isfolder(gpath), mkdir(gpath); end

    x13path = tse.getoption('x13path');
    if isempty(x13path)
        error('tseries:noMatch', ...
            ['No x13as binary is configured. Set it with ', ...
             'tse.setoption(''x13path'', ''/path/to/x13as'').  ', ...
             'The MATLAB port does not bundle the X13-ARIMA-SEATS executable.']);
    end

    cmd = sprintf('"%s" -I "%s" -G "%s" -S', x13path, fullfile(folder, 'spec'), gpath);
    old = cd(folder);
    restore = onCleanup(@() cd(old));
    [~, stdout] = system(cmd);
    clear restore;

    res = tse.x13.X13result(spec, folder, stdout);

    stdoutLines = strsplit(stdout, newline, 'CollapseDelimiters', false);
    for i = 1:numel(stdoutLines)
        if contains(stdoutLines{i}, 'ERROR:')
            msg = stdoutLines{i};
            if p.allow_errors
                warning('%s', msg);
            else
                error('tseries:noMatch', 'X13 reported: %s', msg);
            end
        end
    end

    C = tse.x13.x13consts();
    files = local_listfiles(folder);
    for k = 1:numel(files)
        file = files{k};
        [~, ~, e] = fileparts(file);
        ext = regexprep(e, '^\.', '');
        if ismember(ext, C.series_extensions) || ismember(ext, C.probably_series_extensions)
            res.series.(matlab.lang.makeValidName(ext)) = tse.x13.loadresult(file, ext, F);
        elseif ismember(ext, C.table_extensions)
            res.tables.(matlab.lang.makeValidName(ext)) = tse.x13.loadresult(file, ext, F);
        elseif strcmp(ext, 'udg') || ismember(ext, C.kv_list_extensions) || ...
                ismember(ext, {'est','mdl','ipc','iac'})
            res.other.(matlab.lang.makeValidName(ext)) = tse.x13.loadresult(file, ext, F);
        elseif strcmp(ext, 'err')
            [res.warnings, res.notes, res.errors] = tse.x13.x13read_err(file);
            res.text.err = fileread(file);
        elseif ismember(ext, C.human_text_extensions)
            res.text.(matlab.lang.makeValidName(ext)) = fileread(file);
        end
    end

    if p.verbose
        for i = 1:numel(res.warnings), warning('%s', res.warnings{i}); end
        for i = 1:numel(res.notes), fprintf('NOTE: %s\n', res.notes{i}); end
    end
    if ~isempty(res.errors) && ~p.allow_errors
        error('tseries:noMatch', 'There were errors in the specification file.');
    end
end

function files = local_listfiles(folder)
    files = {};
    d = dir(folder);
    for i = 1:numel(d)
        if d(i).isdir
            if ~ismember(d(i).name, {'.','..'})
                sub = dir(fullfile(folder, d(i).name));
                for j = 1:numel(sub)
                    if ~sub(j).isdir
                        files{end+1} = fullfile(folder, d(i).name, sub(j).name); %#ok<AGROW>
                    end
                end
            end
        else
            files{end+1} = fullfile(folder, d(i).name); %#ok<AGROW>
        end
    end
end
