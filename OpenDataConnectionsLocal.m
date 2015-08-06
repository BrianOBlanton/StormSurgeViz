%%  OpenDataConnectionsLocal
%%% OpenDataConnectionsLocal
%%% OpenDataConnectionsLocal
function Connections=OpenDataConnectionsLocal(Url)

    global TheGrids Debug 

    ll=false;
    msg='Opening Local OPeNDAP connections ...';
    if Debug
        fprintf('SSViz++ Function = %s\n',ThisFunctionName);
        fprintf('SSViz++   %s\n',msg);
    end
    
    SetUIStatusMessage(msg)
    
    CF=CF_table;

    fig=findobj(0,'Tag','MainVizAppFigure');
    %TempDataLocation=getappdata(fig,'TempDataLocation');
    
    %HOME=fileparts(which(mfilename));

    if strcmp(Url.ThisInstance,'Local') && ~strncmp(Url.Base,'file://',7)
        msg='Local mode Url.Base must start with "file://"';
        if Debug
            fprintf('SSViz++   %s\n',msg);
        end
        SetUIStatusMessage(msg)
    end
     
    if isnan(Url.Ens{1}),Url.Ens{1}='./';end

    if strcmp(Url.FullDodsC,'file://')
    
        [filename, pathname] = uigetfile('*.ncml','Navigate to an ncml file.');
    
        if filename==0 % cancel was pressed
            return
        end
        
        url=sprintf('file://%s',fullfile(pathname,filename));
       % set(Handles.ServerInfoString,'String',url);
        Url.FullDodsC=url;
        Url.FullFileServer=url;
 
    end
    
    try
        nc=ncgeodataset(Url.FullDodsC);
    catch
        ME = MException('CheckForNcml:NotPresent', ...
            ['Could not connect to an ncml file. ',...
            Url.FullDodsC]);
        SetUIStatusMessage(ME.message)
        throw(ME);
    end
    
    TopDodsCUrl= [Url.FullDodsC];
%    TopTextUrl= [Url.FullFileServer];
    
%     if any(strcmpi(Url.Units,{'english','feet'}))
%         VariableUnitsFac=VariableUnitsFac.eng;
%         VariableUnits=VariableUnits.eng;
%     else
%         VariableUnitsFac=VariableUnitsFac.mks;
%         VariableUnits=VariableUnits.mks;
%     end
    

   % open up connection to ncml file
    %nc=ncgeodataset(TopDodsCUrl);
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
        
  
   end
   
   msg=sprintf('Successfully retrieved %s  ...',TopDodsCUrl);
   SetUIStatusMessage(msg)
   
  
%     % try to get the nhc shapefile
%     if Url.UseShapeFiles
%         if strcmp(Url.StormType,'TC')
%             adv=str2double(Url.ThisAdv);
%             UrlBase='http://www.nhc.noaa.gov/gis/forecast/archive/';
%             yr=GetRunProperty(RunProperties,'year');
%             stormnumber=GetRunProperty(RunProperties,'stormnumber');
%             f=sprintf('%s%02d%s_5day_%03d.zip',Url.Basin,Url.ThisStormNumber,yr,adv);
%             try
%                 urlwrite([UrlBase f],sprintf('%s/%s','TempData',f));
%                 Connections.AtcfShape=LoadAtcfShapefile(Url.Basin,Url.ThisStorm,yr,adv,'TempData');
%             catch ME
%                 SetUIStatusMessage(sprintf('Failed to get %s/%s.  Check arguments to %s.\n',UrlBase,f,mfilename));
%             end
%         end
%     end
      
             
    % check the grids on which the variables are defined
    NumberOfGridNodes=NaN*ones(NEns*NVars,1);
    GridId=0;
    for i=1:NEns
        for j=1:NVars+1        % +1 for the added grid depth
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
    
 end
