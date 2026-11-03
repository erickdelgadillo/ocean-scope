function [fig,n] = plot_section(T,dataset,variable)
%PLOT_SECTION Interpolate one oceanographic variable; never extrapolate.
cols = dataset.columns;
dist = oceanscope.coastal_distance(T.(string(cols.longitude)),T.(string(cols.latitude)));
depth = double(T.(string(cols.depth)));
values = double(T.(string(variable.column)));
limit = double(dataset.max_depth);
mask = isfinite(dist) & isfinite(depth) & isfinite(values) ...
    & depth >= 0 & depth <= limit;
n = nnz(mask);
if n < 3
    error('OceanScope:InsufficientData','At least three finite samples required for %s.',variable.id);
end
x = dist(mask); z = depth(mask); y = values(mask);
if numel(unique(x)) < 2 || numel(unique(z)) < 2
    error('OceanScope:DegenerateGrid','At least two distances and two depths required.');
end
xg = linspace(min(x),max(x),60);
zg = (0:5:limit)';
[X,Z] = meshgrid(xg,zg);
try
    Y = griddata(x,z,y,X,Z,'linear');
catch cause
    error('OceanScope:Interpolation','Interpolation failed: %s',cause.message);
end
fig = figure('Visible','off','Color','white','Position',[100 100 900 520]);
ax = axes(fig);
surface(ax,X,-Z,zeros(size(Y)),Y,'EdgeColor','none','FaceColor','interp');
view(ax,2);
hold(ax,'on');
scatter(ax,x,-z,8,'o','MarkerEdgeColor',[0.45 0.45 0.45]);
if isfield(variable,'limits')
    clim(ax,double(variable.limits));
end
colormap(ax,parula(256));
colorbar(ax);
xlabel(ax,'Distance from coastal endpoint (km)');
ylabel(ax,'Depth (m)');
title(ax,sprintf('%s — %s',char(string(dataset.id)),char(string(variable.id))), ...
    'Interpreter','none');
ylim(ax,[-limit 0]);
xlim(ax,[min(x),max(x)]);
grid(ax,'on');
end
