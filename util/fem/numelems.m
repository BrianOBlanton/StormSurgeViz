function h=numelems(fem_grid_struct,varargin)
%NUMELEMS number elements on current axes in viewing region.
%
%  INPUT : fem_grid_struct - (from LOADGRID, see FEM_GRID_STRUCT)
%          p1,v1,...       - any property/vaule pair accepted by TEXT
%
% OUTPUT : h - vector of handle to text objects drawn (optional)
%
%   CALL : h=numelems(fem_grid_struct,p1,v1,...);
%
% Summer 1997
%

% DEFINE ERROR STRINGS 
warn1=['The current axes is too dense for the  '
       'node numbers to be readable.  CONTINUE?']; 

ps=15;
          
% check arguments
if nargin ==0 
   disp('h=numelems(fem_grid_struct,p1,v1,...);');
   return
end
if ~is_valid_struct(fem_grid_struct)
   error('    Argument to NUMELEMS must be a valid fem_grid_struct.')
end


% Extract grid fields from fem_grid_struct
%
elems=fem_grid_struct.e;
x=fem_grid_struct.x;
y=fem_grid_struct.y;

% compute centroid of each element 
i=1:length(elems(:,1));
xcent=(x(elems(i,1))+x(elems(i,2))+x(elems(i,3)))/3;
ycent=(y(elems(i,1))+y(elems(i,2))+y(elems(i,3)))/3;
 
% get indices of centroids within viewing window defined by X,Y
X=get(gca,'XLim');
Y=get(gca,'YLim');

   % get indices of element centroids within viewing window defined by X,Y
   filt=find((xcent>X(1)&xcent<X(2))&(ycent>Y(1)&ycent<Y(2)));

%    % determine if viewing window is zoomed-in enough for element
%    % numbers to be meaningful;
%    set(gca,'Units','points');      % get viewing window width in point size
%    rect=get(gca,'Position');       % point units (1/72 inches)
%    set(gca,'Units','normalized');  % reset viewing window units
%    xr=rect(3)-rect(1);
%    yr=rect(4)-rect(2);;
%    xden=xr/sqrt(length(filt));
%    yden=yr/sqrt(length(filt));
%    den=sqrt(xden*xden+yden*yden);
%    if den < 5*ps
%       click=questdlg(warn1,'Continue??','Yes','No','Cancel','No');
%       if strcmp(click,'No')|strcmp(click,'Cancel'),
% 	 if nargout==1,h=[];,end
% 	 return
%       end
%    end

% Build string matrix
strlist=num2str(filt,12);

xx=xcent(filt);yy=ycent(filt);

format long e
% label only those nodes that lie within viewing window.
htext=text(xx,yy,strlist,...
                 'HorizontalAlignment','center',...
                 'VerticalAlignment','middle',...
                 'Color','k',...
		 'FontSize',ps,...
                 'Tag','Element #',varargin{:});
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


