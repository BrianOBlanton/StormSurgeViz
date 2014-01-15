land = shaperead('landareas', 'UseGeoCoords', true);
lat = [land.Lat];
lon = [land.Lon];
[landImage, refvec] = ...
   vec2mtx(lat, lon, 2, [-90, 90], [-180,180], 'filled');
mergedImage = landImage;

rivers = shaperead('worldrivers.shp','UseGeoCoords',true);
riverImage = vec2mtx([rivers.Lat], [rivers.Lon], landImage, refvec);

mergedImage(riverImage == 1) = 3;

mergedImage = flipud(mergedImage);
%mergedImage(boundariesImage(:,:,1) == 0) = 1;

figure
worldmap(mergedImage, refvec)
geoshow(mergedImage, refvec, 'DisplayType', 'texturemap')
colormap([.45 .60 .30; 0 0 0; 0 0.5 1; 0 0 1])


return















vizglobe = wmsfind('viz.globe', 'SearchField', 'serverurl');
coastlines = vizglobe.refine('coastline');
national_boundaries = vizglobe.refine('national*bound');
base_layer = vizglobe.refine('egm96');

layers = [base_layer;coastlines;national_boundaries];

request = WMSMapRequest(layers);

request.Transparent = true;

request = request.boundImageSize(720);

overlayImage = request.Server.getMap(request.RequestURL);

figure
worldmap('world')
geoshow(overlayImage, request.RasterRef);
title(base_layer.LayerTitle)

