function [phi,j]=basis2d(fem_grid_struct,xylist,j)
%BASIS2D compute basis functions for input points in FEM grid
%   BASIS2D computes the FEM basis functions for a given 
%   horizontal position, specified either in the argument
%   list or with the mouse.
%
%   In determining which element has been selected, 
%   BASIS2D needs elemental areas and shape functions.
%   Element areas are returned by LOADGRID.
%   The routine BELINT computes shape function information
%   and attaches it to the input fem_grid_struct.
%   These two functions MUST be run before BASIS2D will 
%   run.
%
%   BELINT is run as: 
%      new_struct=belint(fem_grid_struct); 
%   If ever needed, EL_AREAS is run as:
%      [new_struct,ineg]=el_areas(fem_grid_struct); 
%
%   INPUT : fem_grid_struct - (from LOADGRID, see FEM_GRID_STRUCT)     
%           xylist  (op)    - points to find elements for [n x 2 double] 
%           j       (op)    - element list corresponding to the xylist
%                             set of points.  Optional, but if passed in, 
%                             points will not be relocated. length(j) must
%                             equal length(xylist).
%           
%   OUTPUT : basis function(s) and element number(s)
%            If elements were NOT passed in, then providing two output
%            arguments will collect the elements determined to contain the 
%            specified points.
% 
%   CALL : >> [phi,j]=basis2d(fem_grid_struct)   for interactive
%    or
%          >> [phi,j]=basis2d(fem_grid_struct,xylist)        
%    or
%          >> phi=basis2d(fem_grid_struct,xylist,j)        
%

% Written by : Brian O. Blanton 
% Summer 1998


if nargin==0 & nargout==0
   disp('[phi,j]=basis2d(fem_grid_struct,xylist)')
   return
end

% Input arguemnt number check
nargchk(1,3,nargin);

if nargin==3 & nargout==2
   error('cannot input AND output element list to BASIS2D')
end

if nargin==1
   % VERIFY INCOMING STRUCTURE
   %
   if ~is_valid_struct(fem_grid_struct)
      error('    Grid argument to BASIS2D must be a valid fem_grid_struct.')
   end

   % Make sure additional needed fields of the fem_grid_struct
   % have been filled.
   if ~is_valid_struct2(fem_grid_struct)
      error('    fem_grid_struct to BASIS2D invalid.')
   end
   xylist=[];
   j=[];
elseif nargin==2 | nargin==3
   % second argument must be Nx2
   [m,n]=size(xylist);
   if n~=2 & m~=2
      error('xylist to BASIS1D must be Nx2')
   end
   
   % allow for possible 2 x N shape
   if n>2
      xylist=xylist';
   end

   [n,m]=size(xylist);  % resize after possible transpose
   
   xp=xylist(:,1);
   yp=xylist(:,2);
   if nargin==3
      [mj,nj]=size(j);
      if mj~=1 & nj~=1
         error(' element list to BASIS2D is not a 1-D vector.')
      end
      nj=max(mj,nj);
      if n~=nj
         error('length of xylist and element list are NOT equal!')
      end
      j=j(:);
   else
      j=[];
   end
   
end

% If no points were input, use mouse to select a 
% set of points
if isempty(xylist)
   disp('Click on element ...');
   waitforbuttonpress;
   Pt=gcp;
   xp=Pt(2);yp=Pt(4);
   line(xp,yp,'Marker','+')
   xylist=[xp(:) yp(:)];
end
if isempty(j)
 % Get the element number containing points
   j=findelem(fem_grid_struct,xylist);
end

inan=find(~isnan(j));

if isempty(inan)
   phi=[];
   j=[];
   return;
end

phi=NaN*ones(length(j),3);

% Extract local information
n3=fem_grid_struct.e(j(inan),:);
x=fem_grid_struct.x(n3);
if length(xp)==1,x=x';,end
x1=x(:,1);x2=x(:,2);x3=x(:,3);
y=fem_grid_struct.y(n3);
if length(xp)==1,y=y';,end
y1=y(:,1);y2=y(:,2);y3=y(:,3);
area=fem_grid_struct.ar(j(inan));

xptemp=xp(inan);
yptemp=yp(inan);

% Basis function #1
a=(x2.*y3-x3.*y2)./(2.0*area);
b=(y2-y3)./(2.0*area);
c=-(x2-x3)./(2.0*area);
phi(inan,1)=a+b.*xptemp+c.*yptemp;

% Basis function #2
a=(x3.*y1-x1.*y3)./(2.0*area);
b=(y3-y1)./(2.0*area);
c=-(x3-x1)./(2.0*area);
phi(inan,2)=a+b.*xptemp+c.*yptemp;

% Basis function #3
a=(x1.*y2-x2.*y1)./(2.0*area);
b=(y1-y2)./(2.0*area);
c=-(x1-x2)./(2.0*area);
phi(inan,3)=a+b.*xptemp+c.*yptemp;

if nargout==0
   clear j phi
end

%
%LabSig  Brian O. Blanton
%        Department of Marine Sciences
%        12-7 Venable Hall
%        CB# 3300
%        University of North Carolina
%        Chapel Hill, NC
%                 27599-3300
%
%        brian_blanton@@unc.edu
%
%        Summer 1998

