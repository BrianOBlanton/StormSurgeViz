function err=TestForCatalogServer(UrlBase,CatalogName)
%%  TestForCatalogServer
%%% TestForCatalogServer
%%% TestForCatalogServer

global Debug
if Debug, fprintf('AdcViz++ Function = %s\n',ThisFunctionName);end



err=0;
% test getting to the server
try 
    fprintf(['AdcViz++ Trying to reach ' UrlBase '/catalog.html\n'])
    urlread([UrlBase '/catalog.html']);
catch ME
    fprintf('\n\nAdcViz++** Could not reach OpenDAP server %s.\n\n',UrlBase)
    throw(ME);
end
fprintf('AdcViz++ Connected.\n')
    
catUrl=[UrlBase '/fileServer/ASGS/' CatalogName];
try
    fprintf(['AdcViz++ Trying to get ' CatalogName ' from ' catUrl '\n']);
    % this is a workaround for ultimately getting a catalog from the thredds
    % server, probably via opensearch/gi-cat.  Here, we just get a cat tree
    % from the server
    urlread(catUrl);
 
catch ME
    fprintf(['AdcViz++** Could not get ' CatalogName ' on remote OpenDAP server ' UrlBase '\n'])
    throw(ME);
end
fprintf('AdcViz++ Got it.\n');

end

