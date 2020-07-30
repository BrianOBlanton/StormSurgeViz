function err=TestForCatalogServer(UrlBase,CatalogName)
%%  TestForCatalogServer
%%% TestForCatalogServer
%%% TestForCatalogServer

global Debug
if Debug, fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

err=0;
% test getting to the server
try 
    fprintf(['SSViz++ Trying to reach ' UrlBase '/catalog.html\n'])
    urlread([UrlBase '/catalog.html']);
catch ME
    fprintf('\n\nSSViz++** Could not reach OpenDAP server %s.\n\n',UrlBase)
    throw(ME);
end
fprintf('SSViz++ Connected to %s\n',UrlBase)
    
if  regexp(UrlBase,'tacc')
    catUrl=[UrlBase '/fileServer/asgs/2020/' CatalogName];
else
    catUrl=[UrlBase '/fileServer/2020/' CatalogName];
end

try
    fprintf(['SSViz++ Trying to get ' CatalogName ' from ' catUrl '\n']);
    % this is a workaround for ultimately getting a catalog from the thredds
    % server, probably via opensearch/gi-cat.  Here, we just get a cat tree
    % from the server
    urlread(catUrl);
 
catch ME
    fprintf(['SSViz++** Could not get ' CatalogName ' on remote OpenDAP server ' UrlBase '\n'])
    throw(ME);
end
fprintf('SSViz++ Got it.\n');

end

