function report = validate_campaign(campaign,archiveRoot,outputDir)
%VALIDATE_CAMPAIGN Independent extraction of the archived section calculation.
% Does not invoke archival rendering or write into the archive.
root = fileparts(fileparts(mfilename('fullpath')));
campaign = validatestring(campaign,{'env1','env2','env3'});
if nargin < 2, archiveRoot = fullfile(root,'..','coastal-upwelling-oceanography'); end
if nargin < 3, outputDir = fullfile(root,'results','validation'); end
if ~isfolder(outputDir), mkdir(outputDir); end
pinned = jsondecode(fileread(fullfile(root,'validation',[campaign '_reference.json'])));
for k = 1:numel(pinned.files)
    assert(strcmp(oceanscope.file_hash(fullfile(archiveRoot,pinned.files(k).path)), ...
        pinned.files(k).sha256),'Historical reference changed; review provenance before rebaselining.');
end
legacyDir = fullfile(archiveRoot,'scripts','longitudinal');
oldPath = path; cleanup = onCleanup(@() path(oldPath));
addpath(legacyDir);
config = jsondecode(fileread(fullfile(root,'configs',[campaign '.json'])));
assert(numel(config.datasets) == 2,'Expected CTD and nutrient datasets.');
report = struct('campaign',campaign,'matlab_version',version,'absolute_tolerance',1e-10, ...
    'coordinate_tolerance_km',1e-10,'archive_commit',pinned.archive_commit,'reference_files',[], 'comparisons',[]);
files = {fullfile(legacyDir,'generate_longitudinal_sections.m'), ...
    fullfile(legacyDir,'geographic_transect_distance.m')};
for k = 1:numel(files)
    report.reference_files = [report.reference_files; struct('file',files{k}, ...
        'sha256',oceanscope.file_hash(files{k}))];
end
for i = 1:numel(config.datasets)
    d = config.datasets(i);
    % Reference file, mappings and limits come from the pinned archival script,
    % independently of the production configuration under test.
    day = 7; if strcmp(campaign,'env3'), day = 5; end
    if i == 1
        name = sprintf('ctd_%s_d%d.xlsx',campaign,day);
        columns = {'Longitude','Latitude','depth'};
        valueColumns = {'temp','sal','fluo','turb','par'};
        limit = 260;
    else
        name = sprintf('nuts_%s_d1.xlsx',campaign);
        columns = {'lon','lat','Prof'};
        valueColumns = {'no2','no3','nh4','TIN','po4','sio2','Total_Chla'};
        limit = 200;
    end
    source = fullfile(archiveRoot,'data','longitudinal',name);
    before = oceanscope.file_hash(source);
    productionSource = fullfile(root,'configs',d.file);
    assert(strcmp(before,oceanscope.file_hash(productionSource)),'Configured input differs from reference.');
    T = readtable(source,'VariableNamingRule','preserve');
    productionTable = oceanscope.read_data(productionSource,d);
    longitude = T.(columns{1}); latitude = T.(columns{2}); depth = T.(columns{3});
    distance = geographic_transect_distance(longitude,latitude);
    assert(numel(d.variables) == numel(valueColumns),'Variable count differs.');
    for j = 1:numel(d.variables)
        v = d.variables(j); values = T.(valueColumns{j});
        valid = isfinite(distance) & isfinite(depth) & isfinite(values) & depth >= 0 & depth <= limit;
        [X,Z] = meshgrid(linspace(min(distance(valid)),max(distance(valid)),60),(5:5:limit)');
        % Duplicate warning is intentionally visible: legacy griddata averages it.
        reference = griddata(distance(valid),depth(valid),values(valid),X,Z,'linear');
        actual = oceanscope.interpolate_section(productionTable,d,v);
        assert(isequal(actual.sample_mask,valid),'Input filtering differs.');
        assert(isequal(isfinite(actual.distance),isfinite(distance)),'Distance finite masks differ.');
        assert(~any(isinf(actual.values), 'all'),'Infinite interpolation output.');
        coordinateError = max(abs(actual.distance-distance),[],'omitnan');
        assert(coordinateError <= report.coordinate_tolerance_km,'Distance differs.');
        assert(isequal(size(X),size(actual.X)) && max(abs(X-actual.X),[],'all') <= 1e-10 && isequal(Z,actual.Z),'Query grids differ.');
        finite = isfinite(reference) & isfinite(actual.values);
        delta = actual.values(finite)-reference(finite);
        [row,col] = find(xor(isnan(reference),isnan(actual.values)));
        idx = sub2ind(size(X),row,col);
        entry = struct('dataset',d.id,'variable',v.id,'input_sha256',before, ...
            'original_samples',height(T),'qc',actual.qc, ...
            'longitude_positions',numel(unique(longitude(isfinite(longitude)))), ...
            'longitude_range',[min(longitude),max(longitude)], ...
            'latitude_range',[min(latitude),max(latitude)], ...
            'observed_depth_range',[min(depth),max(depth)], ...
            'nonfinite_samples',nnz(~isfinite(distance) | ~isfinite(depth) | ~isfinite(values)), ...
            'outside_depth_samples',nnz(isfinite(depth) & (depth < 0 | depth > limit)), ...
            'max_distance_difference_km',coordinateError, ...
            'max_absolute_difference',max(abs(delta)), ...
            'mean_absolute_difference',mean(abs(delta)), ...
            'rmse',sqrt(mean(delta.^2)),'finite_cells',nnz(finite), ...
            'nan_mask_difference_count',numel(row), ...
            'nan_mask_locations_row_col_km_depth',[row,col,X(idx),Z(idx)]);
        positions = unique([distance(valid),depth(valid)],'rows');
        assert(actual.qc.input_samples == nnz(valid) && actual.qc.unique_positions == size(positions,1), ...
            'Sample or duplicate counts differ from independent reference.');
        report.comparisons = [report.comparisons; entry];
        save(fullfile(outputDir,[d.id '_' v.id '.mat']),'reference','actual','X','Z','valid');
    end
    assert(strcmp(before,oceanscope.file_hash(source)),'Source bytes changed.');
end
fid = fopen(fullfile(outputDir,[campaign '_comparison.json']),'w');
if fid < 0, error('OceanScope:IO','Cannot write comparison report.'); end
fileCleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(report,'PrettyPrint',true));
assert(all([report.comparisons.finite_cells] > 0),'No comparable cells.');
assert(all([report.comparisons.nan_mask_difference_count] == 0),'NaN masks differ; inspect report.');
assert(all([report.comparisons.max_absolute_difference] <= report.absolute_tolerance),'Numerical tolerance exceeded; inspect report.');
end
