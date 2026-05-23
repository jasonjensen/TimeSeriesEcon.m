function out = options_db(action, key, val)
%OPTIONS_DB  Process-wide option store (persistent), backing tse.getoption /
%tse.setoption.  Mirrors the options dict in TimeSeriesEcon.jl.

    persistent store
    if isempty(store)
        store = struct( ...
            'bdaily_holidays_map', [], ...
            'bdaily_creation_bias', 'strict', ...
            'bdaily_skip_nans', false, ...
            'x13path', '');
    end

    key = matlab.lang.makeValidName(char(key));
    switch action
        case 'get'
            if ~isfield(store, key)
                error('tseries:noMatch', 'Unknown option: %s', key);
            end
            out = store.(key);
        case 'set'
            store.(key) = val;
            out = [];
        otherwise
            error('tseries:noMatch', 'options_db: unknown action %s', action);
    end
end
