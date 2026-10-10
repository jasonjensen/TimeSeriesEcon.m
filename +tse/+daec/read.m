function db = read(path)
%READ  Read a .daec file into a struct.  Same as tse.daec.readdb(path).
%
%   db = tse.daec.read('data.daec')
%
%   See also tse.daec.readdb.
    db = tse.daec.readdb(path);
end
