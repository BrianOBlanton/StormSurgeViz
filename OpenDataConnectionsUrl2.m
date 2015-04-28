%%  OpenDataConnectionsUrl2
%%% OpenDataConnectionsUrl2
%%% OpenDataConnectionsUrl2
function Connections=OpenDataConnectionsUrl2(Url)

    global TheGrids Debug 
    if Debug,fprintf('* Function = %s\n',ThisFunctionName);end
 
    msg='Opening Remote OPeNDAP connections ...\n';
    SetUIStatusMessage(msg)
    
    fig=findobj(0,'Tag','MainVizAppFigure');
    TempDataLocation=getappdata(fig,'TempDataLocation');
    SSVizOpts=getappdata(fig,'SSVizOpts');

    HOME=SSVizOpts.HOME;

    if ~exist([HOME '/private/run.properties.url'],'file')
        msg=['Url run.properties file not found in ' HOME '/private.'];         
        SetUIStatusMessage(msg)
    elseif strcmp(Url.ThisInstance,'Url') && ~strfind(Url.Base,'http://')
        msg='Url mode Url.Base must start with "http://"';
        SetUIStatusMessage(msg)
    end
     
    if isnan(Url.Ens{1}),Url.Ens{1}='./';end


    
    % read the variable list, which is actually an excel spreadsheet
    % to make it easier to edit.  The first row are the variable names
    % in this function, declared above as empty cells.
