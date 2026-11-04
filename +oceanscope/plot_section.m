function [fig,n,qc,section] = plot_section(T,dataset,variable)
%PLOT_SECTION Interpolate one oceanographic variable; never extrapolate.
section = oceanscope.interpolate_section(T,dataset,variable);
X = section.X; Z = section.Z; Y = section.values;
x = section.x; z = section.z;
n = nnz(section.sample_mask); qc = section.qc;
limit = dataset.max_depth;
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
