function j=findelem(fem_grid_struct,xorig,yorig,jorig)
%FINDELEM find element numbers for points in a FEM domain
%   FINDELEM finds the element number for the
%   current mouse position.  FINDELEM prompts
%   the user to click on the current axes and returns
%   the element for the "click-on" position, or NaN
%   if the click is outside the domain.
%
%   Alternatively, a list of horizontal points can
%   be passed in and a list of element numbers, one for
%   each input point, will be returned; NaN is returned
%   for each point outside of the FEM domain.
%
%   In determining which element has been selected,
%   FINDELEM needs elemental areas and shape functions.
%   The routines BELINT and EL_AREAS compute these arrays
%   and add them to a previously created fem_grid_struct.
%   These two functions MUST be run before FINDELEM will
%   run. GRD_TO_OPNML appends these fields to the fem_grid_struct
%   automatically.
%   	  BELINT is run as:
%   		 new_struct=belint(fem_grid_struct);
%   	  EL_AREAS is run as:
%   		 [new_struct,ineg]=el_areas(fem_grid_struct);
%
%   INPUT : fem_grid_struct - (from LOADGRID, see FEM_GRID_STRUCT)
%   	      xylist	       - points to find elements for [n x 2 double]
%           OR 
%           x - list of x-coordinates [n x 1 double]
%           y - list of y-coordinates [n x 1 double]
%
%   OUTPUT : an element number(s)
% 
%   CALL : >> j=findelem(fem_grid_struct)   for interactive
%     OR   >> j=findelem(fem_grid_struct,xylist)
%     OR   >> j=findelem(fem_grid_struct,x,y)        
%
%   Written by : Brian O. Blanton 
%   Summer 1997
%   Fall 2009 : added x,y 
%


j=[];
Debug=false;

% VERIFY INCOMING STRUCTURE
%
if ~is_valid_struct(fem_grid_struct)
   error('    fem_grid_struct to FINDELEM invalid.')
end

% Make sure additional needed fields of the fem_grid_struct
% have been filled.
if ~is_valid_struct2(fem_grid_struct)
   error('    fem_grid_struct to FINDELEM invalid.')
end

if nargin==2
   % xorig must be nX2
   if size(xorig,2) ~=2
      error('Number of columns in xylist must be 2.')
   end
   xp=xorig(:,1);
   yp=xorig(:,2);
   jsearch=[];
elseif nargin==4
   % assume 4th arg is jsearch.  

   if ~all(size(xorig) == size(yorig))
      error('Size of x,y must be the same.')
   end
   if ~all(size(xorig) == size(jorig))
      error('Size of x,y and jsearch must be the same.')
   end
   xp=xorig(:);
   yp=yorig(:);   
   jsearch=jorig(:);
elseif nargin==3   %  this is the tricky case
   if size(xorig,2)==2
      xp=xorig(:,1);
      yp=xorig(:,2);
      jsearch=jorig(:);
   elseif all(size(xorig)==size(yorig))
      xp=xorig(:);
      yp=yorig(:);
      jsearch=[];      
   else
      error('Case fall-through for nargin==3')
   end
   
else  % interactive
   disp('Click on element ...');
   waitforbuttonpress;
   Pt=gcp;
   xp=Pt(2);yp=Pt(4);
   line(xp,yp,'LineStyle','+')
   jsearch=[];
end

% default tolerance for basis function evaluation
DefaultTolerance=1.e-6;
if ~exist('tolerance')
   tolerance=DefaultTolerance;
end


% at this point, xp,yp,jsearch must all be 1-d vectors
if ~(size(xp,2)==1 & size(yp,2)==1 & size(xp,1)==size(yp,1)) 
   error('Incorrect dimensions on xp,yp.')
end
if ~isempty(jsearch)
   if ~(size(xp,2)==1 & size(jsearch,2)==1)
      error('Incorrect dimensions on xp,jsearch.')
   end   
end

ifind=find(isfinite(xp));

xtemp=xp(ifind);
ytemp=yp(ifind);

j=NaN*ones(size(xp));

if isempty(jsearch)
   if Debug, disp('Calling findelemex5...'),end
   jtemp=findelemex5(xtemp,ytemp,fem_grid_struct.ar,...
                     fem_grid_struct.A,...
                     fem_grid_struct.B,...
                     fem_grid_struct.T,...
                     tolerance);
else
   if Debug, disp('Calling findelemex52...'),end
   jtemp=findelemex52(xtemp,ytemp,fem_grid_struct.ar,...
                      fem_grid_struct.A,...
                      fem_grid_struct.B,...
                      fem_grid_struct.T,...
                      jsearch,...
                      tolerance);
end

j(ifind)=jtemp;
%reshape if needed
% if size(xorig,2)>1
%    if Debug, disp('Reshaping j ... '),end 
%    j=reshape(j,size(xorig));
% end
if nargin==4
   if Debug, disp('Reshaping j ... '),end 
   j=reshape(j,size(xorig));
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
%        Summer 1997
%

