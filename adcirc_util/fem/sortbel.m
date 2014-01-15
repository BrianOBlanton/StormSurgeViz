
	function [inbe3,message]=sortbel(bfile,outfile);
%
%  SORTBEL.M 	sorts an edited belfile to move open boundary elevation
%	segments to the front, connects possible split boundaries, and reorders
%	the file accordingly
%
%	SORTBEL requires the following arguments:
%		bfile		 - filename for bel file
%				 ** alternately, can be passed 
%				    as boundary element list inbe ***
%		outfile (optional)- if passed, will write out to filename
%
%	output vars
%		inbe3		 - sorted boundary element list
%		message		 - message if belfile written correctly (1/0),
%				   if called with outfile specified
%
%	[inbe,message]=sortbel(belfile,outfile);
%
% Calls: fem_io/read_bel
%
% Catherine R. Edwards
% Last modified: 28 May 2002
% Added conditions for flux-specified open boundaries: 12 Jun 2002
%

if(isstr(bfile))
  [inbe,gridname]=read_bel(bfile);
else
  inbe=bfile; gridname='gridname';
end

% sort inbe to push first open boundary to front
iopn=find(inbe(:,5)==5); inbe2=inbe; 

if(isempty(iopn))
  iopn=find(inbe(:,5)==3); inbe2=inbe; 
end

if(isempty(iopn));
  disp('No elevation or flux specified open boundary nodes in bel file');
  inbe3=inbe;return;
elseif(iopn(1)~=1)
  inbe2=[inbe(iopn(1):end,:);inbe(1:iopn(1)-1,:)];
end
inbe3=inbe2;

iopn=find(inbe2(:,5)==5); 
if(isempty(iopn))
  iopn=find(inbe2(:,5)==3);inbe3=inbe2;
end
di=diff(iopn); gt1=find(di>1); lgt=length(gt1);
if(inbe2(iopn(1),2)==inbe2(iopn(end),3))
  pind=iopn(gt1(lgt)+1:end); notpind=setdiff(1:length(inbe2),pind);
  inbe3=[inbe2(pind,:);inbe2(notpind,:)];
end

% lastly, move islands back to end
isl=(inbe3(:,5)==2);  inbe3=[inbe3(~isl,:);inbe3(isl,:)];

inbe3(:,1)=(1:length(inbe3))';

if nargin==2
  [fid,message]=fopen(outfile,'w');
  fprintf(fid,'%s\n',gridname);
  header='Sorted belfile';
  fprintf(fid,'%s\n',header);
  fprintf(fid,'%10d %7d %7d %7d %7d\n',inbe3');
  fclose(fid);
end
