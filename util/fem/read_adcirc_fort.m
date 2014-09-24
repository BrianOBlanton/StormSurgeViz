function D=read_adcirc_fort(varargin)
%READ_ADCIRC_FORT read ADCIRC fort.XX output file
% READ_ADCIRC_FORT reads in the contents of a fort.XX ADCIRC output 
% file.  Units handled are 14,61,62,63,64,71,72,73,74,
% Details of the output files are described in the ADCIRC Users 
% Manual.  Time is converted from ADCIRC time to Gregorian time,
% if the ADCIRC Cold Start Date is provided. 
%
%  Input : All input arguments are provided in Parameter/Value
%          pairs:
%          FileName  - filename from which to read ADCIRC output.  
%                      Default='fort.63'
%          FortUnit  - unit number to read FileName as, input as a
%                      string. Overrides any unit number suffix in 
%                      FileName, by being APPENDED TO the filename 
%                      specified in FileName. Default = [];
%          AdcCSD    - ADCIRC Cold Start Date, needed for conversion of 
%                      ADCIRC time to Gregorian time.  If empty,
%                      no conversion is made.  AdcCSD must be passed inpwd
%                      as a 1x6-element vector, [yyyy,mm,dd,hr,mn,sec],
%                      or as a DATENUM Gregorian date. Default=[];
%          Compact   - Expect (or not) compact ADCIRC file format (0|1)
%          HeaderOnly - return after reading header information   
%          IterStart - time step in fort file to start recording 
%          IterEnd   - time step in fort file to stop recording
%          Level     - sigma-level to extract from a 3-d file
%          Stride    - number of step between saving output
%          Strip     - number of steps to skip at beginning of file
%          Verbose   - Verbose (or not) diagnostic output (0|1)
%
% Output : The details of the output struct depend on the unit number. 
%          The return structure for a fort.61 or fort.63 file is :
%
%          D.data  - matrix of data, one node per row
%          D.t     - vector of times
%          D.nodes - number of nodes
%          D.dt    - output interval in fort.XX file
%
% Call as: D=read_adcirc_fort('FileName',<filename>,...
%                             'FortUnit',<fortunit>,...);
% 
% Written by: Brian Blanton, Fall '05
% Added IterStart,IterEnd  Fall '09



if nargin==0 & nargout==0
  disp('Call as: D=read_adcirc_fort(''FileName'',<filename>,''FortUnit'',<fortunit>,''AdcCSD'',  [yyyy mm dd hr mn sec])');
  return
end

% Set defaults
AdcCSD=[];
Compact=[];
FileName='maxele.63';
FortUnit=[];
HeaderOnly=0;
IterStart=1;
IterEnd=NaN;
Level=-1;
Stride=1;
Strip=0;
Verbose=0;

% if nargin==1, assume it's the filename, else assume pv pairs

if nargin==1
    FileName=varargin{1};
    if isempty(FileName)
       [FileName, PathName] = uigetfile('*.*', ...
        'Pick a file'); 
    end
else

    % Strip off propertyname/value pairs in varargin not related to
    % "line" object properties.
    k=1;
    while k<length(varargin),
      switch lower(varargin{k}),
        case 'compact',
          Compact=varargin{k+1};
          varargin([k k+1])=[];
          if ~(Compact == 0 | Compact==1)
             error(sprintf('Compact parameter must be integer 0 or 1'))
          end
        case 'level',
          Level=varargin{k+1};
          varargin([k k+1])=[];
        case 'stride',
          Stride=varargin{k+1};
          varargin([k k+1])=[];
        case 'headeronly',
          HeaderOnly=varargin{k+1};
          varargin([k k+1])=[];
        case 'iterstart',
          IterStart=varargin{k+1};
          varargin([k k+1])=[];
        case 'iterend',
          IterEnd=varargin{k+1};
          varargin([k k+1])=[];
        case 'strip',
          Strip=varargin{k+1};
          varargin([k k+1])=[];
        case 'verbose',
          Verbose=varargin{k+1};
          varargin([k k+1])=[];
        case 'filename',
          FileName=varargin{k+1};
          if ~isstr(FileName)
             error(sprintf('FileName to READ_ADCIRC_FORT must be a string. Terminal.'))
          end
          varargin([k k+1])=[];
        case 'fortunit',
          FortUnit=varargin{k+1};
          if ~isstr(FortUnit)
             error(sprintf('FortUnit to READ_ADCIRC_FORT must be a string. Terminal.'))
          end
          varargin([k k+1])=[];
        case 'adccsd',
          AdcCSD=varargin{k+1};
          if ~isnumeric(AdcCSD)
             error('AdcCSD to READ_ADCIRC_FORT must be numeric. Terminal.')
          elseif length(AdcCSD) ~=6 & length(AdcCSD)~=1
             error('AdcCSD must be a 1x6 vector or a datenum number. Terminal.') 
          end
          varargin([k k+1])=[];
        otherwise
          k=k+2;
      end
    end

    if ~isempty(varargin)
       disp(sprintf('Unused varargins.  Terminal.'));
       for i=1:length(varargin)/2
          j=(i-1)*2+1;
          disp(sprintf('%s : %d',varargin{j},varargin{j+1}))
       end
       D=[];
       return
    end

