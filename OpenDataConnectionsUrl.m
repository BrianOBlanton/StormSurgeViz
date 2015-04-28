%%  OpenDataConnectionsUrl
%%% OpenDataConnectionsUrl
%%% OpenDataConnectionsUrl
function Connections=OpenDataConnectionsUrl(Url)

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

    FileNetcdfVariableNames={}; 
    FilesToOpen={};              
    VariableDisplayNames={};     
    VariableNames={};
    VariableTypes={};
    VariableUnits={};
    VariableUnitsFac={};

    % read the variable list, which is actually an excel spreadsheet
    % to make it easier to edit.  The first row are the variable names
    % in this function, declared above as empty cells.
    ff='AdcircVizVariableList.xls';
    sheet=SSVizOpts.VariablesTable;  % this is the sheet NAME to read, not the sheet data!
    [~,~,C] = xlsread(ff,sheet);
    [m,n]=size(C);
    vars=C(1,:)';
    for i=1:n
        for j=2:m
            thisvar=vars{i};
            switch thisvar
                case {'VariableUnitsFac.mks','VariableUnitsFac.eng'}
                    com=sprintf('%s{j-1}=%f;',thisvar, str2num(C{j,i})); %#ok<ST2NM>
                otherwise
                    com=sprintf('%s{j-1}=''%s'';',thisvar,C{j,i});
            end
            eval(com)
        end
    end
    % convert any FileNetcdfVariableNames from a 2-string string into a
    % 2-element cell.
    for i=1:m-1 
        if strcmp(VariableTypes{i},'Vector')
            temp=FileNetcdfVariableNames{i};
            temp=textscan(temp,'%s %s');
            temp={char(temp{1}) char(temp{2})};
            FileNetcdfVariableNames{i}=temp; %#ok<AGROW>
        end
    end
    
    if any(strcmpi(Url.Units,{'english','feet'}))
        VariableUnitsFac=VariableUnitsFac.eng;
        VariableUnits=VariableUnits.eng;
    else
        VariableUnitsFac=VariableUnitsFac.mks;
        VariableUnits=VariableUnits.mks;
    end
        
    NVars=length(FilesToOpen);

    DeleteTempFiles=false;
    SetUIStatusMessage('Opening Url OPeNDAP connections ...\n')

    Connections.EnsembleNames=Url.Ens;
    Connections.VariableNames=VariableNames;
    Connections.VariableDisplayNames=VariableDisplayNames;
    Connections.VariableUnitsFac=VariableUnitsFac;
    Connections.VariableTypes=VariableTypes;
    
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
    
    Connections.members=cell(length(Connections.EnsembleNames),length(Connections.VariableNames));
    
    NEns=length(Url.Ens);
       
    for i=1:NEns
        TopDodsCUrl=[Url.FullDodsC '/' Url.Ens{i}];
        storm=GetStorm(TopDodsCUrl); 

        for j=1:NVars
            Connections.members{i,j}=storm(j);
        end
        
        % attach extra stuff if available.
        f22url=[Url.FullFileServer '/' Url.Ens{i} '/fort.22'];
        Connections.Tracks{i}='';
        try
            msg='* Connecting to fort.22 file\n';
            if ll
                fprintf(msg);
            else
                SetUIStatusMessage(msg);
            end
            urlwrite(f22url,[TempDataLocation '/fort.22']);
            temp=read_adcirc_nws19([TempDataLocation '/fort.22']);
            Connections.Tracks{i}=temp;
            if DeleteTempFiles
                delete([TempDataLocation '/fort.22']) %#ok<UNRCH>
            end
        catch ME
            SetUIStatusMessage(msg)
        end
        msg=sprintf('* Successfully retrieved %s file links ...\n',Url.Ens{i});
        SetUIStatusMessage(msg)
    end
 
    % add bathy as a variable
    Connections.VariableNames{NVars+1}='Grid Elevation';
    Connections.VariableDisplayNames{NVars+1}='Grid Elevation';
    Connections.VariableTypes{1,NVars+1}='Scalar';
    Connections.members{1,NVars+1}.NcTBHandle=Connections.members{1,1}.NcTBHandle;
    Connections.members{1,NVars+1}.FieldDisplayName=[];
    Connections.members{1,NVars+1}.FileNetcdfVariableName='depth';
    Connections.members{1,NVars+1}.VariableDisplayName='Grid Elevation';
    Connections.members{1,NVars+1}.NNodes=Connections.members{1,1}.NNodes;
    Connections.members{1,NVars+1}.NTimes=1;
    
    Connections.members{1,NVars+1}.Units='Meters';
    Connections.VariableUnitsFac{NVars+1}=1;
    if any(strcmpi(Url.Units,{'english','feet'}))
        Connections.VariableUnitsFac{NVars+1}=3.2808;
        Connections.members{1,NVars+1}.Units='Feet';
    end
             
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
             
    SetUIStatusMessage('* Done.\n\n')
    
    %%% nested fxn to get the data objects (not the data itself; that's
    %%% done in GetDataObjects)
    
    function storm=GetStorm(url1) 
        storm=struct('NcTBHandle',[],'Units',[],'FieldDisplayName',[],'FileNetcdfVariableName',[],'GridHash',[]);
        for ii=1:length(FilesToOpen)
            ThisVariable=FilesToOpen{ii};
            ThisVariableDisplayName=VariableDisplayNames{ii};
            %ThisVariableName=VariableNames{ii};
            %ThisVariableType=VariableType{ii};
            ThisUnits=VariableUnits{ii};
            ThisFileNetcdfVariableName=FileNetcdfVariableNames{ii};
            url=[url1 '/' ThisVariable];
            ttemp=[];
            try
                SetUIStatusMessage(sprintf('* Connecting to %s\n', ThisVariable))
                ttemp=ncgeodataset(url);
                SetUIStatusMessage(sprintf('* Opened %s  file connection.\n',ThisVariable))
                if length(ttemp.variables)<1
%                 SetUIStatusMessage(sprintf('***** No variables found in %s\n', ThisVariable))
%                 ttemp=[];
                end
            catch ME
                SetUIStatusMessage(sprintf('***** Could not open %s connection. *****\n',ThisVariable))
                if ii==1,throw(ME);end
            end
            
            storm(ii).NcTBHandle=ttemp;
            storm(ii).Units=ThisUnits;
            storm(ii).VariableDisplayName=ThisVariableDisplayName;
            storm(ii).FileNetcdfVariableName=ThisFileNetcdfVariableName;
            
            if ~isempty(ttemp)
                
                a=prod(double(size(ttemp.variable{'element'})));
                b=prod(double(size(ttemp.variable{'x'})));

                storm(ii).GridHash=DataHash2(a*b);
                
                if iscell(ThisFileNetcdfVariableName)
                    MandN=size(ttemp{ThisFileNetcdfVariableName{1}});
                else
                    MandN=size(ttemp{ThisFileNetcdfVariableName});
                end
                
                if (length(MandN)>1  && ~any(MandN==1))
                    m=MandN(2);n=MandN(1);
                else
                    m=max(MandN);n=1;
                end
                storm(ii).NNodes=m;
                storm(ii).NTimes=n;
            end
            %storm(ii).VariableType=ThisVariableType;
        end  
    end
end

