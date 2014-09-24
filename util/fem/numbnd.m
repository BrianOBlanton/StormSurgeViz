function h=numbnd(fem_grid_struct,varargin)
%NUMBND number boundary nodes on current axes in viewing region.
%
%  INPUT : fem_grid_struct - (from LOADGRID, see FEM_GRID_STRUCT)
%
% OUTPUT : h - vector of handle to text objects drawn (optional)
%
%   CALL : h=numbnd(fem_grid_struct,p1,v1,p2,v2,...);
%
% Written by : Brian O. Blanton
% Summer 1997
%

% DEFINE ERROR STRINGS
err1=['Not enough input arguments; need atleast fem_grid_struct'];
err2=['Too many input arguments; type "help numbnd"'];
       
% check arguments
if nargin ==0 
   error(err1);
end  

if ~is_valid_struct(fem_grid_struct)
   error('    Argument to NUMBND must be a valid fem_grid_struct.')
end

% Extract grid fields from fem_grid_struct
%
bnd=fem_grid_struct.bnd;
x=fem_grid_struct.x;
y=fem_grid_struct.y;
 
X=get(gca,'Xlim');
Y=get(gca,'YLim');

% Since the boundary list is not guaranteed to be "ordered" 
% we need to know the unique node numbers in the boundary
%
[nlist,ncount] = count(bnd(:));
nlist=nlist(:);

xb=x(nlist);
yb=y(nlist);

% get indices of nodes within viewing window defined by X,Y
filt=find(xb>=X(1)&xb<=X(2)&yb>=Y(1)&yb<=Y(2));

% Build string matrix
temp=nlist(filt);
strlist=num2str(temp,6);

xx=xb(filt);yy=yb(filt);
format long e
% label only those nodes that lie within viewing window.
htext=text(xx,yy,strlist,...
                 'HorizontalAlignment','center',...
                 'VerticalAlignment','middle',...
                 'Tag','Bnd Node #',varargin{:});

if nargout==1,h=htext;,end
return
%
%LabSig  Brian O. Blanton
%        Department of Marine Sciences
%        12-7 Venable Hall
%        CB# 3300
%        University of North Carolina
%        Chapel Hill, NC
%                 27599-3300
%
%        brian_blanton@unc.edu
%
%        Summer 1997
%


