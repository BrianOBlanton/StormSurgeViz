function S=LoadAtcfShapefile(basin,stormnumber,year,advisory,destination)
% S=LoadAtcfShapefile(basin,stormnumber,year,advisory,destination)

HERE=pwd;

if (nargin<4 || nargin>5)
    error('Must have 4|5 input args to %s.',mfilename)
end
if ~exist('destination','var')
    destination=HERE;
end
if ~exist(destination,'dir')
    error('Destination dir %s does not exist.',destination)
end
f=sprintf('%s/test.%d',destination,floor(rand*1000000));
fid=fopen(f,'w');
if fid < 3 
   error('Destination dir %s may not be writable',destination)
else
    delete(f)
end

if ischar(year)
    year=str2double(year);
end

if ischar(advisory)
    advisory=str2double(advisory);
end

% if ischar(stormnumber) % assume a tc name...
%     % need to skip "Q" since there are no storm names starting with Q
%     startingnameletters={'a','b','c','d','e','f','g','h','i','j',...
%                          'k','l','m','n','o','p','r','s','t','u',...
%                          'v','w','x','y','z'};
%     stormnumber=find(strcmpi(stormnumber(1),startingnameletters));
% end


% for archived files:
UrlBase='http://www.nhc.noaa.gov/gis/forecast/archive/';
f=sprintf('%s%02d%4d_5day_%03d.zip',basin,stormnumber,year,advisory);

try 
    urlwrite([UrlBase f],sprintf('%s/%s',destination,f));
catch ME
    fprintf('Failed to get %s/%s.  Check arguments to %s.\n',UrlBase,f,mfilename); 
    throw(ME);
end

cd(destination)
try 
    unzip(sprintf('%s',f))
catch ME
    throw(ME);
end
cd(HERE)

fb=sprintf('%s/%s%02d%4d-%03d',destination,basin,stormnumber,year,advisory);
f=sprintf('%s_5day_lin',fb);
if exist([f '.shp'],'file')
    s=shaperead(f);
    S.lin=s;
end

f=sprintf('%s_5day_pgn',fb);
if exist([f '.shp'],'file')
    s=shaperead(f);
    S.pgn=s;
end

f=sprintf('%s_5day_pts',fb);
if exist([f '.shp'],'file')
    s=shaperead(f);
    S.pts=s;
end

f=sprintf('%s_ww_wwlin',fb);
if exist([f '.shp'],'file')
    s=shaperead(f);
    S.ww=s;
end

S.AdvString=datestr(datenum(S.pgn(1).ADVDATE,'yymmdd/HHMM')-4/24,'ddd, dd mmm, HH PM');

delete([fb '*'])

