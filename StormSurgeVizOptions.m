function p=StormSurgeVizOptions
% StormSurgeVizOptions - Parameters that can be used to influence the behavior
% of StormSurgeViz.  These are passed in as options to StormSurgeViz, or can be set 
% in the user's MyStormSurgeViz_Init.m.  A template MyStormSurgeViz_Init.m file is
% in the StormSurgeViz directory. 
%
% See the StormSurgeViz documentation for available options and definitions.
%
% http://renci-unc.github.io/StormSurgeViz/
%
% or: 
%
% https://docs.google.com/document/d/1a5ZLwSY1JB8t2m794KdqqLL1g8FiRQ8_pUB70ubumLU/pub

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
p.ThreddsServer='';
p.Url='';

% feature options
p.Verbose=true;
p.Debug=true;
p.DisableContouring=false;
p.LocalTimeOffset=0;
p.UseStrTree=false;
p.UseGoogleMaps=true;
p.UseShapeFiles=true;
p.KeepScalarsAndVectorsInSync=true;

p.Mode={'Network','Local', 'Url'}; 
p.Units={'Meters','Metric','Feet','English'};
p.DepthContours='10 50 100 500 1000 3000';  % depths must be enclosed in single quotes

% color options
p.ColorIncrement=.25;    % in whatever units
p.NumberOfColors=32;
p.ColorMax=NaN;
p.ColorMin=NaN;
p.ColorMap='parula';
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
