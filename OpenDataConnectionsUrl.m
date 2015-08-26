%%  OpenDataConnections
%%% OpenDataConnections
%%% OpenDataConnections
function Connections=OpenDataConnectionsUrl(Url)
  
% this mode (Url) assumes that the url points to an ncml file on a THREDDS
% server.  

    global TheGrids Debug 
    
    msg='Opening Network OPeNDAP connections ... ';
    if Debug
        fprintf('SSViz++   Function = %s\n',ThisFunctionName)
        fprintf('SSViz++   %s\n',msg);
    end
    
    fig=findobj(0,'Tag','MainVizAppFigure');
    TempDataLocation=getappdata(fig,'TempDataLocation');
    %SSVizOpts=getappdata(fig,'SSVizOpts');

    CF=CF_table;
    
    Connections.EnsembleNames=Url.Ens;
    %Connections.VariableUnitsFac=VariableUnitsFac;
    %Connections.VariableTypes=VariableTypes;
    
    if Debug,fprintf('SSViz++   Attempting to get to NCML file on server.\n');end
    i=1;
    TopDodsCUrl= [Url.FullDodsC];
    TopTextUrl= [Url.FullFileServer];
    
    [~,~,ext]=fileparts(TopDodsCUrl);
    if ~strcmpi(ext,'.ncml')
        ME = MException('CheckForNcml:NotPresent', ...
            ['Input URL does not end in .ncml: ',...
            TopDodsCUrl]);
        SetUIStatusMessage(ME.message)
        throw(ME); 
        
    end
    
    try
        f=[TempDataLocation '/test.retrieve.ncml'];
        delete(f)
        websave(f,TopTextUrl);
    catch
       str={'The ncml file ' 
            TopTextUrl
            'could not be connected to.  It is possible that the server is down, '
            'or that there are firewall issues on the client side.'}; 
            msgbox(str)
        ME = MException('CheckForNcml:NotPresent', ...
            ['Could not retrieve the ncml file. It is possible that the server is down, or that there are firewall issues on the client side. ',... 
            TopTextUrl]);
        SetUIStatusMessage(ME.message)
        throw(ME);
    end
       
    % open up connection to ncml file
    try 
        nc=ncgeodataset(TopDodsCUrl);
    catch
        str={'The ncml file ' 
            TopDodsCUrl
            'could not be connected to.  It is possible that it references '
            'a remote TDS catalog on a server that is s down.'}; 
            msgbox(str)
         ME = MException('CheckForNcml:Broken', ...
            ['Could not connect to the ncml file. It is possible that the server is down or that files referenced in the ncml file do not exist. ',...
            TopDodsCUrl]);
        SetUIStatusMessage(ME.message)
        throw(ME);
    end
    
    if Debug,fprintf('SSViz++   nc.location=%s\n',nc.location);end  

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
    Connections.Title='unspecified';
    if ~isempty(nc.attribute{'title'})
        Connections.Title=nc.attribute{'title'};
    else
        fprintf('SSViz++    Optional NC file global attribute "title" not found.  Setting to unspecified ...\n')
    end
    
    % set SubConvention according to existence of "element" variable
%     if ~isempty(strcmp(nc.variables,'element'))
%         Connections.SubConvention='CGRID';
%         Connections.SubConventionVersion='0.X';
%     else
%         Connections.SubConvention='UGRID';
%         Connections.SubConventionVersion='0.9';
%     end
    
    NEns=length(Url.Ens);
    
    for i=1:NEns
        storm=GetFieldsNcml(TopDodsCUrl,Url.Units);
        NVars=length(storm);
        
        % these are the scalar variables
        for j=1:NVars
            Connections.members{i,j}=storm(j);
            Connections.VariableNames{j}=storm(j).VariableName;
            Connections.VariableDisplayNames{j}=storm(j).VariableDisplayName;

            % set Units fac according to Url.Units
            Connections.VariableUnitsFac{j}=1.0;
            switch lower(Url.Units)
                case {'meters','metric'}
                    Connections.VariableUnitsFac{j}=1.0;
                    Connections.Units{j}=storm(j).Units;
                case {'feet','english'}
                    Connections.VariableUnitsFac{j}=storm(j).UnitsConvertFac;
                otherwise
                    fprintf('SSViz++   Unrecognized units speficication.  Proceeding with Metric/MKS...\n')
            end            
            Connections.VariableTypes{j}=storm(j).VariableType;
        end
        
        if isfield(CF,'Vectors')           
            NVecs=length(CF.Vectors);
            for jj=1:NVecs
                               
                 uname=nc.standard_name(CF.Vectors(jj).u);
                 vname=nc.standard_name(CF.Vectors(jj).v);

                 if isempty(uname) || isempty(vname)
                    msg=sprintf('         Variable not found for vector component %s or %s. Skipping ...',CF.Vectors(jj).u,CF.Vectors(jj).v);
                    SetUIStatusMessage(msg)
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
        
        msg=sprintf('Successfully retrieved %s forecast links ...',Url.Ens{i});
        SetUIStatusMessage(msg)
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
    
    msg=sprintf('%d ensemble members found.',i);
    SetUIStatusMessage(msg)
 
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
             
end