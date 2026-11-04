function distanceKm = coastal_distance(longitude,latitude,geometry)
%COASTAL_DISTANCE Haversine radial distance; longitude convention must be consistent.
% Default preserves the original observed-minimum endpoint behavior.
% Explicit origin_longitude with origin_latitude='median' reproduces ENVISION.
if nargin < 3, geometry = struct; end
longitude = double(longitude(:));
latitude = double(latitude(:));
if numel(longitude) ~= numel(latitude)
    error('OceanScope:InvalidCoordinates','Coordinate lengths differ.');
end
valid = isfinite(longitude) & isfinite(latitude);
if ~any(valid)
    error('OceanScope:MissingCoordinates','No finite geographic coordinates.');
end
if any(abs(latitude(valid)) > 90) || any(abs(longitude(valid)) > 360)
    error('OceanScope:InvalidCoordinates','Coordinate ranges are invalid.');
end
% ENVISION west-positive longitude: smaller stored value is more coastal.
coast = min(longitude(valid));
% Use the latitude of the first observation at the coastal longitude.
idx = find(valid & longitude == coast,1,'first');
lat0 = latitude(idx);
if isfield(geometry,'origin_longitude')
    coast = geometry.origin_longitude;
    validateattributes(coast,{'numeric'},{'scalar','finite','>=',-360,'<=',360});
    if ~isfield(geometry,'origin_latitude')
        error('OceanScope:InvalidConfig','Explicit longitude requires origin_latitude.');
    end
    if isequal(string(geometry.origin_latitude),"median")
        lat0 = median(latitude(isfinite(latitude)));
    else
        lat0 = geometry.origin_latitude;
        validateattributes(lat0,{'numeric'},{'scalar','finite','>=',-90,'<=',90});
    end
end
rad = pi/180;
dLat = (latitude-lat0)*rad;
dLon = (longitude-coast)*rad;
a = sin(dLat/2).^2 + cos(latitude*rad).*cos(lat0*rad).*sin(dLon/2).^2;
a = max(0,min(1,a));
distanceKm = 2*6371.0088*atan2(sqrt(a),sqrt(1-a));
distanceKm(~valid) = NaN;
end
