function out = from_db(d)
%FROM_DB  Convert a struct of DataEcon DESeries into a struct of tse.* series.
%
%   out = tse.daec.from_db(d)
%
%   Walks the input struct: fields that are DESeries are converted via
%   tse.daec.from_series; all other fields are copied through unchanged.
%   Field order is preserved.  This is an in-memory conversion and does not
%   touch disk (see tse.daec.read for the file form).
    if ~isstruct(d)
        error('tseries:noMatch', 'from_db expects a struct.');
    end
    out = d;
    fns = fieldnames(out);
    for i = 1:numel(fns)
        v = out.(fns{i});
        if isa(v, 'DESeries')
            out.(fns{i}) = tse.daec.from_series(v);
        end
    end
end
