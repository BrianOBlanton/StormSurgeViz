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
    disp(['Could not get ' CatalogName ' on remote OpenDAP server ' Url.Base])
    disp(' ')
    throw(ME);
end
%disp('Got it.')

urlwrite(catUrl,'TempData/cat.tree');
fid=fopen('TempData/cat.tree','r');

fgetl(fid);  % get the dashed line

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

TheCatalog.Catalog=catalog;
TheCatalog.CatalogHash=CatalogHash;
TheCatalog.CurrentSelection=[];


%delete 'TempData/cat.tree'
