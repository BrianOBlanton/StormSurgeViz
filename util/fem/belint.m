function ret_struct=belint(fem_grid_struct)
%BELINT compute shape function information for a FEM domain
% BELINT(FEM_GRID_STRUCT) computes shape function 
% information to be used in element finding (FINDELE).
% BELINT must return a new structure containing the input
% structure and adding the new components.  The returned
% structure now includes:...
%
%  INPUT : fem_grid_struct - (from LOADGRID, see FEM_GRID_STRUCT)       
%           
% OUTPUT : new_struct (REQ) - new structure with areas
%
%   CALL : >>new_struct=belint(fem_grid_struct);
%
% Written by : Brian O. Blanton 
% Summer 1997
%


% VERIFY INCOMING STRUCTURE
%
if ~is_valid_struct(fem_grid_struct)
   error('    Argument to BELINT must be a valid fem_grid_struct.')
end

% NEED ONE OUT ARG
%
if nargout~=1 
   error('   BELINT must have 1 output argument.')
end

% BREAK DOWN INCOMING STRUCTURE
%
e=fem_grid_struct.e;
x=fem_grid_struct.x;
y=fem_grid_struct.y;


% COMPUTE GLOBAL DX,DY
%
dx=[x(e(:,2))-x(e(:,3)) x(e(:,3))-x(e(:,1)) x(e(:,1))-x(e(:,2))];
dy=[y(e(:,2))-y(e(:,3)) y(e(:,3))-y(e(:,1)) y(e(:,1))-y(e(:,2))];

% COMPUTE ELEMENTAL AREAS
%
AR=(x(e(:,1)).*dy(:,1)+x(e(:,2)).*dy(:,2)+x(e(:,3)).*dy(:,3))/2.;

% COMPUTE ARRAYS FOR ELEMENT FINDING 
%
n1 = e(:,1);
n2 = e(:,2);
n3 = e(:,3);
A(:,1)=x(n3)-x(n2);
A(:,2)=x(n1)-x(n3);
A(:,3)=x(n2)-x(n1);
B(:,1)=y(n2)-y(n3);
B(:,2)=y(n3)-y(n1);
B(:,3)=y(n1)-y(n2);
A0(:,1)=.5*(x(n2).*y(n3)-x(n3).*y(n2));
A0(:,2)=.5*(x(n3).*y(n1)-x(n1).*y(n3));
T(:,1)=A0(:,1)*2;
T(:,2)=A0(:,2)*2;
T(:,3)=2*AR-T(:,1)-T(:,2);

%Create return structure and attach element areas to ret_struct
%
ret_struct=fem_grid_struct;
ret_struct.A=A;
ret_struct.B=B;
ret_struct.A0=A0;
ret_struct.T=T;
ret_struct.dy=dy;
ret_struct.dx=dx;

%
%LabSig  Brian O. Blanton
%        Department of Marine Sciences
%        Ocean Processes Numerical Modeling Laboratory
%        12-7 Venable Hall
%        CB# 3300
%        University of North Carolina
%        Chapel Hill, NC
%                 27599-3300
%
%        brian_blanton@unc.edu
%
%        October 1995
%
