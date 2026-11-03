function [xUnique, zUnique, meanValues, qc] = aggregate_duplicates(x, z, values)
%AGGREGATE_DUPLICATES Explicitly average observations at identical 2D positions.
%   All vectors must already be filtered for finite values and depth limits.
%   Equality is exact (no spatial binning or rounding); original data are untouched.
x = double(x(:));
z = double(z(:));
values = double(values(:));
if numel(x) ~= numel(z) || numel(x) ~= numel(values)
    error('OceanScope:InvalidSamples','Distance, depth, and value lengths differ.');
end
if any(~isfinite(x) | ~isfinite(z) | ~isfinite(values))
    error('OceanScope:InvalidSamples','Aggregation requires finite samples.');
end
[coordinates,~,group] = unique([x,z],'rows','stable');
groupSizes = accumarray(group,1);
meanValues = accumarray(group,values,[],@mean);
xUnique = coordinates(:,1);
zUnique = coordinates(:,2);
qc = struct( ...
    'input_samples',numel(values), ...
    'unique_positions',size(coordinates,1), ...
    'duplicate_groups',nnz(groupSizes > 1), ...
    'duplicate_samples',sum(groupSizes-1), ...
    'aggregation_method',"arithmetic_mean_exact_distance_depth");
end
