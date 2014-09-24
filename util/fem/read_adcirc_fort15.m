function f15=read_adcirc_fort15(f15name,nopen)
% f15=read_adcirc_fort15(f15name,nopen)

if nargin+nargout==0
   disp('Call as: f15=read_adcirc_fort15(f15name);');
   return
end
if ~exist('f15name')
   f15name='fort.15';
end

if ~exist(f15name)
   error([f15name ' file DNE. Terminal.'])
end


fid=fopen(f15name,'r');

f15.file=f15name;

% run parameters
%for i=1:31
%   eval(['f15.line' int2str(i) '=fgetl(fid);'])
%end
l=fgetl(fid);temp=strtok(l,'!'); f15.gridname=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.comment=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.nfover=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.nabout=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.nscreen=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.ihot=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.ics=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.im=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.nolibf=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.nolifa=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.nolica=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.nolicat=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.nwp=strtrim(temp);
for i=1:str2num(f15.nwp)
   l=fgetl(fid);
end
l=fgetl(fid);temp=strtok(l,'!'); f15.ncor=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.ntip=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.nws=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.nramp=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.grav=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.tau0=strtrim(temp);
if  strcmp(f15.tau0,'-5.0')
   l=fgetl(fid);temp=strtok(l,'!'); f15.tau0minmax=strtrim(temp);
end
l=fgetl(fid);temp=strtok(l,'!'); f15.dt=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.statim=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.reftim=strtrim(temp);
if ~strcmp(f15.nws,'0')
   l=fgetl(fid);temp=strtok(l,'!'); f15.wtiminc=strtrim(temp);
end
l=fgetl(fid);temp=strtok(l,'!'); f15.rnday=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.dramp=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.timeweights=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.depthfactors=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.centerofcpp=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.frictionfactors=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.cori=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.esl=strtrim(temp);
l=fgetl(fid);temp=strtok(l,'!'); f15.ntif=str2num(strtrim(temp));
for i=1:f15.ntif
   l=fgetl(fid);
   l=fgetl(fid);
end

l=fgetl(fid);temp=strtok(l,'!'); f15.nbfr=str2num(strtrim(temp));
if f15.nbfr>0
   for i=1:f15.nbfr
      l=fgetl(fid);
      l=fgetl(fid);
   end
   for i=1:f15.nbfr
      l=fgetl(fid);
      for i=1:nopen
         l=fgetl(fid);
      end
   end
end

l=fgetl(fid);temp=strtok(l,'!'); f15.anginn=str2num(strtrim(temp));

% NOUTE
l=fgetl(fid);
temp=strtok(l,'!');
[f15.NOUTE f15.TOUTSE f15.TOUTFE f15.NSPOOLE]=strread(strtrim(temp));
l=fgetl(fid);
temp=strtok(l,'!');
f15.NSTAE=str2num(strtrim(temp));
for i=1:f15.NSTAE
   l=fgetl(fid);
   [a,b]=strtok(l,'!');
   f15.STAE_COMMENT{i}=blank(b(2:end));
   [f15.STAE(i,1) f15.STAE(i,2)]=strread(strtrim(a));
end


% NOUTV
l=fgetl(fid);
temp=strtok(l,'!');
[f15.NOUTV f15.TOUTSV f15.TOUTFV f15.NSPOOLV]=strread(strtrim(temp));
l=fgetl(fid);
f15.NSTAV=str2num(strtok(l,'!'));
for i=1:f15.NSTAV
   l=fgetl(fid);
   [a,b]=strtok(l,'!');
   f15.STAV_COMMENT{i}=b;
   [l1,l2]=strread(a,'%f%f');
   f15.STAV(i,1)=l1; 
   f15.STAV(i,2)=l2; 
end


return


% tidal potential forcing
l=fgetl(fid);
f15.ntidepot=str2num(strtok(l));
for i=1:f15.ntidepot
   l=fgetl(fid);
   f15.tidepotname{i}=strtok(l);
   l=fgetl(fid);
   f15.tidepotnum{i}=l;
end
 
% open boundary forcing
l=fgetl(fid);
f15.ntideobc=str2num(strtok(l));
for i=1:f15.ntideobc
   l=fgetl(fid);
   f15.tideobcname{i}=strtok(l);
   l=fgetl(fid);
   f15.tideobcnum{i}=l;
end

%determine number of obcs
curpos=ftell(fid);
nobc=0;
l=strtok(fgetl(fid));
while ~strcmp(l,f15.tideobcname{2})
   nobc=nobc+1;
   l=strtok(fgetl(fid));
end
newpos=ftell(fid);
fseek(fid,-(newpos-curpos),0);
nobc=nobc-1;

for i=1:f15.ntideobc
   l=strtok(fgetl(fid));
   if ~strcmp(l,f15.tideobcname{i})
      error('Frequency out of order')
   end
   clear temp
   for j=1:nobc
      l=fgetl(fid);
      [a,b]=strtok(l,'!');
      [a,b]=strtok(a,' ');
      temp(j,:)=[str2num(a) str2num(b)];
   end
   f15.tideobcamppha(:,:,i)=temp;
