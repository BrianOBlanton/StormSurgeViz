function outstr=blank(instr)
%BLANK strip leading and trailing whitespace and/or NULL characters
% BLANK strips leading and trailing whitespace and/or NULL characters
%       from input string instr.  The MATLAB function DEBLANK only
%       removes trailing blanks and NULLS.
%
% outstr=blank(instr)
%

[m,n]=size(instr);
if m>1
   error('input string must be a vector');
end

% REMOVE LEADING BLANKS
%
[m,n]=size(instr);
count=0;
for i=1:n
   if strcmp(instr(i),' ')==1
      instr=instr(i+1:n-count);
      count=count+1;
   else
      break;
   end
   
end

% REMOVE TRAILING BLANKS WITH MATLAB DEBLANK FUNCTION
%
outstr=deblank(instr);
%instr=outstr;
%[m,n]=size(instr);
%for i=n:-1:1
%   if strcmp(instr(i),' ')==1
%      outstr=instr(1:n-1);
%   else
%      break;
%   end
%end

