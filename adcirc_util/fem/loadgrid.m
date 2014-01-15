function fem_grid_struct=loadgrid(gridname)
%LOADGRID load principle gridfiles for a given FEM domain
% LOADGRID loads grid files for a given FEM domain and returns
% a fem_grid_struct to the local workspace.  The returned
% structure contains atleast the minimum grid components
% for boundary plotting, contouring, etc.  Additionally,
% if land description files exist (.lnd, .lbe), the land
% description arrays are attached to the structure as well.
%
%  Input: gridname - name of domain to load grid files
%
% Output: LOADGRID returns a fem_grid_struct containing (atleast)
%         the following fields:
%         1)  .name   name of FEM domain
%         2)  .e      node connectivity array (cols 2-4 of .ele file )
%         3)  .x      x-horizontal node list  (col 2 of .nod file )
%         4)  .y      y-horizontal node list  (col 3 of .nod file )
%         5)  .z      bathymetry list	      (col 2 of .bat) file
%         6)  .bnd    boundary node/pair list (.bnd file )
%         7)  .nn     number of horizontal nodes
%         8)  .ne     number of horizontal elements
%
%   #7,8 are only for completeness.
%
% LOADGRID with no input gridname checks to see if the global
% variable DOMAIN has been set.  If so, LOADGRID uses this
% name to load files for.  If DOMAIN does NOT exist or is
% empty, the input gridname must be specified.
%
% If the boundary list (.bnd) exists locally, LOADGRID
% attempts to load the remaining files locally.  If the .bnd
% file does NOT exist locally, LOADGRID searches the
% GRIDS and GRIDDIRS global variables for the grid data.
%
% If any of the principle grids files does not exist, LOADGRID
% displays the appropriate message and exits, returning a
% partially filled fem_grid_struct WHICH IS INVALID.  The
% returned structure CANNOT be passed to any subsequent
% OPNML/MATLAB function expecting a valid fem_grid_struct.
% NOTE THIS EXCEPTION: the function GRIDINFO will take any
% fem_grid_struct and describe the field contents.
%
% EXAMPLE CALL:
% >> mcbo=loadgrid('mcbo')
%
% This returns a fem_grid_struct into the local workspace
% named "mcbo" which contains the following minimum fields:
%
%    mcbo =
%	 name: 'mcbo'
%	    e: [727x3 double]
%	    x: [444x1 double]
%	    y: [444x1 double]
%	    z: [444x1 double]
%	  bnd: [161x2 double]
%          nn: 444
%          ne: 727
%
% Written  by : Brian O. Blanton
% Summer 1997
%


% make sure this is atleast MATLAB version5.0.0
%
vers=version;
if vers(1)<5
   disp('??? Error using ==>> LOADGRID ');
   disp('This version of LOADGRID REQUIRES!! MATLAB version 5.0.0 or later.');
   disp('Sorry, but this is terminal.');
   return
end 
    
% DEFINE ERROR STRINGS
err1=str2mat('You must specify 1 output argument; call LOADGRID',...
      'as grid_struct=loadgrid(gridname)');
err2=['gridname not supplied and global DOMAIN is empty'];

global DOMAIN GRIDS GRIDDIRS

if nargout ~=1
   disp('??? Error using ==> loadgrid');
   disp(err1);
   return
end

if ~exist('gridname')
   if isempty(DOMAIN)
      error(err2); 
   else
      gridname=DOMAIN;
   end
else
   slashes=findstr(gridname,'/');
   if length(slashes)==0
      fpath=[];
   else
      lastslash=slashes(length(slashes));
      fpath=gridname(1:lastslash);
      gridname=gridname(lastslash+1:length(gridname));
   end
   DOMAIN=gridname;
end

% Is there a dot in the gridname?
%
dots=findstr(gridname,'.');
if length(dots)~=0
   lastdot=dots(length(dots));
   dotname=gridname(1:lastdot-1);
end      
   
% check current working directory or fpath/cwd for principle gridfiles
%
if isempty(fpath)
   disp('Searching locally ...');
