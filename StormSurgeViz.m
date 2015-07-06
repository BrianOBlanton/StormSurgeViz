function varargout=StormSurgeViz(varargin)
%
% StormSurgeViz - Visualization Application for Storm Surge Model Output
% 
% Call as: StormSurgeViz(P1,V1,P2,V2,...)
%
% Allowed Parameter/Value pairs (default value listed first):
%
% Instance          - String ASGS instance to use;
%                       {'nodcorps','hfip','ncfs'} and others as needed.
% Storm             - String storm name; default='most recent storm in catalog';
% Advisory          - String advisory number; default='most recent storm in catalog';
% Grid              - String model gridname; default=[]; 
% Units             - String to set height units; {'Meters','Feet'}
% FontOffset        - Integer to increase (+) or decrease (-) fontsize in the app;
% LocalTimeOffset   - (0, i.e. UTC) Hour offset for displayed times ( < 0 for west of GMT).
% BoundingBox       - [xmin xmax ymin ymax] vector for initial axes zoom
% CatalogName       - Name of catalog file to search for
% ColorMax          - Maximum scalar value for color scaling
% ColorMin          - Minimum scalar value for color scaling
% ColorMap          - Color map to use; {'noaa_cmap','jet','hsv',...}
% DisableContouring - {false,true} logical disabling mex compiled code calls
% GoogleMapsApiKey  - Api Key from Google for extended map accessing
% PollingInterval   - (900) interval in seconds to poll for catalog updates.
% ThreddsServer     - specify alternative THREDDS server
% Mode              - Local | Url | Network
% Help              - Opens a help window with parameter/value details.
%                     Must be the first and only argument to StormSurgeViz.
% SendDiagnosticsToCommandWindow - {false,true}
%
% These parameters can be set in the MyStormSurgeViz_Init.m file.  This
% file can be put anywhere on the MATLAB path EXCEPT in the StormSurgeViz 
% directory.  A convenient place is in the user "matlab" directory, which
% is in <USERHOME>/matlab by default in Unix/OSX. Parameters passed in via  
% the command line will override any settings in MyStormSurgeViz_Init.m, as
% well as any loaded in from the remotely maintained InstanceDefaults.m.  
%
% Do not put StormSurgeViz parameters in startup.m since this 
% is called first by MATLAB at startup.
%
% Only one instance of StormSurgeViz is allowed concurrently.  Close existing
% instances first.
%
% Example:
%
% >> StormSurgeViz;
% or
% >> close all; StormSurgeViz('Instance','rencidaily','Units','feet')
%
% Copyright (c) 2014  Renaissance Computing Institute. All rights reserved.
% Licensed under the RENCI Open Source Software License v. 1.0.
% This software is open source. See the bottom of this file for the 
% license.
% 
% Brian Blanton, Renaissance Computing Institute, UNC-CH, Brian_Blanton@Renci.Org
% Rick Luettich, Institute of Marine SCiences,    UNC-CH, Rick_Luettich@Unc.Edu
%
% Call as: [Handles,Url,Connections,Options]=StormSurgeViz;
% or:      [Handles,Url,Connections,Options]=StormSurgeViz(P1,V1,P2,V2,...);
%

if nargin==1
    if strcmp(varargin{1},'help')
        fprintf('Call as: close all; StormSurgeViz(''Instance'',''gomex'',''Units'',''feet'')\n')
        return
    end
end

% check to see if another instance of StormSurgeViz is already running
tags=findobj(0,'Tag','MainVizAppFigure');
if ~isempty(tags)
    str={'Only one instance of StormSurgeViz can run simultaneously.'
         'Press Continue to close other StormSurgeViz instances and start this one, or Cancel to abort the current instance.'};
    ButtonName=questdlg(str,'Other StormSurgeViz Instances Found!!!','Continue','Cancel','Cancel');
    switch ButtonName,
        case 'Continue'
            close(tags)
        otherwise
            fprintf('Aborting this instance of StormSurgeViz.\n')
            return
    end
end

% check java heap space size;  needs to be big for grids > ~1M nodes
if ~usejava('jvm')
    str={[mfilename ' requires Java to run.']
        'Make sure MATLAB is run with jvm.'};
    errordlg(str)
    return
end

if java.lang.Runtime.getRuntime.maxMemory/1e9  < 1.0 
    str={'Java Heap Space is < 1Gb.  For big model grids, this may '
        'be too small.  Increase Java Heap Memory through the MATLAB '
        'preferences.  This message is non-fatal, but if strange '
        'behavior occurs, then increase the java memory available. ' 
        ' '
        'More info on MATLAB ahd Java Heap Memory can '
        'be found at this URL:'
        ' '
        'http://www.mathworks.com/support/solutions/en/data/1-18I2C/'};
    msgbox(str)
end
    
%% Initialize StormSurgeViz
fprintf('\nSSViz++ Initializing application.\n')

StormSurgeViz_Init;  % this sets defaults and processes vars

% Storm
% Advisory
% Grid
% Instance
% CatalogName
switch SSVizOpts.Mode
    case 'Network'
        UrlBase=SSVizOpts.ThreddsServer;  %  ThreddsList{1}; %#ok<USENS>
        
        %% Test for the catalog existence
        err=TestForCatalogServer(UrlBase,SSVizOpts.CatalogEntryPoint,SSVizOpts.CatalogName);
        if err
            error('catalog file could not be found.')
        end
        
        %% Get the catalog
        %global TheCatalog
        fprintf('\nSSViz++ Getting Catalog.\n')
        TheCatalog=GetCatalogFromServer(UrlBase,SSVizOpts.CatalogEntryPoint,SSVizOpts.CatalogName,TempDataLocation);
        %catalog=TheCatalog.Catalog;
        %CatalogHash=TheCatalog.CatalogHash;
        
        %% Determine starting URL based on Instance
        Url=GetUrl2(SSVizOpts.Storm,...
                    SSVizOpts.Advisory,...
                    SSVizOpts.Grid,...
                    SSVizOpts.Machine,...
                    SSVizOpts.Instance,...
                    UrlBase,...
                    TheCatalog,...
                    SSVizOpts.CatalogEntryPoint);
        Url.UseShapeFiles=SSVizOpts.UseShapeFiles;
        Url.Units=SSVizOpts.Units;
        
    case 'Url'
        str={'Direct Url file access is not yet supported. Best of Luck!!'};
        UrlBase=SSVizOpts.Url;
        Url.ThisInstance='Url';
        Url.ThisStorm=NaN;
        Url.ThisAdv=NaN;
        Url.ThisGrid=NaN;
        Url.Basin=NaN;
        Url.StormType='other';
        Url.ThisStormNumber=NaN;
        Url.FullDodsC= UrlBase;
        Url.FullFileServer= UrlBase;
        Url.Ens={''};
        Url.CurrentSelection=NaN;
        Url.Base=UrlBase;
        Url.UseShapeFiles=SSVizOpts.UseShapeFiles;
        Url.Units=SSVizOpts.Units;
        
        TheCatalog.Catalog='Local';
        TheCatalog.CatalogHash=NaN;
        TheCatalog.CurrentSelection=[];
%        errordlg(str)
%        return
        
    otherwise
        %% Set up for Local Files
        UrlBase='file://';
        Url.ThisInstance='Local';
        Url.ThisStorm=NaN;
        Url.ThisAdv=NaN;
        Url.ThisGrid=NaN;
        Url.Basin=NaN;
        Url.StormType='other';
        Url.ThisStormNumber=NaN;
        Url.FullDodsC= UrlBase;
        Url.FullFileServer= UrlBase;
        Url.Ens={LocalDirectory};
        Url.CurrentSelection=NaN;
        Url.Base=UrlBase;
        Url.UseShapeFiles=SSVizOpts.UseShapeFiles;
        Url.Units=SSVizOpts.Units;
        
        TheCatalog.Catalog='Local';
        TheCatalog.CatalogHash=NaN;
        TheCatalog.CurrentSelection=[];
        
end

%% InitializeUI
Handles=InitializeUI(SSVizOpts);

setappdata(Handles.MainFigure,'SSVizOpts',SSVizOpts);
setappdata(Handles.MainFigure,'Catalog',TheCatalog);
setappdata(Handles.MainFigure,'Url',Url);
setappdata(Handles.MainFigure,'CurrentSelection',Url.CurrentSelection);
setappdata(Handles.MainFigure,'Instance',Url.ThisInstance);
setappdata(Handles.MainFigure,'VectorOptions',VectorOptions);
setappdata(Handles.MainFigure,'DateStringFormatInput',DateStringFormatInput);
setappdata(Handles.MainFigure,'DateStringFormatOutput',DateStringFormatOutput);
setappdata(Handles.MainFigure,'TempDataLocation',TempDataLocation);
setappdata(Handles.MainFigure,'SendDiagnosticsToCommandWindow',SSVizOpts.SendDiagnosticsToCommandWindow);


set(Handles.MainFigure,'UserData',Handles);
    
% temporary fix for Jesse Feyen's contmex5 dll problem
if SSVizOpts.DisableContouring
    set(Handles.DepthContours,'Enable','off','String','Disabled: no contmex5 binary')
    set(Handles.HydrographButton,'Enable','off','String','Hydrographs Disabled: no findelem binary')
end
    
if SSVizOpts.UITest, return, end   

global EnableRendererKludge
EnableRendererKludge=false;

CurrentPointer=get(Handles.MainFigure,'Pointer');
set(Handles.MainFigure,'Pointer','watch');

%% OpenDataConnections 
global Connections
if strcmpi(SSVizOpts.Mode,'Local')
    set(Handles.ServerInfoString,'String',[Url.Base Url.Ens{1}]);
    Connections=OpenDataConnectionsLocal(Url);
elseif strcmpi(SSVizOpts.Mode,'Url')
    set(Handles.ServerInfoString,'String',[Url.Base Url.Ens{1}]);
    Connections=OpenDataConnectionsUrl(Url);
else
    set(Handles.ServerInfoString,'String',Url.FullDodsC);
    Connections=OpenDataConnections(Url);
end
setappdata(Handles.MainFigure,'Connections',Connections);

%%
global TheGrids

%% SetEnsembleControls
Handles=SetEnsembleControls(Handles.MainFigure);
set(Handles.MainFigure,'UserData',Handles);

%% SetVariableControls
Handles=SetVariableControls(Handles.MainFigure,Handles.MainAxes);
set(Handles.MainFigure,'UserData',Handles);

%% SetSnapshotControls 
Handles=SetSnapshotControls(Handles.MainFigure,Handles.MainAxes);
set(Handles.MainFigure,'UserData',Handles);

%% GetDataObject 
SetUIStatusMessage('Getting initial data set links...\n');
EnsIndex=1;
VarIndex=1;
TimIndex=1;
Connections=GetDataObject(Connections,EnsIndex,VarIndex,TimIndex);

VectorVariableClicked=get(get(Handles.VectorVarButtonHandlesGroup,'SelectedObject'),'string');
if ~isempty(VectorVariableClicked)
    WindVecIndex=find(strcmp(Connections.VariableNames,VectorVariableClicked));  
    Connections=GetDataObject(Connections,EnsIndex,WindVecIndex,TimIndex);
    setappdata(Handles.MainFigure,'Connections',Connections);
end

%% MakeTheAxesMap
SetUIStatusMessage('Making default plot ... \n')
Handles=MakeTheAxesMap(Handles);  

ThisData=Connections.members{EnsIndex,VarIndex}.TheData{1};
Handles=DrawTriSurf(Handles,Connections.members{EnsIndex,VarIndex},ThisData);
if isfield(Connections,'Tracks')
    if ~isempty(Connections.Tracks{EnsIndex})
        Handles.Storm_Track=DrawTrack(Connections.Tracks{EnsIndex});
        set(Handles.ShowTrackButton,'String','Hide Track')
        set(Handles.ShowTrackButton,'Enable','on')
    end
end

RendererKludge;  %% dont ask...

temp=Connections.members{EnsIndex,VarIndex}.TheData{1};
if ~isreal(temp),temp=abs(temp);end
[MinTemp,MaxTemp]=GetMinMaxInView(TheGrids{1},temp);
Max=min([MaxTemp SSVizOpts.ColorMax]);
Min=max([MinTemp SSVizOpts.ColorMin]);
SetColors(Handles,Min,Max,SSVizOpts.NumberOfColors,SSVizOpts.ColorIncrement);

SetUIStatusMessage('* Done.\n\n');

%% Finalize Initializations
set(Handles.UnitsString,'String',SSVizOpts.Units);
set(Handles.TimeOffsetString,'String',SSVizOpts.LocalTimeOffset)
set(Handles.MainFigure,'UserData',Handles);

UpdateUI(Handles.MainFigure);
SetTitle(Connections.RunProperties);
axes(Handles.MainAxes);

% Last thing
% Set a timer to check for catalog updates
if exist('timer','file')
    if isfinite(SSVizOpts.PollInterval)
        SetUIStatusMessage('Setting Timer Function to check for updates.\n')
        Handles.Timer=timer('ExecutionMode','fixedRate',...
            'TimerFcn',@CheckForUpdateFromTimer,...
            'Period',SSVizOpts.PollInterval,...
            'StartDelay',SSVizOpts.PollInterval,...
            'Name','StormSurgeVizTimer');
        
        set(Handles.MainFigure,'UserData',Handles);
        if SSVizOpts.PollInterval>0
            start(Handles.Timer);
        end
    end
end

SetUIStatusMessage('Done Done.\n')
set(Handles.MainFigure,'Pointer',CurrentPointer);

if nargout>0, varargout{1}=Handles; end
if nargout>1, varargout{2}=Url; end
if nargout>2, varargout{3}=Connections; end
if nargout>3, varargout{4}=SSVizOpts; end

% ff=figure('Position',[31 82 816 902],'Color','w','Toolbar','none','MenuBar','none');
% axes('color','w','Position',[0 0 1 1])
% im=imread([HOME '/private/hb.tiff']);
% image(im(:,:,1:3))
% axis image
% axis off
% pause(3)
% delete(ff)

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Private functions
%%% Private functions
%%% Private functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%  CheckForUpdateFromTimer
%%% CheckForUpdateFromTimer
%%% CheckForUpdateFromTimer
function CheckForUpdateFromTimer(~,~) 

    SetUIStatusMessage('Checking for Updates via Timer ...')

    f=findobj(0,'Tag','MainVizAppFigure');
    Handles=get(f,'UserData');
    Url=getappdata(Handles.MainFigure,'Url');
    TempDataLocation=getappdata(Handles.MainFigure,'TempDataLocation');
    SSVizOpts=getappdata(Handles.MainFigure,'SSVizOpts');
    TheCatalog=getappdata(Handles.MainFigure,'Catalog');

    OldCatalogHash=TheCatalog.CatalogHash;
    OldCatalogName=SSVizOpts.CatalogName;
    CatalogEntryPoint=SSVizOpts.CatalogEntryPoint;
    
    % Get the current catalog...
    tempCatalog=GetCatalogFromServer(Url.Base,CatalogEntryPoint,OldCatalogName,TempDataLocation);
    timenow=datestr(fix(clock),'HH:MM PM');
    if strcmp(OldCatalogHash,tempCatalog.CatalogHash)
        %update=[];
        %CatalogHash=[];
        SetUIStatusMessage(sprintf('No Catalog Updates yet at %s\n',timenow))
    else
        if ~isempty(findobj(0,'Tag','StormSurgeVizUpdateMsgBox'))
            delete(findobj(0,'Tag','StormSurgeVizUpdateMsgBox'))
        end
        h=msgbox(sprintf('\nUpdate Available @ %s. Click on Show Catalog to update.\n',timenow));
        set(h,'Tag','StormSurgeVizUpdateMsgBox','Name','StormSurgeVizUpdateMsgBox','HandleVisibility','on')
        %LocalTimeOffset=getappdata(Handles.MainFigure,'LocalTimeOffset');
        SetUIStatusMessage(sprintf('\nUpdate Available @ %s. Click on Show Catalog to update.\n',timenow))
    end
    
end

%%  CheckForUpdate
%%% CheckForUpdate
%%% CheckForUpdate
function [update,CatalogHash]=CheckForUpdate(Url,TheCatalog)

    global Debug 
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
    
    SetUIStatusMessage('Checking for Updates...')

    f=findobj(0,'Tag','MainVizAppFigure');
    Handles=get(f,'UserData');

    SSVizOpts=getappdata(Handles.MainFigure,'SSVizOpts');
    OldCatalogHash=TheCatalog.CatalogHash;
    OldCatalogName=SSVizOpts.CatalogName;
    CatalogEntryPoint=SSVizOpts.CatalogEntryPoint;
    TempDataLocation=getappdata(Handles.MainFigure,'TempDataLocation');

    % Get the current catalog...
    tempCatalog=GetCatalogFromServer(Url.Base,CatalogEntryPoint,OldCatalogName,TempDataLocation);
    update=tempCatalog.Catalog;
    CatalogHash=tempCatalog.CatalogHash;
    if strcmp(OldCatalogHash,CatalogHash)
        update=[];
        CatalogHash=[];
        SetUIStatusMessage('No Updates.\n')
    else
        SetUIStatusMessage('Update Available.  Click on Show Catalog to update.\n')
    end
    
end

%%  BrowseFileSystem
%%% BrowseFileSystem
%%% BrowseFileSystem
function BrowseFileSystem(~,~)
    global Debug 
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    if exist('hObj','var')
        FigThatCalledThisFxn=gcbf;
    else
        FigThatCalledThisFxn=findobj(0,'Tag','MainVizAppFigure');
    end
    Handles=get(FigThatCalledThisFxn,'UserData');
    Url=getappdata(FigThatCalledThisFxn,'Url');
    
    directoryname = uigetdir(LocalStartingDirectory,'Navigate to a dir containing a maxele.63.nc file');
    
    if directoryname==0 % cancel was pressed
       return
    end
    
    set(Handles.ServerInfoString,'String',['file://' directoryname]);
    ClearUI(FigThatCalledThisFxn);
    
end

%%  DisplayCatalog
%%% DisplayCatalog
%%% DisplayCatalog
function DisplayCatalog(~,~)

    global Debug 
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    if exist('hObj','var')
        FigThatCalledThisFxn=gcbf;
    else
        FigThatCalledThisFxn=findobj(0,'Tag','MainVizAppFigure');
    end
    
    %MainFig=get(get(get(hObj,'Parent'),'Parent'),'Parent');
    
    Handles=get(FigThatCalledThisFxn,'UserData');
    Url=getappdata(FigThatCalledThisFxn,'Url');

    CatalogName=getappdata(Handles.MainFigure,'CatalogName');  
    TheCatalog=getappdata(Handles.MainFigure,'Catalog');  
    CurrentSelection=getappdata(Handles.MainFigure,'CurrentSelection');

    [update,CatalogHash]=CheckForUpdate(Url,TheCatalog);
    if ~isempty(update)
        TheCatalog.Catalog=update;
        TheCatalog.CatalogHash=CatalogHash;
    end
    
    catalog=TheCatalog.Catalog;
    CatalogHash=TheCatalog.CatalogHash;
    
    f=fields(catalog);
    fwidth=zeros([length(f) 1]);
    str=cell(length(catalog),1);

    % get max width of each catalog column
    for i=1:length(f)
       s=sprintf('[m,n]=size(char([catalog.%s]''));',f{i});
       eval(s);
       fwidth(i)=n;
    end
    
    for i=1:length(catalog)
        ll=[];
        for j=1:length(f)
            s=sprintf('d=catalog(%d).%s;',i,f{j});
            eval(s);
            if isempty(ll)
                fmt=sprintf('  %%%ds  ',fwidth(j));
                ll=sprintf(fmt,char(d));
            else
                fmt=sprintf('%%s   :   %%%ds  ',fwidth(j));
                ll=sprintf(fmt,ll,char(d));
            end
        end
        str{i}=ll;
    end

    dfs = get(0, 'DefaultUICOntrolFontSize');
    dfn = get(0, 'DefaultUICOntrolFontName');
    set(0,'DefaultUICOntrolFontName','Courier')
    set(0,'DefaultUICOntrolFontSize',14)
    
