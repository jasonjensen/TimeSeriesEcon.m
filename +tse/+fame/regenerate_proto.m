function regenerate_proto()
%REGENERATE_PROTO  Maintainer helper: rebuild private/hli_proto.m from fame.h.
%
%   tse.fame.regenerate_proto()
%
%   Locates $FAME/hli/64/fame.h (or $FAME/hli/fame.h on 32-bit MATLAB), asks
%   MATLAB's loadlibrary to generate a fresh prototype file, and writes it to
%   +tse/+fame/private/hli_proto.m.
%
%   Only maintainers run this -- it needs a supported C compiler and $FAME set.
%   Regular users do NOT need to call it; the committed hli_proto.m is enough.
%
%   The auto-generated file may need small hand-edits (see the comment at
%   the top of hli_proto.m for the current known ones).
    famehome = getenv('FAME');
    if isempty(famehome)
        error('tseries:noMatch', ...
            'Environment variable FAME is not set; cannot locate fame.h.');
    end

    if strcmp(mexext(), 'mexw64') || strcmp(mexext(), 'mexa64') ...
            || strcmp(mexext(), 'mexmaci64')
        header = fullfile(famehome, 'hli', '64', 'fame.h');
    else
        header = fullfile(famehome, 'hli', 'fame.h');
    end
    if exist(header, 'file') ~= 2
        error('tseries:noMatch', ...
            'fame.h not found at %s.  Expected $FAME/hli or $FAME/hli/64.', header);
    end

    here = fileparts(mfilename('fullpath'));
    outdir = fullfile(here, 'private');
    if exist(outdir, 'dir') ~= 7
        mkdir(outdir);
    end

    was_loaded = libisloaded('hli');
    if was_loaded
        unloadlibrary('hli');
    end
    loadlibrary('hli', header, ...
        'mfilename', fullfile(outdir, 'hli_proto.m'), ...
        'includepath', fileparts(header), ...
        'notempdir');
    unloadlibrary('hli');

    fprintf('Wrote %s.\nReview it and re-commit.\n', ...
        fullfile(outdir, 'hli_proto.m'));
    if was_loaded
        warning(['hli was loaded before; you may want to call ', ...
                 'tse.fame.startup() again.']);
    end
end
