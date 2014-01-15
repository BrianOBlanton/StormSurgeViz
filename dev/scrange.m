function scrange(data)
%SCRANGE return the min and max of the input array
% SCRANGE(x) returns the min and max of the input array.
% If x is a vector, SCRANGE returns the minimum and
% maximum values. 
% If x is a matrix, SCRANGE returns the minimum and
% maximum values of each column.  
%
% SCRANGE is most useful in determining the range of vector 
% data to be passed to LCONTOUR2.
%
% Example: >> x = 1:10;
%          >> scrange(x)
%             min = 1
%             max = 10

[m,n]=size(data);

if m==1 | n==1 
   data=data(:);
%    disp(' ')
    disp(['min = ' num2str(min(data),16)]);
    disp(['max = ' num2str(max(data),16)]);
%    disp(' ')
%   disp(' ')
%   disp('min = ');
%   min(data)
%   disp('max = ');
%   max(data)
%   disp(' ')
else
   minimum=min(data)
   maximum=max(data)
end

%
%        Brian O. Blanton
%        Department of Marine Sciences
%        12-7 Venable Hall
%        CB# 3300
%        University of North Carolina
%        Chapel Hill, NC
%                 27599-3300
%
%        brian_blanton@unc.edu