%     D={};
%     for i=1:length(f)
%         s=sprintf('D=[D [catalog.%s]''];',f{i});
%         eval(s);
%     end
    
%     DD=cell(length(str),7);
%     DD(:,2:7)=D;  
%     for i=1:length(str)
%         DD{i,1}=false;
%     end


% experimental jtable catalog display    
%     tfs=14;
%     trh=ceil(tfs*1.5); 
%     th=(length(D)+2)*trh;
%     
%     tcw=150;
%     tw=6*tcw+45;
%     
%     ff=figure('Resize','off','Name',sprintf('ASGS Catalog : %s',CatalogName),'NumberTitle','off','MenuBar','none','Visible','on');
%     p=get(ff,'Position');    
%     set(ff,'Position',[p(1) p(2) tw th],'Visible','on')    
% 
%     
%     %    mtable = uitable(ff,'FontSize',tfs,'RowStriping','on', 'ColumnWidth',{tcw},'Position',[0 0 tw*2 th],'Data',D, 'ColumnName',f,'Tag','AdcircVizCatalogDisplayTable');
%     mtable = uitable(ff,'FontSize',tfs,'RowStriping','on', 'ColumnWidth',{tcw},'Position',[0 0 tw th],'Data',D, 'ColumnName',f,'Tag','AdcircVizCatalogDisplayTable');
%     %set(mtable,'RowName',[])
%     %set(mtable, 'ColumnEditable', [true false false false false false false]);
%     
%     jscrollpane = findjobj(mtable);
%     jtable = jscrollpane.getViewport.getView;
% %    jtable.setSortable(true);
%     jtable.setAutoResort(true);
%     jtable.setMultiColumnSortable(true);
%     jtable.setPreserveSelectionsAfterSorting(true);
%     jtable.setNonContiguousCellSelection(false);
%     jtable.setRowSelectionAllowed(true);
%     jtable.setRowHeight(trh);

%     if ~isempty(CurrentSelection) && (CurrentSelection>0 && CurrentSelection < length(str)) 
%     
%     end
        
    [s,~]=listdlg('Name',sprintf('ASGS Catalog on %s', Url.Base),...
        'PromptString','Select a Catalog Entry or click Cancel.',...
        'ListString',str,'ListSize',[1200 700],'SelectionMode','single');

    %%% this is going to wait until the user selects and clicks OK, or
    %%% clicks Cancel
    %%% "s" is the selection.  Split and process...    
    
    if ~isempty(s)
        UserSelectedUrl=sprintf('%s/dodsC/ASGS/%s/%s/%s/%s/%s',...
            Url.Base,...
            char(catalog(s).Storms),...
            char(catalog(s).Advisories),...
            char(catalog(s).Grids),...
            char(catalog(s).Machines),...
            char(catalog(s).Instances));
        %disp(UserSelectedUrl)
        set(Handles.ServerInfoString,'String',UserSelectedUrl);
        ClearUI(FigThatCalledThisFxn);
        InstanceUrl;
    end
    set(0,'DefaultUICOntrolFontName',dfn)
    set(0,'DefaultUICOntrolFontSize',dfs)
        
    setappdata(Handles.MainFigure,'Catalog',TheCatalog);  

    %SetUIStatusMessage('Done.')
    
end

%%  OpenDataConnections
%%% OpenDataConnections
%%% OpenDataConnections
function Connections=OpenDataConnections(Url)
  
    global TheGrids Debug 
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    msg='Opening Remote OPeNDAP connections ...\n';
    SetUIStatusMessage(msg)
    
    fig=findobj(0,'Tag','MainVizAppFigure');
    TempDataLocation=getappdata(fig,'TempDataLocation');
    SSVizOpts=getappdata(fig,'SSVizOpts');

    FileNetcdfVariableNames={}; 
    FilesToOpen={};              
    VariableDisplayNames={};     
    VariableNames={};
    VariableTypes={};
    VariableUnits={};
    VariableUnitsFac={};

    % read the variable list, which is actually an excel spreadsheet
    % to make it easier to edit.  The first row is the variable names
    % in this function, declared above as empty cells.
    ff='AdcircVizVariableList.xls';
    sheet=SSVizOpts.VariablesTable;
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
    SetUIStatusMessage('Opening Network OPeNDAP connections ...\n')
    
    Connections.EnsembleNames=Url.Ens;
    Connections.VariableNames=VariableNames;
    Connections.VariableDisplayNames=VariableDisplayNames;
    Connections.VariableUnitsFac=VariableUnitsFac;
    Connections.VariableTypes=VariableTypes;
    
    
    if SSVizOpts.UseNcml
        if Debug,fprintf('SSV++   Attempting to use NCML files on server.\n');end
        i=1;
        TopTextUrl= [Url.FullFileServer '/' Url.Ens{i} '/' SSVizOpts.NcmlDefaultFileName];
        [~,status]=urlread(TopTextUrl);
        if isempty(status)
            SetUIStatusMessage('Could not connect to an ncml file. This is terminal.\n')
            ME = MException('CheckForNcml:NotPresent', ...
                ['Could not connect to an ncml file. ',...
                TopTextUrl]);
            throw(ME);
        end
        
        % ncml file exists on the other end!!
        TopDodsCUrl= [Url.FullDodsC '/' Url.Ens{i} '/' SSVizOpts.NcmlDefaultFileName];
        
    else
    
        % get run.properties file from first ens.
        i=1;
        TopTextUrl= [Url.FullFileServer '/' Url.Ens{i}];
        RPurl=[TopTextUrl '/run.properties'];
        RPlocation=[TempDataLocation '/run.properties'];
        try
            SetUIStatusMessage(['* Connecting to ' Url.Ens{i} ' run.properties file ... \n'])
            urlwrite(RPurl,RPlocation);
            RunProperties=LoadRunProperties(RPlocation);
            if DeleteTempFiles
                delete(RPlocation) %#ok<UNRCH>
            end
        catch ME
            SetUIStatusMessage(['Could not connect to ' Url.Ens{i} ' run.properties file. This is terminal.\n'])
            throw(ME);
        end
        
        SetUIStatusMessage(['* Successfully retrieved ' Url.Ens{i} ' run.properties file. \n'])
        
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
            f22Location=[TempDataLocation '/fort.22'];
            Connections.Tracks{i}='';
            try
                SetUIStatusMessage('* Connecting to fort.22 file\n')
                urlwrite(f22url,f22Location);
                temp=read_adcirc_nws19(f22Location);
                Connections.Tracks{i}=temp;
                if DeleteTempFiles
                    delete(f22Location) %#ok<UNRCH>
                end
            catch ME
                SetUIStatusMessage('* Could not open remote fort.22 file. \n')
            end
            
            SetUIStatusMessage(sprintf('Successfully retrieved %s forecast links ...\n',Url.Ens{i}))
        end
        
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
             
    SetUIStatusMessage('Done.\n')
    
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

%%  GetDataObject
%%% GetDataObject
%%% GetDataObject
function Connections=GetDataObject(Connections,EnsIndex,VarIndex,TimIndex) 

   global Debug 
   if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

   v=Connections.members{EnsIndex,VarIndex}.FileNetcdfVariableName;
   if ~iscell(v)
       v={v};
   end
   if length(v)==2
       % this is a vector field
       vstr=sprintf('%s,%s',v{1},v{2});
   else
       vstr=char(v);
   end
   
   str=sprintf('* Getting %s for ens=%s ',vstr,Connections.EnsembleNames{EnsIndex});

   fac=Connections.VariableUnitsFac{VarIndex};
   h=Connections.members{EnsIndex,VarIndex}.NcTBHandle;
   
%    if isempty(h)
%        % connection was not made.  Disable the variable and return
%    end
   
   MandN=h.size(v{1});
   
   if ~exist('TimIndex','var')
       TimIndex=1;
   else
       str=[str ' at time level ' int2str(TimIndex) ' ... \n'];
   end  % first time level if TimIndex not passed in
   SetUIStatusMessage(str);

   if ~isfield(Connections.members{EnsIndex,VarIndex},'TheData')

      if length(MandN)>1  && ~any(MandN==1)  % must be a time-dependent var...
          %disp(' ')
          m=MandN(2);n=MandN(1);
          hh=h.geovariable(v{1});
          temp=hh.data(TimIndex,:);
          temp=temp';
          if length(v)==2
              hh=h.geovariable(v{2});
              temp2=hh.data(TimIndex,:);
              temp2=temp2';
              inan=abs(temp)<eps & abs(temp2)<eps;
              temp=temp+sqrt(-1)*temp2;
              temp(inan)=NaN;
          end
          if isfield(Connections.members{EnsIndex,VarIndex},'TheData')
              TheData=Connections.members{EnsIndex,VarIndex}.TheData;
          else
              TheData=temp*fac;
          end
          
      else
          m=max(MandN);n=1;
          TheData=h.data(v{1})*fac;
      end
      TheData=cast(TheData(:),'double');  % just in case  ...
      Connections.members{EnsIndex,VarIndex}.TheData{1}=TheData;
      
   else
       
      % Hopefully, this is a time-dependent var that just needs
      % adding/inserting into
     
      hh=h.geovariable(v{1});
      temp=hh.data(TimIndex,:);
      temp=temp';
      if length(v)==2
          hh=h.geovariable(v{2});
          temp2=hh.data(TimIndex,:);
          temp2=temp2';
          inan=abs(temp)<eps & abs(temp2)<eps;
          temp=temp+sqrt(-1)*temp2;
          temp(inan)=NaN;
      end
      Connections.members{EnsIndex,VarIndex}.TheData{TimIndex}=temp*fac;
   end
   
   SetUIStatusMessage('* Got it.\n\n')

end

%%  InstanceUrl
%%% InstanceUrl
%%% InstanceUrl
function InstanceUrl(varargin)

   global TheGrids Connections Debug
   if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
   
   SetUIStatusMessage('Getting data objects from opendap server ...')
   
   if nargin==0
       FigThatCalledThisFxn=findobj(0,'Tag','MainVizAppFigure');
       Handles=get(FigThatCalledThisFxn,'UserData');
       hObj=Handles.ServerInfoString;

   else
       hObj=varargin{1};
       %event=varargin{2};
       FigThatCalledThisFxn=gcbf;
       Handles=get(FigThatCalledThisFxn,'UserData');
   end

   SSVizOpts=getappdata(FigThatCalledThisFxn,'SSVizOpts');
   TempDataLocation=getappdata(FigThatCalledThisFxn,'TempDataLocation');

   url=get(hObj,'String');
   
   temp = textscan(url, '%s','Delimiter','/','MultipleDelimsAsOne',1);
   urlparts = temp{1};
   % reconstruct base thredds url
   Url.Base=[urlparts{1} '//' urlparts{2} '/' urlparts{3}];
   ThisStorm=urlparts{6};
   ThisAdv=urlparts{7};
   ThisGrid=urlparts{8};
   ThisMachine=urlparts{9};
   ThisInstance=urlparts{10};
   
   CatalogName=SSVizOpts.CatalogName;
   CatalogEntryPoint=SSVizOpts.CatalogEntryPoint;
   
   TheCatalog=GetCatalogFromServer(Url.Base,CatalogEntryPoint,CatalogName,TempDataLocation);
      
   f=fields(TheCatalog.Catalog);
   for i=1:length(f)
       s=sprintf('%s=[TheCatalog.Catalog.%s]'';',f{i},f{i});
       eval(s);
   end
   
   idx1=strcmp(Storms,ThisStorm);
   idx2=strcmp(Advisories,ThisAdv);
   idx3=strcmp(Grids,ThisGrid);
   idx4=strcmp(Machines,ThisMachine);
   idx5=strcmp(Instances,ThisInstance);
%   idx=find(all([idx1 idx2 idx3 idx4 idx5 idx_ens],2));
   idx=find(all([idx1 idx2 idx3 idx4 idx5],2));
   if isempty(idx)
       SetUIStatusMessage('Url not found in catalog.\n')
       disp('Url not found in catalog.');
       return
   end
   SetUIStatusMessage('Url match found in catalog.\n')
   
   % parse out ensemble member names
   %idx_ens=strcmp(Advisories,ThisAdv);
   Ensembles=Ensembles(idx); %#ok<*NODEF>
   
   Url.ThisInstance=ThisInstance;
   Url.ThisStorm   =ThisStorm;
   Url.ThisAdv     =ThisAdv;
   Url.ThisGrid    =ThisGrid;
   Url.Basin       ='al';
   
   Url.FullDodsC=sprintf('%s/%s/%s/%s/%s/%s/%s',Url.Base,'/dodsC/ASGS/',ThisStorm,ThisAdv,ThisGrid,ThisMachine,ThisInstance);
   Url.FullFileServer=sprintf('%s/%s/%s/%s/%s/%s/%s',Url.Base,'/fileServer/ASGS/',ThisStorm,ThisAdv,ThisGrid,ThisMachine,ThisInstance);
   Url.Ens=Ensembles;
%   Url.Catalog=TheCatalog.Catalog;
%   Url.CatalogHash=TheCatalog.CatalogHash;
   
   UseShapeFiles=SSVizOpts.UseShapeFiles;
   Url.UseShapeFiles=UseShapeFiles;
   
   Url.Units=SSVizOpts.Units;
      
   if str2double(ThisAdv)<1000
       Url.StormType='TC';       
   else  %  otherwise itll be the nam date...
       Url.StormType='other';
   end

   Instance=ThisInstance;
   InstanceDefaults;
   setappdata(Handles.MainFigure,'DefaultBoundingBox',SSVizOpts.DefaultBoundingBox);

   % new data connections
   Connections=OpenDataConnections(Url);
   setappdata(Handles.MainFigure,'Instance',ThisInstance);

   TheGrid=TheGrids{1};
   
   EnsIndex=1;
   VarIndex=1;
   TimIndex=1;
   Connections=GetDataObject(Connections,EnsIndex,VarIndex,TimIndex);
   %setappdata(Handles.MainFigure,'Connections',Connections);

   Handles=SetEnsembleControls(Handles.MainFigure);
   set(Handles.MainFigure,'UserData',Handles);

   Handles=SetVariableControls(Handles.MainFigure,Handles.MainAxes);
   set(Handles.MainFigure,'UserData',Handles);   
   
   Handles=SetSnapshotControls(Handles.MainFigure,Handles.MainAxes);
   set(Handles.MainFigure,'UserData',Handles);
      
   % get color setting to preserve.
   axes(Handles.MainAxes);
   %cax=caxis;
   
   Handles=MakeTheAxesMap(Handles);
   ThisData=Connections.members{EnsIndex,VarIndex}.TheData{1};
   Handles=DrawTriSurf(Handles,Connections.members{EnsIndex,VarIndex},ThisData);
      
   [Min,Max]=GetMinMaxInView(TheGrid,Connections.members{EnsIndex,VarIndex}.TheData{1});
   NumberOfColors=str2double(get(Handles.NCol,'String'));
   ColorIncrement=SSVizOpts.ColorIncrement;
   SetColors(Handles,Min,Max,NumberOfColors,ColorIncrement);
  
   set(Handles.MainFigure,'UserData',Handles);
   SetTitle(Connections.RunProperties);

   UpdateUI(Handles.MainFigure);
   
   set(Handles.MainFigure,'WindowButtonDownFcn','')
   set(Handles.HydrographButton,'Value',0);
   
   setappdata(Handles.MainFigure,'Url',Url);
   setappdata(Handles.MainFigure,'TheCatalog',TheCatalog);

   SetUIStatusMessage('Done.\n')

   RendererKludge;
   
end

%%  SetNewField
%%% SetNewField
%%% SetNewField
function SetNewField(varargin)

    global TheGrids Connections Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
    
    hObj=varargin{1};
    event=varargin{2};

    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
    SSVizOpts=getappdata(FigHandle,'SSVizOpts');

    CurrentPointer=get(FigHandle,'Pointer');
    set(FigHandle,'Pointer','watch');
    
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');
    
    ButtonGroupThatCalled=get(hObj,'Tag');
    set(Handles.ScalarSnapshotButtonHandle,'Value',1);
    set(Handles.ScalarSnapshotSliderHandle,'Value',1);
    
    InundationClicked=get(Handles.WaterLevelAsInundation,'Value');
    
    EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    ScalarVariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
    VectorVariableClicked=get(get(Handles.VectorVarButtonHandlesGroup,'SelectedObject'),'string');

    EnsembleNames=Connections.EnsembleNames; 
    VariableNames=Connections.VariableNames; 
    VariableTypes=Connections.VariableTypes; 

    %Scalars= find(strcmp(VariableTypes,'Scalar'));
    %Vectors= find(strcmp(VariableTypes,'Vector'));
    
    EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames)); 
    ScalarVarIndex=find(strcmp(ScalarVariableClicked,VariableNames));
    VectorVarIndex=find(strcmp(VectorVariableClicked,VariableNames));

    if ~isfield(Connections.members{EnsIndex,ScalarVarIndex},'TheData')
        Connections=GetDataObject(Connections,EnsIndex,ScalarVarIndex);
    end
    
    if ~isempty(VectorVarIndex) && ~isfield(Connections.members{EnsIndex,VectorVarIndex},'TheData')
        Connections=GetDataObject(Connections,EnsIndex,VectorVarIndex);
    end
     
    SetUIStatusMessage(sprintf('Setting/Drawing New Field to ens=%s, var=%s...',EnsembleClicked,ScalarVariableClicked),false)

    Member=Connections.members{EnsIndex,ScalarVarIndex};
    ThisData=Member.TheData{1};
    TheGrid=TheGrids{Member.GridId};

    axes(Handles.MainAxes);
    
    if ~isreal(ThisData)
       disp('No vector plots yet. Showing speed instead.')
       ThisData=abs(ThisData);
    end
            
    if InundationClicked && ismember(Connections.VariableNames{ScalarVarIndex},{'Water Level','Max Water Level'})
       z=TheGrid.z;
       idx=z<0;
       temp=ThisData(idx)+z(idx);
       ThisData=NaN*ones(size(ThisData));
       ThisData(idx)=temp;
    end    
    
    Handles=DrawTriSurf(Handles,Member,ThisData);
    
    % only reset colors if the variable is changing
    if strcmp(ButtonGroupThatCalled,'ScalarVariableMemberRadioButtonGroup')
        
        NumberOfColors=str2double(get(Handles.NCol,'String'));
        ColorIncrement=SSVizOpts.ColorIncrement;
        [Min,Max]=GetMinMaxInView(TheGrid,ThisData);
        SetColors(Handles,Min,Max,NumberOfColors,ColorIncrement);
        
    end
    set(get(Handles.ColorBar,'ylabel'),'String',Connections.members{EnsIndex,ScalarVarIndex}.Units,'FontSize',FontSizes(1));
    drawnow
    
    % redraw track if already present in axes
    temp=strcmp(get(Handles.ShowTrackButton,'String'),'Hide Track');
    temp2=strcmp(get(Handles.ShowTrackButton,'Enable'),'on');
    if (temp && temp2)
        temp=findobj(Handles.MainAxes,'Tag','Storm_Track');
        temp2=findobj(Handles.MainAxes,'Tag','AtcfTrackShape');
        delete(temp);
        delete(temp2);
        track=Connections.Tracks{EnsIndex};
        Handles.Storm_Track=DrawTrack(track);
    end
    
    % if this is a time-dependent var, enable snapshot controls
    if  Connections.members{EnsIndex,ScalarVarIndex}.NTimes>1
        set(Handles.ScalarSnapshotButtonHandle,'Enable','on')
        set(Handles.ScalarSnapshotSliderHandle,'Enable','on')
        % set trisurf userdata to datenum time
        t=get(Handles.ScalarSnapshotSliderHandle,'UserData');
        ScalarVariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
        timesetting=get(Handles.ScalarSnapshotSliderHandle,'Value');
        set(Handles.TriSurf,'UserData',t(timesetting));
        
    else
        set(Handles.ScalarSnapshotButtonHandle,'Enable','off')
        set(Handles.ScalarSnapshotSliderHandle,'Enable','off')
    end
   
    if ~isempty(VectorVarIndex) && (Connections.members{EnsIndex,VectorVarIndex}.NTimes>1)
        set(Handles.VectorSnapshotButtonHandle,'Enable','on')
        set(Handles.VectorSnapshotSliderHandle,'Enable','on')
    else
        set(Handles.VectorSnapshotButtonHandle,'Enable','off')
        set(Handles.VectorSnapshotSliderHandle,'Enable','off')
    end
    
    set(Handles.MainFigure,'UserData',Handles);
    UpdateUI(Handles.MainFigure);
    % doesnt matter which Connection is passed in.
    SetTitle(Connections.RunProperties);  
    
    set(FigHandle,'Pointer','arrow');

    RendererKludge;

    SetUIStatusMessage('Done. \n')

    
