function section = interpolate_section(T,dataset,variable)
%INTERPOLATE_SECTION Compute a section without graphics or file writes.
cols = dataset.columns;
geometry = struct;
if isfield(dataset,'geometry'), geometry = dataset.geometry; end
dist = oceanscope.coastal_distance(T.(string(cols.longitude)),T.(string(cols.latitude)),geometry);
depth = double(T.(string(cols.depth)));
values = double(T.(string(variable.column)));
limit = double(dataset.max_depth);
validateattributes(limit,{'numeric'},{'scalar','finite','positive'});
grid = struct('horizontal_points',60,'depth_start',0,'depth_step',5);
if isfield(dataset,'interpolation')
    names = fieldnames(dataset.interpolation);
    for k = 1:numel(names)
        if ~isfield(grid,names{k})
            error('OceanScope:InvalidConfig','Unknown interpolation option: %s',names{k});
        end
        grid.(names{k}) = dataset.interpolation.(names{k});
    end
end
validateattributes(grid.horizontal_points,{'numeric'},{'scalar','integer','>=',2});
validateattributes(grid.depth_start,{'numeric'},{'scalar','finite','nonnegative','<=',limit});
validateattributes(grid.depth_step,{'numeric'},{'scalar','finite','positive'});
mask = isfinite(dist) & isfinite(depth) & isfinite(values) ...
    & depth >= 0 & depth <= limit;
n = nnz(mask);
if n < 3
    error('OceanScope:InsufficientData','At least three finite samples required for %s.',variable.id);
end
x = dist(mask); z = depth(mask); y = values(mask);
% Aggregate exact duplicate interpolation coordinates explicitly rather than
% delegating silent averaging to griddata. Preserve all original observations.
[x,z,y,qc] = oceanscope.aggregate_duplicates(x,z,y);
qc.excluded_samples = height(T) - n;
if numel(x) < 3 || rank([x-mean(x),z-mean(z)]) < 2
    error('OceanScope:DegenerateGrid','At least three noncollinear distance/depth positions required.');
end
xg = linspace(min(x),max(x),grid.horizontal_points);
zg = (grid.depth_start:grid.depth_step:limit)';
[X,Z] = meshgrid(xg,zg);
try
    Y = griddata(x,z,y,X,Z,'linear');
catch cause
    error('OceanScope:Interpolation','Interpolation failed: %s',cause.message);
end
section = struct('X',X,'Z',Z,'values',Y,'distance',dist, ...
    'sample_mask',mask,'x',x,'z',z,'sample_values',y,'qc',qc, ...
    'interpolation',grid,'method','linear','extrapolation','none');
end
