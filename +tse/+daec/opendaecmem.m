function de = opendaecmem(varargin)
%OPENDAECMEM  Open an empty, writable .daec file held in memory.
%
%   de = tse.daec.opendaecmem()
%   de = tse.daec.opendaecmem('overwrite', true)
%
%   Its contents are lost when it is closed.  See tse.daec.opendaec.
    overwrite = false;
    if numel(varargin) == 2 && strcmpi(char(varargin{1}), 'overwrite')
        overwrite = logical(varargin{2});
    elseif ~isempty(varargin)
        error('tseries:noMatch', 'The only option is ''overwrite''.');
    end
    de = tse.daec.File(':memory:', false, overwrite);
end
