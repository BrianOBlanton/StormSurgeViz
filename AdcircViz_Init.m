%function AdcircViz_Init

global Debug

HOME=fileparts(which(mfilename));

ThreddsList={
            'http://opendap.renci.org:1935/thredds'
            'http://workhorse.europa.renci.org:8080/thredds'
            'http://thredds.crc.nd.edu/thredds'
            'http://coastalmodeldev.data.noaa.gov/thredds'
            };
InstanceDefaultsFileLocation='http://opendap.renci.org:1935/thredds/fileServer/ASGS/InstanceDefaults.m';

%if ~exist('varargin','var')
%    error([mfilename ' cannot be called directly. Call AdcircViz instead.'])
%end

%global Verbose

set(0,'DefaultUICOntrolFontName','Courier')

% Default PN/PVs
Storm=[];
Advisory=[];
Grid=[];
Machine=[];
Instance='';
Verbose=true;
Debug=true;
DisableContouring=false;
PollInterval=Inf;  % update check interval in seconds; Inf for no polling
LocalTimeOffset=0;

TempDataLocation=[HOME '/TempData']; 
VariablesTable='Reduced';    % or 'Full'
Mode='Network';              % or 'Local', 'Network' by default
LocalDirectory='./';

Units='Feet';          % 'Metric' | 'Meters' | 'English' | 'Feet'
ColorIncrement=.25;    % in whatever units
NumberOfColors=32;
UITest=false;
DepthContours='10 50 100 500 1000 3000';  % depths must be enclosed in single quotes
ColorMax=12;
ColorMin=NaN;
ColorMap='noaa_cmap';
%ScreenTake=100; % percent of screen width to take up
FontOffset=2;
UseGoogleMaps=true;
UseShapeFiles=true;
CanOutputShapeFiles=true;
DefaultShapeBinWidth=.5;  
GoogleMapsApiKey='';
SendDiagnosticsToCommandWindow=true;
ForkAxes=false;
CatalogName='catalog.tree';
BoundingBox=[-100 -60 7 47];
DateStringFormatInput='yyyy-mm-dd HH:MM:SS';
DateStringFormatOutput='ddd, dd mmm, HH:MM PM';