end

supported_units={'45','46','61','62','63','64','71','72','73','74'};

if isempty(FortUnit)
   FortUnit=FileName(end-1:end);
end

if ~any(strcmp(FortUnit,supported_units))
   error(sprintf('Unit of %s is not yet supported. Terminal.',FortUnit))
end

if Verbose
   disp(sprintf('Looking for FileName=%s with FortUnit=%s',FileName,FortUnit))
end
if ~exist(FileName)
   error(sprintf('%s DNE. Terminal.',FileName))
end
if Verbose
   disp('Got it.')
end

if ~any(strcmp(FortUnit,{'45','46'})) & Level>0
   error('Level cannot be specified for a 2-d unit number. Terminal. ')
end
if any(strcmp(FortUnit,{'45','46'})) & Level<1
   error('Level must be specified for a 3-d unit number. Terminal. ')
end

% get file header for error checking
fid=fopen(FileName,'r');
if fid < 0
   error('Error opening file=%s',FileName)
end
headerline=fgetl(fid);
nextline=fgetl(fid);
temp=sscanf(nextline,'%f');
NDSETS=temp(1);
NND=temp(2);
DT=temp(3);
NSTEP=temp(4);
IFLAG=temp(5);
D=[];

ndsets=ceil((NDSETS-Strip)/Stride);
IterEnd=nanmin(NDSETS,IterEnd);

nextline=fgetl(fid);
n=textscan(nextline,'%s');
nwords=length(n{:});

if nwords==2
    tempCompact=0;
elseif nwords == 4 
    tempCompact=1;
else
    error('Incorrect number of words on first time line in file.')    
end

if isempty(Compact)
    Compact=tempCompact;
else
    if Compact ~= tempCompact
        disp('detected compactness of file inconsistent with user input.  Assuming user is wrong.')
    end
end

if HeaderOnly==1
   D.headerline=headerline;
   D.NDSETS=NDSETS;
   D.NND=NND;
   D.DT=DT;
   D.NSTEP=NSTEP;
   D.IFLAG=IFLAG;
  
   fclose(fid);
   return
end

if IterStart<0
   IterStart=NDSETS+IterStart+1;
end
Strip=IterStart-1;

if Verbose
   disp('Parameters:')
   disp(sprintf('   Compact  =%d',Compact))
   disp(sprintf('   FortUnit =%s',FortUnit))
   disp(sprintf('   FileName =%s',FileName))
   disp(sprintf('   Level    =%d',Level))
   disp(sprintf('   Stride   =%d',Stride))
   disp(sprintf('   Strip    =%d',Strip))   
   disp(sprintf('   IterStart=%d',IterStart))
   disp(sprintf('   IterEnd  =%d',IterEnd))
   disp(sprintf('   Verbose  =%d',Verbose))
end

%ItersToReturn=IterStart:Stride:IterEnd

fclose(fid);

if Compact==0
   if Verbose
      disp('calling ADCIRC output file reader ...')
   end
   D=read_adcirc_fort_mex(FileName,str2num(FortUnit),Verbose,Stride,Strip,IterStart,IterEnd,Level);
else
   if Verbose
      disp('calling compact ADCIRC  output file reader ...')
   end
   D=read_adcirc_fort_compact_mex(FileName,str2num(FortUnit),Verbose,Stride,Strip,IterStart,IterEnd);
end

D.NSTEP=NSTEP;
D.NDSETS=NDSETS;
D.IFLAG=IFLAG;
D.FortUnit=FortUnit;

% account for AdcCSD (Adcirc ColdStartDate)
if ~isempty(AdcCSD)
   if length(AdcCSD)==6
      AdcCSD=datenum(AdcCSD(1),AdcCSD(2),AdcCSD(3),AdcCSD(4),AdcCSD(5),AdcCSD(6));
      if Verbose
         disp(sprintf('Gregorian Time Offset = %s',datestr(AdcCSD,31)))
      end
      D.kd=D.time/86400+AdcCSD;
   end
end
D.header=blank(D.header);

