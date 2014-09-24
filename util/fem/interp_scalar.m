function [outq,jj]=interp_scalar(fem_grid_struct,q,x,y,j)
%INTERP_SCALAR interpolate scalar values onto scatter points
%   INTERP_SCALAR Interpolates a scalar defined at all 2-D grid points
%   in the fem_grid_struct onto the scattered points (x,y).
%
%     INPUT : fem_grid_struct (from LOADGRID, see FEM_GRID_STRUCT)
%   	      q - scalar field to interpolate
%   	      x,y - points to interpolate to (optional)
%   	      j - elements that contain x,y points (optional)
%
%     If x,y are not passed in, INTERP_SCALAR prompts the user
%     to specify a location with the mouse.  In this case,
%     the location, element number, and interpolated vaule
%     are returned through the first output argument, or else
%     to the screen, as [x y j outq].
%
%     If j is not passed in, INTERP_SCALAR locates the points
%     within fem_grid_struct and returns the element list
%     if two output arguments are provided.
%
%    OUTPUT : outq - interpolated values
%   	      j    - elements (optional)
%   	      x,y  - mouse-specified point (optional)
%
%      CALL : outq=interp_scalar(fem_grid_struct,q); (mouse-driven)
%   	      [outq,j]=interp_scalar(fem_grid_struct,q,x,y);
%   	      outq=interp_scalar(fem_grid_struct,q,x,y,j);
%
%   Written by : Brian O. Blanton
%   Summer 1998


if nargin <2 | nargin>5
   error('    Incorrect number of input arguments to INTERP_SCALAR');
end

% VERIFY INCOMING STRUCTURE
%
if ~is_valid_struct(fem_grid_struct)
   error('    Argument to INTERP_SCALAR must be a valid fem_grid_struct.')
end

if ~is_valid_struct2(fem_grid_struct)
   disp('Adding components')
   fem_grid_struct=el_areas(fem_grid_struct);
   fem_grid_struct=belint(fem_grid_struct);
end


if nargin==2
   x=[];y=[];j=[];
elseif nargin==3
   error('Must pass in both x AND y to INTERP_SCALAR')
elseif nargin==4
   if length(y)~=length(x)
      error('lengths of x and y MUST be equal.')
   end
   j=[];
elseif nargin==5
   if length(j)~=length(x)
      error('lengths of element list and x,y must be equal.')
   end
end

if size(q,1)~=size(fem_grid_struct.x,1)
   error('Shape of scalar input must match length of grid.x')
end


e=fem_grid_struct.e;
AR=fem_grid_struct.ar;
A0=fem_grid_struct.A0;
A=fem_grid_struct.A;
B=fem_grid_struct.B;

if isempty(x)
   disp('Click on a point ...');
   waitforbuttonpress;
   Pt=gcp;
   x=Pt(2);y=Pt(4);
   line(x,y,'LineStyle','none','Marker','+')
   j=[];
end

% Need to know which elements the input (x,y) points
% live in, if not passed in
%
tolerance=1.e-6;
if isempty(j)
   disp('Computing elements within interp_scalar.')
   j=findelemex5(x,y,fem_grid_struct.ar,...
                     fem_grid_struct.A,...
                     fem_grid_struct.B,...
                     fem_grid_struct.T,...
                     tolerance);
end

% Only operate on points within domain.
idx=find(~isnan(j));
jdx=j(idx);

ARI=.5./AR(jdx);
ARI=ARI(:);
A03 = AR(jdx)-A0(jdx,1) - A0(jdx,2);

q1 = q(e(jdx,1));
q2 = q(e(jdx,2));
q3 = q(e(jdx,3));

e1 = ARI.* (B(jdx,1).*q1+B(jdx,2).*q2+B(jdx,3).*q3);
e2 = ARI.* (A(jdx,1).*q1+A(jdx,2).*q2+A(jdx,3).*q3);
e3 = 2*ARI.* (A0(jdx,1).*q1+A0(jdx,2).*q2+A03.*q3);

% 
%x=x(:);y=y(:);
      
outq=NaN*ones(size(x));

outq(idx) = e1.*x(idx) + e2.*y(idx) + e3;

if nargin==0
   [x y j q]
elseif nargin==2
   if nargout==1
      outq=[x y j outq];
   else 
      jj=j;
   end     
elseif nargin==4
   if nargout==2
      jj=j;
   end     
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
%        brian_blanton@unc.edu
%
%        Summer 1998