end

%%  SetBaseMap
%%% SetBaseMap
%%% SetBaseMap
function SetBaseMap(~,~,~)

    global Debug
   if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    GoogleMapsApiKey=getappdata(Handles.MainFigure,'GoogleMapsApiKey');
    %EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    MapTypeClicked=get(get(Handles.BaseMapButtonGroup,'SelectedObject'),'string');
    
    if strcmp(MapTypeClicked,'none')
        delete(findobj(Handles.MainAxes,'Type','image','Tag','gmap'))
    else
        axes(Handles.MainAxes);
        plot_google_map('MapType',MapTypeClicked,'ApiKey',GoogleMapsApiKey,'AutoAxis',0)
    end

end

%%  DrawDepthContours
%%% DrawDepthContours
%%% DrawDepthContours
function DrawDepthContours(hObj,~)
    
    global TheGrids Debug
   if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    TheGrid=TheGrids{1};

    MainFig=get(get(get(hObj,'Parent'),'Parent'),'Parent');
    Handles=get(MainFig,'UserData');
    DisableContouring=getappdata(Handles.MainFigure,'DisableContouring');

    axes(Handles.MainAxes);
    if ~(isempty(which('contmex5')) && DisableContouring)
        DepthContours=get(hObj,'String');
        SetUIStatusMessage('** Drawing depth contours ... \n')
        if isempty(DepthContours) || strcmp(DepthContours,'none')
           delete(findobj(Handles.MainAxes,'Tag','BathyContours'))
        else
            DepthContours=sscanf(DepthContours,'%d');
            Handles.BathyContours=lcontour(TheGrid,TheGrid.z,DepthContours,'Color','k');
            for i=1:length(Handles.BathyContours)
                nz=2*ones(size(get(Handles.BathyContours(i),'XData')));
                set(Handles.BathyContours(i),'ZData',nz)
            end
            set(Handles.BathyContours,'Tag','BathyContours');
        end
        SetUIStatusMessage('Done. \n')

    else
        SetUIStatusMessage(sprintf('Contouring routine contmex5 not found for arch=%s.  Skipping depth contours.\n',computer))
    end

end

%%  MakeTheAxesMap
%%% MakeTheAxesMap
%%% MakeTheAxesMap
function Handles=MakeTheAxesMap(Handles)

    global TheGrids Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
   
    TheGrid=TheGrids{1};

    axes(Handles.MainAxes);
    
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');    
    SSVizOpts=getappdata(Handles.MainFigure,'SSVizOpts');              
        ColorBarLocation=SSVizOpts.ColorBarLocation;
        HOME=SSVizOpts.HOME;
        DisableContouring=SSVizOpts.DisableContouring;

    axx=SSVizOpts.BoundingBox;
    if isnan(axx),axx=[min(TheGrid.x) max(TheGrid.x) min(TheGrid.y) max(TheGrid.y)];end
    cla
    
    Handles.GridBoundary=plotbnd(TheGrid,'Color','k');
    set(Handles.GridBoundary,'Tag','GridBoundary');
    nz=2*ones(size(get(Handles.GridBoundary,'XData')));
    set(Handles.GridBoundary,'ZData',nz)
    axis('equal')
    axis(axx)
    grid on
    box on
    hold on
    view(2)
    
    if ~isempty(which('contmex5'))  && ~DisableContouring
        SetUIStatusMessage('** Drawing depth contours ... \n')
        DepthContours=get(Handles.DepthContours,'String');
        DepthContours=sscanf(DepthContours,'%d');
        Handles.BathyContours=lcontour(TheGrid,TheGrid.z,DepthContours,'Color','k');
        
        for i=1:length(Handles.BathyContours)
            nz=2*ones(size(get(Handles.BathyContours(i),'XData')));
            set(Handles.BathyContours(i),'ZData',nz)
        end
        set(Handles.BathyContours,'Tag','BathyContours');
    else
        SetUIStatusMessage(sprintf('Contouring routine contmex5 not found for arch=%s.  Skipping depth contours.\n',computer))
        set(Handles.DepthContours,'Enable','off')
    end
 
%     if exist([HOME '/private/gomex_wdbII.cldat'],'file')
%         load([HOME '/private/gomex_wdbII.cldat'])
%         Handles.Coastline=line(gomex_wdbII(:,1),gomex_wdbII(:,2),...
%             'Tag','Coastline');
%     end
    if exist([HOME '/private/states.cldat'],'file')
        load([HOME '/private/states.cldat'])
        Handles.States=line(states(:,1),states(:,2),'Tag','States');
    end
    
    % add colorbar
    Handles.ColorBar=colorbar('Location',ColorBarLocation);
    set(Handles.ColorBar,'FontSize',FontSizes(2))
    set(get(Handles.ColorBar,'ylabel'),'FontSize',FontSizes(1));
    set(Handles.AxisLimits,'String',num2str(axx))

    SetUIStatusMessage('** Done.\n')

    
end

%%  DrawTriSurf
%%% DrawTriSurf
%%% DrawTriSurf 
function Handles=DrawTriSurf(Handles,Member,Field)

    global TheGrids Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    TheGrid=TheGrids{Member.GridId};

    MarkerHandles=findobj(Handles.MainAxes,'Tag','NodeMarker');
    TextHandles=findobj(Handles.MainAxes,'Tag','NodeText');
    if ~isempty(MarkerHandles),delete(MarkerHandles);end
    if ~isempty(TextHandles),delete(TextHandles);end
    
    if isfield(Handles,'TriSurf')
        if ishandle(Handles.TriSurf)
            delete(Handles.TriSurf);
        end
    end
%     if isfield(Handles,'Storm_Track')
%         if ishandle(Handles.Storm_Track)
%             delete(Handles.Storm_Track);
%         end
%         delete(findobj(Handles.MainAxes,'Tag','Storm_Track'))
%         delete(findobj(Handles.MainAxes,'Tag','AtcfTrackShape'))
% 
%     end
    
    Handles.TriSurf=trisurf(TheGrid.e,TheGrid.x,TheGrid.y,...
        ones(size(TheGrid.x)),Field,'EdgeColor','none',...
        'FaceColor','interp','Tag','TriSurf');

    setappdata(Handles.TriSurf,'Field',Field);
    setappdata(Handles.TriSurf,'FieldMax',max(Field));
    setappdata(Handles.TriSurf,'FieldMin',min(Field));
    setappdata(Handles.TriSurf,'Name',[]);
%   
%     if isfield(Storm,'track')
%         if ~isempty(Storm.track)
%             Handles.Storm_Track=DrawTrack(Storm.track);
%             set(Handles.ShowTrackButton,'String','Hide Track')
%             set(Handles.ShowTrackButton,'Enable','on')
%         else
%             set(Handles.ShowTrackButton,'Enable','off')
%         end
%     end
%     if isfield(Storm,'AtcfShape')
%         Handles.AtcfTrack=PlotAtcfShapefile(Storm.AtcfShape);
%     end
    
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');
    set(get(Handles.ColorBar,'ylabel'),'String',Member.Units,'FontSize',FontSizes(1));

    drawnow 
end

%%  DrawTrack
%%% DrawTrack
%%% DrawTrack
function h=DrawTrack(track)
    
    global Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    f=findobj(0,'Tag','MainVizAppFigure');
    Handles=get(f,'UserData');
    SSVizOpts=getappdata(Handles.MainFigure,'SSVizOpts');              
        LocalTimeOffset=SSVizOpts.LocalTimeOffset;
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');

    %fmtstr=' mmmdd@HH PM';
    %fmtstr=' ddd HHPM';
    fmtstr='yyyy-mm-dd HH';
    txtcol=[0 0 0]*.8;
    lincol=[1 1 1]*0;
    
    [~,ii,~]=unique(track.hr);

    lon=track.lon2(ii);
    lat=track.lat2(ii);
    time=track.time(ii);
    
    try 
        
        h1=line(lon,lat,2*ones(size(lat)),'Marker','o','MarkerSize',6,'Color',lincol,...
            'LineWidth',2,'Tag','Storm_Track','Clipping','on');
        
        h2=NaN*ones(length(lon),1);
        for i=1:length(lon)-1
            heading=atan2((lat(i+1)-lat(i)),(lon(i+1)-lon(i)))*180/pi;
            h2(i)=text(lon(i),lat(i),2*ones(size(lat(i))),datestr(time(i)+LocalTimeOffset/24,fmtstr),...
                'FontSize',FontSizes(2),'FontWeight','bold','Color',txtcol,'Tag','Storm_Track','Clipping','on',...
                'HorizontalAlignment','left','VerticalAlignment','middle','Rotation',heading-90);
        end
        
        h2(i+1)=text(lon(i+1),lat(i+1),2*ones(size(lat(i+1))),datestr(time(i+1)+LocalTimeOffset/24,fmtstr),...
            'FontSize',FontSizes(2),'FontWeight','bold','Color',txtcol,'Tag','Storm_Track','Clipping','on',...
            'HorizontalAlignment','left','VerticalAlignment','middle','Rotation',heading-90);
        h=[h1;h2(:)];
        
    catch ME

        fprintf('Could not draw the track.\n')
    
    end
    
    drawnow
end

%%  DrawVectors
%%% DrawVectors
%%% DrawVectors
function Handles=DrawVectors(Handles,Member,Field)

    global TheGrids Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end 
    
    TheGrid=TheGrids{Member.GridId};
    
    %VectorOptions=getappdata(Handles.MainFigure,'VectorOptions');
    Stride=get(Handles.VectorOptionsStride,'String');
    Stride=str2double(Stride);
    ScaleFac=get(Handles.VectorOptionsScaleFactor,'String');
    ScaleFac=str2double(ScaleFac);
    ScaleLabel=get(Handles.VectorOptionsScaleLabel,'String');
    if isempty(ScaleLabel) || strcmp(ScaleLabel,'no scale')
        ScaleLabel='no scale';
    else
        SetUIStatusMessage('place scale on plot with a mouse button.\n')
    end
    Color=get(Handles.VectorOptionsColor,'String');
    %ScaleOrigin=get(Handles.VectorOptionsScaleOrigin,'String');

    u=real(Field);
    v=imag(Field);
    axes(Handles.MainAxes);
    Handles.Vectors=vecplot(TheGrid.x,TheGrid.y,u,v,...
        'ScaleFac',ScaleFac,...
        'Stride',Stride,...
        'Color',Color,...
        'ScaleLabel',ScaleLabel); %,...
        %'ScaleType','floating');
    
    % depending on the args to vecplot, the handle may have >1 values.
    % but the first is the handle to the drawn vectors
    nz=2*ones(size(get(Handles.Vectors(1),'XData')));
    set(Handles.Vectors(1),'ZData',nz);
    setappdata(Handles.Vectors(1),'Field',Field);
    
    drawnow
    
end

%%  RedrawVectors
%%% RedrawVectors
%%% RedrawVectors
function RedrawVectors(varargin)

    global Connections Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
   
    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
    
    EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    ScalarVariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
    VectorVariableClicked=get(get(Handles.VectorVarButtonHandlesGroup,'SelectedObject'),'string');

    EnsembleNames=Connections.EnsembleNames; 
    VariableNames=Connections.VariableNames; 
    VariableTypes=Connections.VariableTypes; 
    
    EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames)); 
    ScalarVarIndex=find(strcmp(ScalarVariableClicked,VariableNames));
    VectorVarIndex=find(strcmp(VectorVariableClicked,VariableNames));

    % Delete the current vector set
    if isfield(Handles,'Vectors')
        if ishandle(Handles.Vectors)
            % get data to redraw before deleting the vector object
            Field=getappdata(Handles.Vectors(1),'Field');
            delete(Handles.Vectors);
        else
            SetUIStatusMessage('No vectors to redraw.\n')
            return
        end
    else
        SetUIStatusMessage('No vectors to redraw.\n')
        return
    end
    
    Member=Connections.members{EnsIndex,VectorVarIndex}; %#ok<FNDSB>
    
    %if ~isfield(Handles,'Vectors'),return,end
    %if ~ishandle(Handles.Vectors(1)),return,end
    
    Handles=DrawVectors(Handles,Member,Field);
    set(Handles.MainFigure,'UserData',Handles);

end

%%  DeleteVectors
%%% DeleteVectors
%%% DeleteVectors
function DeleteVectors(varargin)
    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
    
    if ~isfield(Handles,'Vectors'),return,end
    if ~ishandle(Handles.Vectors(1)),return,end
    
    % Delete the current vector set
    for i=1:length(Handles.Vectors)
        if ishandle(Handles.Vectors(i))
            delete(Handles.Vectors(i));
        end
    end
    
    Handles=rmfield(Handles,'Vectors');
    set(Handles.MainFigure,'UserData',Handles);

end

%%  InitializeUI
%%% InitializeUI
%%% InitializeUI
function Handles=InitializeUI(SSVizOpts)

%%% This function sets up the gui and populates several UserData and
%%% ApplicationData properties with data needed by other functions and ui
%%% callbacks, some of which is set in other functions
%%%
%%% MainFigure : UserData contains the application handle list
%%% MainFigure : ApplicationData contains initialization parameters, etc...
%%% MainAxes   : UserData 
%%% MainAxes   : ApplicationData 

global Debug

fprintf('SSViz++ Setting up GUI ... \n')
if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

FontOffset=SSVizOpts.FontOffset;
AppName=SSVizOpts.AppName;
BoundingBox=SSVizOpts.BoundingBox;
DepthContours=SSVizOpts.DepthContours;
ColorMap=SSVizOpts.ColorMap;
UseGoogleMaps=SSVizOpts.UseGoogleMaps;
ForkAxes=SSVizOpts.ForkAxes;
HOME=SSVizOpts.HOME;
Mode=SSVizOpts.Mode;
KeepInSync=SSVizOpts.KeepScalarsAndVectorsInSync;

panelColor = get(0,'DefaultUicontrolBackgroundColor');

ratio_x=get(0,'ScreenPixelsPerInch')/72;
fs3=floor(get(0,'DefaultAxesFontSize')/ratio_x)+FontOffset;
fs2=fs3+2;
fs1=fs3+4;
fs0=fs3+6;
global Vecs
Vecs='on';

%LeftEdge=.01;

colormaps={'noaa_cmap','jet','hsv','hot','cool','gray'};
cmapidx=find(strcmp(ColorMap,colormaps));

% normalized positions of container panels depend on ForkAxes
if ~ForkAxes
    
    Handles.MainFigure=figure(...
        'Units','normalized',...
        'Color',panelColor,...
        'OuterPosition',[0.05 .2 SSVizOpts.AppWidthPercent/100 .877*SSVizOpts.AppWidthPercent/100],...
        'ToolBar','figure',...
        'DeleteFcn',@ShutDownUI,...
        'Tag','MainVizAppFigure',...
        'NumberTitle','off',...
        'Name',AppName,...
        'Resize','off');
        Handles.panHandle=pan(Handles.MainFigure); %#ok<*NASGU>
        Handles.zoomHandle=zoom(Handles.MainFigure);
        
    Positions.CenterContainerUpper      = [.50 .45 .24 .54];
    Positions.CenterContainerMiddle     = [.50 .21 .12 .23];
    Positions.CenterContainerLowerLeft  = [.50 .10 .12 .11];
    Positions.CenterContainerLowerRight = [.63 .10 .12 .11];
    Positions.FarRightContainer         = [.75 .10 .24 .79];
    Positions.LogoContainer             = [.75 .90 .24 .09];
    Positions.StatusUrlBarContainer     = [.50 .01 .49 .09];
                   
else
    
    Handles.MainFigure=figure(...
        'Units','normalized',...
        'Color',panelColor,...
        'OuterPosition',[0.52 .2 .45 .79],...
        'ToolBar','figure',...
        'DeleteFcn',@ShutDownUI,...
        'Tag','MainVizAppFigure',...
        'NumberTitle','off',...
        'Name',AppName,...
        'Resize','off');
    

    Handles.MainFigureSub=figure(...  % this contains the drawing axes if forked
        'Units','normalized',...
        'Color',panelColor,...
        'OuterPosition',[0.05 .2 .9 .8],...
        'ToolBar','figure',...
        'DeleteFcn','',...
        'Tag','MainVizAppFigureSub',...
        'NumberTitle','off',...
        'Name',AppName,...
        'CloseRequestFcn','');
    
    Handles.panHandle=pan(Handles.MainFigureSub);
    Handles.zoomHandle=zoom(Handles.MainFigureSub);
    
    Positions.CenterContainerUpper       = [.01 .45 .48 .54];
    Positions.CenterContainerMiddle      = [.01 .21 .48 .23];
    Positions.CenterContainerLowerLeft   = [.01 .10 .48 .11];
    Positions.CenterContainerLowerRight  = [.01 .10 .48 .11];
    Positions.FarRightContainer          = [.50 .10 .48 .79];
    Positions.LogoContainer              = [.50 .90 .48 .09];
    Positions.StatusUrlBarContainer      = [.01 .01 .98 .09];
    
end

Handles=SetPanZoomFxns(Handles);

% 
% set(Handles.panHandle,'ActionPostCallback',@RecordAxisLimits);
% set(Handles.zoomHandle,'ActionPostCallback',@RecordAxisLimits);

setappdata(Handles.MainFigure,'FontSizes',[fs0 fs1 fs2 fs3]);

%% containers for figure content
%%%%%%%%
% StatusUrlBar Container
% StatusUrlBar Container
%%%%%%%%
StatusUrlBarContainer = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','etchedin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'Position',Positions.StatusUrlBarContainer);

%%%%%%%%
% MainAxes Container
% MainAxes Container
%%%%%%%%
if ~ForkAxes
    MainAxesPanel = uipanel(...
        'Parent',Handles.MainFigure,...
        'BorderType','etchedin',...
        'BackgroundColor',panelColor,...
        'Units','normalized',...
        'Position',[.01 .01 .49 .98]);
else
    MainAxesPanel = uipanel(...
        'Parent',Handles.MainFigureSub,...
        'BorderType','etchedin',...
        'BackgroundColor',panelColor,...
        'Units','normalized',...
        'Position',[.01 .01 .98 .98]);
end

%%%%%%%%
% Center Container Upper
% Center Container Upper
%%%%%%%%
Handles.CenterContainerUpper = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','etchedin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'HitTest','off',...
    'Position',Positions.CenterContainerUpper);

%%%%%%%%
% Center Container Middle
% Center Container Middle
%%%%%%%%
Handles.CenterContainerMiddle = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','beveledin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'Title','Background Maps',...
    'FontSize',fs0,...
    'HitTest','off',...
    'Position',Positions.CenterContainerMiddle);

%%%%%%%%
% Center Container Lower Left
% Center Container Lower Left
%%%%%%%%
Handles.CenterContainerLowerLeft = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','beveledin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'Title','Print',...
    'FontSize',fs0,...
    'HitTest','off',...
    'Position',Positions.CenterContainerLowerLeft);

%%%%%%%%
% Center Container Lower Right
% Center Container Lower Right
%%%%%%%%
Handles.CenterContainerLowerRight = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','beveledin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'Title','ShapeFiles',...
    'FontSize',fs0,...
    'HitTest','off',...
    'Position',Positions.CenterContainerLowerRight);

%%%%%%%%
% FarRight Containers 
% FarRight Containers 
%%%%%%%%

LogoContainer = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','etchedin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'Visible','off',...
    'Position',Positions.LogoContainer);

FarRightContainer = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','etchedin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'Position',Positions.FarRightContainer);

Handles.InformationPanel = uipanel(...
    'Parent',FarRightContainer,...
    'Title','Information',...
    'BackgroundColor',panelColor,...
    'FontSize',fs0,...
    'bordertype','etchedin',...
    'Position',[.01 .60 .98 .39]);

