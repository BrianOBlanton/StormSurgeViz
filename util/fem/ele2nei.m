function nei=ele2nei(e,x,y)
%ELE2NEI build a FEM neighbor list from element and node lists
% ELE2NEI computes the neighbor list for a FEM mesh specified
% by the triangular element lists.  Each node's neighbor list
% is then sorted into counter-clockwise order.
%
% The resulting neighbor list can be passed to WRITE_NEI
% to output a FEM neighbor file (.nei) to disk.
%
%  INPUTS:  e - 3-column element connectivity list (REQ)
%           x - x-coordinate list (REQ)
%           y - y-coordinate list (REQ)
% OUTPUTS:  nei - neighbor list (REQ)
%
%    CALL: nei=ele2nei(e,x,y);
%
% Written by : Brian O. Blanton 
%              March 1996
%

if nargin~=3
   error('ELE2NEI REQUIRES!!! 3 input arguments.');
elseif nargout~=1
   error('ELE2NEI REQUIRES!!! 1 output argument.');
end

nei=ele2neimex5(e,x,y);

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
%        March 1996
%
