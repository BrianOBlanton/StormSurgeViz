function NewFemGridStruct=el_areas(OldFemGridStruct)
%EL_AREAS compute triangular finite element areas
%
% EL_AREAS(FEM_GRID_STRUCT) computes the areas for the 
% elements of the FEM domain described in the 
% structure FEM_GRID_STRUCT.  The function must
% return a new structure, which is identical to the 
% input structure with the element areas attached.
% The element areas are contained in the field .ar,
% so that the new structure now includes:
%
% .ar    - element areas                  
% .ineg  - element numbers for elements with negative areas        
% .acute - flag of acute-ness
% .interiorangles - the elements' interior angles in deg.
%
% EL_AREAS returns an index of element
% numbers whose areas are negative (if any) in the structure field 
% ineg. Negative element areas indicate clockwise elemental
% node numbering, instead of the conventional counter-
% clockwise numbering.
%
%  INPUT : fem_grid_struct - (from LOADGRID, see FEM_GRID_STRUCT)       
%           
% OUTPUT : new_struct (REQ) - new structure with areas
%
%   CALL : >>new_struct=el_areas(fem_grid_struct);
%
% Written by : Brian O. Blanton 
% Summer 1997
% Fall 2009 added other element properties (angle, etc...)


if nargout==0
   disp('NewFemGridStruct=el_areas(OldFemGridStruct);');
   return
end


% VERIFY INCOMING STRUCTURE
%
if ~is_valid_struct(OldFemGridStruct)
   error('    Argument to EL_AREAS must be a valid fem_grid_struct.')
end


% NEED ONE for return struct
%
if nargout~=1
   error('   EL_AREAS must have 1 output argument.')
end

% Create return structure 
%
NewFemGridStruct=OldFemGridStruct;

% BREAK DOWN INCOMING STRUCTURE
%
e=OldFemGridStruct.e;
x=OldFemGridStruct.x;
y=OldFemGridStruct.y;

% convert to cart for areas and edge length arrays
% if range(x) < 90 && range(y) < 90   % assume in lon/lat
%     NewFemGridStruct.lo0=mean(x);
%     NewFemGridStruct.la0=mean(y);
%     [x,y]=convll2m(x,y,NewFemGridStruct.lo0,NewFemGridStruct.la0);
%     NewFemGridStruct.trx0=mean(x);
%     NewFemGridStruct.try0=mean(y);
%     NewFemGridStruct.xcart=x-NewFemGridStruct.trx0;
%     NewFemGridStruct.ycart=y-NewFemGridStruct.try0;
% end

% COMPUTE GLOBAL DX,DY, Len, angles
%
i1=e(:,1);
i2=e(:,2);
i3=e(:,3);

x1=x(i1);x2=x(i2);x3=x(i3);
y1=y(i1);y2=y(i2);y3=y(i3);

% coordinate deltas
%
dx23=x2-x3;
dx31=x3-x1;
dx12=x1-x2;
dy23=y2-y3;
dy31=y3-y1;
dy12=y1-y2;

% lengths of sides
%
a = sqrt(dx12.*dx12 + dy12.*dy12);  
b = sqrt(dx31.*dx31 + dy31.*dy31);
c = sqrt(dx23.*dx23 + dy23.*dy23);  

% angles
%
if isfield(NewFemGridStruct,'interiorangles')
   NewFemGridStruct=rmfield(NewFemGridStruct,'interiorangles');
end
NewFemGridStruct.interiorangles(:,1)=acos((b.^2 + c.^2 - a.^2)./(2*b.*c))*180/pi;
NewFemGridStruct.interiorangles(:,2)=acos((a.^2 + c.^2 - b.^2)./(2*a.*c))*180/pi;
NewFemGridStruct.interiorangles(:,3)=acos((a.^2 + b.^2 - c.^2)./(2*a.*b))*180/pi;

% cuteness of elements
%
%NewFemGridStruct.acute = (a+c>b) & (c+b>a) & (b+a>c);
NewFemGridStruct.acute = all(NewFemGridStruct.interiorangles'<90)';

% COMPUTE ELEMENTAL AREAS
%
NewFemGridStruct.ar = ( x1.*dy23 + x2.*dy31 + x3.*dy12 )/2.;

% ANY NEGATIVE OR ZERO AREAS ?
%
ineg=find(NewFemGridStruct.ar<=0);
if ~isempty(ineg)
   disp('There are negative element areas.  Check grid!')
end
NewFemGridStruct.ineg=ineg;

%
%LabSig  Brian O. Blanton
%        Renaissance Computing Institute
%        University of North Carolina
%        Chapel Hill, NC
%
%        brian_blanton@renci.org
%
