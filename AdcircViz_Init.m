%function AdcircViz_Init

global Debug

HOME=fileparts(which(mfilename));
addpath([HOME '/extern'])
if isempty(which('detbndy'))
    cd([HOME '/adcirc_util'])
    adcircinit
end

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
fprintf('AdcViz++ Processing Input Parameter/Value Pairs...\n')
opts=AdcircVizOptions;
opts=parseargs(opts);

Debug=opts.Debug;

if exist('MyAdcircViz_Init.m','file')
    if opts.Verbose
        fprintf('AdcViz++ Found MyAdcircViz_Init ...\n')
    end
    p=MyAdcircViz_Init;
    snames=fieldnames(p);
    svals=struct2cell(p);
    for i=1:size(snames,1)
        opts=parseargs(opts,snames{i},svals{i});
    end
    
end

% now process varargins, which will override any parameters set in
% MyAdcirc_Init.m
opts=parseargs(opts,varargin{:});

AdcVizOpts=opts;

scc=get(0,'ScreenSize');
DisplayWidth=scc(3);

AdcVizOpts.AppName=blank(fileread('ThisVersion'));
fprintf('AdcViz++ %s\n',AdcVizOpts.AppName')

AdcVizOpts.HOME = HOME;
cd(AdcVizOpts.HOME)

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
        
        fprintf('AdcViz++ Mode is Local/Url.\n')
        fprintf('AdcViz++ Local/Url Mode not yet fully supported. Best of Luck... \n')
        
        [status,result]=system([cpcom ' private/run.properties.fake ' TempDataLocation '/run.properties']);
        AdcVizOpts.DefaultBoundingBox=NaN;
        
    otherwise
        
        AdcVizOpts.Mode='Network';
        fprintf('Adcviz++ Mode is Network.\n')
        
        % get InstanceDefaults.m file from thredds server
        try
            fprintf('AdcViz++ Retrieving remote InstanceDefaults.m file ...\n')
            urlwrite(InstanceDefaultsFileLocation,'temp.m');
            if exist('InstanceDefaults.m','file')
                [status,result]=system([mvcom ' InstanceDefaults.m InstanceDefaults.m.backup']);
            end
            [status,result]=system([mvcom ' temp.m InstanceDefaults.m']);
        catch ME1
            fprintf('*AdcViz++ Failed to get InstanceDefaults.m.  Looking for previous version ...\n')
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
