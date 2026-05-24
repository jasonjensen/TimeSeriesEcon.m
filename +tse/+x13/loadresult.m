function out = loadresult(file, ext, F)
%LOADRESULT  Read one X13 output file into the appropriate MATLAB object.
%
%   Dispatches on the file extension EXT: series files become TSeries/MVTSeries,
%   table files become structs of columns, key/value and .udg files become
%   structs, and human-readable files become char.  F is the run frequency.
    C = tse.x13.x13consts();
    if ismember(ext, C.series_extensions) || ismember(ext, C.probably_series_extensions)
        out = tse.x13.x13read_series(file, F);
    elseif ismember(ext, C.table_extensions)
        lines = strsplit(fileread(file), newline, 'CollapseDelimiters', false);
        out = tse.x13.x13read_workspace_table(lines);
    elseif strcmp(ext, 'udg')
        lines = strsplit(fileread(file), newline, 'CollapseDelimiters', false);
        out = tse.x13.x13read_key_values(lines, ': ');
    elseif ismember(ext, C.kv_list_extensions)
        lines = strsplit(fileread(file), newline, 'CollapseDelimiters', false);
        out = tse.x13.x13read_key_values(lines, '\s+');
    else
        out = fileread(file);
    end
end
