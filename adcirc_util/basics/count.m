function [elts,nelt]=count(x)
%COUNT Elements of a matrix in set theoretic sense.
% COUNT(X) is a row vector containing the
% distinct elements of X.
% [ELTS,NELT] = COUNT(X) produces
% the elements of X in ELTS and
% the corresponding count of the elements in NELT.
% X is treated as 1 set and may contain NaN's and Inf's
% (which are counted also). Complex arrays as well as
% sparse matrices and text strings are handled properly.
% ELTS is sorted.
% Enter 'count' for a demo.

% Author:  J. Rodney Jee, rodjee@delphi.com,  28-JAN-95
% Brian O. Blanton changed the name of this routine from
% ELEMENTS to COUNT for obvious FEM-related reasons. 30-Oct-95

if ( nargin == 0 )               % DEMO this function when no input.
   disp('+++++++++++++++ DEMO of COUNT +++++++++++++++')
   disp('GIVEN a set, say')
   x = round( rand(4,6)*4 )
   disp('COUNT returns its')
   [members,counts]=count(x);
   members
   disp('and their respective')
   counts
   disp('+++++++++++++++++ END of DEMO +++++++++++++++++')
   return
end


% The key ideas of this method are to (1)sort the data, (2)take the
% differences of the sorted data and look for nonzeros in the 
% differences which mark the ends of strings of the same values, (3)
% collect the values of step 2, and (4)use the indices of the
% jumps to tally the members.

if (issparse(x))                         % Check for sparse matrix.
   nzeros=prod(size(x))-nnz(x);
   x = nonzeros(x);                      % Required to be a column matrix.
else
   if ( isstr(x) )                       % Convert text strings to integer.
      xstring=1;
      x = abs(x);
	  x = x(:);
   else
      xstring=0;
      nzeros=0;
      x = x(:);
   end
end

indexf = isfinite(x);
xout   = x( ~indexf );                   % Set aside NaNs and Infs.
x      = sort( x(indexf) );                             % Step (1).
if ( isempty(x) )
   elts = [];
   nelt = [];
elseif (length(x) == 1)
   elts = x;
   nelt = 1;
else
  indjump = find(diff(x) ~= 0);                         % Step (2).
  if ( length(indjump) == 0 )
     elts = x(1);
     nelt = length(x);
  else
     elts = x(indjump);                                 % Step (3).
     elts = [elts.',x(length(x))];
     nelt = diff( [0, indjump.', length(x)] );          % Step (4).
  end
end

if (isempty(xout) & (nzeros==0))        
   return
else                                  % Append NaN's,Inf's, and 0's.
   nnan = sum(isnan(xout));
   ninf = length(xout) - nnan;
   if ( nnan > 0)
      elts = [elts, NaN];
      nelt = [nelt, nnan];
   end
   if ( ninf > 0)
      elts = [elts, Inf];
      nelt = [nelt, ninf];
   end
   if ( nzeros > 0)
      elts = [elts, 0];
	  nelt = [nelt, nzeros];
   end
end

if (xstring)                        
   elts = setstr(elts);
end
