classdef X13default
%X13DEFAULT  Sentinel marking an unset X13 spec field.
%
%   Every field of an X13 spec object starts out holding a tse.x13.X13default
%   instance.  When a spec is serialised, fields that still hold this sentinel
%   are omitted, exactly like an unset field in the Julia X13 module.
%
%   Use tse.x13.isdefault(v) to test for it.
%
%   See also: tse.x13.isdefault, tse.x13.newspec.
end