Handles.VectorOptionsPanel = uipanel(...
    'Parent',FarRightContainer,...
    'Title','Vector Options',...
    'BackgroundColor',panelColor,...
    'FontSize',fs0,...
    'bordertype','etchedin',...
    'Visible','off',...
    'Position',[.01 .60 .98 .39]);

Handles.ControlPanel = uipanel(...
    'Parent',FarRightContainer,...
    'Title','Controls',...
    'BackgroundColor',panelColor,...
    'FontSize',fs0,...
    'bordertype','etchedin',...
    'Visible','off',...
    'Position',[.01 .01 .98 .58]);

% Place Dev Team Logos
 
h=axes('Parent',LogoContainer,'Position',[0.20 0.01 .25 .898]);
im=imread([HOME '/private/RENCI-Logo.tiff']);
axes(h)
image(im(:,:,1:3))
axis off
set(h,'HandleVisibility','off');

h=axes('Parent',LogoContainer,'Position',[0.575 0.01 .36 .898]); 
im=imread([HOME '/private/unc_ims_logo.jpeg']);
axes(h)
image(im)
axis off
set(h,'HandleVisibility','off');
set(LogoContainer,'Visible','on')

%%
%%%%%%%%
% Container Contents
% Container Contents
%%%%%%%%

% MainAxes
Handles.MainAxes=axes(...
    'Parent',MainAxesPanel,...
    'Units','normalized',...
    'Position',[.05 .05 .9 .9],...
    'Box','on',...
    'FontSize',fs0,...
    'Tag','StormSurgeVizMainAxes','Layer','top');


StatusUrlBarContainerContainerContents;
ControlPanelContainerContents;
VectorOptionsPanelContainerContents;
InformationPanelContainerContents;
GraphicOutputControlContainerContents;
BackgroundMapsContainerContents;

%%% only nested functions below here...

%%  StatusUrlBarContainerContainerContents
%%% StatusUrlBarContainerContainerContents
%%% StatusUrlBarContainerContainerContents

    function StatusUrlBarContainerContainerContents
        
        % StatusBar
        % StatusBar
        % StatusBar
        uicontrol(...
            'Parent',StatusUrlBarContainer,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .55 .09 .44],...
            'HorizontalAlignment','right',...
            'FontSize',fs1,...
            'String','Status :');
        Handles.StatusBar=uicontrol(...
            'Parent',StatusUrlBarContainer,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.11 .55 .77 .40],...
            'HorizontalAlignment','left',...
            'BackGroundColor','w',...
            'Tag','StatusBar',...
            'FontSize',fs2,...
            'String','Initializing UI ...');
        
        % UserEnteredText Box
        % UserEnteredText Box
        % UserEnteredText Box
        Handles.UserEnteredText=uicontrol(...
            'Parent',StatusUrlBarContainer,...
            'Style','edit',...
            'Units','normalized',...
            'Position',[.89 .55 .10 .40],...
            'HorizontalAlignment','center',...
            'BackGroundColor','w',...
            'Tag','UserEnteredText',...
            'FontSize',fs2,...
            'String','');
        %    'Enable','Inactive',...
        %    'Min',0,'Max',3,...
        % ServerBar
        % ServerBar
        % ServerBar
        uicontrol(...
            'Parent',StatusUrlBarContainer,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .01 .09 .44],...
            'HorizontalAlignment','right',...
            'Tag','ServerInfo',...
            'FontSize',fs1,...
            'String','URL :');
        Handles.ServerInfoString=uicontrol(...
            'Parent',StatusUrlBarContainer,...
            'Style','edit',...
            'Units','normalized',...
            'Position',[.11 .01 .88 .48],...
            'HorizontalAlignment','left',...
            'BackGroundColor','w',...
            'Tag','ServerInfoString',...
            'FontSize',fs2,...
            'String',{'<>'},...
            'CallBack',@InstanceUrl);
        
        %    'BackGroundColor','w',...
        %    'HorizontalAlignment','left',...
       
    end

 %%  Graphic Output Control Container Contents
 %%% Graphic Output Control Container Contents
 %%% Graphic Output Control Container Contents
 
    function GraphicOutputControlContainerContents
        
        printobj={'Current Axes';'Current GUI'};
        Handles.GraphicOutputHandlesGroup = uibuttongroup(...
            'Parent',Handles.CenterContainerLowerLeft,...
            'BorderType','etchedin',...
            'FontSize',fs2,...
            'BackGroundColor',panelColor,...
            'Position',[.01 0.1 .96 0.8],...
            'Tag','GraphicOutputHandlesGroup',...
            'SelectionChangeFcn',@SetGraphicOutputType);
        
        for i=1:2
            Handles.GraphicOutputHandles(i)=uicontrol(...
                Handles.GraphicOutputHandlesGroup,...
                'Style','Radiobutton',...
                'String',printobj{i},...
                'Units','normalized',...
                'FontSize',fs2,...
                'Position', [.1 1-0.47*i .9 0.42],...
                'Tag','GraphicOutputHandles');
            
            set(Handles.GraphicOutputHandles(i),'Enable','on');
        end
        
        if ForkAxes,
            set(Handles.GraphicOutputHandles(2),'Enable','off');
        end
        
        Handles.GraphicOutputPrint=uicontrol(...
            Handles.GraphicOutputHandlesGroup,...
            'Style','pushbutton',...
            'String','Print',...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.65 0.25 .3 0.5],...
            'CallBack',@GraphicOutputPrint,...
            'Enable','on',...
            'Tag','GraphicOutputPrint');
        
        %%% Shape Files
        %%% Shape Files
        %%% Shape Files
        Handles.ExportShapeFilesHandlesGroup = uibuttongroup(...
            'Parent',Handles.CenterContainerLowerRight,...
            'BorderType','etchedin',...
            'FontSize',fs2,...
            'BackGroundColor',panelColor,...
            'Position',[.01 0.1 .98 0.8],...
            'Tag','ExportShapeFilesHandlesGroup',...
            'SelectionChangeFcn',@SetGraphicOutputType);
        
        Handles.ExportShape=uicontrol(...
            Handles.ExportShapeFilesHandlesGroup,...
            'Style','pushbutton',...
            'String','Export',...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.01 0.50 .5 0.45],...
            'CallBack',@ExportShapeFile,...
            'Enable','on',...
            'Tag','ExportShapeFile');
        
     temp=uicontrol(...
            'Parent',Handles.ExportShapeFilesHandlesGroup,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .05 .49 .2],...
            'HorizontalAlignment','left',...
            'BackGroundColor','w',...
            'Tag','',...
            'FontSize',fs3,...
            'String','Shape File Name');
        
        Handles.DefaultShapeFileName=uicontrol(...
            Handles.ExportShapeFilesHandlesGroup,...
            'Style','edit',...
            'String','FileName',...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.01 0.25 .49 0.25],...
            'CallBack',@ExportShapeFile,...
            'Enable','on',...
            'Tag','DefaultShapeFileName');
        
       temp=uicontrol(...
            'Parent',Handles.ExportShapeFilesHandlesGroup,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.51 .05 .4 .2],...
            'HorizontalAlignment','left',...
            'BackGroundColor','w',...
            'Tag','',...
            'FontSize',fs3,...
            'String','Bin Centers');
        
        Handles.ShapeFileBinCenterIncrement=uicontrol(...
            Handles.ExportShapeFilesHandlesGroup,...
            'Style','edit',...
            'String','1',...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.51 0.25 .4 0.25],...
            'CallBack',@ExportShapeFile,...
            'Enable','on',...
            'Tag','ShapeFileBinCenterIncrement');
        
        if ~getappdata(Handles.MainFigure,'CanOutputShapeFiles')
            set([Handles.ExportShape Handles.ExportShapeFileName],'Enable','off')
        end
    
    end

%%  Background Maps Container Contents
%%% Background Maps Container Contents
%%% Background Maps Container Contents

    function BackgroundMapsContainerContents
        
        %%% UpdateUI
        %%% UpdateUI
        %%% UpdateUI
        % Handles.UpdateUIButton=uicontrol(...
        %     'Parent',Handles.CenterContainerLower,...
        %     'Style','Pushbutton',...
        %     'String', 'Update UI Contents',...
        %     'Units','normalized',...
        %     'BackGroundColor','w',...
        %     'FontSize',fs0,...
        %     'Position', [.01 .01 Width .1],...
        %     'Tag','UpdateUIButton',...
        %     'Callback', @UpdateUI);
        
        
        if ~UseGoogleMaps,return,end
        
        NVar=5;
        % dy=NVar*.08;
        % y=0.9-NVar*.075;
        
        Handles.BaseMapButtonGroup = uibuttongroup(...
            'Parent',Handles.CenterContainerMiddle,...
            'Title','Map Type ',...
            'FontSize',fs2,...
            'BackGroundColor',panelColor,...
            'Position',[.01 .45 .98 .52],...
            'Tag','BaseMapButtonGroup',...
            'SelectionChangeFcn',@SetBaseMap);
        
        %         dy=.9/(NVar+1);
        buttonnames={'none','roadmap','satellite','terrain','hybrid'};
        ytemp=linspace(4/5,1/5-1/10,5);
        for i=1:NVar
            Handles.BaseMapButtonHandles(i)=uicontrol(...
                'Parent',Handles.BaseMapButtonGroup,...
                'Style','Radiobutton',...
                'String',buttonnames{i},...
                'Units','normalized',...
                'Value',5,...
                'FontSize',fs2,...
                'Position', [.1 ytemp(i) .9 .15],...
                'Tag','BaseMapRadioButton');
        end
        
        uicontrol(...
            'Parent',Handles.CenterContainerMiddle,...
            'Style','text',...
            'String','Transparency',...
            'Units','normalized',...
            'BackGroundColor',panelColor,...
            'FontSize',fs2,...
            'Position', [.01 0.3 .8 .15]);
        
        Handles.TransparencySlider=uicontrol(...
            'Parent',Handles.CenterContainerMiddle,...
            'Style','Slider',...
            'Min', .1,...
            'Max',.99,...
            'Value',.9,...
            'Units','normalized',...
            'BackGroundColor','w',...
            'FontSize',fs1,...
            'Position', [.01 0.2 .8 .15],...
            'Tag','TransparencySlider',...
            'Callback', @SetTransparency);
        
        %     %jShandle=findjobj(Handles.TransparencySlider);
        %     %set(jShandle,'AdjustmentValueChangedCallback',@SetTransparency)
        
        uicontrol(...
            'Parent',Handles.CenterContainerMiddle,...
            'Style', 'text',...
            'String', 'Figure Renderer',...
            'Units','normalized',...
            'BackGroundColor',panelColor,...
            'FontSize',fs2,...
            'Position', [.01 .13 .8 .1]);
        
        % get the current renderer setting
        list={'painter','zbuffer','OpenGL'};
        curren=get(gcf,'Renderer');
        val=find(strcmp(curren,list));
        Handles.FigureRenderer=uicontrol(...
            'Parent',Handles.CenterContainerMiddle,...
            'Style', 'popup',...
            'String', list,...
            'Value',val,...
            'Units','normalized',...
            'BackGroundColor',panelColor,...
            'FontSize',fs2,...
            'Position', [.01 .06 .8 .1],...
            'Tag','SetFigureRendererPopup',...
            'Callback', @SetFigureRenderer);
        
    end

%%  InformationPanelContainerContents
%%% InformationPanelContainerContents
%%% InformationPanelContainerContents
        
    function InformationPanelContainerContents
             
        Width=.48;
        Height=.09;
              
        % InstanceName
        % InstanceName
        % InstanceName
        uicontrol(...
            'Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.01 .9 Width Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Instance = ');
        Handles.InstanceName=uicontrol(...
            'Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.50 .9 Width Height],...
            'FontSize',fs1,...
            'HorizontalAlignment','left',...
            'Tag','InstanceName',...
            'String','N/A');
        
        % ModelName
        % ModelName
        % ModelName
        uicontrol(...
            'Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.01 .8 Width Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Model = ');
        Handles.ModelName=uicontrol(...
            'Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.50 .8 Width Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','ModelName',...
            'String','N/A');
        
        % StormNumberName
        % StormNumberName
        % StormNumberName
        uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .7 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Storm Number/Name = ');
        Handles.StormNumberName=...
            uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.50 .7 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','StormNumberName',...
            'String','N/A');
        
        % AdvisoryNumber
        % AdvisoryNumber
        % AdvisoryNumber
        uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.01 .6 Width Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Advisory Number = ');
        Handles.AdvisoryNumber=...
            uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.50 .6 Width Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','AdvisoryNumber',...
            'String','N/A');
        
        % StormSurgeGridName
        % StormSurgeGridName
        % StormSurgeGridName
        uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .5 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Model Grid = ');
        Handles.ModelGridName=...
            uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.50 .5 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','ModelGridName',...
            'String','N/A');
        
       Handles.ModelGridNums=...
            uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.50 .32 Width Height*1.9],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','ModelGridNums',...
            'String','N/A');
        
        % UnitsString
        % UnitsString
        % UnitsString
        uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .21 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Units = ');
        Handles.UnitsString=...
            uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.50 .21 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','UnitsString',...
            'String','N/A');
        
        % TimeOffsetString
        % TimeOffsetString
        % TimeOffsetString
        uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .11 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Time Offset from UTC = ');
        Handles.TimeOffsetString=...
            uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.50 .11 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','TimeOffsetString',...
            'String','0');

        % ShowCatalogToggleButton
        % ShowCatalogToggleButton
        % ShowCatalogToggleButton
        if strcmp(Mode,'Network')
            Handles.ShowCatalogToggleButton=uicontrol(...
                'Parent',Handles.InformationPanel,...
                'Style','pushbutton',...
                'Units','normalized',...
                'Position',[.15 .01 .35 .1],...
                'Tag','ShowCatalogToggleButton',...
                'FontSize',fs1,...
                'String','Show Catalog',...
                'CallBack',@DisplayCatalog);
            
            Handles.CheckForCatalogUpdate=uicontrol(...
                'Parent',Handles.InformationPanel,...
                'Style','pushbutton',...
                'Units','normalized',...
                'Position',[.55 .01 .45 .1],...
                'Tag','CheckForCatalogUpdate',...
                'FontSize',fs1,...
                'String','CheckForUpdates',...
                'CallBack',@CheckForUpdateFromTimer);
            
        else
            Handles.ShowCatalogToggleButton=uicontrol(...
                'Parent',Handles.InformationPanel,...
                'Style','pushbutton',...
                'Units','normalized',...
                'Position',[.25 .01 .50 .1],...
                'Tag','ShowCatalogToggleButton',...
                'FontSize',fs1,...
                'Enable','on',...
                'String','Browse File System',...
                'CallBack',@BrowseFileSystem);
        end
        
        
        % Handles.Field_Maximum=...
        %     uicontrol('Parent',Handles.InformationPanel,...
        %     'Style','text',...
        %     'Units','normalized',...
        %     'Position',[LeftEdge .4 Width Height],...
        %     'Tag','Field_Maximum',...
        %     'HorizontalAlignment','left',...
        %     'String','Maximum = 0');
        %
        % Handles.Field_Minimum=...
        %     uicontrol('Parent',Handles.InformationPanel,...
        %     'Style','text',...
        %     'Units','normalized',...
        %     'Position',[LeftEdge .3 Width Height],...
        %     'HorizontalAlignment','left',...
        %     'Tag','Field_Minimum',...
        %     'String','Minimum = 0');
        
        %              Handles.ModelInitTime=...
        %                  uicontrol('Parent',Handles.InformationPanel,...
        %                     'Style','text',...
        %                     'Units','normalized',...
        %                     'Position',[LeftEdge .2 Width Height],...
        %                     'HorizontalAlignment','left',...
        %                     'Tag','ModelInitTime',...
        %                     'String',sprintf('Model Init = NaN'))
        
        % ForecastStartTime
        % ForecastStartTime
        % ForecastStartTime
        % % uicontrol('Parent',Handles.InformationPanel,...
        % %     'Style','text',...
        % %     'Units','normalized',...
        % %     'Position',[.01 .11 Width Height],...
        % %     'BackGroundColor','w',...
        % %     'FontSize',fs2,...
        % %     'HorizontalAlignment','right',...
        % %     'String',sprintf('Forecast Start = '));
        % % Handles.ForecastStartTime=...
        % %     uicontrol('Parent',Handles.InformationPanel,...
        % %     'Style','text',...
        % %     'Units','normalized',...
        % %     'Position',[.50 .11 Width Height],...
        % %     'BackGroundColor','w',...
        % %     'FontSize',fs2,...
        % %     'HorizontalAlignment','left',...
        % %     'Tag','ForecastStartTime',...
        % %     'String','NaN');
        
        % ForecastEndTime
        % ForecastEndTime
        % ForecastEndTime
        % % uicontrol('Parent',Handles.InformationPanel,...
        % %     'Style','text',...
        % %     'Units','normalized',...
        % %     'FontSize',fs2,...
        % %     'BackGroundColor','w',...
        % %     'Position',[.01 .01 Width Height],...
        % %     'HorizontalAlignment','right',...
        % %     'String','Forecast End   = ');
        % % Handles.ForecastEndTime=...
        % %     uicontrol('Parent',Handles.InformationPanel,...
        % %     'Style','text',...
        % %     'Units','normalized',...
        % %     'FontSize',fs2,...
        % %     'BackGroundColor','w',...
        % %     'Position',[.50 .01 Width Height],...
        % %     'HorizontalAlignment','left',...
        % %     'Tag','ForecastEndTime',...
        % %     'String','NaN');
        
    end

