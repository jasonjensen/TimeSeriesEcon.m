function cls = type_from_fame(code)
%TYPE_FROM_FAME  Map a FAME type code to the MATLAB class it becomes on read.
%
%   cls = tse.fame.type_from_fame(5)   % -> 'double'
%
%   FAME type codes (see FAME.jl src/Types.jl):
%     numeric=1, namelist=2, boolean=3, string=4, precision=5, date=6.
%
%   FAME -> MATLAB element type:
%     numeric   (1) -> single
%     boolean   (3) -> logical
%     string    (4) -> string
%     precision (5) -> double
%     date      (6) -> tse.MIT
%
%   namelist(2) has no series element form and raises an error here (it is
%   handled separately as a scalar object).
%
%   See also: tse.fame.type_to_fame.
    switch double(code)
        case 1
            cls = 'single';
        case 3
            cls = 'logical';
        case 4
            cls = 'string';
        case 5
            cls = 'double';
        case 6
            cls = 'tse.MIT';
        otherwise
            error('tseries:noMatch', ...
                'Unsupported FAME type code %d for a series element.', double(code));
    end
end
