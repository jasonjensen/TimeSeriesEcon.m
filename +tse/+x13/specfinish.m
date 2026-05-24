function out = specfinish(spec, name, obj)
%SPECFINISH  Either return a freshly built subspec OBJ, or store it on SPEC.
%
%   When SPEC is [] (the constructor was called without a spec) OBJ is returned.
%   Otherwise SPEC.(NAME) is set to OBJ and SPEC is returned, mirroring the
%   Julia "name!" mutating functions.  SPEC is a handle, so it is updated in place.
    if isempty(spec)
        out = obj;
    else
        spec.(name) = obj;
        out = spec;
    end
end
