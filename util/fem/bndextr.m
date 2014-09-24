
	function fem_struct=bndextr(fem_struct,bfile,infile);
%
%  BNDEXTR.M 	extracts boundary and creates ADCIRC style boundary
%	information from fem_struct, a bel file, and an output grdfile
%
%	BNDEXTR can handle the follow bel codes (1,2,3,5) and will 
%	  translate them to (0,1,2, and spec. elev.), respectively
%
%	fem_struct=bndextr(fem_struct,belfile,infile);
%
% Calls: grid_util/bnd_conn, vecfun/rlencode, grid_util/sortbel,
%	 and the OPNML toolbox
%
% Catherine R. Edwards
% Last modified: 17 Apr 2002
% Added IBTYPE=2 autofind 12 Jun 2002
%

% initialize some variables 
len=0; isllen=0; fllen=0; allen=0; nopen=0; nland=0; nflux=0;
bnodes=[]; islnodes=[]; flnodes=[]; albnodes=[];

[conn,kk]=bnd_conn(fem_struct);

% sort inbe to push first open boundary to front, connect split elev bdry
inbe2=sortbel(bfile); 

% check which types of boundaries used in belfile
icheck=unique(inbe2(:,5));

if(ismember(5,icheck))		% specified elevation	
  [len,bnodes]=rlencode(column(inbe2(find(inbe2(:,5)==5),2:3)'));
  nopen=sum((len==1))/2;
end;
if(ismember(2,icheck))		% islands
  [isllen,islnodes]=rlencode(column(inbe2(find(inbe2(:,5)==2),2:3)'));
end
if(ismember(3,icheck))		% specified elevation
  [fllen,flnodes]=rlencode(column(inbe2(find(inbe2(:,5)==3),2:3)'));
  nflux=sum(fllen==1)/2;
end
if(ismember(1,icheck))		% mainland boundary	
  [allen,albnodes]=rlencode(column(inbe2(find(inbe2(:,5)==1),2:3)'));
  nland=sum(allen==1)/2;
end

% get list of all land boundaries
[llen,alland]=rlencode(column(inbe2(find(inbe2(:,5)==1|inbe2(:,5)==3),2:3)'));

% specified elevation first
list=[nopen;length(bnodes);];
ones=find(len==1); 
for i=1:nopen
  istart=find(bnodes==bnodes(ones(2*(i-1)+1)));
  iend=find(bnodes==bnodes(ones(2*i)));
  nstart=bnodes(ones(2*(i-1)+1)); nend=bnodes(ones(2*i));
  nlen=length(bnodes(find(bnodes==nstart):find(bnodes==nend)));
  list=[list;nlen;bnodes(istart:iend)]; 
end
str=repmat(' ',length(list),1);

% islands next
nisland=kk-1; list3=[]; str3=[];
for i=1:nisland
  conntmp=eval(['conn.bnd',num2str(i+1)]);
  nlen3(i)=length(conntmp)-1;
  list3=[list3;nlen3(i);conntmp(1:nlen3(i))];
  str3=[str3;'1';repmat(' ',nlen3(i),1)];
end

% velocity boundaries (ibtype=2,0) next

[segs,ifl,ial]=intersect(flnodes,albnodes);
nvell=length([flnodes;albnodes;islnodes])-nisland-length(segs);
list2=[nland+nisland+nflux;nvell]; str2=[];

% find beginning and end points (len=1) and sort in order around mainland
allones=[flnodes(find(fllen==1));albnodes(find(allen==1))];
[ind,ia,ib]=intersect(alland,allones); ia(ia==length(alland))=1; 
ia=[ia;length(alland)]; [isort,ii]=sort(ia);  

% zip down list of beginning, ends and get nodes between, ibtype
for i=1:length(ii)-1
  if(isort(i)~=isort(i+1))
    nodes=alland(isort(i):isort(i+1));
    ibtype=inbe2(find(inbe2(:,2)==nodes(2)),5);
    % flux bdry takes precedence if nodes shared w/mainland
    if(ibtype==1);
      nodes=nodes(1+ismember(nodes(1),segs):end-ismember(nodes(end),segs));
    end
% double check that ordering is correct (elev bdry in middle of
% mainland/flux boundaries can get tricky)
    inset=ismember((nodes(1:2))',inbe2(:,2:3),'rows');
    if(inset & (ibtype==1 | ibtype==3))
      list2=[list2;length(nodes);nodes];
      str2=[str2;num2str(ibtype-1);repmat(' ',length(nodes),1)];
    end
  end
end    
str2=[' ';' ';str2]; list2=[list2];

nnod=length(fem_struct.x); nele=length(fem_struct.e);
fid=fopen(infile,'w');
fprintf(fid,'%s\n%i %i\n',fem_struct.name,nele,nnod);
nn=(1:nnod)'; ne=(1:nele)';x=fem_struct.x; y=fem_struct.y; z=fem_struct.z;
fprintf(fid,'%7d %12.6f %12.6f %12.4f\n',[nn x y z]');
fprintf(fid,'%8d %8d %8d %8d %8d\n',[ne 3*ne./ne fem_struct.e]');
llist=[list;list2;list3]; sstr=[str;str2;str3]; nline=length(sstr);
%test=fprintf(fid,'%8d %s\n',[llist sstr]);
for i=1:length(llist)
  fprintf(fid,'%8d',llist(i));
  fprintf(fid,'%s\n',['    ',sstr(i)]);
end
fclose(fid);