%     ff='AdcircVizVariableList.xls';
%     sheet=SSVizOpts.VariablesTable;  % this is the sheet NAME to read, not the sheet data!
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
%     
%     if any(strcmpi(Url.Units,{'english','feet'}))
%         VariableUnitsFac=VariableUnitsFac.eng;
%         VariableUnits=VariableUnits.eng;
%     else
%         VariableUnitsFac=VariableUnitsFac.mks;
%         VariableUnits=VariableUnits.mks;
%     end
       
    DeleteTempFiles=false;
    SetUIStatusMessage('Opening Url OPeNDAP connections ...\n')

    RPurl=[HOME '/private/run.properties.url']; 
    
    try
        msg=['* Connecting to ' RPurl ' ... \n'];
        SetUIStatusMessage(msg)
        urlwrite(['file:///' RPurl],[TempDataLocation '/run.properties']);
        RunProperties=LoadRunProperties([TempDataLocation '/run.properties']);
        if DeleteTempFiles
            delete([TempDataLocation '/run.properties']) %#ok<UNRCH>
        end
    catch ME
        msg='Could not connect to run.properties.url file. This is terminal.\n';
        SetUIStatusMessage(msg); 
        throw(ME);
    end
    
    msg=['* Successfully retrieved ' RPurl  '\n'];
    SetUIStatusMessage(msg)
 
    Connections.RunProperties=RunProperties;
    
    % now, add storm parts
    %FileNetcdfVariableNames={}; 
    %FilesToOpen={};              
    VariableDisplayNames={};     
    VariableNames={};
    VariableTypes={};
    VariableDimensions={};
    VariableUnits={};
    VariableUnitsFac={};

    nc=ncgeodataset(Url.FullDodsC);

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
    if ~isempty(strcmp(nc.variables,'element'))
        Connections.SubConvention='CGRID';
        Connections.SubConventionVersion='0.X';
    else
        Connections.SubConvention='UGRID';
        Connections.SubConventionVersion='0.9';
    end
    
    % look for variables by standard name
    c=0;
    % look for "water level" variables
    disp('Looking for water level variables ...')
    % possible standard names
    stdnames={'sea_surface_height_above_sea_level',...
              'sea_surface_height_above_geoid',...
              'sea_surface_elevation_anomaly',...
              'sea_surface_height_above_reference_ellipsoid',...
              'sea_surface_height'};
    
    str=GetVariableName(nc,stdnames);
    if isempty(str)
        error('No water level variable found in %s.\n\nWhat''s the point!!\n\n',url)
    end
    v=nc{str};
    c=c+1;
    VariableNames{c}=str;
    VariableLongNames{c}=v.attribute('long_name');
    VariableUnits{c}=v.attribute('units');
    VariableStandardNames{c}=v.attribute('standard_name'); 
    VariableDisplayNames{c}=v.attribute('long_name');
    VariableTypes{c}='scalar';
    VariableUnitsFac{c}=1.;
    VariableDimensions{c}=3;  % meaning x,y,t

    % look for "atmos pressure" variables
    disp('Looking for atmos pressure  variables ...')
    % possible standard names
    stdnames={'air_pressure_at_sea_level'};
    str=GetVariableName(nc,stdnames);
    if isempty(str)
        fprintf('No atmospheric pressure variable found in %s.\n\nContinuing without it...!!\n\n',url)
    else
        c=c+1;
        v=nc{str};
        VariableNames{c}=str;
        VariableLongNames{c}=v.attribute('long_name');
        VariableUnits{c}=v.attribute('units');
        VariableStandardNames{c}=v.attribute('standard_name');
        VariableDisplayNames{c}=v.attribute('long_name');
        VariableTypes{c}='scalar';
        VariableUnitsFac{c}=1.;
        VariableDimensions{c}=3;  % meaning x,y,t
    end
    
    % look for "depth" variables
    disp('Looking for depth/barhymetry variables ...')
    % possible standard names
    stdnames={'depth','depth below geoid'};
    str=GetVariableName(nc,stdnames);
    if isempty(str)
        fprintf('No depth/bahtymetry variable found in %s.\n\nContinuing without it...!!\n\n',url)
    else
        c=c+1;
        v=nc{str};
        VariableNames{c}=str;
        VariableLongNames{c}=v.attribute('long_name');
        VariableUnits{c}=v.attribute('units');
        VariableStandardNames{c}=v.attribute('standard_name');
        VariableDisplayNames{c}=v.attribute('long_name');
        VariableTypes{c}='scalar';
        VariableUnitsFac{c}=1.;
        VariableDimensions{c}=2;  % meaning x,y (no time-dependence)
    end
    
    % look for "wind" variables
    disp('Looking for east wind variables ...')
    % possible standard names
    stdnames={'eastward_wind'};
    str=GetVariableName(nc,stdnames);
    if isempty(str)
        fprintf('No eastward_wind variable found in %s.\n\nContinuing without it...!!\n\n',url)
    else
        c=c+1;
        v=nc{str};
        VariableNames{c}=str;
        VariableLongNames{c}=v.attribute('long_name');
        VariableUnits{c}=v.attribute('units');
        VariableStandardNames{c}=v.attribute('standard_name');
        VariableDisplayNames{c}=v.attribute('long_name');
        VariableTypes{c}='scalar';
        VariableUnitsFac{c}=1.;
        VariableDimensions{c}=3;  % meaning x,y,t
    end
    
    % look for "wind" variables
    disp('Looking for north wind variables ...')
    % possible standard names
    stdnames={'northward_wind'};
    str=GetVariableName(nc,stdnames);
    if isempty(str)
        fprintf('No northward_wind variable found in %s.\n\nContinuing without it...!!\n\n',url)
    else
        c=c+1;
        v=nc{str};
        VariableNames{c}=str;
        VariableLongNames{c}=v.attribute('long_name');
        VariableUnits{c}=v.attribute('units');
        VariableStandardNames{c}=v.attribute('standard_name');
        VariableDisplayNames{c}=v.attribute('long_name');
        VariableTypes{c}='scalar';
        VariableUnitsFac{c}=1.;
        VariableDimensions{c}=3;  % meaning x,y,t
    end
    
    
    
    Connections.EnsembleNames=Url.Ens;
    Connections.VariableNames=VariableNames;
    Connections.VariableLongNames=VariableLongNames;
    Connections.VariableStandardNames=VariableStandardNames;
    Connections.VariableDisplayNames=VariableDisplayNames;
    Connections.VariableUnitsFac=VariableUnitsFac;
    Connections.VariableTypes=VariableTypes;
    
    Connections.members=cell(length(Connections.EnsembleNames),length(Connections.VariableNames));
    
    NEns=length(Url.Ens);
    NVars=length(VariableNames);
   
    for i=1:NEns
        TopDodsCUrl=Url.FullDodsC;
        
        storm=struct('NcTBHandle',[],'Units',[],'FieldDisplayName',[],'FileNetcdfVariableName',[],'GridHash',[]);
        
        for ii=1:length(VariableDisplayNames)
            ThisVariableDisplayName=VariableDisplayNames{ii};
            ThisVariable=VariableNames{ii};
            %ThisVariableType=VariableType{ii};
            ThisUnits=VariableUnits{ii};
            %ThisFileNetcdfVariableName=FileNetcdfVariableNames{ii};
            
            storm(ii).NcTBHandle=nc;
            storm(ii).Units=ThisUnits;
            storm(ii).VariableDisplayName=ThisVariableDisplayName;
            storm(ii).FileNetcdfVariableName=TopDodsCUrl;
            
            if strcmp(Connections.Conventions,'UGRID')
                a=prod(double(size(nc.variable{'element'})));
                b=prod(double(size(nc.variable{'x'})));
                storm(ii).GridHash=DataHash2(a*b);
            end
            
            SZ=size(nc{ThisVariable});
            if strcmp(Connections.Conventions,'UGRID')
                if numel(SZ)~=2
                    error('Variable dimension for UGRID variable %s does not equal 2. Terminal.',ThisVariable)
                end
                if (length(SZ)>1  && ~any(SZ==1))
                    m=SZ(2);
                    n=SZ(1);
                else
                    m=max(SZ);
                    n=1;
                end
                
