function distanceKm = coastal_distance(longitude,latitude)
%COASTAL_DISTANCE Great-circle distance from easternmost observed longitude.
% Source ENVISION values are *degrees west represented by positive numbers*.
% For a general geographic input, use signed east-positive longitude.
% Both forms produce identical absolute angular separations.
longitude = double(longitude(:));
latitude = double(latitude(:));
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
rad = pi/180;
dLat = (latitude-lat0)*rad;
dLon = (longitude-coast)*rad;
a = sin(dLat/2).^2 + cos(latitude*rad).*cos(lat0*rad).*sin(dLon/2).^2;
a = max(0,min(1,a));
distanceKm = 2*6371.0088*atan2(sqrt(a),sqrt(1-a));
distanceKm(~valid) = NaN;
end
