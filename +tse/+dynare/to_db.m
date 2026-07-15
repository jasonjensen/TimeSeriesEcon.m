function out = to_db(d)
%TO_DB  Convert a struct of tse.* series into a struct of Dynare dseries.
%
%   out = tse.dynare.to_db(d)
%
%   Walks the input struct: fields that are tse.TSeries or tse.MVTSeries are
%   converted via tse.dynare.to_dseries; all other fields are copied through
%   unchanged.  Field order is preserved.
    if ~isstruct(d)
        error('tseries:noMatch', 'to_db expects a struct.');
    end
    out = d;
    fns = fieldnames(out);
    for i = 1:numel(fns)
        v = out.(fns{i});
        if isa(v, 'tse.TSeries') || isa(v, 'tse.MVTSeries')
            out.(fns{i}) = tse.dynare.to_dseries(v);
        end
    end
end
