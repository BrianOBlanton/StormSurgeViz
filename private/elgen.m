function ellist=elgen(nhorz,nvert)
%ELGEN generate an element list for a rectangular FEM mesh 
% ELGEN generate an element list for a FEM mesh with nhorz nodes in the 
% x-direction and nvert nodes in the y-direction.  This function 
% is used primarily to provide element lists for transect data
% so that contours can be computed for the normal component of
% the transect.  
%
% Example: If a transect is made with 25 horizontal and 10 vertical
% stations,  ELGEN would be called as follows:
%       
%   >> ellist=elgen(25,10);
%
% The result would be an element list containing the node numbers
% for the three vertices of 2*(nhorz-1)*(nvert-1) elements in a matrix
% with 2*(nhorz-1)*(nvert-1) rows and 3 columns.
%

nrx=nhorz-1;
nry=nvert-1;
ellist=zeros(nrx*nry*2,3);

iel=0;
for ic=1:nrx
   for ir=1:nry
      iel=iel+1;
      n1=ir+(ic-1)*nvert;
      n2=n1+nvert;
      n3=n2+1;
      ellist(iel,:)=[n1 n2 n3]; 
      iel=iel+1;
      n2=n3;
      n3=n1+1;
      ellist(iel,:)=[n1 n2 n3]; 
   end
end

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
%        September 1994
%
