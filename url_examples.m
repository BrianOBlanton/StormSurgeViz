function Url=url_examples(sw)

%Url.NoaaCsdl='http://coastalmodeldev.data.noaa.gov/thredds/';
%Url.NoaaEstofs='http://coastalmodeldev.data.noaa.gov/thredds/dodsC/dailyESTOFS/estofs.20150621/estofs.atl.t00z.fields.cwl.nc';

%Url.AsgsRenci='http://opendap.renci.org:1935/thredds/dodsC/ASGS/ana/12/nc6b/hatteras.renci.org/anav50/nhcConsensus/00_dir.ncml';

if ~exist('sw'),sw='local';end

if strcmp(sw,'local')
    Url.AsgsRenci='http://localhost:8080/thredds/dodsC/SSV-Ncml/RenciAsgs.ncml';
    Url.NoaaCsdl='http://localhost:8080/thredds/dodsC/SSV-Ncml/CSDL.ncml';
    Url.NoaaEstofs='http://localhost:8080/thredds/dodsC/SSV-Ncml/ESTOFS_Local.ncml';
    Url.NYHOPS='http://localhost:8080/thredds/dodsC/SSV-Ncml/NYHOPS.ncml';
    Url.IrishSea='http://localhost:8080/thredds/dodsC/SSV-Ncml/IrishSeaROMS_Local.ncml';
    Url.NoaaPsurge='http://localhost:8080/thredds/dodsC/SSV-Ncml/SLOSH_Psurge.ncml';
else
    
    
    Url.AsgsRenci='http://mrtee.europa.renci.org:8080/thredds/dodsC/SSV-Ncml/RenciAsgs.ncml';
    Url.NoaaCsdl='http://mrtee.europa.renci.org:8080/thredds/dodsC/SSV-Ncml/CSDL.ncml';
    Url.NoaaEstofs='http://mrtee.europa.renci.org:8080/thredds/dodsC/SSV-Ncml/ESTOFS.ncml';
    Url.NYHOPS='http://mrtee.europa.renci.org:8080/thredds/dodsC/SSV-Ncml/NYHOPS.ncml';
    Url.IrishSea='http://mrtee.europa.renci.org:8080/thredds/dodsC/SSV-Ncml/IrishSeaROMS.ncml';
    Url.NoaaPsurge='http://mrtee.europa.renci.org:8080/thredds/dodsC/SSV-Ncml/SLOSH_Psurge.ncml';
end

