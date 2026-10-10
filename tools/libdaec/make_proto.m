function make_proto(libfile, hfile, outdir)
%MAKE_PROTO  Generate the loadlibrary prototype and thunk files for libdaec.
%
%   make_proto(libfile, hfile, outdir) parses daec.h once, on the platform
%   it runs on, and writes daec_proto_<arch>.m plus the compiled thunk
%   library libdaec_thunk_<arch>.<ext> into outdir.  With those shipped
%   next to the library, tse.daec loads libdaec without a C compiler.
%
%   Used by .github/workflows/libdaec.yml; not part of the toolbox.
    arch = computer('arch');
    proto = ['daec_proto_' arch];
    thunk = ['libdaec_thunk_' arch];
    alias = 'tse_libdaec';

    here = pwd;
    restore = onCleanup(@() cd(here));
    cd(outdir);

    if libisloaded(alias), unloadlibrary(alias); end
    loadlibrary(libfile, hfile, 'alias', alias, ...
        'mfilename', proto, 'thunkfilename', thunk);
    fprintf('Generated %s; libdaec reports version %s\n', proto, ...
        calllib(alias, 'de_version'));
    unloadlibrary(alias);

    % The prototype looks for its thunk library next to itself.  The
    % toolbox keeps prototypes in +tse/+daec/private and binaries in
    % private/bin/<arch>, so point it there.
    file = [proto '.m'];
    txt = fileread(file);
    pattern = 'ThunkLibName\s*=\s*fullfile\(\s*MfilePath\s*,\s*''([^'']+)''\s*\)';
    if isempty(regexp(txt, pattern, 'once'))
        error('make_proto:thunk', 'No ThunkLibName line found in %s.', file);
    end
    txt = regexprep(txt, pattern, ...
        sprintf('ThunkLibName=fullfile(MfilePath,''bin'',''%s'',''$1'')', arch));

    % ndtseries_t holds axis_t axis[DE_MAX_AXES], which loadlibrary cannot
    % describe ('axis_t#5'), so de_load_ndtseries would be unusable.  Five
    % consecutive axis_t fields have the same memory layout, so spell the
    % array out as axis1..axis5.
    arrayField = '''axis'', ''axis_t#5''';
    if ~contains(txt, arrayField)
        error('make_proto:ndtseries', 'No ndtseries_t axis array found in %s.', file);
    end
    txt = strrep(txt, arrayField, strjoin(compose('''axis%d'', ''axis_t''', 1:5), ', '));
    fid = fopen(file, 'w');
    fwrite(fid, txt);
    fclose(fid);

    % Check the result the way the toolbox loads it.
    mkdir(fullfile('bin', arch));
    movefile([thunk '.*'], fullfile('bin', arch));
    [~, name, ext] = fileparts(libfile);
    copyfile(libfile, fullfile('bin', arch, [name ext]));
    loadlibrary(fullfile('bin', arch, [name ext]), str2func(proto), 'alias', alias);
    fprintf('Reloaded through the prototype; version %s\n', calllib(alias, 'de_version'));
    unloadlibrary(alias);
end
