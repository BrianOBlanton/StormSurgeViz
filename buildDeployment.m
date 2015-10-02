cd /Users/bblanton/SVN/AdcircVizTool/trunk

delete *.p
pcode ./ 
delete buildDeployment.p AdcircViz_Init.p 
delete GetRunProperties.p GetRunProperty.p

cd adcirc_util
delete *.p
pcode ./

cd fem
delete *.p
pcode ./

cd ../basics
delete *.p
pcode .

cd ../../


zip('AdcircVizTool.zip',{'*.p',...
    'AdcircViz_Init.m',...
    'adcirc_util/*.p',...
    'adcirc_util/mex/*.mex*',...
    'adcirc_util/basics/*.p',...
    'adcirc_util/fem/*.p',...
    'extern',...
    'nctoolbox',...
    'private'})

delete *.p

cd adcirc_util
delete *.p

cd basics
delete *.p

cd ../fem
delete *.p

cd ../../