else
   disp([ 'Searching ' fpath]);
end

bndname=[deblank(gridname) '.bnd'];
nodname=[deblank(gridname) '.nod'];
elename=[deblank(gridname) '.ele'];
batname=[deblank(gridname) '.bat'];

if isempty(fpath)
   fpath='./';
end

gsum=0;
if exist([fpath bndname])==2 
   loadfn=['load ' fpath bndname];
   eval(loadfn);
   if ~isempty(dots)
      bnd=eval(dotname);
   else
      bnd=eval(gridname);
   end
   bndfound=1;
   gsum=gsum+1;
   disp(['Got ' bndname])
else
   bndfound=0;
   bnd=[];
end

if exist([fpath nodname])==2
   loadfn=['load ' fpath nodname];
   eval(loadfn);
   if ~isempty(dots)
      nodes=eval(dotname);
   else
      nodes=eval(gridname);
   end
   x=nodes(:,2);
   y=nodes(:,3);
   nodfound=1;
   gsum=gsum+1;
   disp(['Got ' nodname])
else   
   nodfound=0;
   x=[];
   y=[];
end
   
if exist([fpath elename])==2
   loadfn=['load ' fpath elename];
   eval(loadfn);
   if ~isempty(dots)
      ele=eval(dotname);
   else
      ele=eval(gridname);
   end
   ele=ele(:,2:4);
   elefound=1;
   gsum=gsum+1;
   disp(['Got ' elename])
else
   elefound=0;
   ele=[];
end

if exist([fpath batname])==2
   loadfn=['load ' fpath batname];
   eval(loadfn);
   if ~isempty(dots)
      z=eval(dotname);
   else
      z=eval(gridname);
   end
   z=z(:,2);
   batfound=1;
   gsum=gsum+1;
   disp(['Got ' batname])
else
   batfound=0;
   z=[];
end

% If all gridfiles found locally, return
if gsum==4
   lnod=length(x);
   lbat=length(z);
   maxe=max(max(ele));
   if lnod~=lbat,disp(['WARNING!! Lengths of node list and depth list'...
   ' are NOT equal']),end
   if lnod~=maxe,disp(['WARNING!! Max node number in element list does NOT'...
   ' equal length of node list']),end
   % Load up return structure
   fem_grid_struct.name=gridname;
   fem_grid_struct.e=ele;
   fem_grid_struct.x=x;
   fem_grid_struct.y=y;
   fem_grid_struct.z=z;
   fem_grid_struct.bnd=bnd;
   fem_grid_struct.nn=length(x);
   fem_grid_struct.ne=length(ele);
   %
   % Attach areas
   fem_grid_struct=el_areas(fem_grid_struct);
   fem_grid_struct=belint(fem_grid_struct);
   fem_grid_struct.bwidth=bwidth(fem_grid_struct.e);
   
   % Check for land description files locally.
   lndname=[deblank(gridname) '.lnd'];
   lbename=[deblank(gridname) '.lbe'];
   if exist([fpath lndname])==2 & exist([fpath lbename])==2
      loadfn=['load ' fpath lndname];
      eval(loadfn);
      if ~isempty(dots)
         lnd=eval(dotname);
      else
         lnd=eval(gridname);
      end
      disp(['Got ' lndname])
      loadfn=['load ' fpath lbename];
      eval(loadfn);
      if ~isempty(dots)
         lbe=eval(dotname);
      else
         lbe=eval(gridname);
      end
      disp(['Got ' lbename])
      fem_grid_struct.lbe=lbe;
      fem_grid_struct.lnd=lnd(:,2:3);
   else
      disp('No land description files found locally')
   end   

   elqname=[deblank(gridname) '.elq'];
   if exist([fpath elqname])==2
      loadfn=['load ' fpath elqname];
      eval(loadfn);
      disp(['Got ' elqname])
      if ~isempty(dots)
         elq=eval(dotname);
      else
         elq=eval(gridname);
      end
      elq(:,1)=[];
      fem_grid_struct.elq=elq;
   end

   ehashname=[deblank(gridname) '.ehash.mat'];
   if exist([fpath ehashname])==2
      com=sprintf('load(''%s/%s'')',fpath,ehashname);
      eval(com); 
      fem_grid_struct.ehash=ehash;
      disp(['Got ' ehashname])
   end

   fem_grid_struct.dir=pwd;
   return
