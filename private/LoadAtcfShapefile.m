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

% for archived files:
UrlBase='https://www.nhc.noaa.gov/gis/forecast/archive/';
f=sprintf('%s%s%4d_5day_%03d.zip',basin,stormnumber,year,advisory);

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

fb=sprintf('%s/%s%s%4d-%03d',destination,basin,stormnumber,year,advisory);
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

%S.AdvString=datestr(datenum(S.pgn(1).ADVDATE,'yymmdd/HHMM')-4/24,'ddd, dd mmm, HH PM');
% hh=str2double(S.pgn(1).ADVDATE(1:2));
% mm=str2double(S.pgn(1).ADVDATE(3:4));
% ampm=S.pgn(1).ADVDATE(6:7);
% tz=S.pgn(1).ADVDATE(9:11);
% day=S.pgn(1).ADVDATE(13:15);
% mon=S.pgn(1).ADVDATE(17:19);
% dday=str2double(S.pgn(1).ADVDATE(21:22));
% year=str2double(S.pgn(1).ADVDATE(24:27));
temp=strsplit(S.pgn(1).ADVDATE);
hhmm=temp{1};
hhmm=sprintf('%04s',hhmm);
hh=hhmm(1:2);
mm=hhmm(3:4);

ampm=temp{2};
if strcmp(lower(ampm),'pm')
    hh=int2str(str2double(hh)+12);
end

tz=temp{3};

day=temp{4};
mon=temp{5};
switch lower(mon)
    case 'jan'
        mmon=1;
    case 'feb'
        mmon=2;
    case 'mar'
        mmon=3;
    case 'apr'
        mmon=4;
    case 'may'
        mmon=5;
    case 'jun'
        mmon=6;
    case 'jul'
        mmon=7;
    case 'aug'
        mmon=8;
    case 'sep'
        mmon=9;
    case 'oct'
        mmon=10;
    case 'nov'
        mmon=11;
    case 'dec'
        mmon=12;
        
end
mmon=sprintf('%02d',mmon);

dday=temp{6};
year=temp{7};

temp=datetime(str2double(year),str2double(mmon),str2double(dday),str2double(hh),str2double(mm),0);
if strcmp(tz,'AST')
    temp=temp+duration(4,0,0);
elseif strcmp(tz,'EST')
    temp=temp+duration(5,0,0);
elseif strcmp(tz,'CST')
    temp=temp+duration(6,0,0);
end
    
S.AdvString=datestr(datenum(temp)-4/24,'ddd, dd mmm, HH PM');

delete([fb '*'])

