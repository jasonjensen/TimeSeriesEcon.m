function out = from_db(d)
%FROM_DB  Convert a struct of IRIS tseries into a struct of tse.* series.
%
%   out = tse.iris.from_db(d)
%
%   Walks the input struct: fields that are IRIS tseries are converted via
%   tse.iris.from_tseries; all other fields are copied through unchanged.
%   Field order is preserved.
    if ~isstruct(d)
        error('tseries:noMatch', 'from_db expects a struct.');
    end
    out = d;
    fns = fieldnames(out);
    for i = 1:numel(fns)
        v = out.(fns{i});
        if isa(v, 'tseries')
            out.(fns{i}) = tse.iris.from_tseries(v);
        end
    end
end
