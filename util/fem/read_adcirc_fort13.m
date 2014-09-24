function D=read_adcirc_fort13(fname)
% READ_ADCIRC_FORT13 read an ADCIRC nodal attribute file (fort.13)
% D=read_adcirc_fort13(fname);

if ~exist('fname'),fname='fort.13';,end

fid=fopen(fname,'r');

D.header=fgets(fid);
D.nn=fscanf(fid,'%d',1);

D.natts=fscanf(fid,'%d',1);
fgets(fid);
disp(sprintf('%d attributes to scan in ... ',D.natts))

disp(sprintf('Scanning attribute metadata ... '))
for i=1:D.natts
   D.att_names{i}=deblank(fgets(fid));
   disp(sprintf('   %s ... ',D.att_names{i}))
   D.att_units{i}=deblank(fgets(fid));
   D.att_numdefvals(i)=fscanf(fid,'%d',1);
   D.att_defvals{i}=fscanf(fid,'%f',D.att_numdefvals(i));
   fgets(fid);
end

TotalNumberOfColumns=sum(D.att_numdefvals);
%D.atts=NaN*ones(D.nn,TotalNumberOfColumns);
for i=1:D.natts

   ThisNumberOfColumns=D.att_numdefvals(i);
   
   an=deblank(fgets(fid));
   non_def_vals=fscanf(fid,'%d',1);
   fgets(fid);
   
   disp(sprintf('Reading %d values for %s from %s',non_def_vals,an,fname))
   
   temp1=repmat(D.att_defvals{i}',[D.nn 1]);
   fmtstr=repmat('%f ',[1 ThisNumberOfColumns]);
   fmtstr=['%d ' fmtstr];
   
   temp2=fscanf(fid,fmtstr,[ThisNumberOfColumns+1 non_def_vals])';
   temp1(temp2(:,1),:)=temp2(:,2:end);
   D.atts{i}=temp1;
   D.att_setnodes{i}=temp2(:,1);
   
end

