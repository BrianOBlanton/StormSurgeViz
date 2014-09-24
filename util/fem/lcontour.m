function h=lcontour(fem_grid_struct,Q,cval,varargin)
%LCONTOUR contour a scalar on a FEM grid.
%   LCONTOUR contours a scalar field on the input FEM grid.
%   LCONTOUR accepts a vector of values to be contoured 
%   over the provided mesh.  
%
%   INPUT : fem_grid_struct (from LOADGRID, see FEM_GRID_STRUCT)
%           Q    - scalar to be contoured upon; must be a 1-D vector 
%                  or the single character 'z', IN SINGLE QUOTES!!
%           cval - vector of values to contour
%
%           In order to contour the FEM domain bathymetry, pass
%           in the string 'z' in place of an actual scalar field Q.
%           You could, of course, pass in the actual bathymetry as
%           the scalar to contour.  Otherwise, Q must be a 1-D vector
%           with length equal to the number of nodes in the FEM mesh.
%
%           Any property name/value pair that LINE accepts can be 
%           passed to LCONTOUR. See LINE help for details.
%
%  OUTPUT :  h - the handle to the contour line(s) drawn
%
%    CALL : >> h=lcontour(fem_grid_struct,Q,cval,pn1,pv1,pn2,pv2,...)
%     OR    >> h=lcontour(fem_grid_struct,'z',cval,pn1,pv1,pn2,pv2,...)

% Written by : Brian O. Blanton
% 
% 07 Mar, 2004: moved drawing of contours outside of computational
%               loop to speed up rendering of graphics over slow
%               net connections
% 
% 
% 
% VERIFY INCOMING STRUCTURE
%
if ~isstruct(fem_grid_struct)
   msg=str2mat(' ',...
               'First argument to LCONTOUR not a structure.  Perhaps its',...
               'the element list.  If so you should use LCONTOUR4, which',...
               'takes the standard grid arrays (e,x,...).  The first ',...
               'argument to LCONTOUR MUST be a fem_grid_struct.',' ');
   disp(msg)
   error(' ')
end
if ~is_valid_struct(fem_grid_struct)
   error('    fem_grid_struct to LCONTOUR invalid.')
end

e=fem_grid_struct.e;
x=fem_grid_struct.x;
y=fem_grid_struct.y;

% DETERMINE SCALAR TO CONTOUR
%
if ischar(Q)
   Q=fem_grid_struct.z;
else
   % columnate Q
   Q=Q(:);
   [nrowQ,ncolQ]=size(Q);
   if nrowQ ~= length(x)
      error('Length of scalar must be same length as grid coordinates.');
   end   
end
 
% range of scalar quantity to be contoured; columnate cval
Qmax=max(Q);
Qmin=min(Q);
cval=cval(:);
h=zeros(size(cval));

for kk=1:length(cval)
%parfor (kk=1:length(cval))
   if (cval(kk) > Qmax) || (cval(kk) < Qmin)
      disp(sprintf('%s not within range of scalar field.  Min = %f  :  Max = %f',num2str(cval(kk)),Qmin,Qmax));
      h(kk)=NaN;
   else
   
% Call cmex function contmex5
%
%keyboard

      C=contmex5(x,y,e,Q,cval(kk));
      if(size(C,1)*size(C,2)~=1)
              X = [ C(:,1) C(:,3) NaN*ones(size(C(:,1)))]';
              Y = [ C(:,2) C(:,4) NaN*ones(size(C(:,1)))]';
              XX{kk} = X(:);
              YY{kk} = Y(:);
              len(kk)=length(X(:));
      else
         disp(['CVal ' num2str(cval(kk)) ' within range but still invalid.']);
         h(kk)=NaN;
      end
   end
end 

for kk=1:length(cval)
   if ~isnan(h(kk))
      h(kk)=line(XX{kk},YY{kk},varargin{:},'UserData',cval(kk),'Tag','contour');
   end
end
h(find(isnan(h)))=0;

return

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
%            Mod 08 Mar, 2004   





 
