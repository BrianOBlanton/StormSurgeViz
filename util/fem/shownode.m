function shownode(fem_grid_struct,in,varargin)
%SHOWNODE highlight and display statistics on selected node
% SHOWNODE highlights a user-specified node, either 
% by mouse-click or by passing SHOWNODE an node number.
% The mesh must have been previously drawn by the OPNML/MATLAB
% routine DRAWELEMS for SHOWNODE to work.
%             
%   INPUT: fem_grid_struct - (from LOADGRID, see FEM_GRID_STRUCT)     
%          in - node to highlight (OPT)
%          If in is not provided, SHOWNODE prompts the user to
%          click on the mesh drawing to specify a node.
%
% OUTPUTS: NONE (display to figure)
%
%    CALL :  >> shownode(fem_grid_struct,in)
%     or
%            >> shownode(fem_grid_struct)    
%             
% Written by : Brian O. Blanton
% Spring 1997
%

% VERIFY INCOMING STRUCTURE
%
if ~is_valid_struct(fem_grid_struct)
   error('    fem_grid_struct to SHOWNODE invalid.')
end

x=fem_grid_struct.x;
y=fem_grid_struct.y;
e=fem_grid_struct.e;
z=fem_grid_struct.z;

if ~exist('in')
   disp('Click on node ...');
   waitforbuttonpress;
   Pt=gcp;
   xp=Pt(2);yp=Pt(4);
   htempmark=line(xp,yp,'LineStyle','+','Tag','Temp Node Marker');
   ie=findelem(fem_grid_struct,[xp yp]);
   % Find least dist from xp,yp to nodes of element ie
   dx=xp-x(e(ie,:));
   dy=yp-y(e(ie,:));
   dist=sqrt(dx.*dx+dy.*dy);
   [yy,imin]=min(dist);
   in=e(ie,imin);
   delete(htempmark)
   line(x(in),y(in),'LineStyle','+','Tag','Node Marker');
end

if in==0,return,end

% Find the elements that contain node in as vertices;
ifind1=find(e(:,1)==in);
ifind2=find(e(:,2)==in);
ifind3=find(e(:,3)==in);
%ifind=sort([ifind1;ifind2;ifind3]);
ifind=[ifind1;ifind2;ifind3];

elems=e(ifind,:);

% Make matrix of line segments
elems=elems(:,[1 2 2 3 3 1]);

[m,n]=size(elems);
segs=reshape(elems,m*n/2,2);

xt=x(segs);
yt=y(segs);

xt=[xt NaN*ones(size(xt(:,1)))]';
yt=[yt NaN*ones(size(yt(:,1)))]';

%if n~=1 
%   if m>n
%      xt=reshape(xt,n,m);
%      yt=reshape(yt,n,m);
%   else
%      xt=reshape(xt,m,n);
%      yt=reshape(yt,m,n);
%   end
%   xt=[xt
%       NaN*ones(size(1:length(xt)))];
%   yt=[yt
%       NaN*ones(size(1:length(yt)))];
%end

xt=xt(:);
yt=yt(:);

% Get the unique node numbers
nn=e(ifind,:);
nn=unique(nn(:));
xtn=x(nn);
ytn=y(nn);

minxt=min(xt);maxxt=max(xt);
minyt=min(yt);maxyt=max(yt);

xtn=xtn-min(xt);xtn=xtn/max(xtn);
ytn=ytn-min(yt);ytn=ytn/max(ytn);

xt=xt-min(xt);
xt=xt/max(xt);
yt=yt-min(yt);
yt=yt/max(yt);


% currfig=gcf;
% delete(findobj(0,'Type','figure','Tag','Node Info Fig'));
% shfig=figure('Units','normalized',...
%              'Position',[.5 .5 .3 .3],...
%              'NumberTitle','off',...
%              'Name',['Node ' int2str(in) ' Information'],...
%              'Tag','Node Info Fig');
% shax=axes('Xlim',[-0.1 1.1],'Ylim',[-.1 1.1]);
% set(shax,'Visible','off');
% set(shax,'Box','on');
% hel=line(xt,yt,'LineWidth',1,'LineStyle','-','Color',[1 0 0]*1);
% 
% text(xtn,ytn,int2str(nn),'HorizontalAlignment','center','FontSize',15)
% 
% % Label Elements
% xc=mean(x(e(ifind,:))');
% yc=mean(y(e(ifind,:))');
% xc=xc-min(xc);
% xc=xc/max(xc);
% yc=yc-min(yc);
% yc=yc/max(yc);
% text(xc,yc,int2str(ifind),'Color','g','HorizontalAlignment','Center');



%figure(currfig);
% Place a red asterisk on the node
line(x(in),y(in),'Color',[1 0 0]*1,'Marker','*','LineStyle','none','MarkerSize',20,varargin{:})

return
%
%        Brian O. Blanton
%        Department of Marine Sciences
%        12-7 Venable Hall
%        CB# 3300
%        University of North Carolina
%        Chapel Hill, NC
%                 27599-3300
%
%        brian_blanton@unc.edu
%
%        Spring 1997

