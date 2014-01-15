% speedtest

% from ADCIRC/RENCI/THREDDS
url='http://opendap.renci.org:1935/thredds//dodsC/tc//isaac/34/ocpr_v19a_DesAllemands4CERA/garnet.erdc.hpc.mil/nodcorps/nhcConsensus/fort.63.nc';
varnameinfile='zeta';
nc=ncgeodataset(url);
zeta_obj=nc.geovariable(varnameinfile);

disp('getting first time slice from zeta_obj, unchunked')
tic
zeta1=zeta_obj.data(1,:);
toc
disp('getting time series  from zeta_obj, unchunked')
tic
zetats=zeta_obj.data(:,1);
toc



disp(' ')


% from ADCIRC/RENCI/THREDDS
url='http://opendap.renci.org:1935/thredds//dodsC/tc//isaac/34/ocpr_v19a_DesAllemands4CERA/garnet.erdc.hpc.mil/nodcorps/nhcConsensus/fort.63.chunked.nc';
varnameinfile='zeta';
nc=ncgeodataset(url);
zeta_obj=nc.geovariable(varnameinfile);

disp('getting first time slice from zeta_obj, chunked')
tic
zeta1=zeta_obj.data(1,:);
toc
disp('getting time series  from zeta_obj, chunked')
tic
zetats=zeta_obj.data(:,1);
toc












% 
% % from nctoolbox doc
% url ='http://geoport.whoi.edu/thredds/dodsC/examples/bora_feb.nc';
% nc = ncgeodataset(url);
% salt_obj = nc.geovariable('salt');
% 
% 
% disp('getting first time slice from salt_obj')
% tic
% salt1=squeeze(salt_obj.data(1,:,:,:));
% toc
% 
% 
% disp('getting time series from salt_obj')
% tic
% saltts=squeeze(salt_obj.data(:,1,1,1));
% toc
