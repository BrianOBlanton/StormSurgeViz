function chandle=isophase(fem_grid_struct,Q,cval,varargin)                                           
%ISOPHASE contour a vector of scalar (phase) values on a FEM grid.
%   ISOPHASE accepts a vector of values to be contoured 
%   over the provided mesh. 
%
% Input:    fem_grid_struct (from LOADGRID, see FEM_GRID_STRUCT)
%           Q - scalar (phase in DEGREES) to be contoured; must be 1-D
%           cval - vector of values to contour
%
%           Additionally, all line objecy property/value pairs are 
%           passed to line.
%
% Output:  isophase returns the handle to the contour line drawn
%
% Call as: h=isophase(fem_grid_struct,Q,cval,p1,v1,p2,v2,...);
%
% To use the obsolete calling sequence, call isophase4.
%
% Written by : Brian O. Blanton
%     24 Oct 2002: Converted to fem_grid_struct input and varargin
%     18 Feb 2010: Fixed bug in contouring "0"  phase
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


% DEFINE ERROR STRINGS
err1=['matrix of elements must be either 3 or 4 columns wide' ];
err2=['node coordinate vectors must be the same length'];
err3=['length of scalar must be the same length as coordinate vectors'];
err4=['scalar to be contoured must be 1-D'];
err5=['insufficient number of parameters or values'];

% check number of arguments
N=nargin;
msg=nargchk(1,21,N);
if ~isempty(msg)
   disp(msg);
   disp('Routine: isophase');
   return
end


[nrowQ,ncolQ]=size(Q);
if nrowQ~=1 & ncolQ~=1 ,error(err4),end

% columnate Q
Q=Q(:);
[nrowQ,ncolQ]=size(Q);

if nrowQ ~= length(x)
   error(err3);
end   

% determine number of pv pairs input
npv = N-5;
if rem(npv,2)==1,error(err5);,end
 
 
% range of scalar quantity to be contoured; columnate cval
Qmax=max(Q);
Qmin=min(Q);
cval=cval(:);
 
for kk=1:length(cval)
  
% Call cmex function isopmex5

    C=isopmex5(x,y,e,Q,cval(kk));

    if ~isempty(C)
        chandle(kk)=line(C(:,1),C(:,2),varargin{:});
        set(chandle(kk),'UserData',cval(kk));
        set(chandle(kk),'Tag','contour');
        drawnow
    else
        disp([num2str(cval(kk)) ' not found.']);
        chandle(kk)=0;
    end 
end 

return
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
%        
%        Fall 2002

   





 