end

%anginn
f15.anginn=str2num(strtok(fgetl(fid)))

% NOUTE
l=fgetl(fid);
temp=strtok(l,'!');
words=strsep2(temp);
f15.NOUTE=str2num(words{1});
f15.TOUTSE=str2num(words{2});
f15.TOUTFE=str2num(words{3});
f15.NSPOOLE=str2num(words{4});
l=fgetl(fid);
f15.NSTAE=str2num(strtok(l,'!'));
for i=1:f15.NSTAE
   l=fgetl(fid);
   [a,b]=strtok(l,'!');
   aa=strsep2(a);
   f15.STAE_COMMENT{i}=b(2:end);
   f15.STAE(i,1)=str2num(aa{1}); 
   f15.STAE(i,2)=str2num(aa{2}); 
end

disp('here')

% NOUTV
l=fgetl(fid);
temp=strtok(l,'!');
words=strsep2(temp);
f15.NOUTV=str2num(words{1});
f15.TOUTSV=str2num(words{2});
f15.TOUTFV=str2num(words{3});
f15.NSPOOLV=str2num(words{4});
l=fgetl(fid);
f15.NSTAV=str2num(strtok(l,'!'));
for i=1:f15.NSTAV
   l=fgetl(fid);
   [a,b]=strtok(l,'!');
   aa=strsep2(a);
   f15.STAV_COMMENT{i}=b;
   f15.STAV(i,1)=str2num(aa{1}); 
   f15.STAV(i,2)=str2num(aa{2}); 
end


% NOUTM (met stations)
l=fgetl(fid);
temp=strtok(l,'!');
words=strsep2(temp);
f15.NOUTM=str2num(words{1});
f15.TOUTSM=str2num(words{2});
f15.TOUTFM=str2num(words{3});
f15.NSPOOLM=str2num(words{4});
l=fgetl(fid);
f15.NSTAM=str2num(strtok(l,'!'));
for i=1:f15.NSTAM
   l=fgetl(fid);
   [a,b]=strtok(l,'!');
   aa=strsep2(a);
   f15.STAM_COMMENT{i}=b;
   f15.STAM(i,1)=str2num(aa{1}); 
   f15.STAM(i,2)=str2num(aa{2}); 
end

% NOUTGE
l=fgetl(fid);
temp=strtok(l,'!');
words=strsep2(temp);
f15.NOUTGE=str2num(words{1});
f15.TOUTSGE=str2num(words{2});
f15.TOUTFGE=str2num(words{3});
f15.NSPOOLGE=str2num(words{4});


% NOUTGV
l=fgetl(fid);
temp=strtok(l,'!');
words=strsep2(temp);
f15.NOUTGV  =str2num(words{1});
f15.TOUTSGV =str2num(words{2});
f15.TOUTFGV =str2num(words{3});
f15.NSPOOLGV=str2num(words{4});

% NOUTGM
l=fgetl(fid);
temp=strtok(l,'!');
words=strsep2(temp);
f15.NOUTGM  =str2num(words{1});
f15.TOUTSGM =str2num(words{2});
f15.TOUTFGM =str2num(words{3});
f15.NSPOOLGM=str2num(words{4});

% HARM ANL 
l=fgetl(fid);
temp=strtok(l,'!');
words=strsep2(temp);
f15.NHARF=str2num(words{1});
for i=1:f15.NHARF
   l=fgetl(fid);
   temp=strtok(l,'!');
   f15.HA_FREQ_NAME{i}=blank(temp);
   l=fgetl(fid);
   temp=strtok(l,'!');
   words=strsep2(temp);
   f15.HA_FREQ(i)   =str2num(words{1});
   f15.HA_FREQ_NF(i)=str2num(words{2});
   f15.HA_FREQ_EA(i)=str2num(words{3});
end
l=fgetl(fid);
temp=strtok(l,'!');
words=strsep2(temp);
f15.THAS  =str2num(words{1});
f15.THAF  =str2num(words{2});
f15.NHAINC=str2num(words{3});
f15.FMV   =str2num(words{4});
l=fgetl(fid);
temp=strtok(l,'!');
words=strsep2(temp);
f15.NHASE=str2num(words{1});
f15.NHASV=str2num(words{2});
f15.NHAGE=str2num(words{3});
f15.NHAGV=str2num(words{4});
l=fgetl(fid);
temp=strtok(l,'!');
words=strsep2(temp);
f15.NHSTAR=str2num(words{1});
f15.NHSINC=str2num(words{2});
l=fgetl(fid);
temp=strtok(l,'!');
words=strsep2(temp);
f15.ITITER=str2num(words{1});
f15.ISLDIA=str2num(words{2});
f15.CONVCR=str2num(words{3});
f15.ITMAX=str2num(words{4});

%get_word
