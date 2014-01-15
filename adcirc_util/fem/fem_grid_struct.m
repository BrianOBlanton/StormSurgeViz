function fem_grid_struct
%FEM_GRID_STRUCT Finite element method (FEM) grid description structure
% FEM_GRID_STRUCT is a structure containing the components
% that make up a finite element grid as well as several derived fields.  
% The structure contains the following MINIMUM set of fields.  
% FEM_GRID_STRUCT is NOT a function.  This is just the description file 
% for the structure.
%
%    .name - the domain name of the FEM grid
%    .e    - node connectivity list (linear, triangular) [ne x 3 double]
%    .x    - x-horizontal node coordinates		 [nn x 1 double]
%    .y    - y-horizontal node coordinates		 [nn x 1 double]
%    .z    - bathymetry list				 [nn x 1 double]
%    .bnd  - boundary segment list			 [nb x 2 double]
%  
% The above set of fields is considered minimum from an ADCIRC/MATLAB
% post-processing standpoint.  
% 
% The .bnd file need not exist on disk. The ADCIRC/MATLAB function
% GRD_TO_OPNML can build the .bnd array if it is not located with
% the other grid files.  Note that the .bnd field is not used by the
% ADCIRC model itself, but is required by ADCIRC/MATLAB to speed up
% the plotting of large domains.
%
% If land description files are located by GRD_TO_OPNML, then the 
% land description arrays will be attached to the structure as
% the .lnd and .lbe fields.  These fields are used by the function
% LNDFILL to mask out the exterior of the FEM domain when using the 
% FDCONT contour/vector plotting tools. See FDCONT and LNDMAKE for 
% details.
%
% All ADCIRC/MATLAB functions that take a fem_grid_struct as an input argument
% will REQUIRE atleast these fields to be filled.  Some functions
% will use more fields. 
% 
% The function LOADGRID returns a structure containing the above 
% minimum fields.  Other functions may add fields, and even modify the 
% minimum field contents, and the user is free to add fields as long as 
% the user-added field names do not conflict with existing or reserved 
% field names.  The only currently reserved field names are as above.
%

%
%LabSig  Brian O. Blanton
%        Renaissance Computing Institute
%        University of North Carolina
%        Chapel Hill, NC
%
%        brian_blanton@renci.org
%
%        Summer 1997, Rev Spring 2010
%

