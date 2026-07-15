function out = from_db(d)
%FROM_DB  Convert a struct of Dynare dseries into a struct of tse.* series.
%
%   out = tse.dynare.from_db(d)
%
%   Walks the input struct: fields that are Dynare dseries are converted via
%   tse.dynare.from_dseries; all other fields are copied through unchanged.
%   Field order is preserved.
    if ~isstruct(d)
        error('tseries:noMatch', 'from_db expects a struct.');
    end
    out = d;
    fns = fieldnames(out);
    for i = 1:numel(fns)
        v = out.(fns{i});
        if isa(v, 'dseries')
            out.(fns{i}) = tse.dynare.from_dseries(v);
        end
    end
end
