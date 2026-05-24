classdef X13result
%X13RESULT  The outcome of a tse.x13.run call.
%
%   Properties:
%     spec       - the X13spec that was run
%     outfolder  - folder holding the raw X13 output files
%     series     - struct of TSeries / MVTSeries outputs (by table code)
%     tables     - struct of table outputs (each a struct of columns)
%     text       - struct of human-readable text outputs
%     other      - struct of key/value and model outputs
%     stdout     - console output from the X13 run
%     errors / warnings / notes - messages parsed from the .err file
%
%   Use descriptions(res) for a grouped listing of the available outputs.
%
%   See also: tse.x13.run, tse.x13.descriptions.
    properties
        spec
        outfolder
        series = struct()
        tables = struct()
        text = struct()
        other = struct()
        stdout = ''
        errors = {}
        warnings = {}
        notes = {}
    end
    methods
        function obj = X13result(spec, outfolder, stdout)
            if nargin > 0
                obj.spec = spec;
                obj.outfolder = outfolder;
                obj.stdout = stdout;
            end
        end
        function d = descriptions(obj)
            d = tse.x13.descriptions(obj);
        end
    end
end
