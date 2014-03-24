function p=AdcircVizOptions

p=struct;

% catalog parameters
p.Storm=[];
p.Advisory=[];
p.Grid=[];
p.Machine=[];
p.Instance='';
p.CatalogName='catalog.tree';
p.VariablesTable={'Full','Reduced'};
p.PollInterval=900;        % update check interval in seconds; Inf for no polling

% feature options
p.Verbose=true;
p.Debug=true;
p.DisableContouring=false;
p.LocalTimeOffset=0;
p.UseStrTree=false;
p.UseGoogleMaps=true;
p.UseShapeFiles=true;


p.Mode={'Network','Local', 'Url'}; 
p.Units={'Meters','Metric','Feet','English'};
p.DepthContours='10 50 100 500 1000 3000';  % depths must be enclosed in single quotes

% color options
p.ColorIncrement=.25;    % in whatever units
p.NumberOfColors=32;
p.ColorMax=NaN;
p.ColorMin=NaN;
p.ColorMap='noaa_cmap';
p.ColorBarLocation={'EastOutside','SouthOutside','NorthOutside','WestOutside','North','South','East','West'};


% GUI options
%ScreenTake=100; % percent of screen width to take up
p.AppWidthPercent=90;
p.FontOffset=2;
p.CanOutputShapeFiles=true;
p.DefaultShapeBinWidth=.5;  
p.GoogleMapsApiKey='';
p.SendDiagnosticsToCommandWindow=true;
p.ForkAxes=false;
p.UITest=false;

p.BoundingBox=[-100 -60 7 47];
