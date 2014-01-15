function [A,G,FREQ,PERNAMES]=read_adcirc_fort53(varargin)
%READ_ADCIRC_FORT53 read ADCIRC elevation output file
% This routine reads in the contents of an ADCIRC elevation file,
% as typically output from an harmonic analysis output to a fort.53
% file.  fort.53 is the default output file for the global harmonic
% analysis of the elevation field.  
%
%  Input : fname - filename to read elevation from.  If empty,
%                  routine reads from fort.53.  Analysis from
%                  specified stations (fort.51) can be read in
%                  by providing fname='fort.51'.
%          flag  - if flag==1, the contents of the elevation file 
%                  are output to disk in .s2c file format, one file
%                  per period. 
%          gname - if flag==1, then gname provides the grid name
%                  for the .s2c file output format.
% Output : AMP      -  matrix of amplitudes = [amp1 amp2 ...];
%          PHA      -  matrix of phases = [pha1 pha2 ...];
%          FREQ     -  vector of component frequencies
%          PERNAMES -  string vector of component names
%
%          If nargout==1, the output is packaged into a structure 
%          with the above fields (e.g., D.AMP, ...)
%
% Call as: [AMP,PHA,FREQ,PERNAMES]=read_adcirc_fort53(fname,flag,gname);
%      or: D=read_adcirc_fort53(fname,flag,gname);
% 
% Written by: Brian Blanton, Spring '99

A=[];
G=[];
FREQ=[];
PERNAMES=[];
skipdataread=0;


% Default propertyname values
fname='fort.53';
constits=-1;  % default is all
flag=0;
gname='';


if nargin==0 & nargout==0
   disp('[AMP,PHA,FREQ,PERNAMES]=read_adcirc_fort53(fname,flag,gname);')
   return
end

% elseif nargin>4
%    error('READ_ADCIRC_FORT53 must have 1|2|4 input arguments')
% elseif nargout~=4 & nargout~=1
%    error('READ_ADCIRC_FORT53 must have 1|4 output arguments')
% end
% elseif nargin==2
%    error('READ_ADCIRC_FORT53 must have 1|3 input arguments')
   
   
% Strip off propertyname/value pairs in varargin not related to
% "line" object properties.
k=1;
while k<length(varargin),
  switch lower(varargin{k}),
    case 'filename',
      fname=varargin{k+1};
      varargin([k k+1])=[];
    case 'constits',
      constits=varargin{k+1};
      varargin([k k+1])=[];
    case 'flag',
      flag=varargin{k+1};
      varargin([k k+1])=[];
    case 'gname',
      gname=varargin{k+1};
      varargin([k k+1])=[];
    case 'skipdataread',
      skipdataread=varargin{k+1};
      varargin([k k+1])=[];
    otherwise
      k=k+2;
  end;
end;

if length(varargin)<2
   varargin={};
end


% See if fname is string
if ~isstr(fname)
    fname='fort.53';
    if flag~=0 || flag~=1
        error('FLAG to READ_ADCIRC_FORT53 must be 0|1')
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
   
% elseif nargin==3
%    if ~isstr(fname)
%       error('First argument to READ_ADCIRC_FORT53 must be a string')
%    elseif ~isstr(gname)
%       error('Third argument to READ_ADCIRC_FORT53 must be a string')
%    else
%       if isempty(fname),fname='fort.53';,end
%       if flag~=0 & flag~=1
%          error('FLAG to READ_ADCIRC_FORT53 must be 0|1')
%       end
%    end
% end
% 
% Determine if there is a path on the fname, that may have been 
% passed in.
[fpath,fname,ext] = fileparts(fname);

if isempty(fpath)
   filename=[fname ext];
   fid=fopen([fname ext],'r');
else
   fid=fopen([fpath '/' fname ext],'r');
end
NcompsInFile=fscanf(fid,'%d',1);

for i=1:NcompsInFile
   temp=fscanf(fid,'%f %f %f',[1 3]);
   FREQ(i)=temp(1);
   PERNAMES{i}=fscanf(fid,'%s',[1]);
end

nnodes=fscanf(fid,'%d',1);

ncomps=NcompsInFile;
if iscell(constits)
    % find matches in PERNAMES
    %if any(~isstr(constits))
    %    error('Constits must be a cell array of strings')
    %end
    idx=NaN*ones(length(constits),1);
    for i=1:length(constits)
        temp=strmatch(constits(i),PERNAMES);
        if ~isempty(temp)
            idx(i)=temp;
        end
    end
elseif constits(1)==-1
       idx=1:length(FREQ);
else
      if max(constits)>NcompsInFile
         error('Largest constit number in constits larger that number of constituents in file.')
      end
      idx=intersect(1:length(FREQ),constits);
end
ConstitsToExtract=idx;
 
ncomps=length(ConstitsToExtract);

A=NaN*ones(nnodes,ncomps);
G=NaN*ones(nnodes,ncomps);

% for i=1:nnodes
%    n=fscanf(fid,'%d',1);
%    for j=1:ncomp
%       temp=fscanf(fid,'%e %f',[1 2]);
%       a(i,j)=temp(1);
%       g(i,j)=temp(2);
%    end
% end

if ~skipdataread

    disp('Scanning nodes ... ')
    for i=1:nnodes
        if (mod(i,10000)==1),disp(int2str(i)),end
        n=fscanf(fid,'%d',1);
        temp=fscanf(fid,'%e %f',[2 NcompsInFile])';
        A(i,:)=temp(idx,1);
        G(i,:)=temp(idx,2);
    end
    
    % if flag==1,output constituents into .s2c files
    if flag
        disp('Writing individual components to disk...')
        for i=1:ncomp
            if isempty(fpath)
                fname=[PERNAMES{i} '.s2c'];
            else
                fname=[fpath '/' PERNAMES{i} '.s2c'];
            end
            disp(['   Writing ' fname '...'])
            comment=[PERNAMES{i} ' HA RESULTS'];
            D=[A(:,i) G(:,i)];
            err=write_s2c(D,FREQ(i),gname,fname,comment);
        end
    end
    
    inan=A<1e-6;
    A(inan)=NaN;
    G(inan)=NaN;

end

clear temp
if nargout==1
   temp.AMP=A;
   temp.PHA=G;
   temp.FREQ=FREQ(ConstitsToExtract);
   temp.PERNAMES=PERNAMES(ConstitsToExtract);
   clear PERNAMES G FREQ A
   A=temp;
end


