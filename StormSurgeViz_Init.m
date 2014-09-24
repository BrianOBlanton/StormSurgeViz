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
    cd([HOME '/ss_util'])
    ssinit
end

cd(PWD)

global SSVizOpts

ThreddsList={
             'http://opendap.renci.org:1935/thredds'
             'http://coastalmodeldev.data.noaa.gov/thredds'
            };
%            'http://workhorse.europa.renci.org:8080/thredds'
%            'http://thredds.crc.nd.edu/thredds'
        
InstanceDefaultsFileLocation='http://opendap.renci.org:1935/thredds/fileServer/ASGS/InstanceDefaults_SS.m';

%if ~exist('varargin','var')
%    error([mfilename ' cannot be called directly. Call StormSurgeViz instead.'])
%end

set(0,'DefaultUIControlFontName','Courier')
set(0,'DefaultAxesTickDir','out')
set(0,'DefaultFigureRenderer','zbuffer');

LocalDirectory='./';
TempDataLocation=[PWD '/TempData']; 
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

if isempty(SSVizOpts.ThreddsServer)
    SSVizOpts.ThreddsServer=ThreddsList{1};
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

%%
% get remote copy of InstanceDefaults.m
if isunix
    mvcom='mv';
    cpcom='cp';
else
    mvcom='move';
    cpcom='copy';
end

switch SSVizOpts.Mode
    
    case {'Local','Url'}
        
        fprintf('SSViz++ Mode is Local/Url.\n')
        fprintf('SSViz++ Local/Url Mode not yet fully supported. Best of Luck... \n')
        
        [status,result]=system([cpcom ' private/run.properties.fake ' TempDataLocation '/run.properties']);
        SSVizOpts.DefaultBoundingBox=NaN;
        
    otherwise
        
        SSVizOpts.Mode='Network';
        fprintf('SSViz++ Mode is Network.\n')
        
        % get InstanceDefaults.m file from thredds server
        try
            fprintf('SSViz++ Retrieving remote InstanceDefaults.m file ...\n')
            urlwrite(InstanceDefaultsFileLocation,'temp.m');
            if exist('InstanceDefaults.m','file')
                [status,result]=system([mvcom ' InstanceDefaults.m InstanceDefaults.m.backup']);
            end
            [status,result]=system([mvcom ' temp.m InstanceDefaults.m']);
            InstanceDefaults;
        catch ME1
            fprintf('*SSViz++ Failed to get InstanceDefaults.m.  Looking for previous version ...\n')
            try
                if exist('InstanceDefaults.m','file')
                    fprintf('* Found it.\n')
                    InstanceDefaults;
                end
            catch ME2
                % set a big default view
                fprintf('SSViz++   No local InstanceDefaults.m found. Setting a wide default view.\n')
                SSVizOpts.DefaultBoundingBox=[-100 -78 17 33];
                %error('\nNo local InstanceDefaults.m found. This is Terminal.\n')
            end
        end
end

if ~isempty(SSVizOpts.BoundingBox),SSVizOpts.DefaultBoundingBox=SSVizOpts.BoundingBox;end

%SetVectorOptions('Stride',100,'ScaleFac',25,'Color','k')
VectorOptions.Stride=100;
VectorOptions.ScaleFac=25;
VectorOptions.Color='k';

%%% clean up after initialization
clear jts
global Debug

Debug=SSVizOpts.Debug;
