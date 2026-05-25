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
            C = tse.x13.x13consts();

            d = struct();
            d.series = local_collect_workspace_descriptions(fieldnames(obj.series), obj.spec, C.output_descriptions);
            d.tables = local_collect_workspace_descriptions(fieldnames(obj.tables), obj.spec, C.output_descriptions);

            if isfield(obj.other, 'udg') && isstruct(obj.other.udg)
                udg = local_collect_udg_descriptions(fieldnames(obj.other.udg), C.output_udg_description);
                if ~isempty(fieldnames(udg))
                    d.other = struct('udg', udg);
                end
            end
        end
    end
end

function out = local_collect_workspace_descriptions(keys, spec, outputDescriptions)
    out = struct();
    specNames = fieldnames(outputDescriptions);
    for i = 1:numel(keys)
        key = keys{i};
        code = matlab.lang.makeValidName(local_result_code(key));
        for j = 1:numel(specNames)
            specName = specNames{j};
            if ~isprop(spec, specName) || tse.x13.isdefault(spec.(specName))
                continue
            end
            specDescriptions = outputDescriptions.(specName);
            if isfield(specDescriptions, code)
                out.(key) = sprintf('%s: %s', upper(specName), specDescriptions.(code));
            end
        end
    end
end

function out = local_collect_udg_descriptions(keys, udgDescriptions)
    out = struct();
    for i = 1:numel(keys)
        key = keys{i};
        if isfield(udgDescriptions, key)
            out.(key) = udgDescriptions.(key);
        end
    end
end

function code = local_result_code(key)
    code = key;
    if startsWith(code, 'x') && all(isstrprop(code(2:end), 'digit'))
        code = code(2:end);
    end
end
