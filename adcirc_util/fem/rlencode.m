function [len, val] = rlencode(x)
%RLENCODE Run-length encode a vector.
%   [LEN, VAL] = RLENCODE(X) returns a vector LEN with the length of each
%   run and a vector VAL with the corresponding values.  LEN and VAL have
%   the same lengths.  X must be a vector.
%
%   Example: rlencode([ 6 6 4 4 4 5 8 8 7 7 7 7 ]) will return
%
%      len = [ 2 3 1 2 4 ];     % run lengths
%      val = [ 6 4 5 8 7 ];     % values
%
%   See also RLDECODE.
%
% Calls: none

%   Author:      Peter J. Acklam
%   Time-stamp:  2000-09-12 11:44:14
%   E-mail:      jacklam@math.uio.no
%   WWW URL:     http://www.math.uio.no/~jacklam

   % check number of input arguments
   error(nargchk(1, 1, nargin));

   isiz = size(x);
   ldim = isiz > 1;
   if sum(ldim) > 1
      error('Input must be a vector.');
   end

   % make sure input is a column vector
   x = x(:);

   % now perform the run-length encoding
   i = [ find(x(1:end-1) ~= x(2:end)) ; length(x) ];
   len = diff([ 0 ; i ]);
   val = x(i);

   % make sure that the output is a vector in the same dimension as input
   osiz = isiz;
   osiz(ldim) = length(len);
   len = reshape(len, osiz);
   val = reshape(val, osiz);