%%  ControlPanelContainerContents
%%% ControlPanelContainerContents
%%% ControlPanelContainerContents

    function ControlPanelContainerContents
        
        Width=.48;
        Height=.07;
        
        % ColormapSetter
        % ColormapSetter
        % ColormapSetter
        uicontrol('Parent',Handles.ControlPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .9 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Set Colormap : ');
        
        Handles.ColormapSetter=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style', 'popup',...
            'String', colormaps,...
            'Value',cmapidx,...
            'Units','normalized',...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'Position', [.5 .88 Width/2 Height],...
            'Tag','ColormapSetter',...
            'Callback', @SetColorMap);
        
        Handles.FlipCMap=...
            uicontrol('Parent',Handles.ControlPanel,...
            'Style','checkbox',...
            'Units','normalized',...
            'Position',[.76 .90 Width/2 Height],...
            'FontSize',fs2,...
            'BackGroundColor','w',...
            'Value',0,...
            'HorizontalAlignment','left',...
            'String','Flip CMap',...
            'Tag','FlipCMap',...
            'CallBack',@SetCLims);
        
        % Number of Colors
        % Number of Colors
        % Number of Colors
        uicontrol('Parent',Handles.ControlPanel,...
            'Style','text',...
            'Units','normalized',...
            'FontSize',fs2,...
            'BackGroundColor','w',...
            'Position',[.01 .8 Width Height],...
            'HorizontalAlignment','right',...
            'String','Number of Colors : ');
        Handles.NCol=...
            uicontrol('Parent',Handles.ControlPanel,...
            'Style','edit',...
            'Units','normalized',...
            'Position',[.5 .8 Width/2 Height],...
            'FontSize',fs2,...
            'BackGroundColor','w',...
            'String','32',...
            'HorizontalAlignment','left',...
            'Tag','NCol',...
            'CallBack',@SetCLims);
        
        
        % Color Minimum
        % Color Minimum
        % Color Minimum
        uicontrol('Parent',Handles.ControlPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'Position',[.01 .7 Width Height],...
            'String','Color Minimum : ');
        Handles.CMin=...
            uicontrol('Parent',Handles.ControlPanel,...
            'Style','edit',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'Position',[.5 .7 Width/2 Height],...
            'HorizontalAlignment','left',...
            'String','0',...
            'Tag','CMin',...
            'CallBack',@SetCLims);
        
        % Color Maximum
        % Color Maximum
        % Color Maximum
        uicontrol('Parent',Handles.ControlPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'Position',[.01 .6 Width Height],...
            'String','Color Maximum : ');
        Handles.CMax=...
            uicontrol('Parent',Handles.ControlPanel,...
            'Style','edit',...
            'Units','normalized',...
            'Position',[.5 .6 Width/2 Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'String','1',...
            'Tag','CMax',...
            'CallBack',@SetCLims);
        
        % DepthContours
        % DepthContours
        % DepthContours
        uicontrol('Parent',Handles.ControlPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .5 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Depth Contours : ');
        Handles.DepthContours=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style', 'edit',...
            'String', DepthContours,...
            'Units','normalized',...
            'BackGroundColor','w',...
            'HorizontalAlignment','left',...
            'FontSize',fs2,...
            'Position', [.5 .5 Width Height],...
            'Tag','DepthContours',...
            'Callback', @DrawDepthContours);
        
        % AxisLimits
        % AxisLimits
        % AxisLimits
        uicontrol('Parent',Handles.ControlPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .4 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Axis Limits : ');
        Handles.AxisLimits=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style', 'edit',...
            'String',num2str(BoundingBox),...
            'Units','normalized',...
            'BackGroundColor','w',...
            'HorizontalAlignment','left',...
            'FontSize',fs2,...
            'Enable','off',...
            'Position', [.5 .4 Width Height],...
            'Tag','AxisLimits');
        
        
        % ShowMaximum
        % ShowMaximum
        % ShowMaximum
        Handles.ShowMaxButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','pushbutton',...
            'String', {'Show Maximum in View'},...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.01 .32 Width Height],...
            'Callback', @ShowMaximum,...
            'Tag','ShowMaxButton');
        
        % ShowMapThings
        % ShowMapThings
        % ShowMapThings
        Handles.ShowMapButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','togglebutton',...
            'String', {'Show Roads/Counties'},...
            'Units','normalized',...
            'Position', [0.51 .32 Width Height],...
            'FontSize',fs2,...
            'Callback', @ShowMapThings,...
            'Tag','ShowMapThings');
        
        % ShowMinimum
        % ShowMinimum
        % ShowMinimum
        Handles.ShowMinButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','pushbutton',...
            'String', {'Show Minimum in View'},...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.01 .25 Width Height],...
            'Callback', @ShowMinimum,...
            'Tag','ShowMinButton');
        
        % FindFieldValue
        % FindFieldValue
        % FindFieldValue
        Handles.FindFieldValueButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','togglebutton',...
            'String', 'Get Field Values',...
            'Units','normalized',...
            'Position', [.51 .25 Width Height],...
            'FontSize',fs2,...
            'Callback', @FindFieldValue,...
            'Tag','FindFieldValueButton');
        
        % ShowTrack
        % ShowTrack
        % ShowTrack
        Handles.ShowTrackButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','pushbutton',...
            'String', 'Show Track',...
            'FontSize',fs2,...
            'Units','normalized',...
            'Position', [.01 .18 Width Height],...
            'Tag','ShowTrackButton',...
            'Callback', @ShowTrack);
        
        % ResetAxes
        % ResetAxes
        % ResetAxes
        Handles.ResetAxesButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','pushbutton',...
            'String', 'Reset Axes',...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.51 .18 Width Height],...
            'Tag','ResetAxesButton',...
            'Callback', @ResetAxes);
        
        % Toggle surf edge color
        % Toggle surf edge color
        % Toggle surf edge color
        Handles.ElementsToggleButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','togglebutton',...
            'String', 'Show Elements',...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.01 .11 Width Height],...
            'Tag','ElementsToggleButton',...
            'Callback', @ToggleElements);
        
        % Show Full Domain AXes Extents
        % Show Full Domain AXes Extents
        % Show Full Domain AXes Extents
        Handles.ShowFullDomainToggleButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','togglebutton',...
            'String', 'Show Full Domain',...
            'Units','normalized',...
            'Enable','off',...
            'FontSize',fs2,...
            'Position', [.51 .11 Width Height],...
            'Tag','ShowFullDomainToggleButton',...
            'Callback', @ShowFullDomain);
        
        % FindHydrograph
        % FindHydrograph
        % FindHydrograph
        Handles.HydrographButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','togglebutton',...
            'String', 'Plot Hydrographs',...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.51 .04 Width Height],...
            'Tag','HydrographButton',...
            'Callback', @FindHydrograph,...
            'Enable','on');
        
        % Water Level as Inundation
        % Water Level as Inundation
        % Water Level as Inundation
        Handles.WaterLevelAsInundation=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','togglebutton',...
            'String', {'Show Water Level As Inundation'},...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.01 .04 Width Height],...
            'Tag','WaterLevelAsInundation',...
            'Callback', @WaterLevelAsInundation);
             
        set(Handles.ControlPanel,'Visible','on');

        function WaterLevelAsInundation(~,~)
            v=get(Handles.WaterLevelAsInundation,'Value');
            if v
                set(Handles.WaterLevelAsInundation,'String','Turn Off Inundation')
            else
                set(Handles.WaterLevelAsInundation,'String','Turn On Inundation')
            end
        end
        
        
        % if ~UseShapeFiles
        %     set(Handles.ShowMapButton,'Enable','off')
        % end
    end

