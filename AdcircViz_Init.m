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

set(0,'DefaultUIControlFontName','Courier')
set(0,'DefaultAxesTickDir','out')
set(0,'DefaultFigureRenderer','zbuffer');

LocalDirectory='./';
TempDataLocation=[HOME '/TempData']; 
DateStringFormatInput='yyyy-mm-dd HH:MM:SS';
DateStringFormatOutput='ddd, dd mmm, HH:MM PM';


%% Default PN/PVs
fprintf('* Processing Input Parameter/Value Pairs...\n')
opts=AdcircVizOptions;
opts=parseargs(opts);

if exist('MyAdcircViz_Init.m','file')
    if opts.Verbose
        fprintf('* Found MyAdcircViz_Init ...\n')
    end
    p=MyAdcircViz_Init;
    snames=fieldnames(p);
    svals=struct2cell(p);
    for i=1:size(snames,1)
        opts=parseargs(opts,snames{i},svals{i});
    end
    
end

% now process varargins, whcih will override any parameters set in
% MyAdcirc_init.m
opts=parseargs(opts,varargin{:});

AdcVizOpts=opts;


AdcVizOpts.AppName=blank(fileread('ThisVersion'));
fprintf('* %s\n',AdcVizOpts.AppName')

AdcVizOpts.HOME = fileparts(which(mfilename));
cd(AdcVizOpts.HOME)

addpath([AdcVizOpts.HOME '/extern'])

if isempty(which('detbndy'))
    cd([AdcVizOpts.HOME '/adcirc_util'])
    adcircinit
end

if isempty(which('ncgeodataset')) || isempty(javaclasspath('-dynamic'))
    cd([AdcVizOpts.HOME '/extern/nctoolbox'])
    setup_nctoolbox;
end
cd(AdcVizOpts.HOME)


AdcVizOpts.HasMapToolBox=false;
if ~isempty(which('almanac'))
    AdcVizOpts.HasMapToolBox=true;
    %set(0,'DefaultFigureRenderer','opengl');
end

if isempty(which('shaperead'))
    AdcVizOpts.UseShapeFiles=false;
end

if isempty(which('shapewrite'))
    disp('Can''t locate MATLAB''s shapewrite.  Disabling shape file output.')
    AdcVizOpts.CanOutputShapeFiles=false;
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

switch AdcVizOpts.Mode
    
    case {'Local','Url'}
        
        fprintf('* Mode is Local/Url.\n')
        fprintf('* Local/Url Mode not yet fully supported. Best of Luck... \n')
        
        [status,result]=system([cpcom ' private/run.properties.fake ' TempDataLocation '/run.properties']);
        AdcVizOpts.DefaultBoundingBox=NaN;
        
    otherwise
        
        AdcVizOpts.Mode='Network';
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


if ~isempty(AdcVizOpts.BoundingBox),AdcVizOpts.DefaultBoundingBox=AdcVizOpts.BoundingBox;end

%SetVectorOptions('Stride',100,'ScaleFac',25,'Color','k')
VectorOptions.Stride=100;
VectorOptions.ScaleFac=25;
VectorOptions.Color='k';



%%


% if isempty(which('m_track'))    
%     addpath([HOME '/m_map'])
% end

%UseMMap=false;
%MMap.proj='lambert';

%AppWidth=1680;
%scc=get(0,'ScreenSize');
%ScreenWidth=scc(3);
%clear scc;









% if exist('varargin','var')
% % Strip off parameter/value pairs
% k=1;
% while k<length(varargin),
%   switch lower(varargin{k}),
%     case 'units',
%       Units=varargin{k+1};
%       varargin([k k+1])=[];
%       if ~any(strcmpi(Units,{'Metric','Meters','English','Feet'}))
%         disp('*** Units must be either Metric, Meters, English, Feet.  Setting to Meters.')
%         Units='Meters';
%       end
%     case 'boundingbox',
%       BoundingBox=varargin{k+1};
%       varargin([k k+1])=[];
%       [m,n]=size(BoundingBox);
%       if ~(m==1 && n==4) || ~isnumeric(BoundingBox)
%          disp('*** BoundingBox must be a 1x4 numeric vector.  Ignoring...')
%          BoundingBox=[];
%       end   
%     case 'fontoffset',
%       FontOffset=varargin{k+1};
%       varargin([k k+1])=[];
%     case {'storm','stormname'}
%       Storm=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'advisory',
%       Advisory=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'grid',
%       Grid=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'machine',
%       Machine=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'instance',
%       Instance=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'colormax',
%       ColorMax=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'colormin',
%       ColorMin=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'disablecontouring',
%       DisableContouring=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'tempdatalocation',
%       TempDataLocation=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'localdirectory',
%       LocalDirectory=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'localtimeoffset',
%       LocalTimeOffset=varargin{k+1};
%       varargin([k k+1])=[];      
%     case 'colormap',
%       ColorMap=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'googlemapsapikey'
%       GoogleMapsApiKey=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'pollinginterval'
%       PollingInterval=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'mode',
%       Mode=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'verbose',
%       Verbose=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'depthcontours',
%       DepthContours=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'catalogname',
%       CatalogName=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'forkaxes',
%       ForkAxes=varargin{k+1};
%       varargin([k k+1])=[];
% %%% Don't document input parameters below here yet!!
% %     case 'url',
% %       Url=varargin{k+1};
% %       varargin([k k+1])=[];
% %     case 'UseMMap',
% %       UseMMap=varargin{k+1};
% %       varargin([k k+1])=[];
%     case 'colorbarlocation',
%       ColorBarLocation=varargin{k+1};
%       varargin([k k+1])=[];
%       if ~any(strcmpi(ColorBarLocation,{'North','South','East','West','NorthOutside','SouthOutside','EastOutside','WestOutside'}))
%         disp('*** ColorBarLocation value invalid. Setting to EastOutside.')
%         ColorBarLocation='EastOutside';
%       end
% 
%     case 'colorincrement',
%       ColorIncrement=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'numberofcolors',
%       NumberOfColors=varargin{k+1};
%       varargin([k k+1])=[];
%     case 'uitest',
%       UITest=varargin{k+1};
%       varargin([k k+1])=[];
% 
%     otherwise
%       k=k+2;
%   end;
% end;
% if length(varargin)<2
%    varargin={};
% end
% end