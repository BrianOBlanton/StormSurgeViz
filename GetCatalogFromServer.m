function TheCatalog=GetCatalogFromServer(UrlBase,CatalogName,TempDataLocation)
% catalog=GetCatalogFromServer(url)
% catalog=GetCatalogFromServer('http://opendap.renci.org:1935/thredds/')

if ~exist('UrlBase','var'),UrlBase='http://opendap.renci.org:1935/thredds/';end
if ~exist('CatalogName','var'),CatalogName='catalog.tree';end

catUrl=[UrlBase '/fileServer/ASGS/' CatalogName];
try
%    disp(['Trying to get catalog.tree from ' catUrl])
    % this is a workaround for ultimately getting a catalog from the thredds
    % server, probably via opensearch/gi-cat.  Here, we just get a cat tree
    % from the server
    urlread(catUrl);
catch ME
    disp(' ')
    disp(['Could not get ' CatalogName ' on remote OpenDAP server ' UrlBase])
    disp(' ')
    throw(ME);
end

notFound=true;
c=0;

tlimit=10;
try
    while notFound
        c=c+1;
        [fpath,status]=urlwrite(catUrl,[TempDataLocation '/cat.tree']);
        if ~status
            fprintf('Couldnt retrieve catalog file on try #%d. Trying again... \n',c);
            if c >= tlimit
                error('Tried and failed %d times to get catalog file.  This is terminal.',tlimit)
            end
            continue
        else
            fid=fopen(fpath,'r');
            l=fgetl(fid);  % get the dashed line
            if l == -1
                fprintf('cat file is empty on try #%d. Trying again... \n',c);
                if c >= tlimit
                    error('Tried and failed %d times to get catalog file.  This is terminal.',tlimit)
                end
                continue
            end
            notFound=false;
        end
        pause(2)
    end
catch ME
     
    str={ME.message
         ' '
         'This is most likely due to a network connection issue with the primary'
         'THREDDS server, or the unlucky situation where the catalog file was in the'
         'middle of updating.  Try running AdcircViz again.  If this same error occurs,'
         'contact Brian_Blanton@Renci.Org for connection debugging.'};
    str=sprintf('%s\n',str{:});
    error(str)
    
end

l=fgetl(fid);  % get the line with the field names
fields=deblank(strread(l,'%s','delimiter','$'));

% remove UseNcml and HasHsign
fields(ismember(fields,{'HasHsign','UseNcml'}))=[];

fgetl(fid);  % get the dashed line

temp=textscan(fid,'%s%s%s%s%s%s%s%s%s','Delimiter','$');
fclose(fid);


nLines=length(temp{1});
if nLines<1
    str=sprintf('Catalog file on %s appears to be empty.  This is terminal.',UrlBase);
    error(str)
end

for j=1:length(fields)
for i=1:nLines
   data{i,j}=deblank(temp{j}(i));
end
end
catalog=cell2struct(data,fields,2);
CatalogHash=DataHash(catalog);

TheCatalog=struct;
TheCatalog.Catalog=catalog;
TheCatalog.CatalogHash=CatalogHash;
TheCatalog.CurrentSelection=[];


%delete 'TempData/cat.tree'