%%  VectorOptions panel container contents
%%% VectorOptions panel container contents
%%% VectorOptions panel container contents

    function VectorOptionsPanelContainerContents
        
        Width=.33;
        Width2=.17;
        Height=.09;
        
        tbh = findall(Handles.MainFigure,'Type','uitoolbar');
        a=imread('private/vo.png');
        tth = uitoggletool(tbh,'CData',a, 'Separator','on', 'HandleVisibility','off','Enable',Vecs);
        set(tth,'ClickedCallback',@RevealVecOpts)
        set(tth,'TooltipString','Reveal Vector Options')
        
        % Stride
        % Stride
        % Stride
        Height=.12;
        uicontrol(...
            'Parent',Handles.VectorOptionsPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.01 .87 Width Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Stride = ');
        Handles.VectorOptionsStride=uicontrol(...
            'Parent',Handles.VectorOptionsPanel,...
            'Style','edit',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.34 .87 Width2 Height],...
            'FontSize',fs1,...
            'HorizontalAlignment','left',...
            'Tag','VectorOptionsStride',...
            'String','1000');
        
        % ScaleFac
        % ScaleFac
        % ScaleFac
        uicontrol(...
            'Parent',Handles.VectorOptionsPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.01 .74 Width Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Scale Factor = ');
        Handles.VectorOptionsScaleFactor=uicontrol(...
            'Parent',Handles.VectorOptionsPanel,...
            'Style','edit',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.34 .74 Width2 Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','VectorOptionsScaleFactor',...
            'String','25');
        
        % Color
        % Color
        % Color
        uicontrol('Parent',Handles.VectorOptionsPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .61 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Color = ');
        Handles.VectorOptionsColor=...
            uicontrol('Parent',Handles.VectorOptionsPanel,...
            'Style','edit',...
            'Units','normalized',...
            'Position',[.34 .61 Width2 Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','VectorOptionsColor',...
            'String','k');
        
        % ScaleLabel
        % ScaleLabel
        % ScaleLabel
        uicontrol('Parent',Handles.VectorOptionsPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.01 .48 Width Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Scale Label = ');
        Handles.VectorOptionsScaleLabel=...
            uicontrol('Parent',Handles.VectorOptionsPanel,...
            'Style','edit',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.34 .48 Width2 Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','VectorOptionsScaleLabel',...
            'String','no scale');
        
        % ScaleOrigin
        % ScaleOrigin
        % ScaleOrigin
        uicontrol('Parent',Handles.VectorOptionsPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.01 .35 Width Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Scale Origin = ');
        Handles.VectorOptionsScaleOrigin=...
            uicontrol('Parent',Handles.VectorOptionsPanel,...
            'Style','edit',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.34 .35 Width2 Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','VectorOptionsScaleOrigin',...
            'String','NaN NaN');
        
        Handles.VectorOptionsRedrawButton=uicontrol(...
            'Parent',Handles.VectorOptionsPanel,...
            'Style','pushbutton',...
            'Units','normalized',...
            'Position',[.25 .22 .50 .1],...
            'Tag','RedrawVectorsButton',...
            'FontSize',fs1,...
            'String','(Re)Draw Vectors',...
            'CallBack',@RedrawVectors);
        
        Handles.VectorOptionsDeleteButton=uicontrol(...
            'Parent',Handles.VectorOptionsPanel,...
            'Style','pushbutton',...
            'Units','normalized',...
            'Position',[.25 .12 .50 .1],...
            'Tag','DeleteVectorsButton',...
            'FontSize',fs1,...
            'String','Delete Vectors',...
            'CallBack',@DeleteVectors);
        
%         Handles.VectorOptionsOverlayButton=uicontrol(...
%             'Parent',Handles.VectorOptionsPanel,...
%             'Style','checkbox',...
%             'Units','normalized',...
%             'Position',[.25 .02 .50 .1],...
%             'Tag','OverlayVectorsButton',...
%             'FontSize',fs1,...
%             'String','Overlay Vectors',...
%             'CallBack','');
        
        % right side interpolation options
        
        
    end
    fprintf('SSViz++    Done.\n\n')

end

%%  UpdateUI
%%% UpdateUI
%%% UpdateUI
function UpdateUI(varargin)

    global Connections Debug TheGrids
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    SetUIStatusMessage('Updating GUI ... \n')

    if nargin==1
        %disp('UpdateUI called as a function')
        FigHandle=varargin{1};     
    else
        %disp('UpdateUI called as a callback')
        %hObj=varargin{1};
        %event=varargin{2};
        FigHandle=gcbf;
    end

    Handles=get(FigHandle,'UserData');

    SSVizOpts=getappdata(FigHandle,'SSVizOpts');

    LocalTimeOffset=SSVizOpts.LocalTimeOffset;

    VariableNames=Connections.VariableNames; 
    VariableTypes=Connections.VariableTypes; 
    Scalars= find(strcmp(VariableTypes,'Scalar'));
    Vectors= find(strcmp(VariableTypes,'Vector'));
    
    % disable variable buttons according to NcTBHandle
    EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    EnsembleNames=Connections.EnsembleNames; 
    EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames)); 
    
    for i=1:length(Handles.ScalarVarButtonHandles)
        if ~isfield(Connections.members{EnsIndex,Scalars(i)},'NcTBHandle') || ... 
                isempty(Connections.members{EnsIndex,Scalars(i)}.NcTBHandle)
            set(Handles.ScalarVarButtonHandles(i),'Enable','off')
        end
    end
%     for i=1:length(Handles.ScalarVarButtonHandles)
%         if ~isempty(Connections.members{EnsIndex,Scalars(i)}.NcTBHandle)
%             set(Handles.ScalarVarButtonHandles(i),'Value',1)
%             break
%         end
%     end
    
    for i=1:length(Handles.VectorVarButtonHandles)
        if isempty(Connections.members{EnsIndex,Vectors(i)}.NcTBHandle) || ... 
                isempty(Connections.members{EnsIndex,Vectors(i)}.NcTBHandle)
            set(Handles.VectorVarButtonHandles(i),'Enable','off')
        end
    end
%     for i=1:length(Handles.VectorVarButtonHandles)
%         if ~isempty(Connections.members{EnsIndex,Vectors(i)}.NcTBHandle)
%             set(Handles.VectorVarButtonHandles(i),'Value',1)
%             break
%         end
%     end
    
   
%    ColorIncrement=getappdata(FigHandle,'ColorIncrement');
%     Field=getappdata(Handles.TriSurf,'Field');
%     %FontSizes=getappdata(Handles.MainFigure,'FontSizes');
%     
% %     set(Handles.Field_Maximum,'String',sprintf('Maximum = %f',max(Field)))
% %     set(Handles.Field_Minimum,'String',sprintf('Minimum = %f',min(Field)))
%     
%     CMax=max(Field);
%     CMax=ceil(CMax/ColorIncrement)*ColorIncrement;
%     CMin=min(Field);
%     CMin=floor(CMin/ColorIncrement)*ColorIncrement;
%     ncol=(CMax-CMin)/ColorIncrement;
%     
%     set(Handles.CMax,'String',sprintf('%f',CMax))
%     set(Handles.CMin,'String',sprintf('%f',CMin))
%     set(Handles.NCol,'String',sprintf('%d',ncol))
%     setappdata(FigHandle,'NumberOfColors',ncol);

    str=sprintf('# Elements = %d\n# Nodes    = %d',size(TheGrids{1}.e,1), size(TheGrids{1}.x,1));


    if isfield(Connections,'RunProperties')
       rp=Connections.RunProperties;
       stormnumber=GetRunProperty(rp,'stormnumber');
       stormname=GetRunProperty(rp,'stormname');
       advnumber=GetRunProperty(rp,'advisory');
       ModelGrid=GetRunProperty(rp,'ADCIRCgrid');
       ModelName=GetRunProperty(rp,'Model');
       %Instance=GetRunProperty(rp,'instance');
       Instance=getappdata(FigHandle,'Instance');
       if strcmp(stormname,'STORMNAME')
           stormname='Nam-Driven';
           stormnumber='00';
           advnumber='N/A';
       end

       set(Handles.StormNumberName,'String',sprintf('%s/%s',stormnumber,stormname));
       set(Handles.AdvisoryNumber, 'String',advnumber)
       set(Handles.ModelGridName,  'String',ModelGrid)
       set(Handles.ModelGridNums,  'String',str)
       set(Handles.ModelName,      'String',ModelName)
       set(Handles.InstanceName,   'String',Instance)

%        temp=GetRunProperty(rp,'RunStartTime');
%        yyyy=str2double(temp(1:4));
%        mm=str2double(temp(5:6));
%        dd=str2double(temp(7:8));
%        hr=str2double(temp(9:10));
%        t1=datenum(yyyy,mm,dd,hr,0,0);
%        set(Handles.ForecastStartTime,'String',sprintf('%s',datestr(t1+LocalTimeOffset/24,0)))
%        
%        temp=GetRunProperty(rp,'RunEndTime');
%        yyyy=str2double(temp(1:4));
%        mm=str2double(temp(5:6));
%        dd=str2double(temp(7:8));
%        hr=str2double(temp(9:10));
%        t2=datenum(yyyy,mm,dd,hr,0,0);
%        set(Handles.ForecastEndTime,'String',sprintf('%s',datestr(t2+LocalTimeOffset/24,0)))
    end
    

%    set(Handles.UnitsString,   'String',Units)
%    set(Handles.TimeOffsetString,   'String',LocalTimeOffset)

    if isempty(Connections.Tracks{1})  && isempty(Connections.AtcfShape)
        set(Handles.ShowTrackButton,'String','No Track to Show')
        set(Handles.ShowTrackButton,'Enable','off')
    else
        set(Handles.ShowTrackButton,'String','Show Track')
        set(Handles.ShowTrackButton,'Enable','on')
    end

    set(FigHandle,'UserData',Handles);
    SetUIStatusMessage('* Done.\n\n')
    set(Handles.MainFigure,'Pointer','arrow');

end

%%  ClearUI
%%% ClearUI
%%% ClearUI
function ClearUI(varargin)

    if nargin==1  % called as function
        FigHandle=varargin{1};     
    else  % called as callback
        %hObj=varargin{1};
        %event=varargin{2};
        FigHandle=gcbf;
    end
    Handles=get(FigHandle,'UserData');
    set(Handles.CMin,'String','0')
    set(Handles.CMax,'String','1')
    set(Handles.NCol,'String','32')
    set(Handles.InstanceName,'String','N/A')
    set(Handles.ModelName,'String','N/A')
    set(Handles.StormNumberName,'String','N/A')
    set(Handles.AdvisoryNumber,'String','N/A')
    set(Handles.ModelGridName,'String','N/A')
    %set(Handles.UnitsString,'String','N/A')
    %set(Handles.ForecastStartTime,'String','NaN')
    %set(Handles.ForecastEndTime,'String','NaN')
%     handlesToDelete={'EnsButtonHandles','VarButtonHandles',...
%                      'SnapshotButtonHandles','SnapshotSliderHandle',...
%                      'EnsButtonHandlesGroup','VarButtonHandlesGroup',...
%                      'SnapshotButtonHandlesPanel'};
%     for i=1:length(handlesToDelete)
%         h=sprintf('Handles.%s',handlesToDelete{i});
%         for j=1:length(h)
%             if ishandle(h(j))
%                 delete(h(j)); 
%             end
% 
%         end
%         Handles=rmfield(Handles,handlesToDelete{i});
%     end
%     
%     set(FigHandle,'UserData',Handles);
end

%%  ShutDownUI
%%% ShutDownUI
%%% ShutDownUI
function ShutDownUI(~,~)

    global Debug
    if Debug,fprintf('SSViz++  Function = %s\n',ThisFunctionName);end
    
    fprintf('\nSSViz++ Shutting Down StormSurgeViz GUI.\n');
   
    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    if isfield(Handles,'Timer')
        if isvalid(Handles.Timer)
            stop(Handles.Timer);
            delete(Handles.Timer);
        end
    end

    parent=get(get(Handles.MainAxes,'Parent'),'Parent');
    delete(parent)
        
    TempDataLocation=getappdata(Handles.MainFigure,'TempDataLocation');       
    if exist([TempDataLocation '/run.properties'],'file')
        delete([TempDataLocation '/run.properties'])
    end
    if exist([TempDataLocation '/fort.22'],'file')
        delete([TempDataLocation '/fort.22'])
    end
    if exist([TempDataLocation '/cat.tree'],'file')
        delete([TempDataLocation '/cat.tree'])
    end    
    
    delete(FigThatCalledThisFxn)
    
    %delete(findobj(0,'Tag','HydrographFigure'))

end

%%  RevealVecOpts
%%% RevealVecOpts
%%% RevealVecOpts
function RevealVecOpts(hObj,~)

    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
    infopanelstate=get(Handles.InformationPanel,'Visible');
    vecoptspanelstate=get(Handles.VectorOptionsPanel,'Visible');
    if strcmp(infopanelstate,'on')
        set(Handles.InformationPanel,'Visible','off');
        set(Handles.VectorOptionsPanel,'Visible','on');
        set(hObj,'TooltipString','Hide Vector Options')
    else
        set(Handles.InformationPanel,'Visible','on');
        set(Handles.VectorOptionsPanel,'Visible','off');
        set(hObj,'TooltipString','Reveal Vector Options')
    end

end

%%  SetEnsembleControls
%%% SetEnsembleControls
%%% SetEnsembleControls
function Handles=SetEnsembleControls(varargin)

    global Connections Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    SetUIStatusMessage('Setting up Ensemble controls ...\n')

    FigHandle=varargin{1};     
    Handles=get(FigHandle,'UserData');  
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');
    panelColor = get(0,'DefaultUicontrolBackgroundColor');

    % delete previously instanced controls, if they exist
    if isfield(Handles,'EnsButtonHandlesGroup')
        if ishandle(Handles.EnsButtonHandles)
            delete(Handles.EnsButtonHandles);      
        end
        Handles=rmfield(Handles,'EnsButtonHandles');
        
        if ishandle(Handles.EnsButtonHandlesGroup)
            delete(Handles.EnsButtonHandlesGroup);      
        end
        Handles=rmfield(Handles,'EnsButtonHandlesGroup');
    end
    
    EnsembleNames=Connections.EnsembleNames;
    
    % build out ensemble member controls
    NEns=length(EnsembleNames);
    dy=.45;
    
    Handles.EnsButtonHandlesGroup = uibuttongroup(...
        'Parent',Handles.CenterContainerUpper,...
        'Title','Ensemble Members',...
        'FontSize',FontSizes(2),...
        'BackGroundColor',panelColor,...
        'Position',[.01 .975-dy .48 dy],...
        'Tag','EnsembleMemberRadioButtonGroup',...
        'SelectionChangeFcn',@SetNewField);
    dy=1/10;
    for i=1:NEns
        Handles.EnsButtonHandles(i)=uicontrol(...
            Handles.EnsButtonHandlesGroup,...
            'Style','Radiobutton',...
            'String',EnsembleNames{i},...
            'Units','normalized',...
            'FontSize',FontSizes(2),...
            'Position', [.1 .975-dy*i .9 dy],...
            'Tag','EnsembleMemberRadioButton');
  
            set(Handles.EnsButtonHandles(i),'Enable','on');
    end
    set(Handles.MainFigure,'UserData',Handles);
    SetUIStatusMessage('* Done.\n\n')

end

%%  SetVariableControls
%%% SetVariableControls
%%% SetVariableControls
function Handles=SetVariableControls(varargin)
    

    global Connections Debug Vecs SSVizOpts
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    SetUIStatusMessage('Setting up Variable controls ...\n')

    FigHandle=varargin{1};     
    AxesHandle=varargin{2};  
    Handles=get(FigHandle,'UserData');
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');
    panelColor = get(0,'DefaultUicontrolBackgroundColor');
    KeepInSync=SSVizOpts.KeepScalarsAndVectorsInSync;

    VariableNames=Connections.VariableNames; 
    VariableTypes=Connections.VariableTypes; 

    % delete previously instanced controls, if they exist
    if isfield(Handles,'ScalarVarButtonHandlesGroup')
        delete(Handles.ScalarVarButtonHandles);        
        Handles=rmfield(Handles,'ScalarVarButtonHandles');
        delete(Handles.ScalarVarButtonHandlesGroup);
        Handles=rmfield(Handles,'ScalarVarButtonHandlesGroup');
    end
    if isfield(Handles,'VectorVarButtonHandlesGroup')
        delete(Handles.VectorVarButtonHandles);        
        Handles=rmfield(Handles,'VectorVarButtonHandles');
        delete(Handles.VectorVarButtonHandlesGroup);
        Handles=rmfield(Handles,'VectorVarButtonHandlesGroup');
    end
    
    Scalars= find(strcmp(VariableTypes,'Scalar'));
    Vectors= find(strcmp(VariableTypes,'Vector'));

    % build out variable member controls, scalars first
    NVar=length(Scalars);

    dy1=.45;
    Handles.ScalarVarButtonHandlesGroup = uibuttongroup(...
        'Parent',Handles.CenterContainerUpper,...
        'Title','Scalar Variables ',...
        'FontSize',FontSizes(2),...
        'BackGroundColor',panelColor,...
        'Position',[.51 .975-dy1 .48 dy1],...
        'Tag','ScalarVariableMemberRadioButtonGroup',...
        'SelectionChangeFcn',@SetNewField);
    
    dy2=1/11;
    for i=1:NVar
        Handles.ScalarVarButtonHandles(i)=uicontrol(...
            Handles.ScalarVarButtonHandlesGroup,...
            'Style','Radiobutton',...
            'String',VariableNames{Scalars(i)},...
            'Units','normalized',...
            'FontSize',FontSizes(2),...
            'Position', [.1 .975-dy2*i .9 dy2],...
            'Tag','ScalarVariableMemberRadioButton');
  
            set(Handles.ScalarVarButtonHandles(i),'Enable','on');
    end
    
    for i=1:length(Handles.ScalarVarButtonHandles)
        if isempty(Connections.members{1,Scalars(i)}.NcTBHandle)
            set(Handles.ScalarVarButtonHandles(i),'Value',0)
            %set(Handles.ScalarVarButtonHandles(i),'Value','off')
        end
    end
    for i=1:length(Handles.ScalarVarButtonHandles)
        if ~isempty(Connections.members{1,Scalars(i)}.NcTBHandle)
            set(Handles.ScalarVarButtonHandles(i),'Value',1)
            break
        end
    end
        
    % build out variable member controls, Vectors 
    NVar=length(Vectors);

    Handles.VectorVarButtonHandlesGroup = uibuttongroup(...
        'Parent',Handles.CenterContainerUpper,...
        'Title','Vector Variables',...
        'FontSize',FontSizes(2),...
        'BackGroundColor',panelColor,...
        'Position',[.51 .025 .48 dy1],...
        'Tag','VectorVariableMemberRadioButtonGroup',...
        'SelectionChangeFcn',@SetNewField);
    
    for i=1:NVar
        Handles.VectorVarButtonHandles(i)=uicontrol(...
            Handles.VectorVarButtonHandlesGroup,...
            'Style','Radiobutton',...
            'String',VariableNames{Vectors(i)},...
            'Units','normalized',...
            'FontSize',FontSizes(2),...
            'Position', [.1 .975-dy2*i .9 dy2],...
            'Tag','VectorsVariableMemberRadioButton');
  
            set(Handles.VectorVarButtonHandles(i),'Enable',Vecs);
    end
    
    for i=1:length(Handles.VectorVarButtonHandles)
        if isempty(Connections.members{1,Vectors(i)}.NcTBHandle)
            set(Handles.VectorVarButtonHandles(i),'Value',0)
            set(Handles.VectorVarButtonHandles(i),'Enable','off')
        end
    end
    for i=1:length(Handles.VectorVarButtonHandles)
        if ~isempty(Connections.members{1,Vectors(i)}.NcTBHandle)
            %set(Handles.VectorVarButtonHandles(i),'Value',1)
            break
        end
    end
   
    Handles.VectorKeepInSyncButton=uicontrol(...
        'Parent',Handles.VectorVarButtonHandlesGroup,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[.1 .24 .8 .1],...
        'Tag','OverlayVectorsButton',...
        'FontSize',FontSizes(2),...
        'String','Keep in Sync',...
        'Enable','off',...
        'Callback', @ToggleSync,...
        'Value',KeepInSync);
    
    Handles.VectorOptionsOverlayButton=uicontrol(...
        'Parent',Handles.VectorVarButtonHandlesGroup,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[.1 .12 .8 .1],...
        'Tag','OverlayVectorsButton',...
        'FontSize',FontSizes(2),...
        'String','Overlay Vectors',...
        'Enable',Vecs,...
        'CallBack','',...
        'Value',1);
    

    Handles.VectorAsScalarButton=uicontrol(...
        'Parent',Handles.VectorVarButtonHandlesGroup,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[.1 .02 .8 .1],...
        'Tag','VectorAsScalarButton',...
        'FontSize',FontSizes(2),...
        'String','Display as Speed',...
        'Enable',Vecs,...
        'CallBack','');
    
    set(Handles.MainFigure,'UserData',Handles);
    SetUIStatusMessage('* Done.\n\n')

end

%%  SetSnapshotControls
%%% SetSnapshotControls
%%% SetSnapshotControls
function Handles=SetSnapshotControls(varargin)

    global Connections Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    SetUIStatusMessage('Setting up Snapshot Controls ... \n')

    FigHandle=varargin{1};     
    AxesHandle=varargin{2};  
    Handles=get(FigHandle,'UserData');
    SSVizOpts=getappdata(FigHandle,'SSVizOpts');
    LocalTimeOffset=SSVizOpts.LocalTimeOffset;

    FontSizes=getappdata(Handles.MainFigure,'FontSizes');
        
    panelColor = get(0,'DefaultUicontrolBackgroundColor');
    DateStringFormatInput=getappdata(Handles.MainFigure,'DateStringFormatInput');
    DateStringFormatOutput=getappdata(Handles.MainFigure,'DateStringFormatOutput');

    ThreeDVars={'Water Level', 'Wind Velocity'};
    
    EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    VariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
    EnsembleNames=Connections.EnsembleNames; 
    VariableNames=Connections.VariableNames; 
    EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames)); 
    VarIndex=find(strcmp(VariableClicked,VariableNames));
   
    [a,b]=ismember(ThreeDVars,VariableNames);
    ThreeDvarsattached=false;
    for i=1:length(b)
        if ~isempty(Connections.members{EnsIndex,b(i)}.NcTBHandle)
            ThreeDvarsattached=true;
        end
    end
 
    % delete previously instanced controls, if they exist
    if isfield(Handles,'ScalarSnapshotButtonHandlePanel')
        if ishandle(Handles.ScalarSnapshotButtonHandlePanel)
            delete(Handles.ScalarSnapshotButtonHandlePanel);
        end
        Handles=rmfield(Handles,'ScalarSnapshotButtonHandle');
        Handles=rmfield(Handles,'ScalarSnapshotButtonHandlePanel');
        Handles=rmfield(Handles,'ScalarSnapshotSliderHandle');
    end
    
    if ~any(a) || ~ThreeDvarsattached
        
        set(Handles.HydrographButton,'enable','off')
        %disp('disable Find Hydrographbutton')
        snapshotlist={'Not Available'};
        m=2;
        
    else
               
        % base the times on the variables selected in the UI. 
        
        time=Connections.members{EnsIndex,b(1)}.NcTBHandle.geovariable('time');
        basedate=time.attribute('base_date');
        if isempty(basedate)
            s=time.attribute('units');
            p=strspl(s);
            basedate=datestr(datenum([p{3} ' ' p{4}],DateStringFormatInput));
        end
        timebase_datenum=datenum(basedate,DateStringFormatInput);
        t=cast(time.data(:),'double');
        snapshotlist=cell(length(t),1);
        time_datenum=time.data(:)/86400+timebase_datenum;
        for i=1:length(t)
            snapshotlist{i}=datestr(t(i)/86400+timebase_datenum+LocalTimeOffset/24,DateStringFormatOutput);
        end
        [m,~]=size(snapshotlist);
        
        % build out snapshot list controls
        
        Handles.ScalarSnapshotButtonHandlePanel = uipanel(...
            'Parent',Handles.CenterContainerUpper,...
            'Title','Scalar Snapshot List ',...
            'BorderType','etchedin',...
            'FontSize',FontSizes(2),...
            'BackGroundColor',panelColor,...
            'Position',[.01 0.2 .49 .15],...
            'Tag','ScalarSnapshotButtonGroup');
              
        Handles.VectorSnapshotButtonHandlePanel = uipanel(...
            'Parent',Handles.CenterContainerUpper,...
            'Title','Vector Snapshot List ',...
            'BorderType','etchedin',...
            'FontSize',FontSizes(2),...
            'BackGroundColor',panelColor,...
            'Position',[.01 0.02 .49 .15],...
            'Tag','VectorSnapshotButtonGroup');
        
        
        if m>0
            Handles.ScalarSnapshotButtonHandle=uicontrol(...
                Handles.ScalarSnapshotButtonHandlePanel,...
                'Style','popupmenu',...
                'String',snapshotlist,...
                'Units','normalized',...
                'FontSize',FontSizes(3),...
                'Position', [.05 .75 .9 .1],...
                'Tag','ScalarSnapshotButton',...
                'Callback',@ViewSnapshot);
            
            Handles.ScalarSnapshotSliderHandle=uicontrol(...
                Handles.ScalarSnapshotButtonHandlePanel,...
                'Style','slider',...
                'Units','normalized',...
                'FontSize',FontSizes(1),...
                'Position', [.05 0.25 .9 .1],...
                'value',1,'Min',1,...
                'Max',m,...
                'SliderStep',[1/(m-1) 1/(m-1)],...
                'Tag','ScalarSnapshotSlider',...
                'UserData',time_datenum,...
                'Callback',@ViewSnapshot);
            
            Handles.VectorSnapshotButtonHandle=uicontrol(...
                Handles.VectorSnapshotButtonHandlePanel,...
                'Style','popupmenu',...
                'String',snapshotlist,...
                'Units','normalized',...
                'FontSize',FontSizes(3),...
                'Position', [.05 .75 .9 .1],...
                'Tag','VectorSnapshotButton',...
                'Callback',@ViewSnapshot);
            
            Handles.VectorSnapshotSliderHandle=uicontrol(...
                Handles.VectorSnapshotButtonHandlePanel,...
                'Style','slider',...
                'Units','normalized',...
                'FontSize',FontSizes(1),...
                'Position', [.05 0.25 .9 .1],...
                'value',1,'Min',1,...
                'Max',m,...
                'SliderStep',[1/(m-1) 1/(m-1)],...
                'Tag','VectorSnapshotSlider',...
                'UserData',time_datenum,...
                'Callback',@ViewSnapshot); 
            
        end
        
%        if ~ThreeDvarsattached
            set(Handles.ScalarSnapshotButtonHandle,'Enable','off');
            set(Handles.ScalarSnapshotSliderHandle,'Enable','off');
            set(Handles.VectorSnapshotButtonHandle,'Enable','off');
            set(Handles.VectorSnapshotSliderHandle,'Enable','off');
%        else
%            set(Handles.ScalarSnapshotButtonHandle,'Enable','on');
%            set(Handles.ScalarSnapshotSliderHandle,'Enable','on');
%            set(Handles.VectorSnapshotButtonHandle,'Enable','on');
%            set(Handles.VectorSnapshotSliderHandle,'Enable','on');
%        end     
        
    end
    
    set(Handles.MainFigure,'UserData',Handles);
    SetUIStatusMessage('* Done.\n\n')

end
    
%%  ViewSnapshot
%%% ViewSnapshot
%%% ViewSnapshot
function ViewSnapshot(hObj,~)  

    global TheGrids Connections Debug SSVizOpts
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
    
    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
    DateStringFormatOutput=getappdata(Handles.MainFigure,'DateStringFormatOutput');

    EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    ScalarVariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
    VectorVariableClicked=get(get(Handles.VectorVarButtonHandlesGroup,'SelectedObject'),'string');
    
    % figure out what button/slider was pushed
    tag=get(hObj,'Tag');
    ScalarClicked=~isempty(strfind(tag,'Scalar'));
    VectorClicked=~isempty(strfind(tag,'Vector'));
    SliderClicked=~isempty(strfind(tag,'Slider'));
    ButtonClicked=~isempty(strfind(tag,'Button'));
    SnapshotClicked=floor(get(hObj,'Value'));

    ScalarSnapshotSliderValue=floor(get(Handles.ScalarSnapshotSliderHandle,'Value'));
    VectorSnapshotSliderValue=floor(get(Handles.VectorSnapshotSliderHandle,'Value'));
    ScalarSnapshotButtonValue=floor(get(Handles.ScalarSnapshotButtonHandle,'Value'));
    VectorSnapshotButtonValue=floor(get(Handles.VectorSnapshotButtonHandle,'Value'));
    
    if VectorClicked
        VectorSnapshotSliderValue=SnapshotClicked;
        VectorSnapshotButtonValue=SnapshotClicked;
    end
    
    if ScalarClicked
        ScalarSnapshotSliderValue=SnapshotClicked;
        ScalarSnapshotButtonValue=SnapshotClicked;
    end
    
    if SSVizOpts.KeepScalarsAndVectorsInSync
        ScalarSnapshotSliderValue=SnapshotClicked;
        VectorSnapshotSliderValue=SnapshotClicked;
        ScalarSnapshotButtonValue=SnapshotClicked;
        VectorSnapshotButtonValue=SnapshotClicked;
        ScalarClicked=true;
        VectorClicked=true;
    end
    
    ScalarClicked=ScalarClicked && strcmp(get(Handles.ScalarSnapshotButtonHandle,'Enable'),'on');
    VectorClicked=VectorClicked && strcmp(get(Handles.VectorSnapshotButtonHandle,'Enable'),'on');

    if isempty(VectorVariableClicked)
        VectorClicked=false;
        VectorSnapshotClicked=[];
    end
    
    EnsembleNames=Connections.EnsembleNames; 
    VariableNames=Connections.VariableNames; 
    
    EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames)); 
    ScalarVarIndex=find(strcmp(ScalarVariableClicked,VariableNames));
    VectorVarIndex=find(strcmp(VectorVariableClicked,VariableNames));
    
    InundationClicked=get(Handles.WaterLevelAsInundation,'Value');
    OverlayVectors=get(Handles.VectorOptionsOverlayButton,'Value');
    VectorAsScalar=get(Handles.VectorAsScalarButton,'Value');

    %s=get(Handles.ScalarSnapshotButtonHandle,'string');
    time_datenum=get(Handles.ScalarSnapshotSliderHandle,'UserData');

    SetUIStatusMessage(sprintf('date=%s',datestr(time_datenum(SnapshotClicked),DateStringFormatOutput)),false) 

    axes(Handles.MainAxes);

    % scalar
    ScalarData=[];
    if ScalarClicked
        [~,n]=size(Connections.members{EnsIndex,ScalarVarIndex}.TheData);
        if ScalarSnapshotSliderValue>n
            Connections=GetDataObject(Connections,EnsIndex,ScalarVarIndex,ScalarSnapshotSliderValue); 
        else
            % test value at EnsIndex,VarIndex,TimIndex; fill if empty        
            if isempty(Connections.members{EnsIndex,ScalarVarIndex}.TheData{ScalarSnapshotSliderValue})
                Connections=GetDataObject(Connections,EnsIndex,ScalarVarIndex,ScalarSnapshotSliderValue);
            end
        end
        ScalarData=Connections.members{EnsIndex,ScalarVarIndex}.TheData{ScalarSnapshotSliderValue};
        if InundationClicked && ismember(Connections.VariableNames{ScalarVarIndex},{'Water Level','Max Water Level'});
            z=TheGrid.z;
            idx=z<0;
            temp=ScalarData(idx)+z(idx);
            ScalarData=NaN*ones(size(ScalarData));
            ScalarData(idx)=temp;
        end
    end
    
    %vector
    VectorData=[];
    if VectorClicked
        if ~isempty(VectorVarIndex)
            [~,n]=size(Connections.members{EnsIndex,VectorVarIndex}.TheData);
            if VectorSnapshotSliderValue>n
                Connections=GetDataObject(Connections,EnsIndex,VectorVarIndex,VectorSnapshotSliderValue);
            else
                % test value at EnsIndex,VarIndex,TimIndex; fill if empty 
                if isempty(Connections.members{EnsIndex,VectorVarIndex}.TheData{VectorSnapshotSliderValue})
                    Connections=GetDataObject(Connections,EnsIndex,VectorVarIndex,VectorSnapshotSliderValue);
                end
            end
        end
        VectorData=Connections.members{EnsIndex,VectorVarIndex}.TheData{VectorSnapshotSliderValue};
        if VectorAsScalar
            VectorData=abs(VectorData);
            ScalarData=VectorData;
            VectorData=[];
        end
    end
    
    GridId=Connections.members{EnsIndex,ScalarVarIndex}.GridId;
    TheGrid=TheGrids{GridId};
      
    if ~isempty(ScalarData)
        Handles=DrawTriSurf(Handles,Connections.members{EnsIndex,ScalarVarIndex},ScalarData);
        set(Handles.TriSurf,'UserData',time_datenum(ScalarSnapshotSliderValue))
    end
    
    if ~isempty(VectorData)
    
    % overlay wind vectors
%    if ~isempty(VectorVarIndex) && OverlayVectors  && ~VectorAsScalar
%    if ~isempty(VectorVarIndex) && ~VectorAsScalar
        
%        if ~isfield(Connections.members{EnsIndex,VectorVarIndex},'TheData')
%            error('Wind Velocity TheData field should have been loaded by now.  Terminal.')
%        end
        
%         [~,n]=size(Connections.members{EnsIndex,VectorVarIndex}.TheData);
%         if VectorSnapshotClicked>n
%             Connections=GetDataObject(Connections,EnsIndex,VectorVarIndex,VectorSnapshotClicked);
%         else
%             % test value at EnsIndex,VectorVarIndex,TimIndex
%             if isempty(Connections.members{EnsIndex,VectorVarIndex}.TheData{VectorSnapshotClicked})
%                 Connections=GetDataObject(Connections,EnsIndex,VectorVarIndex,VectorSnapshotClicked);
%             end
%         end
        DeleteThisHandle=[];
        if isfield(Handles,'Vectors')
            if ishandle(Handles.Vectors)
                DeleteThisHandle=Handles.Vectors;
            end
        end
        
        Member=Connections.members{EnsIndex,VectorVarIndex};
        delete(DeleteThisHandle)  
        Handles=DrawVectors(Handles,Member,VectorData);
    end
    
    set(Handles.MainFigure,'UserData',Handles);
    setappdata(FigHandle,'Connections',Connections);
    UpdateUI(Handles.MainFigure);
    SetTitle(Connections.RunProperties);

    %SetUIStatusMessage('Done.')
    if ScalarClicked
        set(Handles.ScalarSnapshotButtonHandle,'value',ScalarSnapshotButtonValue)
        set(Handles.ScalarSnapshotSliderHandle,'value',ScalarSnapshotSliderValue)
    end
    if VectorClicked
        set(Handles.VectorSnapshotButtonHandle,'value',VectorSnapshotButtonValue)
        set(Handles.VectorSnapshotSliderHandle,'value',VectorSnapshotSliderValue)
    end
    
    RendererKludge;
   