%                 if iscell(ThisFileNetcdfVariableName)
%                     SZ=size(ttemp{ThisFileNetcdfVariableName{1}});
%                 else
%                     SZ=size(ttemp{ThisFileNetcdfVariableName});
%                 end
%                                
                storm(ii).NNodes=m;
                storm(ii).NTimes=n;
                % create regular grid
            else
                
                switch numel(SZ)
                    case 2  %  probably depth/bathy
                         storm(ii).NNodes=SZ;     % number of computational points
                         storm(ii).NTimes=1;      % length of time 
                    case 3    
                         storm(ii).NNodes=[SZ(2) SZ(3)];     % number of computational points
                         storm(ii).NTimes=SZ(1);      % length of time 
                    otherwise
                        error('Variable dimension (%d) for CGRID variable %s not supported. Terminal.',ThisVariable,numel(SZ))
                end
            
            end
            
            for j=1:NVars
                Connections.members{i,j}=storm(i);
            end
            
            % attach extra stuff if available.
%             f22url=[Url.FullFileServer '/' Url.Ens{i} '/fort.22'];
%             Connections.Tracks{i}='';
%             try
%                 msg='* Connecting to fort.22 file\n';
%                 if ll
%                     fprintf(msg);
%                 else
%                     SetUIStatusMessage(msg);
%                 end
%                 urlwrite(f22url,[TempDataLocation '/fort.22']);
%                 temp=read_adcirc_nws19([TempDataLocation '/fort.22']);
%                 Connections.Tracks{i}=temp;
%                 if DeleteTempFiles
%                     delete([TempDataLocation '/fort.22']) %#ok<UNRCH>
%                 end
%             catch ME
%                 SetUIStatusMessage(msg)
%             end
            [a,b,c]=fileparts(Url.FullDodsC);
            msg=sprintf('* Successfully retrieved %s.%s file links ...\n',b,c);
            SetUIStatusMessage(msg)
        end
        
        % add bathy as a variable
%         Connections.VariableNames{NVars+1}='Grid Elevation';
%         Connections.VariableDisplayNames{NVars+1}='Grid Elevation';
%         Connections.VariableTypes{1,NVars+1}='Scalar';
%         Connections.members{1,NVars+1}.NcTBHandle=Connections.members{1,1}.NcTBHandle;
%         Connections.members{1,NVars+1}.FieldDisplayName=[];
%         Connections.members{1,NVars+1}.FileNetcdfVariableName='depth';
%         Connections.members{1,NVars+1}.VariableDisplayName='Grid Elevation';
%         Connections.members{1,NVars+1}.NNodes=Connections.members{1,1}.NNodes;
%         Connections.members{1,NVars+1}.NTimes=1;
%         
%         Connections.members{1,NVars+1}.Units='Meters';
%         Connections.VariableUnitsFac{NVars+1}=1;
%         if any(strcmpi(Url.Units,{'english','feet'}))
%             Connections.VariableUnitsFac{NVars+1}=3.2808;
%             Connections.members{1,NVars+1}.Units='Feet';
%         end
        
    % check the grids on which the variables are defined
    if strcmp(Connections.Conventions,'UGRID')
        
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
    
    SetUIStatusMessage('* Done.\n\n')

    end
 
end

