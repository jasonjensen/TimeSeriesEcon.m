function out = metadata(varargin)
%METADATA  Build (or set on a spec) the metadata spec.
%
%   tse.x13.metadata({'key', 'value'})                 a single key/value pair
%   tse.x13.metadata({'k1','v1'; 'k2','v2'})           several pairs (Nx2 cell)
%   tse.x13.metadata(spec, entries)                    sets spec.metadata
    [spec, args] = tse.x13.specsplit(varargin{:});
    if isempty(args)
        error('tseries:noMatch', 'metadata requires a key/value entry or an Nx2 cell of them.');
    end
    entries = args{1};
    if ~iscell(entries) || size(entries, 2) ~= 2
        error('tseries:noMatch', 'metadata entries must be a 1x2 or Nx2 cell of {key, value}.');
    end
    entries = cellfun(@char, entries, 'UniformOutput', false);

    if size(entries, 1) > 20
        error('tseries:noMatch', 'A maximum of 20 metadata entries can be specified. Received %d.', size(entries, 1));
    end
    keys = entries(:, 1);
    vals = entries(:, 2);
    if any(cellfun(@(k) numel(k) > 132, keys))
        error('tseries:noMatch', 'Keys in the metadata spec can have a maximum length of 132 characters.');
    end
    if numel(strjoin(keys', '')) > 2000
        error('tseries:noMatch', 'Keys in the metadata spec can have a maximum combined length of 2000 characters.');
    end
    if any(cellfun(@(v) numel(v) > 132, vals))
        error('tseries:noMatch', 'Values in the metadata spec can have a maximum length of 132 characters.');
    end
    if numel(strjoin(vals', '')) > 2000
        error('tseries:noMatch', 'Values in the metadata spec can have a maximum combined length of 2000 characters.');
    end

    obj = tse.x13.X13metadata();
    obj.entries = entries;

    out = tse.x13.specfinish(spec, 'metadata', obj);
end
