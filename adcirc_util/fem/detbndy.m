function bnd=DetBnd(in)
%DetBnd compute a boundary segment list for a FEM domain
% DetBnd bnd=detbndy(e);
%         This function computes a boundary for the FEM domain
%         described a file containing element connectivity list (e).
%         It uses sparse matrix techniques to determine the element
%         edges on the boundary of the FEM domain.
%
% Input:  ele -  element list; 3 (.tri) or 4 (.ele) columns wide
% Output: bnd -  a 2-column list of boundary-node numbers, returned
%                to the local workspace
%
%         The output boundary list are pairs of node numbers, not 
%         coordinates, describing the edges of elements on the 
%         exterior of the domain, including islands.  The segments 
%         are not connected.
%
%         Call as: bnd=DetBnd(e);
%
% Written by : Brian O. Blanton, The University of North Carolina 
%

% DEFINE ERROR STRINGS
err1='Only one input argument to DetBnd. Type "help DetBnd"';
err2='Element list passed to DetBnd does not have 3 or 4 columns';
err3='DetBnd must have one output argument. Call as: >> bnd=DetBnd(in);';
% check argument list
if nargin~=1
   error(err1);
end

if nargout~=1
   disp(err3);
   return
end
 
 
% Check size of element list
ncol=size(in,2);
if ncol < 3 || ncol > 4
   error(err2);
elseif ncol==4
   in=in(:,2:4);
end

% Form (i,j) connection list from .ele element list
%
i=[in(:,1);in(:,2);in(:,3)];
j=[in(:,2);in(:,3);in(:,1)];

% Form the sparse adjacency matrix and add transpose.
%
n = max(max(i),max(j));
A = sparse(i,j,-1,n,n);
A = A + A';

% Consider only the upper part of A, since A is symmetric
% 
A=A.*triu(A);

% The boundary segments are A's with value == 1
%
B=A==1;

% Extract the row,col from B for the boundary list.
%
[ib,jb,s]=find(B);
bnd=[ib(:),jb(:)];

%
%LabSig  Brian O. Blanton
%        Renaissance Computing Institute
%        University of North Carolina at Chapel Hill, NC
%
%        Brian_Blanton@Renci.Org
%