end

%%  ToggleSync
%%% ToggleSync
%%% ToggleSync
function ToggleSync(~,~)
    global SSVizOpts
    SSVizOpts.KeepScalarsAndVectorsInSync=~SSVizOpts.KeepScalarsAndVectorsInSync;
%     if SSVizOpts.KeepScalarsAndVectorsInSync
%         disp('Vec/Scal Syncing on...')
%     else
%         disp('Vec/Scal Syncing off...')
%     end
    
end

%%  RendererKludge
%%% RendererKludge
%%% RendererKludge
function RendererKludge
    global EnableRendererKludge
    if EnableRendererKludge
        delete(findobj(0,'Tag','RendererMarkerKludge'))
        axx=axis;
        line(axx(1),axx(3),'Clipping','on','Tag','RendererMarkerKludge');
    end
end

%%  SetGraphicOutputType
%%% SetGraphicOutputType
%%% SetGraphicOutputType
function SetGraphicOutputType(hObj,~)
     SelectedType=get(get(hObj,'SelectedObject'),'String');
     SetUIStatusMessage(['Graphic Output is set to the ' SelectedType] )
end

%%  ExportShapeFile
%%% ExportShapeFile
%%% ExportShapeFile
function ExportShapeFile(~,~)  

    global TheGrids Connections Debug 

    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
    
    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
    
    ScalarSnapshotClicked=floor(get(Handles.ScalarSnapshotSliderHandle,'Value')); 

    EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    ScalarVariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
    
    EnsembleNames=Connections.EnsembleNames; 
    VariableNames=Connections.VariableNames; 
    EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames));
    ScalarVarIndex=find(strcmp(ScalarVariableClicked,VariableNames));

    GridId=Connections.members{EnsIndex,ScalarVarIndex}.GridId;
    TheGrid=TheGrids{GridId};

    OutName=get(Handles.DefaultShapeFileName,'String'); 
    if isempty(OutName)
        SetUIStatusMessage('Set ExportShapeFileName to something reasonable.... \n')
        return
    end
        
    ThisData=Connections.members{EnsIndex,ScalarVarIndex}.TheData{ScalarSnapshotClicked};
    temp=get(Handles.ShapeFileBinCenterIncrement,'String'); 
    BinCenters=sscanf(temp,'%d');
    e0=ceil(min(ThisData/BinCenters))*BinCenters;
    e1=floor(max(ThisData/BinCenters))*BinCenters;
    bin_centers=e0:BinCenters:e1;
    
    SetUIStatusMessage('Making shape file object.  Stand by ... \n')
    try 
        [SS,edges,spec]=MakeAdcircShape(TheGrid,ThisData,bin_centers,'FeatureName',VariableNames{ScalarVarIndex});
    catch ME
        SetUIStatusMessage('Error generating shapefile.  Email the current url, scalar field name, and bin settings to Brian_Blanton@Renci.Org\n')
        disp('Error generating shapefile.  Email the current url, scalar field name, and bin settings to Brian_Blanton@Renci.Org')
        throw(ME);
    end
    
    figure
    geoshow(SS,'SymbolSpec',spec)
    caxis([edges(1) edges(end)])
    colormap(jet(length(bin_centers)))
    colorbar
    title(sprintf('GeoShow view of exported Shape File in %s',strrep(OutName,'_','\_')))
    axes(Handles.MainAxes);

    shapewrite(SS,sprintf('%s.shp',OutName))
    SetUIStatusMessage(sprintf('Done. Shape File = %s/%s\n',pwd,OutName))

end

%%  GraphicOutputPrint
%%% GraphicOutputPrint
%%% GraphicOutputPrint
function GraphicOutputPrint(~,~) 

    global Connections

    %prepare for a new figure
    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');
    TempDataLocation=getappdata(Handles.MainFigure,'TempDataLocation');

    EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    ScalarVariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
    VectorVariableClicked=get(get(Handles.VectorVarButtonHandlesGroup,'SelectedObject'),'string');
    VectorAsScalar=get(Handles.VectorAsScalarButton,'Value');

    if VectorAsScalar
        VariableClicked=VectorVariableClicked;
    else
        VariableClicked=ScalarVariableClicked;
    end
      
    EnsembleNames=Connections.EnsembleNames; 
    
    SelectedType=get(get(Handles.GraphicOutputHandlesGroup,'SelectedObject'),'string');
    SelectedType=strtrim(SelectedType(end-3:end));
       
    EnsembleNames=Connections.EnsembleNames; 
    VariableNames=Connections.VariableNames; 
    EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames)); 
    VarIndex=find(strcmp(VariableClicked,VariableNames));
    
    Units=Connections.members{EnsIndex,VarIndex}.Units;    %#ok<FNDSB>
    
    list={'painter','zbuffer','OpenGL'};
    val = get(Handles.FigureRenderer,'Value');
    Renderer=lower(list{val});
    
    titlestr=get(get(Handles.MainAxes,'Title'),'String');
    if iscell(titlestr)
        titlestr=titlestr{1};
    end
    titlestr=strrep(deblank(titlestr),' ','_'); 
    titlestr=strrep(titlestr,'=','');
   
    % get colormap and limits from the user-altered axes, not the defaults! 
    axes(Handles.MainAxes);
    cmap=colormap;
    cax=caxis;
    
    if strfind(VariableClicked,'snapshot')
       SnapshotClickedID=get(Handles.SnapshotButtonHandles,'value');
       SnapshotClicked=get(Handles.SnapshotButtonHandles,'string');
       SnapshotClicked=SnapshotClicked(SnapshotClickedID,:);
       SnapshotClicked=datestr(SnapshotClicked,30);
       filenamedefault=strcat(titlestr,'_',EnsembleClicked,'_',VariableClicked,'_',SnapshotClicked,'_',SelectedType );
       SetUIStatusMessage(['Ensemble = ' EnsembleClicked ', Variable = ' VariableClicked])
       SetUIStatusMessage(['Snapshot = ' SnapshotClicked])
    else
       filenamedefault=strcat(titlestr,'_',EnsembleClicked,'_',VariableClicked,'_',SelectedType);
       SetUIStatusMessage(['Ensemble = ' EnsembleClicked ', Variable = ' VariableClicked '\n'])
    end
    
    %filename=strcat(filename,filterorder{filterindex,:});
    set(gcf,'PaperPositionMode','auto')
    % copy MainAxes into separate figure
    if strfind(SelectedType,'Axes')
        temp=figure('Visible','on');
        h1=copyobj(Handles.MainAxes,temp);
        set(h1,'Units','normalized')
        set(h1,'Position',[.1 .1 .8 .8])
        set(h1,'Box','on')
        set(h1,'FontSize',16)
        %h2=copyobj(Handles.ColorBar,temp);
        h2=colorbar;
        set(get(h2,'ylabel'),...
            'String',sprintf('%s',Units),'FontSize',FontSizes(4));
        CLim([cax(1) cax(2)])
        colormap(cmap)
        set(temp,'Renderer',Renderer)
        %close(temp);
    end
    
    filenamedefault=[TempDataLocation '/' filenamedefault];
    %    filterorder={'.png';'.pdf';'.jpg';'.tif';'.bmp'};
    printopt={'-dpng';'-dpdf';'-djpeg';'-dtiff';'-dbmp'};
    [filename, pathname, filterindex]=uiputfile(...
        {'*.png','Portable Network Graphic file (*.png)';...
        '*.pdf','Portable Document Format (*.pdf)';...
        '*.jpg','JPEG image (*.jpg)';...
        '*.tif','TIFF image (*.tif)';...
        '*.bmp','Bitmap file (*.bmp)';...
        '*.*','All Files' },'Save Image',...
        filenamedefault);
    
    Renderer=['-' Renderer];
    
    if ~(isequal(filename,0) || isequal(pathname,0) || isequal(filterindex,0))
        if strfind(SelectedType,'Axes')
            print(temp,printopt{filterindex,:},'-r200',Renderer,fullfile(pathname,filename));
        elseif strfind(SelectedType, 'GUI')
            print(Handles.MainFigure,printopt{filterindex,:},'-r200',Renderer,fullfile(pathname,filename));
        end
    else
        %disp('User Cancelled...')
    end  
      
end

%%  SetTransparency
%%% SetTransparency
%%% SetTransparency
function SetTransparency(hObj,~)

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    AlphaVal = get(hObj,'Value');
    set(Handles.TriSurf,'FaceAlpha',AlphaVal);
    % need to set renderer to OpenGL
    set(Handles.FigureRenderer,'Value',3)
    axes(Handles.MainAxes);
    parent=get(get(Handles.MainAxes,'Parent'),'Parent');
    set(parent,'Renderer','OpenGL');  
    
end

%%  SetFigureRenderer
%%% SetFigureRenderer
%%% SetFigureRenderer
function SetFigureRenderer(hObj,~) 

    list={'painter','zbuffer','OpenGL'};
    val = get(hObj,'Value');
    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    parent=get(get(Handles.MainAxes,'Parent'),'Parent');

    set(parent,'Renderer',list{val});

end

%%  ResetAxes
%%% ResetAxes
%%% ResetAxes
function ResetAxes(~,~)
    global Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    SSVizOpts=getappdata(FigThatCalledThisFxn,'SSVizOpts');

    axes(Handles.MainAxes);
    
    axx=SSVizOpts.DefaultBoundingBox;
    
    axis(axx)
    set(Handles.AxisLimits,'String',sprintf('%.2f  ',axx));
    setappdata(Handles.MainFigure,'BoundingBox',axx);

end

%%  ShowTrack
%%% ShowTrack
%%% ShowTrack
function ShowTrack(hObj,~) 

    global Connections Debug 
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
    

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
  
    CurrentPointer=get(Handles.MainFigure,'Pointer');
    set(Handles.MainFigure,'Pointer','watch');
    
    % are there tracks already on the axes? 
    temp=findobj(Handles.MainAxes,'Tag','Storm_Track');
    temp2=findobj(Handles.MainAxes,'Tag','AtcfTrackShape');
    if isempty(temp) && isempty(temp2)
        SetUIStatusMessage('Drawing Track ... \n')

        % get the current ens member
        temp=get(Handles.EnsButtonHandles,'Value');
        if length(temp)==1
            CurrentEnsMember=1;
        else
            CurrentEnsMember=find([temp{:}]);
        end
        
        if isfield(Connections,'Tracks')
            track=Connections.Tracks{CurrentEnsMember};
            if ~isempty(track)
                axes(Handles.MainAxes);
                Handles.Storm_Track=DrawTrack(track);
                set(hObj,'String','Hide Track')
            end
        end
        if isfield(Connections,'AtcfShape')
            Handles.AtcfTrack=PlotAtcfShapefile(Connections.AtcfShape);
            set(hObj,'String','Hide Track')
        end
    else
        SetUIStatusMessage('Hiding Track ... \n')
        delete(temp);
        delete(temp2);
        Handles.Storm_Track=[];
        set(FigThatCalledThisFxn,'UserData',Handles);
        set(hObj,'String','Show Track')
    end
    drawnow
    set(Handles.MainFigure,'Pointer','arrow');
    SetUIStatusMessage('Done. \n')

end

%%  ShowMapThings
%%% ShowMapThings
%%% ShowMapThings
function ShowMapThings(hObj,~) 

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    temp1=findobj(Handles.MainAxes,'Tag','SSVizShapesCounties');
    temp2=findobj(Handles.MainAxes,'Tag','SSVizShapesRoadways');
    temp3=findobj(Handles.MainAxes,'Tag','SSVizShapesStateLines');
    temp4=findobj(Handles.MainAxes,'Tag','SSVizShapesCities');
    temp=[temp1(:);temp2(:);temp3(:);temp4(:)];
    axes(Handles.MainAxes);
    
    if any([isempty(temp1)  isempty(temp2) isempty(temp3) isempty(temp4)])  % no objs found; need to draw
        SetUIStatusMessage('Loading shapes...')
        Shapes=LoadShapes;
        setappdata(Handles.MainAxes,'Shapes',Shapes);
        %SetUIStatusMessage('Done.')
        h=plotroads(Shapes.major_roads,'Color',[1 1 1]*.4,'Tag','SSVizShapesRoadways','LineWidth',2);
        h=plotcities(Shapes.cities,'Tag','SSVizShapesCities'); 
        h=plotroads(Shapes.counties,'Tag','SSVizShapesCounties'); 
        h=plotstates(Shapes.states,'Color','b','LineWidth',1,'Tag','SSVizShapesStateLines'); 
        %Shapes=getappdata(Handles.MainAxes,'Shapes');
        set(hObj,'String','Hide Roads/Counties')
    else
        if strcmp(get(temp(1),'Visible'),'off')
            set(temp,'Visible','on');
            set(hObj,'String','Hide Roads/Counties')
        else
            set(temp,'Visible','off');
            set(hObj,'String','Show Roads/Counties')
        end
    end
    
end

%%  ShowMinimum
%%% ShowMinimum
%%% ShowMinimum
function ShowMinimum(hObj,~) 

    global TheGrids Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
    
    TheGrid=TheGrids{1};

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    Field=getappdata(Handles.TriSurf,'Field');

    temp=findobj(Handles.MainAxes,'Tag','MinMarker');
    axes(Handles.MainAxes);
    if isempty(temp)
        idx=GetNodesInView(TheGrid);
        [Min,idx2]=min(Field(idx));
        idx=idx(idx2);
        line(TheGrid.x(idx),TheGrid.y(idx),1,'Marker','o','Color',[1 0 0],...
            'MarkerSize',20,'Tag','MinMarker','LineWidth',3,'Clipping','on');
        line(TheGrid.x(idx),TheGrid.y(idx),1,'Marker','x','Color',[0 1 1],...
            'MarkerSize',20,'Tag','MinMarker','Clipping','on');
        
        SetUIStatusMessage(sprintf('Minimum in view = %.2f\n',Min))
        
        set(hObj,'String','Hide Minimum')
    else
        delete(temp);
        set(hObj,'String','Show Minimum in View')
    end
    
end

%%  ShowMaximum
%%% ShowMaximum
%%% ShowMaximum
function ShowMaximum(hObj,~) 

    global TheGrids Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    TheGrid=TheGrids{1};

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    Field=getappdata(Handles.TriSurf,'Field');

    temp=findobj(Handles.MainAxes,'Tag','MaxMarker');
    if isempty(temp)
        axes(Handles.MainAxes);
        idx=GetNodesInView(TheGrid);
        [Max,idx2]=max(Field(idx));
        idx=idx(idx2);
        line(TheGrid.x(idx),TheGrid.y(idx),1,'Marker','o','Color',[0 0 1],...
            'MarkerSize',20,'Tag','MaxMarker','LineWidth',3,'Clipping','on');
        line(TheGrid.x(idx),TheGrid.y(idx),1,'Marker','x','Color',[1 1 0],...
            'MarkerSize',20,'Tag','MaxMarker','Clipping','on');
        
        SetUIStatusMessage(sprintf('Maximum in view = %.2f\n',Max))

        set(hObj,'String','Hide Maximum')
    else
        delete(temp);
        set(hObj,'String','Show Maximum in View')
    end
    
end

%%  FindFieldValue
%%% FindFieldValue
%%% FindFieldValue
function FindFieldValue(hObj,~) 

    FigToSet=gcbf;
    Handles=get(FigToSet,'UserData');
    %MarkerHandles=findobj(Handles.MainAxes,'Tag','NodeMarker');
    %TextHandles=findobj(Handles.MainAxes,'Tag','NodeText');

    if isfield(Handles,'MainFigureSub')
        FigToSet=Handles.MainFigureSub;
    end
    
    button_state=get(hObj,'Value');
    if button_state==get(hObj,'Max')
        pan off
        zoom off
        set(FigToSet,'WindowButtonDownFcn',@InterpField)
        SetUIStatusMessage('Click on map to get field value ...')
    elseif button_state==get(hObj,'Min')
        %if ~isempty(MarkerHandles),delete(MarkerHandles);end
        %if ~isempty(TextHandles),delete(TextHandles);end
        set(FigToSet,'WindowButtonDownFcn','')
        SetUIStatusMessage('Done.')
    end

end

%%  InterpField
%%% InterpField
%%% InterpField
function InterpField(hObj,~) 

    global TheGrids Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    TheGrid=TheGrids{1};

    FigThatCalledThisFxn=gcbf;
    MainVizAppFigure=findobj(FigThatCalledThisFxn,'Tag','MainVizAppFigure');
    SSVizOpts=getappdata(FigThatCalledThisFxn,'SSVizOpts');
    
    Handles=get(MainVizAppFigure,'UserData');
    cax=Handles.MainAxes; 
    xli=xlim(cax);
    yli=ylim(cax);
    dx=(xli(2)-xli(1))*0.012;
    dy=(yli(2)-yli(1))*0.02;
    Units=get(Handles.UnitsString,'String');
    Field=getappdata(Handles.TriSurf,'Field');
    %MarkerHandles=findobj(Handles.MainAxes,'Tag','NodeMarker');
    %TextHandles=findobj(Handles.MainAxes,'Tag','NodeText');
    if strcmp(get(hObj,'SelectionType'),'normal')

        %  if ~isempty(MarkerHandles),delete(MarkerHandles);end
        %  if ~isempty(TextHandles),delete(TextHandles);end
        axes(Handles.MainAxes);
        findlocation=get(Handles.MainAxes,'CurrentPoint');
        x=findlocation(1,1);
        y=findlocation(1,2);
        InView=IsInView(x,y);
        if InView
            %line(x,y,'Marker','o','Color','k','MarkerFaceColor','k','MarkerSize',5,'Tag','NodeMarker');
            % find element & interpolate scalar
            if SSVizOpts.UseStrTree && isfield(TheGrid,'strtree') && ~isempty(TheGrid.strtree)
                j=FindElementsInStrTree(TheGrid,x,y);
            else
                j=findelem(TheGrid,x,y);
            end
            if ~isnan(j)
                InterpTemp=interp_scalar(TheGrid,Field,x,y,j);
            else
                InterpTemp='OutsideofDomain';
            end
            if isnan(InterpTemp)
                text(x+dx,y-dy,2,'Dry','Color','k','Tag','NodeText','FontWeight','bold','Clipping','on')
                SetUIStatusMessage(['Selected Location (',num2str(x, '% 10.2f'),' , ',num2str(y, '% 10.2f'),') is dry'])
            elseif strcmp(InterpTemp,'OutsideofDomain')
                %text(x+dx,y-dy,'NaN','Color','k','Tag','NodeText','FontWeight','bold')
                %SetUIStatusMessage(['Selected Location (',num2str(x, '% 10.2f'),' , ',num2str(y, '% 10.2f'),') is outside of grid domain'])
                SetUIStatusMessage('Selected Location is outside of grid.')
            else
                line(x,y,2,'Marker','o','Color','k','MarkerFaceColor','k','MarkerSize',5,'Tag','NodeMarker','Clipping','on');
                text(x+dx,y-dy,2,num2str(InterpTemp,'%5.2f'),'Color','k','Tag','NodeText','FontWeight','bold','Clipping','on')
                SetUIStatusMessage(['Field Value at (',num2str(x, '% 10.2f'),' , ',num2str(y, '% 10.2f'),') is ', num2str(InterpTemp, '%5.2f'),' ',Units])
            end
        end
    end
    
end

