function hel=drawnodes(fem_grid_struct,varargin)
%DRAWNODES draw 2-D FEM nodes
%DRAWNODES draws node locations given a valid grid structure.  
%
%  INPUT : fem_grid_struct - (from LOADGRID, see FEM_GRID_STRUCT)       
%           
% OUTPUT : hel - handle to the node object.
%
%   CALL : hel=drawnodes(fem_grid_struct,p1,v1,...);
%
% Summer 2009
%                  

LabelNodes='no';
TheseNodes=[];


% DEFINE ERROR STRINGS
err1=['Not enough input arguments; need a fem_grid_struct'];

% check arguments
if nargin ==0 
   disp('h=drawnodes(fem_grid_struct,p1,v1,...);')
   return
end  

if ~is_valid_struct(fem_grid_struct)
   error('    Argument to DRAWNODES must be a valid fem_grid_struct.')
end


% Strip off propertyname/value pairs in varargin not related to
% "line" object properties.
k=1;
while k<length(varargin),
  switch lower(varargin{k}),
    case 'labelnodes',
      LabelNodes=varargin{k+1};
      varargin([k k+1])=[];
    case 'thesenodes',
      TheseNodes=varargin{k+1};
      varargin([k k+1])=[];      
    otherwise
      k=k+2;
  end;
end;

if length(varargin)<2
   varargin={};
end

% Extract grid fields from fem_grid_struct
x=fem_grid_struct.x;
y=fem_grid_struct.y;

if isempty(TheseNodes)
    % get indices of nodes within viewing window defined by X,Y
    X=get(gca,'Xlim');
    Y=get(gca,'YLim');
    filt=find(x>=X(1)&x<=X(2)&y>=Y(1)&y<=Y(2));
    x=x(filt);
    y=y(filt);
else
    x=x(TheseNodes);
    y=y(TheseNodes);
end


% DRAW NODES
hel=line(x,y,'LineStyle','none','Marker','.','MarkerSize',15,varargin{:},'Tag','nodes');


% Default fontsize=20;
ps=20;
if strcmp(LabelNodes,'yes')
   % Build string matrix
   strlist=num2str(filt,10);
   % label only those nodes that lie within viewing window.
   htext=text(x,y,strlist,...
                    'FontSize',ps,...
                    'HorizontalAlignment','center',...
                    'VerticalAlignment','middle',...
                    'Color','k',...
                    varargin{:},...
                    'Tag','Node #');
end

if exist('plotfx')
   plotfx;
end
