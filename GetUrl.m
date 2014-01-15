function Url=GetUrl(ThisStorm,ThisAdvisory,ThisGrid,ThisInstance,UrlBase,TheCatalog)


%%
%%% Determine starting URL based in Instance

f=fields(TheCatalog.Catalog);
for i=1:length(f)
    s=sprintf('%s=[TheCatalog.Catalog.%s]'';',f{i},f{i});
    eval(s);
end

% filter out catalog parameters
if ~isempty(ThisInstance)
    idx=strcmp(Instances,ThisInstance); %#ok<*NODEF>
    Storms=Storms(idx);
    Advisories=Advisories(idx);
    Grids=Grids(idx);
    Machines=Machines(idx);
    Instances=Instances(idx);
    Ensembles=Ensembles(idx);
end
if ~isempty(ThisStorm)
    idx=strcmp(Storms,ThisStorm);
    Storms=Storms(idx);
    Advisories=Advisories(idx);
    Grids=Grids(idx);
    Machines=Machines(idx);
    Instances=Instances(idx);
    Ensembles=Ensembles(idx);
end
if ~isempty(ThisAdvisory)
    if ~ischar(ThisAdvisory)
        ThisAdvisory=num2str(ThisAdvisory);
    end
    idx=strcmp(Advisories,ThisAdvisory);
    Storms=Storms(idx);
    Advisories=Advisories(idx);
    Grids=Grids(idx);
    Machines=Machines(idx);
    Instances=Instances(idx);
    Ensembles=Ensembles(idx);
end
if ~isempty(ThisGrid)
    idx=strcmp(Grids,ThisGrid);
    Storms=Storms(idx);
    Advisories=Advisories(idx);
    Grids=Grids(idx);
    Machines=Machines(idx);
    Instances=Instances(idx);
    Ensembles=Ensembles(idx);
end

% if sum(idx)==0
%     error('No match found in catalog for Storm=%s  Advisory=%s  Grid=%s   Instance=%s  ',ThisStorm,ThisAdvisory,ThisGrid,ThisInstance)
% end

% the first entry in the catalog tree file is (presumably) the most recent forecast available.
% currentStorm=Storms{end};
% currentAdv=Advisories{end};
% currentGrid=Grids{end};
% currentMachine=Machines{end};
% currentInstance=Instances{end};
currentStorm=Storms{1};
currentAdv=Advisories{1};
currentGrid=Grids{1};
currentMachine=Machines{1};
currentInstance=Instances{1};

%CurrentSelection=length(Instances);
CurrentSelection=1;

% parse out ensemble member names
idx=strcmp(Advisories,currentAdv);
TheseEnsembles=Ensembles(idx);

% set default url and other things
Url.ThisInstance=currentInstance;
Url.ThisStorm   =currentStorm;
Url.ThisAdv     =currentAdv;
Url.ThisGrid    =currentGrid;
Url.Basin='al';
if str2double(currentAdv)<1000
    % need to skip "Q" since there are no storm names starting with Q
    startingnameletters={'a','b','c','d','e','f','g','h','i','j',...
                         'k','l','m','n','o','p','r','s','t','u',...
                         'v','w','x','y','z'};
    Url.StormType='TC';
    Url.ThisStormNumber=find(strcmpi(Url.ThisStorm(1),startingnameletters));
    
else  %  otherwise it will be the nam date...
    Url.StormType='other';
end
Url.FullDodsC=[UrlBase '/dodsC/ASGS/' currentStorm '/' currentAdv '/' currentGrid '/' currentMachine '/' currentInstance];
Url.FullFileServer=[UrlBase '/fileServer/ASGS/' currentStorm '/' currentAdv '/' currentGrid '/' currentMachine '/' currentInstance];
Url.Ens=TheseEnsembles;
Url.CurrentSelection=CurrentSelection;
% Url.catalog=TheCatalog.Catalog;
% Url.CatalogHash=TheCatalog.CatalogHash;
Url.Base=UrlBase;