%%  FindHydrograph
%%% FindHydrograph
%%% FindHydrograph
function FindHydrograph(hObj,~)

    global Connections

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    
    SSVizOpts=getappdata(FigThatCalledThisFxn,'SSVizOpts');
    LocalTimeOffset=SSVizOpts.LocalTimeOffset;
    
    MarkerHandles=findobj(Handles.MainAxes,'Tag','HydroNodeMarker');
    HydrographTextHandles=findobj(Handles.MainAxes,'Tag','HydrographText');
    button_state=get(hObj,'Value');
    
    FigToSet=FigThatCalledThisFxn;
    if isfield(Handles,'MainFigureSub')
        FigToSet=Handles.MainFigureSub;
    end  

    EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    VariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
    
    HyAvail=false;
        if ismember('Water Level',Connections.VariableNames)
            HyAvail=true;
        end
    if ~HyAvail
        SetUIStatusMessage('No hydrographs for this solution.');
        return
    end
    
    fac=getappdata(Handles.MainFigure,'UnitsScaleFactor');
            
    
    % make sure there is a trisurf obj to attach the callback to
    if ~isfield(Handles,'TriSurf')
        SetUIStatusMessage('No TriSurf Object found. Draw a surface first.')
        return
    end
    if ~ishandle(Handles.TriSurf)
        SetUIStatusMessage('No TriSurf Object found. Draw a surface first.')
        return
    end
    
    if button_state==get(hObj,'Max')
        pan off 
        zoom off
        set(Handles.TriSurf,'ButtonDownFcn',@PopoutHydrograph)
        set(Handles.UserEnteredText,'CallBack',@PopoutHydrograph)
        SetUIStatusMessage('Click on map to get hydrograph at nearest node or enter node number in box to right ...\n')
        set(Handles.UserEnteredText,'String','<Enter Node>')

    elseif button_state==get(hObj,'Min')
        
%         if ~isempty(MarkerHandles),delete(MarkerHandles);end
%         if ~isempty(HydrographTextHandles),delete(HydrographTextHandles);end
%         close(findobj(0,'Tag','HydrographFigure'));

        set(Handles.TriSurf,'ButtonDownFcn','')
        set(Handles.UserEnteredText,'CallBack','')
        set(Handles.UserEnteredText,'String','')
        set(Handles.panHandle,'ActionPostCallback',@RecordAxisLimits);
        set(Handles.zoomHandle,'ActionPostCallback',@RecordAxisLimits); 
        SetUIStatusMessage('Done.')
    end  
   
    %%% nested function for the time series plot
    %%% nested function for the time series plot
    %%% nested function for the time series plot
    
    function PopoutHydrograph(hObj,~) 
        
        global TheGrids
        TheGrid=TheGrids{1};
        
        Vizfs=getappdata(Handles.MainFigure,'FontSizes');
        LinestyleList={'-','--','-','-','-','-','-','-','-',':','-','-p','-.','-.','-.'};
        MarkerList   ={'none','none','*','d','o','s','>','<','v','none','+','p','*','o','d'}; 
        LineWidth=2;
        MarkerSize=6;
        
        EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
        VariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
        EnsembleNames=Connections.EnsembleNames;
        VariableNames=Connections.VariableNames;
        EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames));
        VarIndex=find(strcmp(VariableClicked,VariableNames));
        
        if ismember(VariableClicked,{'Max Water Level','Water Level'})
            VarIndexTimeDep=find(strcmp(VariableNames,'Water Level'));
        elseif ismember(VariableClicked,{'Max Sig Wave Height','Sig Wave Height'})
            VarIndexTimeDep=find(strcmp(VariableNames,'Sig Wave Height'));
        else
           VarIndexTimeDep=[];
        end
        
        titlenamebase=Connections.members{EnsIndex,VarIndex}.VariableDisplayName; %#ok<FNDSB>
            
        cax=Handles.MainAxes;
        xli=xlim(cax);
        yli=ylim(cax);
        dx=(xli(2)-xli(1))*0.005;
        dy=(yli(2)-yli(1))*0.005;
        
        MarkerHandles=findobj(Handles.MainAxes,'Tag','FindLocation');

        if strcmp(get(hObj,'Tag'),'UserEnteredText')
            NodeNumber=get(Handles.UserEnteredText,'String');
            if strcmp(NodeNumber,'<Enter Node>') || isempty(NodeNumber)
                return
            end
            NodeNumber=str2double(NodeNumber);
            if NodeNumber>length(TheGrid.x) || NodeNumber<1
                SetUIStatusMessage('Node number not in range.  Try again ...')
                return
            end
            % NodeNumber should be valid at this point....
            
        elseif strcmp(get(hObj,'Tag'),'TriSurf')
            
            findlocation=get(Handles.MainAxes,'CurrentPoint');
            x=findlocation(1,1);
            y=findlocation(1,2);
            
            InView=IsInView(x,y);
            
            if InView
                SetUIStatusMessage('Getting element number...')
 
                j=findelem(TheGrid,x,y);
                if ~isnan(j)
                    diffx=TheGrid.x(TheGrid.e(j,:))-x;
                    diffy=TheGrid.y(TheGrid.e(j,:))-y;
                    [~,imin]=min(diffx.^2+diffy.^2);
                    NodeNumber=TheGrid.e(j,imin);
                    
                else
                    SetUIStatusMessage('Location is out of model domain.')
                    return
                end
            else
                SetUIStatusMessage('Location is not in view.')
                return
            end
            SetUIStatusMessage(sprintf('Location found in element %d ...',j))

        else
            disp('No grid object found.')
            return
        end

        xx=TheGrid.x(NodeNumber);
        yy=TheGrid.y(NodeNumber);
        
        tic;
        
        TimeseriesData=LoadNodeTimeSeries(VarIndexTimeDep,NodeNumber);
        line(xx,yy,2,'linewidth',2,'Marker','o','Color','k','MarkerFaceColor','k','MarkerSize',5,'Tag','HydroNodeMarker','Clipping','on');
        
        if all(isnan(TimeseriesData.q(:)))
            SetUIStatusMessage(['Node: ',num2str(NodeNumber,'%10d'), ' at (',num2str(x, '%10.2f'),' , ',num2str(y, '%10.2f'),') is dry.'])
            text(xx+dx,yy-dy,2,'Dry','Color','k','Tag','HydrographText','FontWeight','bold','Clipping','on')
        else
            text(xx+dx,yy-dy,2,num2str(NodeNumber),'Color','k','Tag','HydrographText','FontWeight','bold','Clipping','on')
            xwin=.35;ywin=.07;
            titlename=titlenamebase;
            figurename=['Hydrograph of ',titlenamebase];
            SetUIStatusMessage(['\nDrawing hydrograph at ( ',num2str(xx,'% 10.2f'),', ',num2str(yy,'% 10.2f'),' ), Node: ',num2str(NodeNumber,'%10d')])
            
            if isempty(findobj(0,'Tag','HydrographFigure'))
                HyFig=figure('Units','normalized',...
                    'OuterPosition',[xwin ywin .65 .3],...
                    'Tag','HydrographFigure',...
                    'NumberTitle','off',...
                    'Name',figurename,...
                    'Resize','on');
                %set(HyFig,'CloseRequestFcn',@deletemarkatclose)
                HyAxes=axes('units','normalized','position',[0.1 0.2 0.75 0.65],'fontsize',Vizfs(4),'Tag','HydrographAxes');
                box on
            else
                HyFig=findobj(0,'Tag','HydrographFigure');
                figure(HyFig)
                HyAxes=findobj(HyFig,'Tag','HydrographAxes');
            end
            
            t=TimeseriesData.t+LocalTimeOffset/24;
            y=TimeseriesData.q;
            corder=get(HyAxes,'ColorOrder');
            c=corder(1,:);
            h=NaN*ones([size(xx,2) 1]);
            for ii=1:size(y,2)
                h(ii)=line(t,y(:,ii),'LineStyle',LinestyleList{ii},'Marker',MarkerList{ii},'markersize',MarkerSize,'linewidth',LineWidth,'Color',c);
            end
            corder=circshift(corder,-1);
            set(HyAxes,'ColorOrder',corder);
            
            axis tight
            grid on
            datetick('x','mm/dd HH:MM','keepticks','keeplimits')
            title(titlename,'fontweight','bold','fontsize',Vizfs(3))
            Units=Connections.members{1,VarIndexTimeDep}.Units;
            
            ylabel(Units)
            
            [~,objh,~,~]=legend(h,Connections.EnsembleNames);
            set(objh,'color','k')
            idx=strcmp(get(objh,'type'),'text');
            set(objh(idx),'FontWeight','bold','FontSize',Vizfs(4))
            
            linecount=length(findobj(HyAxes,'Type','line'))/length(Connections.EnsembleNames)+1;
            text('units','normalized','position',[1.05 1-0.1*linecount],...
                'FontSize',10,'backgroundcolor','w','Color',c,...
                'String',sprintf('Node: %d',NodeNumber),'fontsize',Vizfs(4),...
                'FontWeight','bold','EdgeColor',c)
        end
        dt=toc;
        SetUIStatusMessage(sprintf('\nTook %.1f secs.  Click on another location or enter another node number ...\n',dt))
        axes(cax)
    end

    function deletemarkatclose(~,~) %#ok<DEFNU>
        delete(gcf)
        axes(Handles.MainAxes);
        MarkerHandles=findobj(Handles.MainAxes,'Tag','HydroNodeMarker');
        HydrographTextHandles=findobj(Handles.MainAxes,'Tag','HydrographText');

        if ~isempty(MarkerHandles),delete(MarkerHandles);end
        if ~isempty(HydrographTextHandles),delete(HydrographTextHandles);end

    end
end

%%  LoadNodeTimeSeries
%%% LoadNodeTimeSeries
%%% LoadNodeTimeSeries
function Data=LoadNodeTimeSeries(VarIndex,NodeNumber) 

    global Connections

    SetUIStatusMessage('Getting nodal timeseries ...')

    q=cell(length(Connections.EnsembleNames),1);
    t=q;
    mint=NaN;
    maxt=NaN;
    
    for i=1:length(Connections.EnsembleNames)

        SetUIStatusMessage(sprintf('Getting nodal timeseries at node %d for ens=%s ...',NodeNumber,Connections.EnsembleNames{i}))
        
        varnameinfile=Connections.members{i,VarIndex}.FileNetcdfVariableName;
        
        h=Connections.members{i,VarIndex}.NcTBHandle;
                
        fac=Connections.VariableUnitsFac{VarIndex};
        
        qn=h.geovariable(varnameinfile);
        q{i}=fac*qn.data(:,NodeNumber);

        time=h.geovariable('time');
        basedate=time.attribute('base_date');
        if isempty(basedate)
             s=time.attribute('units');
             basedate=datestr(datenum(s(13:end),'yyyy-mm-dd HH:MM:SS'));
        end
        timebase_datenum=datenum(basedate);
        t{i}=cast(time.data(:),'double');

        maxt=max(maxt,max(t{i}));
        mint=min(mint,min(t{i}));

    end
    
    % get everything onto the same time level; assume the same dt for
    % now...
    dt=(t{1}(2)-t{1}(1));
    nsecs=maxt-mint;
    Data.t=(mint:dt:maxt)';
    Data.q=NaN*ones(length(Data.t),length(Connections.EnsembleNames));
    for i=1:length(Connections.EnsembleNames)
        j1=find(abs(Data.t-t{i}(1))<.001);
        j2=find(abs(Data.t-t{i}(end))<.001);
        Data.q(j1:j2,i)=q{i};
    end
    Data.t=Data.t/86400+timebase_datenum;

end

%%  ToggleElements
%%% ToggleElements
%%% ToggleElements
function ToggleElements(hObj,~)

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    cv=get(Handles.TriSurf,'EdgeColor');
    if strcmp(cv,'none')
        set(Handles.TriSurf,'EdgeColor','k');
        set(hObj,'String','Hide Elements');
    else
        set(Handles.TriSurf,'EdgeColor','none');
        set(hObj,'String','Show Elements');
    end
    
end



%%% Utility functions
%%% Utility functions
%%% Utility functions

%%  SetPanZoomFxns
%%% SetPanZoomFxns
%%% SetPanZoomFxns
function Handles=SetPanZoomFxns(Handles)

    if ~isfield(Handles,'panHandle'),
        Handles.panHandle=pan(Handles.MainFigure);
    end
    
    if ~isfield(Handles,'zoomHandle'),
        Handles.zoomHandle=zoom(Handles.MainFigure);
    end
    
    set(Handles.panHandle,'ActionPostCallback',@RecordAxisLimits);
    set(Handles.zoomHandle,'ActionPostCallback',@RecordAxisLimits);

end

%%  RecordAxisLimits
function RecordAxisLimits(~,arg2)
  
    MainFig=get(get(arg2.Axes,'Parent'),'Parent');
    Handles=get(MainFig,'UserData');
    axx=axis;
    setappdata(Handles.MainFigure,'BoundingBox',axx);
    set(Handles.AxisLimits,'String',sprintf('%.2f  ',axx))
    RendererKludge;

end

%%  GetNodesInView
function idx=GetNodesInView(TheGrid)

    axx=axis;
    idx=find(TheGrid.x<axx(2) & TheGrid.x>axx(1) & ...
        TheGrid.y<axx(4) & TheGrid.y>axx(3));

end

%%  IsInView
function idx=IsInView(x,y)

    axx=axis;
    idx=(x<axx(2) & x>axx(1) & ...
        y<axx(4) & y>axx(3));

end

%%  GetMinMaxInView
function [Min,Max]=GetMinMaxInView(TheGrid,TheField)

    idx=GetNodesInView(TheGrid);
    Min=min(TheField(idx));
    Max=max(TheField(idx));

end

%%  CLim
function CLim(clm)
    if clm(2)>clm(1)
        set(gca,'CLim',clm)
    else
        SetUIStatusMessage('Error: Color Min > Color Max.  Check values.')
    end
end

%%  TC_StormNames
% function names=TC_StormNames(year)
% 
%    fid=fopen('private/TCStormNames.txt','r');
%    yrs=textscan(fid,'%d');
%    names=textscan(fid,'%s%s%s%s%s%s');
%    fclose(fid);
%    idx=find(yrs{:}==year);
%    names=names{idx};
% 
% end


%%  SetCLims
function SetCLims(~,~)

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    axes(Handles.MainAxes);

    PossibleMaps=cellstr(get(Handles.ColormapSetter,'String'));
    CurrentValue=get(Handles.ColormapSetter,'Value');
    CurrentMap=PossibleMaps{CurrentValue};
    NumCols=get(Handles.NCol,'String');
    CMin=get(Handles.CMin,'String');
    CMax=get(Handles.CMax,'String');
    CLim([str2double(CMin) str2double(CMax)])
    eval(sprintf('cmap=colormap(%s(%s));',CurrentMap,NumCols))    
    FlipCMap=get(Handles.FlipCMap,'Value');
    if FlipCMap,cmap=flipud(cmap);end
    colormap(cmap)
    
end

%%  SetColorMap
function SetColorMap(hObj,~) 

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    axes(Handles.MainAxes);

    val = get(hObj,'Value');
    if val==1
        nc=size(colormap,1);
        colormap(noaa_cmap(nc));
    elseif val ==2
        colormap(jet)
    elseif val == 3
        colormap(hsv)
    elseif val == 4
        colormap(hot)
    elseif val == 5
        colormap(cool)
    elseif val == 6
        colormap(gray)
    end
    
end

%%  SetColors
function SetColors(Handles,minThisData,maxThisData,NumberOfColors,ColorIncrement)

     FieldMax=ceil(maxThisData/ColorIncrement)*ColorIncrement;
     FieldMin=floor(minThisData/ColorIncrement)*ColorIncrement;

     set(Handles.CMax,'String',sprintf('%.2f',FieldMax))
     set(Handles.CMin,'String',sprintf('%.2f',FieldMin))
     set(Handles.NCol,'String',sprintf('%d',NumberOfColors))
     PossibleMaps=cellstr(get(Handles.ColormapSetter,'String'));
     CurrentValue=get(Handles.ColormapSetter,'Value');
     CurrentMap=PossibleMaps{CurrentValue};
     cmap=eval(sprintf('%s(%d)',CurrentMap,NumberOfColors));
     CLim([FieldMin FieldMax])
     colormap(cmap)
     
end

%%  GetColors
% function [minThisData,maxThisData,NumberOfColors]=GetColors(Handles)
%      maxThisData=str2double(get(Handles.CMax));
%      minThisData=str2double(get(Handles.CMin));
%      NumberOfColors=str2int(get(Handles.NCol));
% end

%%  SetTitle
function SetTitle(RunProperties)
    
    % SetTitle MUST be called AFTER the Handle struct is set back in the
    % caller:  I.e., it must be placed after
    % "set(Handles.MainFigure,'UserData',Handles);"
    
    f=findobj(0,'Tag','MainVizAppFigure');
    Handles=get(f,'UserData');
    SSVizOpts=getappdata(Handles.MainFigure,'SSVizOpts');              
        
    LocalTimeOffset=SSVizOpts.LocalTimeOffset;
    DateStringFormat=getappdata(Handles.MainFigure,'DateStringFormatOutput');
    
    advisory=GetRunProperty(RunProperties,'advisory');
    if strcmp(advisory,'0'),advisory=[];end
    
    stormname=GetRunProperty(RunProperties,'stormname');
    
    if strcmp(stormname,'STORMNAME')
        stormname='Nam-Driven';
        NowcastForecastOffset=0;
    else
        NowcastForecastOffset=3;
    end
    
    if isempty(get(Handles.TriSurf,'UserData'))
    
        ths=str2double(GetRunProperty(RunProperties,'InitialHotStartTime'));
        tcs=GetRunProperty(RunProperties,'ColdStartTime');
        tcs=datenum(tcs,'yyyymmddHH');
        t=tcs+ths/86400;
        t=t+LocalTimeOffset/24;
        t=t+NowcastForecastOffset/24;

    else
    
        t=get(Handles.TriSurf,'UserData');
        %t=datenum(t,DateStringFormat);
    
    end
    
    
%    LowerString=datestr((datenum(currentdate,'yymmdd')+...
%        (NowcastForecastOffset)/24+LocalTimeOffset/24),'ddd, dd mmm, HH PM');
    LowerString=datestr(t,DateStringFormat);

    
    if ~isempty(advisory)
        %titlestr={sprintf('%s  Advisory=%s  ',stormname, advisory),[LowerString ' ']};
        titlestr=[sprintf('%s  Advisory=%s  ',stormname, advisory),[' ' LowerString ' ']];
    else    
        %titlestr={sprintf('%s',stormname),[LowerString ' ']};
        titlestr=[sprintf('%s',stormname),[' ' LowerString ' ']];
    end
    title(titlestr,'FontWeight','bold') 
end

%{
# ***************************************************************************
# 
# RENCI Open Source Software License
# The University of North Carolina at Chapel Hill
# 
# The University of North Carolina at Chapel Hill (the "Licensor") through 
# its Renaissance Computing Institute (RENCI) is making an original work of 
# authorship (the "Software") available through RENCI upon the terms set 
# forth in this Open Source Software License (this "License").  This License 
# applies to any Software that has placed the following notice immediately 
# following the copyright notice for the Software:  Licensed under the RENCI 
# Open Source Software License v. 1.0.
# 
# Licensor grants You, free of charge, a world-wide, royalty-free, 
# non-exclusive, perpetual, sublicenseable license to do the following to 
# deal in the Software without restriction, including without limitation the 
# rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the 
# Software is furnished to do so, subject to the following conditions:
# 
# . Redistributions of source code must retain the above copyright notice, 
# this list of conditions and the following disclaimers.
# 
# . Redistributions in binary form must reproduce the above copyright 
# notice, this list of conditions and the following disclaimers in the 
# documentation and/or other materials provided with the distribution.
# 
# . Neither You nor any sublicensor of the Software may use the names of 
# Licensor (or any derivative thereof), of RENCI, or of contributors to the 
# Software without explicit prior written permission.  Nothing in this 
# License shall be deemed to grant any rights to trademarks, copyrights, 
# patents, trade secrets or any other intellectual property of Licensor 
# except as expressly stated herein.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
# THE CONTIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR 
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
# OTHER DEALINGS IN THE SOFTWARE.
# 
# You may use the Software in all ways not otherwise restricted or 
# conditioned by this License or by law, and Licensor promises not to 
# interfere with or be responsible for such uses by You.  This Software may 
# be subject to U.S. law dealing with export controls.  If you are in the 
# U.S., please do not mirror this Software unless you fully understand the 
# U.S. export regulations.  Licensees in other countries may face similar 
# restrictions.  In all cases, it is licensee's responsibility to comply 
# with any export regulations applicable in licensee's jurisdiction.
# 
# ***************************************************************************# 
%}
