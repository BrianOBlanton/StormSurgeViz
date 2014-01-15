function bw=bwidth(elems)
%BWIDTH compute the full bandwidth of an FEM element list
%
%        INPUT: elems - 3 or 4 column element list; if the element list
%                       is 4-column, BWIDTH assumes the first column is
%                       an element counter and ignores it.
%
%        OUTPUT: bandwidth
%
%  bw=bwidth(elems)
%

err1=['matrix of elements must be 3 or 4 columns wide'];

% check size of element matrix
% nelems = number of elements, s = # of cols
if nargin~=1
   error('BWIDTH needs element list');
end
[nelems,s]=size(elems);
if s~=3 & s~=4
   error(err1);
end
if s==4
   elems=elems(:,2:4);
end

bw=2*max(max(elems')-min(elems'))+1;

return

