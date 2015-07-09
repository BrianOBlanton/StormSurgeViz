%%  OpenDataConnections
%%% OpenDataConnections
%%% OpenDataConnections
function Connections=OpenDataConnections(Url)
  
    global TheGrids Debug 
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    msg='Opening Network OPeNDAP connections ...\n';
    SetUIStatusMessage(msg)
    
    fig=findobj(0,'Tag','MainVizAppFigure');
    TempDataLocation=getappdata(fig,'TempDataLocation');
    SSVizOpts=getappdata(fig,'SSVizOpts');

    CF=CF_table;
    
    %VariableStandardNames=CF.StandardNames;
    
    %NVars=length(FilesToOpen);
    %DeleteTempFiles=false;
    
    Connections.EnsembleNames=Url.Ens;
    %Connections.VariableUnitsFac=VariableUnitsFac;
    %Connections.VariableTypes=VariableTypes;
    
    if Debug,fprintf('SSViz++   Attempting to use NCML files on server.\n');end
    i=1;
    TopDodsCUrl= [Url.FullDodsC '/' Url.Ens{i} '/' SSVizOpts.NcmlDefaultFileName];
    TopTextUrl= [Url.FullFileServer '/' Url.Ens{i} '/' SSVizOpts.NcmlDefaultFileName];
    
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
    if isempty(strcmp(nc.variables,'element'))
        Connections.SubConvention='CGRID';
        Connections.SubConventionVersion='0.X';
    else
        Connections.SubConvention='UGRID';
        Connections.SubConventionVersion='0.9';
    end
    
    % now, add storm parts
    
%    Connections.members=cell(length(Connections.EnsembleNames),length(Connections.VariableNames));
    
    NEns=length(Url.Ens);
    
    for i=1:NEns
        storm=GetFieldsNcml(TopDodsCUrl,CF);
        NVars=length(storm);
        
        for j=1:NVars
            Connections.members{i,j}=storm(j);
            Connections.VariableNames{j}=storm(j).VariableDisplayName;
            Connections.VariableDisplayNames{j}=storm(j).VariableDisplayName;
            Connections.VariableUnitsFac{j}=1.0;
            Connections.VariableTypes{j}='Scalar';
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
        SetUIStatusMessage(sprintf('Successfully retrieved %s forecast links ...\n',Url.Ens{i}))
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
    
    SetUIStatusMessage(sprintf('%d ensemble members found. \n\n',i))
    
              
    % check the grids on which the variables are defined
    NumberOfGridNodes=NaN*ones(NEns*NVars,1);
    GridId=0;
    for i=1:NEns
        for j=1:NVars       
           Member=Connections.members{i,j};
           if ~isempty(Member) && ~isempty(Member.NcTBHandle)
               nnodes=Member.NNodes;
               gridid=find(NumberOfGridNodes==nnodes);
               if isempty(gridid)
                   GridId=GridId+1;
                   NumberOfGridNodes(GridId)=nnodes;
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









%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     FileNetcdfVariableNames={}; 
%     FilesToOpen={};              
%     VariableDisplayNames={};     
%     VariableNames={};
%     VariableTypes={};
%     VariableUnits={};
%     VariableUnitsFac={};

%     % read the variable list, which is actually an excel spreadsheet
%     % to make it easier to edit.  The first row is the variable names
%     % in this function, declared above as empty cells.
%     ff='AdcircVizVariableList.xls';
%     sheet=SSVizOpts.VariablesTable;
%     [~,~,C] = xlsread(ff,sheet);
%     [m,n]=size(C);
%     vars=C(1,:)';
%     for i=1:n
%         for j=2:m
%             thisvar=vars{i};
%             switch thisvar
%                 case {'VariableUnitsFac.mks','VariableUnitsFac.eng'}
%                     com=sprintf('%s{j-1}=%f;',thisvar, str2num(C{j,i})); %#ok<ST2NM>
%                 otherwise
%                     com=sprintf('%s{j-1}=''%s'';',thisvar,C{j,i});
%             end
%             eval(com)
%         end
%     end
%     % convert any FileNetcdfVariableNames from a 2-string string into a
%     % 2-element cell.
%     for i=1:m-1 
%         if strcmp(VariableTypes{i},'Vector')
%             temp=FileNetcdfVariableNames{i};
%             temp=textscan(temp,'%s %s');
%             temp={char(temp{1}) char(temp{2})};
%             FileNetcdfVariableNames{i}=temp; %#ok<AGROW>
%         end
%     end
    
%     if any(strcmpi(Url.Units,{'english','feet'}))
%         VariableUnitsFac=VariableUnitsFac.eng;
%         VariableUnits=VariableUnits.eng;
%     else
%         VariableUnitsFac=VariableUnitsFac.mks;
%         VariableUnits=VariableUnits.mks;
%     end




%%%%%%%%%%%%%%%%%%%%%%%%%
%    % add bathy as a variable
%     Connections.VariableNames{NVars+1}='Grid Elevation';
%     Connections.VariableDisplayNames{NVars+1}='Grid Elevation';
%     Connections.VariableTypes{1,NVars+1}='Scalar';
%     Connections.members{1,NVars+1}.NcTBHandle=Connections.members{1,1}.NcTBHandle;
%     Connections.members{1,NVars+1}.FieldDisplayName=[];
%     Connections.members{1,NVars+1}.FileNetcdfVariableName='depth';
%     Connections.members{1,NVars+1}.VariableDisplayName='Grid Elevation';
%     Connections.members{1,NVars+1}.NNodes=Connections.members{1,1}.NNodes;
%     Connections.members{1,NVars+1}.NTimes=1;
%     
%     Connections.members{1,NVars+1}.Units='Meters';
%     Connections.VariableUnitsFac{NVars+1}=1;
%     if any(strcmpi(Url.Units,{'english','feet'}))
%         Connections.VariableUnitsFac{NVars+1}=3.2808;
%         Connections.members{1,NVars+1}.Units='Feet';
%     end
