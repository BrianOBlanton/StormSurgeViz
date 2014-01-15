function Connections=OpenDataConnectionsTest  % (UrlBase)

    OpenDapUrlBase='http://opendap.renci.org:1935/thredds/dodsC';
    VortexUrlBase=[OpenDapUrlBase '/tc/debby/17/ultralite/blueridge.renci.org/asgs1/nhcConsensus'];
    UrlBase=VortexUrlBase;

    disp('Opening OPeNDAP connections ...')
    
    Connections(1)=GetStorm(UrlBase);
   
    EnsFound=0;
    for i=1:10
        idx=strfind(UrlBase,'nhcConsensus');
        temp=UrlBase(1:idx-1);
        temp=sprintf('%s/ens%d',temp,i);
        disp(temp)
        try 
            Connections(i+1) = GetStorm(temp);
            EnsFound=EnsFound+1;
        catch
            disp(sprintf('Could not connect to ens%d',i))
            break
        end
    end
    disp(sprintf('%d ensemble members found',i-1))

    
    function storm=GetStorm(url)
    
    try 
        storm.M63 = ncgeodataset([url '/' 'maxele.63.nc']);
    catch
        disp('Could not open maxele.63.nc')
    end
    
%     url=[UrlBase '/' 'fort.63.nc'];
%     try 
%         storm.F63 = ncgeodataset(url);
%     catch
%         SetUIStatusMessage('Could not open fort.63.nc')
%     end

    RPurl=[url '/run.properties'];
    % swap fileServer for dodsC since this is a plain text file
    idx=strfind(RPurl,'dodsC');
    P1=RPurl(1:idx-1);
    P2=RPurl(idx+5:end);
    RPurl=sprintf('%s/%s/%s',P1,'fileServer',P2);
    try
        urlwrite(RPurl,'TempData/run.properties');
        storm.RunProperties=...
            textscan(fopen('TempData/run.properties','r'),'%s %s',...
            'Delimiter',':');
    catch
        disp('Could not open remote run.properties file.')
        disp(RPurl);
    end
    
    f22url=[url '/fort.22'];
    % swap fileServer for dodsC since this is a plain text file
    idx=strfind(f22url,'dodsC');
    P1=f22url(1:idx-1);
    P2=f22url(idx+5:end);
    f22url=sprintf('%s/%s/%s',P1,'fileServer',P2);
    try
        urlwrite(f22url,'TempData/fort.22');
        temp=read_adcirc_nws19('TempData/fort.22');
        storm.storm=temp;
    catch
        disp('Could not open remote fort.22 file.')
        disp(f22url);
    end
    
    end
    
end

