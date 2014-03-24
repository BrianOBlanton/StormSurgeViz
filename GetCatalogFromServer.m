function TheCatalog=GetCatalogFromServer(UrlBase,CatalogName)

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
while notFound
    c=c+1;
    urlwrite(catUrl,'TempData/cat.tree');
    fid=fopen('TempData/cat.tree','r');
    l=fgetl(fid);  % get the dashed line
    if l == -1
        fclose(fid);
        fprintf('cat file is empty on try #%d. Trying again... \n',c);
        if c > 3
            error('Tried and failed three times to get catalog file.  This is terminal.')
        end
        break
    end
    notFound=false;
end

l=fgetl(fid);  % get the line with the field names
fields=deblank(strread(l,'%s','delimiter','$'));

% remove UseNcml and HasHsign
fields(ismember(fields,{'HasHsign','UseNcml'}))=[];

fgetl(fid);  % get the dashed line

temp=textscan(fid,'%s%s%s%s%s%s%s%s%s','Delimiter','$');
fclose(fid);

nLines=length(temp{1});
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
