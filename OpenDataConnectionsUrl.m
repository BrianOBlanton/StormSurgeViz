%%  OpenDataConnections
%%% OpenDataConnections
%%% OpenDataConnections
function Connections=OpenDataConnectionsUrl(Url)
  
% this mode (Url) assumes that the url points to an ncml file on a THREDDS
% server.  

    global TheGrids Debug 
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    msg='Opening Network OPeNDAP connections ...\n';
    SetUIStatusMessage(msg)
    
    fig=findobj(0,'Tag','MainVizAppFigure');
    TempDataLocation=getappdata(fig,'TempDataLocation');
    %SSVizOpts=getappdata(fig,'SSVizOpts');

    CF=CF_table;
    
    Connections.EnsembleNames=Url.Ens;
    %Connections.VariableUnitsFac=VariableUnitsFac;
    %Connections.VariableTypes=VariableTypes;
    
    if Debug,fprintf('SSViz++   Attempting to use NCML files on server.\n');end
    i=1;
    TopDodsCUrl= [Url.FullDodsC];
    TopTextUrl= [Url.FullFileServer];
    
    try
        websave([TempDataLocation '/test.retrieve.ncml'],TopTextUrl);
    catch
        SetUIStatusMessage('Could not connect to an ncml file. This is terminal.\n')
        ME = MException('CheckForNcml:NotPresent', ...
            ['Could not connect to an ncml file. ',...
            TopTextUrl]);
        throw(ME);
    end
       
    % open up connection to ncml file
    nc=ncgeodataset(TopDodsCUrl);
    
    % look for required attributes
    if ~isempty(nc.attribute{'model'})
        Connections.Model=nc.attribute{'model'};
    else
        error('Required NC file global attribute "model" not found.  This is terminal.')
    end
    if ~isempty(nc.attribute{'Conventions'})
        Connections.Conventions=nc.attribute{'Conventions'};
        if ~strcmp(Connections.Conventions(1:2),'CF')
            error('Required NC file global attribute "Conventions" does not start with "CF". This is terminal.')
        end
    else
        error('Required NC file global attribute "Conventions" not found.  This is terminal.')
    end
        
    if ~isempty(nc.attribute{'institution'})
        Connections.Institution=nc.attribute{'institution'};
    else
        error('Required NC file global attribute "Institution" not found.  This is terminal.')
    end
   
    % look for optional attributes
    if ~isempty(nc.attribute{'title'})
        Connections.Title=nc.attribute{'title'};
    else
        error('Optional NC file global attribute "title" not found.  Setting to NaN ...')
    end
    
    % set SubConvention according to existence of "element" variable
%     if ~isempty(strcmp(nc.variables,'element'))
%         Connections.SubConvention='CGRID';
%         Connections.SubConventionVersion='0.X';
%     else
%         Connections.SubConvention='UGRID';
%         Connections.SubConventionVersion='0.9';
%     end
    
    % now, add storm parts
    
%    Connections.members=cell(length(Connections.EnsembleNames),length(Connections.VariableNames));
    
    NEns=length(Url.Ens);
    
    for i=1:NEns
        storm=GetFieldsNcml(TopDodsCUrl);
        NVars=length(storm);
        
        % these are the scalar variables
        for j=1:NVars
            Connections.members{i,j}=storm(j);
            Connections.VariableNames{j}=storm(j).VariableName;
            Connections.VariableDisplayNames{j}=storm(j).VariableDisplayName;
            Connections.VariableUnitsFac{j}=1.0;
            Connections.VariableTypes{j}=storm(j).VariableType;
        end
        
        if isfield(CF,'Vectors')           
            NVecs=length(CF.Vectors);
            for jj=1:NVecs
                
               
                 uname=nc.standard_name(CF.Vectors(jj).u);
                 vname=nc.standard_name(CF.Vectors(jj).v);

                 if isempty(uname) || isempty(vname)
                    SetUIStatusMessage(sprintf('SSViz++ Variable not found for vector component %s or %s. Skipping ...\n',CF.Vectors(jj).u,CF.Vectors(jj).v))
                    continue
                 end
                 
                 Connections.members{i,j+jj}=storm(j);  % copy last member...
                 Connections.VariableNames{j+jj}=[uname,vname];
                 Connections.VariableTypes{j+jj}='Vector';
                 Connections.VariableDisplayNames{j+jj}=CF.Vectors(jj).name;
                 Connections.VariableUnitsFac{j+jj}=1.0;
                 
                 Connections.members{i,j+jj}.Units=CF.Vectors(jj).units;
                 Connections.members{i,j+jj}.VariableType='Vector';
                 Connections.members{i,j+jj}.VariableName=[uname,vname];
                 Connections.members{i,j+jj}.VariableDisplayName=CF.Vectors(jj).name;
             
                 temp=size(nc.variable(uname));

                 cdm=Connections.members{i,j+jj}.CdmDataType;
                 
                 switch numel(temp)
                     case 3
                         if strcmp(cdm,'cgrid')
                             a=[temp(2) temp(3)];
                             b=temp(1);
                         else
                             error('size of array ==3 for ugrid data.  Terminal.')
                         end
                     case 2
                         if strcmp(cdm,'cgrid')
                             a=[temp(1) temp(2)];
                             b=1;
                         else
                             a=temp(2);
                             b=temp(1);
                         end
                     otherwise
                         error('  A 1-D field variable in a cgrid?  Error.   Terminal.')
                 end
                 Connections.members{i,j+jj}.NNodes=a;
                 Connections.members{i,j+jj}.NTimes=b;
            end
        end
        
        
