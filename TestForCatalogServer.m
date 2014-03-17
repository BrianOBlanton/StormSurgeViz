function err=TestForCatalogServer(UrlBase,CatalogName,verbose)
%%  TestForCatalogServer
%%% TestForCatalogServer
%%% TestForCatalogServer

if ~exist('verbose','var'),verbose=false;end

err=0;
% test getting to the server
try 
    if verbose
        disp(['* Trying to reach ' UrlBase '/catalog.html'])
    end
    urlread([UrlBase '/catalog.html']);
catch ME
    if verbose
        disp('*** Could not reach primary OpenDAP server.')
    end
    throw(ME);
end
if verbose
    disp('* Connected.')
end
    
catUrl=[UrlBase '/fileServer/ASGS/' CatalogName];
try
    if verbose
        disp(['* Trying to get ' CatalogName ' from ' catUrl])
    end
    % this is a workaround for ultimately getting a catalog from the thredds
    % server, probably via opensearch/gi-cat.  Here, we just get a cat tree
    % from the server
    urlread(catUrl);
 
catch ME
    if verbose
        disp(['*** Could not get ' CatalogName ' on remote OpenDAP server ' UrlBase])
    end
    throw(ME);
end
if verbose
    disp('* Got it.')
end

end

