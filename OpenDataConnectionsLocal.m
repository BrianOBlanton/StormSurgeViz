%%  OpenDataConnectionsLocal
%%% OpenDataConnectionsLocal
%%% OpenDataConnectionsLocal
function Connections=OpenDataConnectionsLocal(Url)

    global TheGrids Debug 
    if Debug,fprintf('AdcViz++ Function = %s\n',ThisFunctionName);end

    ll=false;
    msg='Opening Local OPeNDAP connections ...\n';
    SetUIStatusMessage(msg)
    
    if Debug,fprintf('* Function = %s\n',ThisFunctionName);end

    fig=findobj(0,'Tag','MainVizAppFigure');
    TempDataLocation=getappdata(fig,'TempDataLocation');
    
    HOME=fileparts(which(mfilename));

    if ~exist([HOME '/private/run.properties.local'],'file')
        msg=['Local run.properties file not found in ' HOME '/private.'];
        if ll
            fprintf(msg);
        else
            SetUIStatusMessage(msg)
        end
    elseif strcmp(Url.ThisInstance,'Local') && ~strfind(Url.Base,'file://')
        msg='Local mode Url.Base must start with "file://"';
        if ll
            fprintf(msg);
        else
            SetUIStatusMessage(msg)
        end
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
    fig=findobj(0,'Tag','MainVizAppFigure');
    
    TempDataLocation=getappdata(fig,'TempDataLocation');    
    AdcVizOpts=getappdata(fig,'AdcVizOpts');

    sheet=AdcVizOpts.VariablesTable;  % this is the sheet NAME to read, not the sheet data!
    [~,~,C] = xlsread(ff,sheet);
    [m,n]=size(C);
    vars=C(1,:)';
    for i=1:n
        for j=2:m
            com=sprintf('%s{j-1}=''%s'';',vars{i},C{j,i});
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

    Connections.EnsembleNames=Url.Ens;
    Connections.VariableNames=VariableNames;
    Connections.VariableDisplayNames=VariableDisplayNames;
    Connections.VariableUnitsFac=VariableUnitsFac;
    Connections.VariableTypes=VariableTypes;
    
    % get run.properties file from first ens.
    i=1;
    if ~exist([Url.Ens{i} '/maxele.63.nc'],'file')
        % pop up a directory browser
        msg=['maxele.63.nc file not found in ' Url.Ens{i} '. Navigate to a simulations directory...\n'];
        if ll
            fprintf(msg);
        else
            SetUIStatusMessage(msg);
        end
        [filename, pathname, filterindex] = uigetfile('*.nc', 'Navigate to a maxele.63.nc file');
        if filename==0 % cancel was pressed
            error('This is terminal.')
        end
        Url.Ens{1}=pathname;
    end
    
    RPurl=[Url.Ens{1} '/run.properties'];
    if ~exist(RPurl,'file')
        RPurl=[HOME '/private/run.properties.local'];
    end
    
    try
        msg=['* Connecting to ' RPurl '  ... \n'];
        if ll
            fprintf(msg);
        else
            SetUIStatusMessage(msg)
        end
        urlwrite(['file://' RPurl],[TempDataLocation '/run.properties']);
        RunProperties=LoadRunProperties([TempDataLocation '/run.properties']);
        if DeleteTempFiles
            delete([TempDataLocation '/run.properties']) %#ok<UNRCH>
        end
    catch ME
        msg=['Could not connect to ' Url.Ens{i} ' run.properties file. This is terminal.\n'];
        if ll
            fprintf(msg);
        else
            SetUIStatusMessage(msg); 
        end
        throw(ME);
    end
    msg=['* Successfully retrieved ' RPurl  '\n'];
    if ll
        fprintf(msg);
    else
        SetUIStatusMessage(msg)
    end
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
            msg='* Could not open remote fort.22 file. \n';
            if ll
                fprintf(msg);
            else
                SetUIStatusMessage(msg)
            end
        end
        msg=sprintf('* Successfully retrieved %s file links ...\n',Url.Ens{i});
        if ll
            fprintf(msg);
        else
            SetUIStatusMessage(msg)
        end
    end
 
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
    
%     msg=sprintf('%d ensemble members found. \n\n',i);
%     if ll
%         fprintf(msg)
%     else
%         SetUIStatusMessage(msg)
%     end
    
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
                SetUIStatusMessage(sprintf('***** No variables found in %s\n', ThisVariable))
                ttemp=[];
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
