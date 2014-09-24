function NEI=read_nei(fname);
%READ_NEI read a FEM neighbor file of .nei filetype.
%
% struct=read_nei(fname);
%
%   Input :   If fname is omitted, READ_NEI enables a file browser
%             with which the user can specify the .NEI file.
%
%             Otherwise, fname is the name of the .nei file, relative 
%             or absolute (fullpath), including the suffix .'nei'.
%             This input is a string so it must be enclosed in
%             single quotes. 
%
%  Output :   Five (5) arrays are returned in fields to the local workspace:
%             1) x - x-coordinates of the grid
%             2) y - y-coordinates of the grid
%             3) bc - boundary codes for each horizontal node
%             4) z - bathymetry of the grid
%             5) nbs - neighbor list of grid's nodes
%
% Call as: R=read_nei(fname);
%
% Written by Brian Blanton 
%

if nargin==0&nargout==0
   disp('Call as: NEI=read_nei(fname);')
   return
end

   
if ~exist('fname')
   [fname,fpath]=uigetfile('*.nei','Which .nei');
   if fname==0,return,end
else
   fpath=[];
end

x=[];y=[];ic=[];z=[];nbs=[];
if nargin > 1
   error(['READ_NEI requires 0 or 1 input argument; type "help READ_NEI"']);
elseif nargout ~=1
   error(['READ_NEI requires 1 output argument; type "help READ_NEI"']);
end

% get filetype from tail of fname
ftype=fname(length(fname)-2:length(fname));

% make sure this is an allowed filetype
if ~strcmp(ftype,'nei')
   error(['READ_NEI cannot read ' ftype ' filetype'])
end

% open fname
[pfid,message]=fopen([fpath fname]);
if pfid==-1
   disp([fpath fname,' not found. ',message]);
   return
end

NEI.nn=fscanf(pfid,'%d',1);
NEI.nnb=fscanf(pfid,'%d',1);
maxmin=fscanf(pfid,'%f %f %f %f',4);
NEI.xmin=maxmin(1);
NEI.xmax=maxmin(2);
NEI.ymin=maxmin(3);
NEI.ymax=maxmin(4);

fmt1='%d %f %f %d %f ';
fmt2='%d ';
for i=2:NEI.nnb
   fmt2=[fmt2 '%d '];
end
fmtstr=[fmt1 fmt2];
nread=NEI.nnb+5;
data=fscanf(pfid,eval('fmtstr'),[nread NEI.nn])';
NEI.x=data(:,2);
NEI.y=data(:,3);
NEI.ic=data(:,4);
NEI.z=data(:,5);
NEI.nei=data(:,6:nread);

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

