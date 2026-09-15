function out = to_db(d)
%TO_DB  Convert a struct of tse.* series into a struct of DataEcon DESeries.
%
%   out = tse.daec.to_db(d)
%
%   Walks the input struct: fields that are tse.TSeries or tse.MVTSeries are
%   converted via tse.daec.to_series; all other fields are copied through
%   unchanged.  Field order is preserved.  This is an in-memory conversion
%   and does not touch disk (see tse.daec.write for the file form).
    if ~isstruct(d)
        error('tseries:noMatch', 'to_db expects a struct.');
    end
    out = d;
    fns = fieldnames(out);
    for i = 1:numel(fns)
        v = out.(fns{i});
        if isa(v, 'tse.TSeries') || isa(v, 'tse.MVTSeries')
            out.(fns{i}) = tse.daec.to_series(v);
        end
    end
end