%Version=0;
%%%+VERSION
% if ispc
%     Revision='XX';
% else
%     [status,Revision]=system('svn info | grep Revision: | awk ''{print $2}''');
% end
%%%-VERSION
% AppName=sprintf('Adcirc Viz Tool Version %d.%s', Version,deblank(Revision));
% fid=fopen('ThisVersion','w');
% fprintf(fid,'%s\n',AppName);
% fclose(fid);
AppName=fileread('ThisVersion');
fprintf('* %s',AppName')

HOME = fileparts(which(mfilename));
% addpath([HOME '/tiles'])
% addpath([HOME '/misc'])

cd(HOME)

addpath([HOME '/extern'])

if isempty(which('detbndy'))
    cd([HOME '/adcirc_util'])
    adcircinit
end

if isempty(which('ncgeodataset')) || isempty(javaclasspath('-dynamic'))
    cd([HOME '/extern/nctoolbox'])
    setup_nctoolbox;
end


cd(HOME)

% if isempty(which('m_track'))    
%     addpath([HOME '/m_map'])
% end

%UseMMap=false;
%MMap.proj='lambert';

%AppWidth=1680;
%scc=get(0,'ScreenSize');
%ScreenWidth=scc(3);
%clear scc;

m2f    =3.2808;
mps2mph=2.236;
ElevationFactor=1;
SpeedFactor=1;

fprintf('* Processing Input Parameter/Value Pairs...\n')

if exist('varargin','var')
% Strip off parameter/value pairs
k=1;
while k<length(varargin),
  switch lower(varargin{k}),
    case 'units',
      Units=varargin{k+1};
      varargin([k k+1])=[];
      if ~any(strcmpi(Units,{'Metric','Meters','English','Feet'}))
        disp('*** Units must be either Metric, Meters, English, Feet.  Setting to Meters.')
        Units='Meters';
      end
      if ismember(lower(Units),{'english','feet'})
          ElevationFactor=m2f;
          SpeedFactor=mps2mph;
      end
    case 'boundingbox',
      BoundingBox=varargin{k+1};
      varargin([k k+1])=[];
      [m,n]=size(BoundingBox);
      if ~(m==1 && n==4) || ~isnumeric(BoundingBox)
         disp('*** BoundingBox must be a 1x4 numeric vector.  Ignoring...')
         BoundingBox=[];
      end   
    case 'fontoffset',
      FontOffset=varargin{k+1};
      varargin([k k+1])=[];
    case {'storm','stormname'}
      Storm=varargin{k+1};
      varargin([k k+1])=[];
    case 'advisory',
      Advisory=varargin{k+1};
      varargin([k k+1])=[];
    case 'grid',
      Grid=varargin{k+1};
      varargin([k k+1])=[];
    case 'machine',
      Machine=varargin{k+1};
      varargin([k k+1])=[];
    case 'instance',
      Instance=varargin{k+1};
      varargin([k k+1])=[];
    case 'colormax',
      ColorMax=varargin{k+1};
      varargin([k k+1])=[];
    case 'colormin',
      ColorMin=varargin{k+1};
      varargin([k k+1])=[];
    case 'disablecontouring',
      DisableContouring=varargin{k+1};
      varargin([k k+1])=[];
    case 'tempdatalocation',
      TempDataLocation=varargin{k+1};
      varargin([k k+1])=[];
    case 'localdirectory',
      LocalDirectory=varargin{k+1};
      varargin([k k+1])=[];
    case 'localtimeoffset',
      LocalTimeOffset=varargin{k+1};
      varargin([k k+1])=[];      
    case 'colormap',
      ColorMap=varargin{k+1};
      varargin([k k+1])=[];
    case 'googlemapsapikey'
      GoogleMapsApiKey=varargin{k+1};
      varargin([k k+1])=[];
    case 'pollinginterval'
      PollingInterval=varargin{k+1};
      varargin([k k+1])=[];
    case 'mode',
      Mode=varargin{k+1};
      varargin([k k+1])=[];
    case 'verbose',
      Verbose=varargin{k+1};
      varargin([k k+1])=[];
    case 'depthcontours',
      DepthContours=varargin{k+1};
      varargin([k k+1])=[];
    case 'catalogname',
      CatalogName=varargin{k+1};
      varargin([k k+1])=[];
    case 'forkaxes',
      ForkAxes=varargin{k+1};
      varargin([k k+1])=[];
%%% Don't document input parameters below here yet!!
%     case 'url',
%       Url=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'UseMMap',
%       UseMMap=varargin{k+1};
%       varargin([k k+1])=[];
    case 'colorincrement',
      ColorIncrement=varargin{k+1};
      varargin([k k+1])=[];
    case 'numberofcolors',
      NumberOfColors=varargin{k+1};
      varargin([k k+1])=[];
    case 'uitest',
      UITest=varargin{k+1};
      varargin([k k+1])=[];

    otherwise
      k=k+2;
  end;
end;
if length(varargin)<2
   varargin={};
end
end

set(0,'DefaultFigureRenderer','zbuffer');
HasMapToolBox=false;
if ~isempty(which('almanac'))
    HasMapToolBox=true;
    %set(0,'DefaultFigureRenderer','opengl');
end

if isempty(which('shaperead'))
    UseShapeFiles=false;
end

if isempty(which('shapewrite'))
    disp('Can''t locate MATLAB''s shapewrite.  Disabling shape file output.')
    CanOutputShapeFiles=false;
end

if ~exist(TempDataLocation,'dir')
    mkdir(TempDataLocation)
end

%%
% get remote copy of InstanceDefaults.m
if isunix
    mvcom='mv';
    cpcom='cp';
else
    mvcom='move';
    cpcom='copy';
end

if strcmp(Mode,'Local')
    
    fprintf('* Mode is Local.\n')
    fprintf('* Local Mode not yet fully supported. Best of Luck... \n')
    
    [status,result]=system([cpcom ' private/run.properties.fake ' TempDataLocation '/run.properties']);
    DefaultBoundingBox=NaN;
    
else
    Mode='Network';
    fprintf('* Mode is Network.\n')

    % get InstanceDefaults.m file from thredds server
    try
        fprintf('* Retrieving remote InstanceDefaults.m file ...\n')
        urlwrite(InstanceDefaultsFileLocation,'temp.m');
        if exist('InstanceDefaults.m','file')
            [status,result]=system([mvcom ' InstanceDefaults.m InstanceDefaults.m.backup']);
        end
        [status,result]=system([mvcom ' temp.m InstanceDefaults.m']);
    catch ME1
        fprintf('** Failed to get InstanceDefaults.m.  Looking for previous version ...\n')
        try
            if exist('InstanceDefaults.m','file')
                fprintf('* Found it.\n')
            end
        catch ME2
            error('\nNo local InstanceDefaults.m found. This is Terminal.\n')
        end
    end
    InstanceDefaults;

end

if exist('MyAdcircViz_Init.m','file')
    if Verbose
        fprintf('* Found MyAdcircViz_Init ...\n')
    end
    MyAdcircViz_Init;
end

if ~isempty(BoundingBox),DefaultBoundingBox=BoundingBox;end

%SetVectorOptions('Stride',100,'ScaleFac',25,'Color','k')
VectorOptions.Stride=100;
VectorOptions.ScaleFac=25;
VectorOptions.Color='k';
