function showelem(fem_grid_struct,ie)
%SHOWELEM highlight and display statistics on selected element
%
%  SHOWELEM highlights a user-specified element, either 
%  by mouse-click or by giving SHOWELEM an element number.
%  The mesh must have been previously drawn by the OPNML/MATLAB
%  routine DRAWELEMS for SHOWELEM to work.
%             
%   INPUT :  fem_grid_struct - (from LOADGRID, see FEM_GRID_STRUCT)     
%            ie - element to highlight (OPT)
%            If ie is not provided, SHOWELEM prompts the user to
%            click on the FEM element drawing to specify an element.
%
% OUTPUTS :  NONE (display to figure)
%
%    CALL :  >> showelem(fem_grid_struct,ie)
%     or
%            >> showelem(fem_grid_struct)    
%             
% Written by : Brian O. Blanton
% Fall 1997
%

% VERIFY INCOMING STRUCTURE
%
if ~is_valid_struct(fem_grid_struct)
   error('    fem_grid_struct to SHOWELEM invalid.')
end



if ~exist('ie')
   ie=findelem(fem_grid_struct);
end

if ie==0,return,end

currfig=gcf;

x=fem_grid_struct.x;
y=fem_grid_struct.y;
e=fem_grid_struct.e;
z=fem_grid_struct.z;

xc=(x(e(ie,1))+x(e(ie,2))+x(e(ie,3)))/3;
yc=(y(e(ie,1))+y(e(ie,2))+y(e(ie,3)))/3;
xe=[x(e(ie,1)) x(e(ie,2)) x(e(ie,3)) x(e(ie,1))];
ye=[y(e(ie,1)) y(e(ie,2)) y(e(ie,3)) y(e(ie,1))];
patch(xe,ye,'r');
text(xc,yc,num2str(ie,6),'Color','g','HorizontalAlignment','Center');
   

delete(findobj(0,'Type','figure','Tag','Element Info Fig'));
shfig=figure('Units','inches',...
             'Position',[7 7 4 3],...
             'NumberTitle','off',...
             'Name',['Element ' int2str(ie) ' Information'],...
             'Tag','Element Info Fig');
set(shfig,'Units','Normalized');
shax=axes('Position',[.1 .1 .8 .8],'Xlim',[-0.5 4.5],'Ylim',[-2.5 1.5]);
set(shax,'Visible','off');
set(shax,'Box','on');
xe=(xe-min(xe));
xe=xe/max(xe);
ye=(ye-min(ye));
ye=ye/max(ye);
line(xe,ye);
patch(xe,ye,'r');
text(xe(1),ye(1),int2str(e(ie,1)),...
     'HorizontalAlignment','Center','Color','g');
text(xe(2),ye(2),int2str(e(ie,2)),...
     'HorizontalAlignment','Center','Color','g');
text(xe(3),ye(3),int2str(e(ie,3)),...
     'HorizontalAlignment','Center','Color','g');

n1=e(ie,1);
n2=e(ie,2);
n3=e(ie,3);     

text(1.75,1.,['Nodes : ' int2str(n1) ]);
text(1.75,.7,['              ' int2str(n2)])
text(1.75,.4,['              ' int2str(n3)])

text(-.5,-.5,['X = { ' num2str(x(n1)) ' ' num2str(x(n2)) ' ' num2str(x(n3)) ...
      ' }'])
text(-.5,-1.,['Y = { ' num2str(y(n1)) ' ' num2str(y(n2)) ' ' num2str(y(n3)) ...
      ' }'])

if exist('z')
  text(-.5,-1.5,['Z = { ' num2str(z(n1)) ' ' num2str(z(n2)) ' ' ...
	num2str(z(n3)) ' }'])
end
 
if ~isempty(fem_grid_struct.ar)
  dy1=y(n2)-y(n3);
  dy2=y(n3)-y(n1);
  dy3=y(n1)-y(n2);
  area=0.5d0*(x(n1)*dy1 + x(n2)*dy2 + x(n3)*dy3);
  text(1.75,0,['Area = ' num2str(area)])
end

figure(currfig);
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
%        Fall 1997

