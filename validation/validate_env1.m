function report = validate_env1(archiveRoot,outputDir)
%VALIDATE_ENV1 Independent extraction of the archived section calculation.
% Does not invoke archival rendering or write into the archive.
root = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1, archiveRoot = fullfile(root,'..','coastal-upwelling-oceanography'); end
if nargin < 2, outputDir = fullfile(root,'results','validation'); end
if ~isfolder(outputDir), mkdir(outputDir); end
pinned = jsondecode(fileread(fullfile(root,'validation','env1_reference.json')));
for k = 1:numel(pinned.files)
    assert(strcmp(oceanscope.file_hash(fullfile(archiveRoot,pinned.files(k).path)), ...
        pinned.files(k).sha256),'Historical reference changed; review provenance before rebaselining.');
end
legacyDir = fullfile(archiveRoot,'scripts','longitudinal');
oldPath = path; cleanup = onCleanup(@() path(oldPath));
addpath(legacyDir);
config = jsondecode(fileread(fullfile(root,'configs','env1.json')));
report = struct('matlab_version',version,'absolute_tolerance',1e-10, ...
    'coordinate_tolerance_km',1e-10,'archive_commit',pinned.archive_commit,'reference_files',[], 'comparisons',[]);
files = {fullfile(legacyDir,'generate_longitudinal_sections.m'), ...
    fullfile(legacyDir,'geographic_transect_distance.m')};
for k = 1:numel(files)
    report.reference_files = [report.reference_files; struct('file',files{k}, ...
        'sha256',oceanscope.file_hash(files{k}))];
end
for i = 1:numel(config.datasets)
    d = config.datasets(i);
    [~,name,ext] = fileparts(d.file);
    source = fullfile(archiveRoot,'data','longitudinal',[name ext]);
    before = oceanscope.file_hash(source);
    T = readtable(source,'VariableNamingRule','preserve');
    % Independent archive geometry and original, unaggregated griddata input.
    distance = geographic_transect_distance(T.(d.columns.longitude),T.(d.columns.latitude));
    depth = T.(d.columns.depth);
    for j = 1:numel(d.variables)
        v = d.variables(j); values = T.(v.column);
        limit = 260; if i == 2, limit = 200; end
        valid = isfinite(distance) & isfinite(depth) & isfinite(values) & depth >= 0 & depth <= limit;
        [X,Z] = meshgrid(linspace(min(distance(valid)),max(distance(valid)),60),(5:5:limit)');
        % Duplicate warning is intentionally visible: legacy griddata averages it.
        reference = griddata(distance(valid),depth(valid),values(valid),X,Z,'linear');
        actual = oceanscope.interpolate_section(T,d,v);
        assert(isequal(actual.sample_mask,valid),'Input filtering differs.');
        coordinateError = max(abs(actual.distance-distance),[],'omitnan');
        assert(coordinateError <= report.coordinate_tolerance_km,'Distance differs.');
        assert(isequal(size(X),size(actual.X)) && max(abs(X-actual.X),[],'all') <= 1e-10 && isequal(Z,actual.Z),'Query grids differ.');
        finite = isfinite(reference) & isfinite(actual.values);
        delta = actual.values(finite)-reference(finite);
        [row,col] = find(xor(isnan(reference),isnan(actual.values)));
        idx = sub2ind(size(X),row,col);
        entry = struct('dataset',d.id,'variable',v.id,'input_sha256',before, ...
            'original_samples',height(T),'qc',actual.qc, ...
            'max_distance_difference_km',coordinateError, ...
            'max_absolute_difference',max(abs(delta)), ...
            'mean_absolute_difference',mean(abs(delta)), ...
            'rmse',sqrt(mean(delta.^2)),'finite_cells',nnz(finite), ...
            'nan_mask_difference_count',numel(row), ...
            'nan_mask_locations_row_col_km_depth',[row,col,X(idx),Z(idx)]);
        report.comparisons = [report.comparisons; entry];
        save(fullfile(outputDir,[d.id '_' v.id '.mat']),'reference','actual','X','Z','valid');
    end
    assert(strcmp(before,oceanscope.file_hash(source)),'Source bytes changed.');
end
fid = fopen(fullfile(outputDir,'env1_comparison.json'),'w');
if fid < 0, error('OceanScope:IO','Cannot write comparison report.'); end
fileCleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(report,'PrettyPrint',true));
assert(all([report.comparisons.finite_cells] > 0),'No comparable cells.');
assert(all([report.comparisons.nan_mask_difference_count] == 0),'NaN masks differ; inspect report.');
assert(all([report.comparisons.max_absolute_difference] <= report.absolute_tolerance),'Numerical tolerance exceeded; inspect report.');
end
