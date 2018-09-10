%function StormSurgeViz_Init

PWD=pwd;

HOME=fileparts(which(mfilename));
addpath([HOME '/extern'])

% need to set up main java path before setting any global variables
if isempty(which('ncgeodataset')) || isempty(javaclasspath('-dynamic'))
    cd([HOME '/extern/nctoolbox'])
    setup_nctoolbox;
end

if isempty(which('detbndy'))
    cd([HOME '/util'])
    ssvinit
end

cd(PWD)

global SSVizOpts

ThreddsList={
             'http://tds.renci.org:8080/thredds'   'RENCI/UNC/ASGS'
             'http://coastalmodeldev.data.noaa.gov/thredds' 'CSDL/NOAA/ASGS'
            };
%            'http://workhorse.europa.renci.org:8080/thredds'
%            'http://thredds.crc.nd.edu/thredds'
        

%if ~exist('varargin','var')
%    error([mfilename ' cannot be called directly. Call StormSurgeViz instead.'])
%end

set(0,'DefaultUIControlFontName','Courier')
set(0,'DefaultAxesTickDir','out')
set(0,'DefaultFigureRenderer','zbuffer');

LocalDirectory='./';
TempDataLocation=[HOME '/TempData']; 
DateStringFormatInput='yyyy-mm-dd HH:MM:SS';
DateStringFormatOutput='ddd, dd mmm, HH:MM PM';

% name of Java Topology Suite file
jts='jts-1.9.jar';

%% Default PN/PVs
fprintf('SSViz++ Processing Input Parameter/Value Pairs...\n')
opts=StormSurgeVizOptions;
opts=parseargs(opts);

if exist('MyStormSurgeViz_Init.m','file')
    if opts.Verbose
        fprintf('SSViz++ Found MyStormSurgeViz_Init ...\n')
    end
    p=MyStormSurgeViz_Init;
    snames=fieldnames(p);
    svals=struct2cell(p);
    for i=1:size(snames,1)
        opts=parseargs(opts,snames{i},svals{i});
    end
end

opts=parseargs(opts,'KeepScalarsAndVectorsInSync',true);

% now process varargins, which will override any parameters set in
% MyStormSurge_Init.m
opts=parseargs(opts,varargin{:});

SSVizOpts=opts;
SSVizOpts.Storm=lower(SSVizOpts.Storm);

SSVizOpts.ThreddsServerProvider='Unknown';
if isempty(SSVizOpts.ThreddsServer)
    SSVizOpts.ThreddsServer=ThreddsList{1,1};
    SSVizOpts.ThreddsServerProvider=ThreddsList{1,2};
end

%scc=get(0,'ScreenSize');
%DisplayWidth=scc(3);

SSVizOpts.AppName=blank(fileread('ThisVersion'));
fprintf('SSViz++ %s\n',SSVizOpts.AppName')

SSVizOpts.HOME = HOME;
%cd(SSVizOpts.HOME)

if SSVizOpts.UseStrTree
    f=[SSVizOpts.HOME '/extern/' jts];
    if exist(f,'file')
        javaaddpath(f);
    else
        disp('Can''t add jts file to javaclasspath.   Disabling strtree searching.')
        SSVizOpts.UseStrTree=false;
    end
end

SSVizOpts.HasMapToolBox=false;
if ~isempty(which('almanac'))
    SSVizOpts.HasMapToolBox=true;
    %set(0,'DefaultFigureRenderer','opengl');
end

if isempty(which('shaperead'))
    SSVizOpts.UseShapeFiles=false;
end

if isempty(which('shapewrite'))
    disp('Can''t locate MATLAB''s shapewrite.  Disabling shape file output.')
    SSVizOpts.CanOutputShapeFiles=false;
end

if ~exist(TempDataLocation,'dir')
    mkdir(TempDataLocation)
end
addpath(TempDataLocation)

if isunix
    mvcom='mv';
    cpcom='cp';
else
    mvcom='move';
    cpcom='copy';
end

switch lower(SSVizOpts.Mode)
    
    case {'local','url'}
        
        fprintf('SSViz++ Mode is Local/Url.\n')
        fprintf('SSViz++ Local/Url Mode not fully supported. Best of Luck... \n')
        
        [status,result]=system([cpcom ' private/run.properties.fake ' TempDataLocation '/run.properties']);
        SSVizOpts.DefaultBoundingBox=NaN;
        
        % check for existence of input local directory
        if isempty(SSVizOpts.Url)
            SSVizOpts.Url=pwd;
        end
        if ~exist(SSVizOpts.Url,'dir')
            fprintf('SSViz++ Input directory (%s) does not exist.  Use file browser...\n',SSVizOpts.Url)
        else
            LocalDirectory=SSVizOpts.Url;
        end
        
    otherwise
        
        SSVizOpts.Mode='Network';
        fprintf('SSViz++ Mode is Network.\n')
        
        %SSVizOpts.DefaultBoundingBox=[-100 -78 17 33];
        SSVizOpts.DefaultBoundingBox=[-93.09   -60.09   17.433   41.433];
end

if isempty(SSVizOpts.BoundingBox),SSVizOpts.BoundingBox=SSVizOpts.DefaultBoundingBox;end

%SetVectorOptions('Stride',100,'ScaleFac',25,'Color','k')
VectorOptions.Stride=100;
VectorOptions.ScaleFac=25;
VectorOptions.Color='k';

%%% clean up after initialization
clear jts
global Debug

Debug=SSVizOpts.Debug;