elseif bndfound==0&elefound==1&gsum==3
   disp(['   ' bndname ' not found; computing from ' elename '.'])
   bnd=detbndy(ele);
   % Load up return structure
   fem_grid_struct.name=gridname;
   fem_grid_struct.e=ele;
   fem_grid_struct.x=x;
   fem_grid_struct.y=y;
   fem_grid_struct.z=z;
   fem_grid_struct.bnd=bnd;
   fem_grid_struct.nn=length(x);
   fem_grid_struct.ne=length(ele);
   %
   % Check for land description files locally.
   lndname=[deblank(gridname) '.lnd'];
   lbename=[deblank(gridname) '.lbe'];
   if exist([fpath lndname])==2 & exist([fpath lbename])==2
      loadfn=['load ' fpath lndname];
      eval(loadfn);
      if ~isempty(dots)
         lnd=eval(dotname);
      else
         lnd=eval(gridname);
      end
      disp(['Got ' lndname])
      loadfn=['load ' fpath lbename];
      eval(loadfn);
      if ~isempty(dots)
         lbe=eval(dotname);
      else
         lbe=eval(gridname);
      end
      disp(['Got ' lbename])
      fem_grid_struct.lbe=lbe;
      fem_grid_struct.lnd=lnd(:,2:3);
   else
      disp('No land description files found locally')
   end   

   elqname=[deblank(gridname) '.elq'];
   if exist([fpath elqname])==2
      loadfn=['load ' fpath elqname];
      eval(loadfn);
      disp(['Got ' elqname])
      if ~isempty(dots)
         elq=eval(dotname);
      else
         elq=eval(gridname);
      end
      elq(:,1)=[];
      fem_grid_struct.elq=elq;
   end
   
   ehashname=[deblank(gridname) '.ehash.mat'];
   if exist([fpath ehashname])==2
      com=sprintf('load(''%s/%s'')',fpath,ehashname);
      eval(com);
      fem_grid_struct.ehash=ehash;
      disp(['Got ' ehashname])
   end

   % Attach areas
   fem_grid_struct=el_areas(fem_grid_struct);
   fem_grid_struct=belint(fem_grid_struct);
   fem_grid_struct.bwidth=bwidth(fem_grid_struct.e);
   
   temp1=[fpath '/' gridname '.i5.nodes'];
   if exist(temp1)==2
      i5=load(temp1);
      fem_grid_struct.i5=i5;
   end
   temp2=[fpath '/' gridname(1:end-2) '.i5.nodes'];
   if exist(temp2)==2
      i5=load(temp2);
      fem_grid_struct.i5=i5;
   end
   fem_grid_struct.dir=fpath;
   return

elseif gsum~=0
   disp(' ')
   disp('   NOT ALL FILES FOUND LOCALLY.')
   if ~nodfound,disp(['   ' nodname ' not found locally.']),end
   if ~elefound,disp(['   ' elename ' not found locally.']),end
   if ~batfound,disp(['   ' batname ' not found locally.']),end
   str=str2mat(' ','   This is a problem.  The files ',...
               ['   ' nodname ' ' elename ' & ' batname],...
               '   must all exist locally or all in one of',...
               '   the following directories (as set in ',...
               '   the global GRIDDIRS):',...
               GRIDDIRS,...
               ' ');
   disp(str);
%   DOMAIN=[];
   return
end

if isempty(fpath)
   disp(['Gridfiles not found in ' pwd])
else
   disp(['Gridfiles not found in ' fpath])
end

if isempty(GRIDDIRS)
   disp('No places in GRIDDIRS to search.');
   return
