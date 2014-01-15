function h=numnodes(fem_grid_struct,varargin)
%NUMNODES number nodes on current axes.
%
%  INPUT : fem_grid_struct - (from LOADGRID, see FEM_GRID_STRUCT)
%          p1,v1,...       - any property/vaule pair accepted by TEXT
%
% OUTPUT : h - vector of handle to text objects drawn
%
%   CALL : h=numnodes(fem_grid_struct,p1,v1,...);
%
% Written by : Brian O. Blanton
% Summer 1997
%

% DEFINE ERROR STRINGS
warn1=['The current axes is too dense for the  '
       'node numbers to be readable.  CONTINUE?']; 
       
% check arguments
if nargin ==0 
   disp('h=numnodes(fem_grid_struct,p1,v1,...);');
   return
end 
if nargin==1
   varargin={};
end

ps=15;

if ~is_valid_struct(fem_grid_struct)
   error('    Argument to NUMNODES must be a valid fem_grid_struct.')
end
 
% Default fontsize=10;
ps=10;
 
% Extract grid fields from fem_grid_struct
elems=fem_grid_struct.e;
x=fem_grid_struct.x;
y=fem_grid_struct.y;

X=get(gca,'Xlim');
Y=get(gca,'YLim');

% get indices of nodes within viewing window defined by X,Y
filt=find(x>=X(1)&x<=X(2)&y>=Y(1)&y<=Y(2));

% determine if viewing window is zoomed-in enough for node
% numbers to be meaningful; 
set(gca,'Units','points');  
rect=get(gca,'Position');   % get viewing window width in point units (1/72 inches)
set(gca,'Units','normalized');
xr=rect(3)-rect(1);
yr=rect(4)-rect(2);;
xden=xr/sqrt(length(filt));
yden=yr/sqrt(length(filt));
den=sqrt(xden*xden+yden*yden);
% if den < 5*ps
%    click=questdlg(warn1,'Continue??','Yes','No','Cancel','Yes');
%    if strcmp(click,'No')|strcmp(click,'Cancel'),
%  if nargout==1,h=[];,end
%  return
%    end
% end

% Build string matrix
strlist=num2str(filt,10);

xx=x(filt);yy=y(filt);
%format long e
% label only those nodes that lie within viewing window.
htext=text(xx,yy,strlist,...
                 'FontSize',ps,...
                 'HorizontalAlignment','center',...
                 'VerticalAlignment','middle',...
                 'Color','k',...
                 varargin{:},...
                 'Tag','Node #');


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