%         % attach extra stuff if available.
%         f22url=[Url.FullFileServer '/' Url.Ens{i} '/fort.22'];
%         f22Location=[TempDataLocation '/fort.22'];
%         Connections.Tracks{i}='';
%         try
%             SetUIStatusMessage('* Connecting to fort.22 file\n')
%             urlwrite(f22url,f22Location);
%             temp=read_adcirc_nws19(f22Location);
%             Connections.Tracks{i}=temp;
%             if DeleteTempFiles
%                 delete(f22Location) %#ok<UNRCH>
%             end
%         catch ME
%             SetUIStatusMessage('* Could not open remote fort.22 file. \n')
%         end
%         
        SetUIStatusMessage(sprintf('SSViz++ Successfully retrieved %s forecast links ...\n',Url.Ens{i}))
    end
     
    % try to get the nhc shapefile
    if Url.UseShapeFiles
        if strcmp(Url.StormType,'TC')
            adv=str2double(Url.ThisAdv);
            UrlBase='http://www.nhc.noaa.gov/gis/forecast/archive/';
            yr=GetRunProperty(RunProperties,'year');
            Url.StormNumber=GetRunProperty(RunProperties,'stormnumber');
            f=sprintf('%s%s%s_5day_%03d.zip',Url.Basin,Url.StormNumber,yr,adv);
            try
                urlwrite([UrlBase f],sprintf('%s/%s',TempDataLocation,f));
                Connections.AtcfShape=LoadAtcfShapefile(Url.Basin,Url.StormNumber,yr,adv,TempDataLocation);
            catch ME
                SetUIStatusMessage(sprintf('Failed to get %s/%s.  Check arguments to %s.\n',UrlBase,f,mfilename));
            end
        end
    end
    
    SetUIStatusMessage(sprintf('SSViz++ %d ensemble members found. \n\n',i))
    
    % check the grids on which the variables are defined
    NumberOfGridNodes=NaN*ones(NEns*NVars,1);
    NVars=length(Connections.VariableTypes);
    GridId=0;
    for i=1:NEns
        for j=1:NVars       
           Member=Connections.members{i,j};
           if ~isempty(Member) && ~isempty(Member.NcTBHandle)
               nnodes=Member.NNodes;
               gridid=find(NumberOfGridNodes==prod(nnodes));
               if isempty(gridid)
                   GridId=GridId+1;
                   NumberOfGridNodes(GridId)=prod(nnodes);
                   TheGrids{GridId}=GetGridStructure(Member,GridId);
                   if isfield(TheGrids{GridId},'z')
                       if any(strcmpi(Url.Units,{'english','feet'}))
                           TheGrids{GridId}.z=TheGrids{GridId}.z*3.2808;
                       end
                   end
                   
                   Connections.members{i,j}.GridId=GridId;
               else
                   Connections.members{i,j}.GridId=gridid;
               end
           end
        end
    end
             
    SetUIStatusMessage('Done.\n')
        
end