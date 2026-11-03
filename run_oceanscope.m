function manifest = run_oceanscope(configPath)
%RUN_OCEANSCOPE Run configurable CTD/nutrient vertical-section analyses.
%   MANIFEST = RUN_OCEANSCOPE("configs/demo.json")
arguments
    configPath (1,1) string
end

if ~isfile(configPath)
    error('OceanScope:MissingConfig','Config not found: %s', configPath);
end

configPath = string(which_or_absolute(configPath));
configDir = string(fileparts(configPath));
config = jsondecode(fileread(configPath));
if ~isfield(config, 'datasets') || isempty(config.datasets)
    error('OceanScope:InvalidConfig','Config requires a nonempty datasets array.');
end
if ~isfield(config,'output_dir')
    error('OceanScope:InvalidConfig','Config requires output_dir.');
end
outputDir = fullfile(configDir, string(config.output_dir));
if ~isfolder(outputDir)
    mkdir(outputDir);
end

datasets = config.datasets;
if iscell(datasets), datasets = [datasets{:}]; end
outputEntries = struct('dataset',{},'variable',{},'input',{},'output',{},'valid_samples',{},'qc',{});
for i = 1:numel(datasets)
    d = datasets(i);
    required = {'id','file','columns','variables','max_depth'};
    for k = 1:numel(required)
        if ~isfield(d,required{k})
            error('OceanScope:InvalidConfig','Dataset %d requires %s.',i,required{k});
        end
    end
    sourceFile = fullfile(configDir,string(d.file));
    T = oceanscope.read_data(sourceFile,d);
    variables = d.variables;
    if iscell(variables), variables = [variables{:}]; end
    for j = 1:numel(variables)
        v = variables(j);
        [f, n, qc] = oceanscope.plot_section(T, d, v);
        safeId = regexprep(char(string(d.id)), '[^A-Za-z0-9_-]', '_');
        safeVar = regexprep(char(string(v.id)), '[^A-Za-z0-9_-]', '_');
        outputFile = fullfile(outputDir,sprintf('%s_%s.png',safeId,safeVar));
        cleanup = onCleanup(@() close(f));
        exportgraphics(f,outputFile,'Resolution',180,'BackgroundColor','white');
        clear cleanup
        outputEntries(end+1) = struct('dataset',string(d.id), ... %#ok<AGROW>
            'variable',string(v.id),'input',string(sourceFile), ...
            'output',string(outputFile),'valid_samples',n,'qc',qc);
    end
end
manifest = struct('config',configPath,'matlab_release',string(version('-release')), ...
    'generated_at',string(datetime('now','Format','yyyy-MM-dd''T''HH:mm:ss')), ...
    'outputs',outputEntries);
manifestFile = fullfile(outputDir,'manifest.json');
fid = fopen(manifestFile,'w');
if fid < 0, error('OceanScope:IO','Cannot write manifest %s',manifestFile); end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(manifest,'PrettyPrint',true));
fprintf('OceanScope: created %d figures in %s\n',numel(outputEntries),outputDir);
end

function result = which_or_absolute(p)
% Resolve config paths without relying on MATLAB search path.
p = char(p);
if isfile(p)
    info = dir(p);
    result = fullfile(info.folder,info.name);
else
    result = p;
end
end
