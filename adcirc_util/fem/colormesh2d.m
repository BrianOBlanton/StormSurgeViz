function rv1=colormesh2d(fem_grid_struct,Q,varargin)
%COLORMESH2D draw a FEM mesh in 2-d colored by a scalar quantity.
%
%   INPUT : fem_grid_struct (from LOADGRID, see FEM_GRID_STRUCT)
%	    Q	      - scalar to color with (optional)
%	    nband     - number of contour bands to compute (optional)
%
%	    With no scalar specified to contour, COLORMESH2D
%	    defaults to the bathymetry fem_grid_struct.z
%
%  OUTPUT : hp - vector of handles, one for each element patch drawn.
%
%   COLORMESH2D colors the mesh using the scalar Q.  If Q
%   is omitted from the argument list, COLORMESH2D draws
%   the element connectivity in black and white.
%
%   CALL : >> hp=colormesh2d(fem_grid_struct,Q,nband)
%
% Written by : Brian O. Blanton
%

%nargchk(1,3,nargin);

% VERIFY INCOMING STRUCTURE
%
if ~isstruct(fem_grid_struct)
   error('First argument to COLORMESH2D must be a structure.')
end
if ~is_valid_struct(fem_grid_struct)
   error('fem_grid_struct to COLORMESH2D invalid.')
end
 
e=fem_grid_struct.e;
x=fem_grid_struct.x;
y=fem_grid_struct.y;

% Default propertyname values
NBands=16;

% Strip off propertyname/value pairs in varargin not related to
% "line" object properties.
k=1;
while k<length(varargin),
  switch lower(varargin{k}),
    case 'nbands'
      NBands=varargin{k+1};
      varargin([k k+1])=[];
    otherwise
      k=k+2;
  end
end
if length(varargin)<2
   varargin={};
end


if ischar(Q)
   if strcmp(lower(Q),'z')
     Q=fem_grid_struct.z;            % Default to bathymetry
   else
      error('Second arg to COLORMESH2D must be ''z'' for depth')
   end
end

% % DETERMINE SCALAR TO CONTOUR
% %
% if ~exist('Q')
%   Q=fem_grid_struct.z;
%   nband=16;
% elseif ischar(Q)
%   if strcmp(lower(Q),'z')
%     Q=fem_grid_struct.z;            % Default to bathymetry
%   else
%      error('Second arg to COLORMESH2D must be ''z'' for depth')
%   end
%   nband=16;
% elseif length(Q)==1
%   % nband pass in as Q
%   nband=Q;
%   Q=fem_grid_struct.z;
% else
%    % columnate Q
%    Q=Q(:);
%    [nrowQ,ncolQ]=size(Q);
%    if nrowQ ~= length(x)
%       error('Length of scalar must equal number of nodes in grid.');
%    end 
%    if nargin==2,nband=16;,end
% end
% 
% if nargin==3
%    if length(nband)>1
%       error('nband argument to COLORMESH2D must be 1 integer')
%    end
% end
            
[nrowQ,ncolQ]=size(Q);
if ncolQ>1,error(err4);,end
if nrowQ ~= length(x)
   error('length of scalar must be the same length as coordinate vectors')

end
Q=Q(:);


% delete previous colorsurf objects
%delete(findobj(gca,'Type','patch','Tag','colorsurf'))
z=ones(size(x));
hp=patch('faces',e,'vertices',[x y z],'facevertexcdata',Q,'EdgeColor','none',...
         'FaceColor','interp','Tag','colorsurf',varargin{:});

%colormap(jet(nband))

% Output if requested.
if nargout==1,rv1=hp;,end


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

 
