function cleanup()
%CLEANUP  Remove leftover temporary X13 run folders.
%
%   tse.x13.run creates folders named "x13_*" under the system temp directory.
%   They are not deleted automatically (so results stay readable); call this to
%   remove all of them.
    parent = tempdir;
    items = dir(fullfile(parent, 'x13_*'));
    removed = 0;
    for i = 1:numel(items)
        if items(i).isdir
            rmdir(fullfile(parent, items(i).name), 's');
            removed = removed + 1;
        end
    end
    fprintf('Removed %d temporary x13 folders.\n', removed);
end