else
   disp('Searching GRIDS for gridname match.');
end

% Check GRIDS list for gridname
%
if ~isempty(GRIDS)
   igrid=0;
   [m,n]=size(GRIDS);
   for i=1:m
      if strcmp(deblank(GRIDS(i,:)),gridname)==1
         igrid=i;
      end
   end
end
if ~igrid
   disp([gridname ' not in GRIDS list']);
   DOMAIN=[];
   return
end
disp('Got it.') 
disp(['Checking ' GRIDDIRS(igrid,:)])

% gridname found in GRIDS.  Now, check GRIDDIRS for gridfiles
%
fpath=deblank(GRIDDIRS(igrid,:));  
      
bn=[fpath '/' gridname '.bnd'];
nn=[fpath '/' gridname '.nod'];
en=[fpath '/' gridname '.ele'];
zn=[fpath '/' gridname '.bat'];

if ~exist(nn)
    disp([nn ' does not exist.']);
   return
end
disp(['Got ' nodname])
loadfn=['load ' nn];
eval(loadfn);
if ~isempty(dots)
   nodes=eval(dotname);
else
   nodes=eval(gridname);
end
x=nodes(:,2);
y=nodes(:,3);

if ~exist(en)
   disp([en ' does not exist.']);
   return
end
disp(['Got ' elename])
loadfn=['load ' en];
eval(loadfn);
if ~isempty(dots)
   ele=eval(dotname);
else
   ele=eval(gridname);
end
ele=ele(:,2:4);

if ~exist(zn)
   disp([zn ' does not exist.']);
   return
end
disp(['Got ' batname])
loadfn=['load ' zn];
eval(loadfn);
if ~isempty(dots)
   z=eval(dotname);
else
   z=eval(gridname);
end
z=z(:,2);

if exist(bn)
   disp(['Got ' bndname])
   loadfn=['load ' bn];
   eval(loadfn);
   if ~isempty(dots)
      bnd=eval(dotname);
   else
      bnd=eval(gridname);
   end
else
   disp([bn ' does not exist.  Computing from ' elename]);
   bnd=detbndy(ele);
end

% Load up return structure
fem_grid_struct.name=gridname;
fem_grid_struct.dir=fpath;
fem_grid_struct.e=ele;
fem_grid_struct.x=x;
fem_grid_struct.y=y;
fem_grid_struct.z=z;
fem_grid_struct.bnd=bnd;
fem_grid_struct.nn=length(x);
fem_grid_struct.ne=length(ele);

%
% Attach areas, grid parameter arrays
fem_grid_struct=el_areas(fem_grid_struct);
fem_grid_struct=belint(fem_grid_struct);
fem_grid_struct.bwidth=bwidth(fem_grid_struct.e);

% Check for land description files locally.
lndname=[fpath '/' gridname '.lnd'];
lbename=[fpath '/' gridname '.lbe'];

if exist(lndname)==2 & exist(lbename)==2
   loadfn=['load ' lndname];
   eval(loadfn);
   if ~isempty(dots)
      lnd=eval(dotname);
   else
      lnd=eval(gridname);
   end
   disp(['Got ' lndname])
   loadfn=['load ' lbename];
   eval(loadfn);
   if ~isempty(dots)
      lbe=eval(dotname);
   else
      lbe=eval(gridname);
   end
   disp(['Got ' lbename])
   fem_grid_struct.lbe=lbe;
   fem_grid_struct.lnd=lnd(:,2:3);
else
   disp('No land description files found.')
end   

temp1=[fpath '/' gridname '.i5.nodes'];
if exist(temp1)==2
   i5=load(temp1);
   fem_grid_struct.i5=i5;
end
temp2=[fpath '/' gridname(1:end-2) '.i5.nodes'];
if exist(temp2)==2
   i5=load(temp2);
   fem_grid_struct.i5=i5;
end
fem_grid_struct.dir=fpath;

return;
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
%        Summer 1997
%

