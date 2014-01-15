function [UA,UG,VA,VG,FREQ,PERNAMES]=read_adcirc_fort54(fname,flag,gname)
%READ_ADCIRC_FORT54 read ADCIRC velocity output file
% This routine reads in the contents of an ADCIRC elevation file,
% as typically output from an harmonic analysis output to a fort.54
% file.  fort.54 is the default output file for the global harmonic
% analysis of the velocity field.  
%
%  Input : fname - filename to read velocity from.  If empty,
%                  routine reads from fort.54.  Analysis from
%                  specified stations (fort.52) can be read in
%                  by providing fname='fort.52'.
%          flag  - if flag==1, the contents of the velocity file 
%                  are output to disk in .v2c file format, one file
%                  per period. 
%          gname - if flag==1, then gname provides the grid name
%                  for the .v2c file output format.
% Output : UA       -  matrix of u-vel amplitudes [uamp1 uamp2 ... ]
%          UP       -  matrix of u-vel phases [upha1 upha2 ... ]
%          VA       -  matrix of v-vel amplitudes [vamp1 vamp2 ... ]
%          VP       -  matrix of v-vel phases [vpha1 vpha2 ... ]
%          FREQ     -  vector of component frequencies
%          PERNAMES -  string vector of component names
%   
%          If nargout==1, the output fields are packaged into a 
%          structure with the above fields (e.g., D.UA, ...)
%
% Call as: [UA,UP,VA,VP,FREQ,PERNAMES]=read_adcirc_fort54(fname,flag,gname);
%      or: D=read_adcirc_fort54(fname,flag,gname);
% 
% Written by: Brian Blanton, Spring '99


if nargin==0 & nargout==0
  disp('[UA,UP,VA,VP,FREQ,PERNAMES]=read_adcirc_fort54(fname,flag,gname);')
  disp('D=read_adcirc_fort54(fname,flag,gname);')
  return
elseif nargout~=6 & nargout~=1
   error('READ_ADCIRC_FORT54 must have 1|6 output arguments');
elseif nargin==0
    fname='fort.54';
    flag=0;
elseif nargin==1
   % See if fname is string
   if ~isstr(fname)
      fname='fort.54';
      if flag~=0 | flag~=1
         error('FLAG to READ_ADCIRC_FORT54 must be 0|1')
      end
   else
      % Try to open fname
      [fid,message]=fopen(fname,'r');
      if fid==-1
         error(['Could not open ' fname ' because ' message])
      end
      fclose(fid);
      flag=0;
      gname='';
   end
elseif nargin==2
   error('READ_ADCIRC_FORT54 must have 1|3 input arguments')
elseif nargin==3
   if ~isstr(fname)
      error('First argument to READ_ADCIRC_FORT54 must be a string')
   elseif ~isstr(gname)
      error('Third argument to READ_ADCIRC_FORT54 must be a string')
   else
      if isempty(fname),fname='fort.54';,end
      if flag~=0 & flag~=1
         error('FLAG to READ_ADCIRC_FORT54 must be 0|1')
      end
   end
end

% Determine if there is a path on the fname, that may have been 
% passed in.
[fpath,fname,ext] = fileparts(fname);

if isempty(fpath)
   fid=fopen([fname ext],'r');
else
   fid=fopen([fpath '/' fname ext],'r');
end

ncomp=fscanf(fid,'%d',1);

for i=1:ncomp
   temp=fscanf(fid,'%f %f %f',[1 3]);
   FREQ(i)=temp(1);
   PERNAMES{i}=fscanf(fid,'%s',[1]);
end

nnodes=fscanf(fid,'%d',1);

UA=NaN*ones(nnodes,ncomp);
UG=NaN*ones(nnodes,ncomp);
VA=NaN*ones(nnodes,ncomp);
VG=NaN*ones(nnodes,ncomp);

for i=1:nnodes
   n=fscanf(fid,'%d',1);
   for j=1:ncomp
      temp=fscanf(fid,'%f %f %f %f',[1 4]);
      UA(n,j)=temp(1);
      UG(n,j)=temp(2);
      VA(n,j)=temp(3);
      VG(n,j)=temp(4);
   end
end

% if flag==1,output comstituents into .v2c files
if flag
   disp('Writing individual components to disk...')
   for i=1:ncomp
      if isempty(fpath)
         fname=[PERNAMES{i} '.v2c'];
      else
         fname=[fpath '/' PERNAMES{i} '.v2c'];    
      end
      disp(['   Writing ' fname '...'])
      comment=[PERNAMES{i} ' HA RESULTS'];
      D=[UA(:,i) UG(:,i) VA(:,i) VG(:,i)];
      err=write_v2c(D,FREQ(i),gname,fname,comment);
   end
end   

if nargout==1
   UA.UA=UA;
   UA.UP=UG;
   UA.VA=VA;
   UA.VP=VG;
   UA.FREQ=FREQ;
   UA.PERNAMES=PERNAMES;
   clear UG VA VG FREQ PERNAMES
end


