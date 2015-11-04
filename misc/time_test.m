url.csdl='http://mrtee.europa.renci.org:8080/thredds/dodsC/SSV-Ncml/CSDL.ncml';
url.estofs='http://mrtee.europa.renci.org:8080/thredds/dodsC/SSV-Ncml/ESTOFS.ncml';

nc.csdl=ncgeodataset(url.csdl);
nc.estofs=ncgeodataset(url.estofs);

time.csdl=nc.csdl{'time'};

time.estofs=nc.estofs{'time'};
