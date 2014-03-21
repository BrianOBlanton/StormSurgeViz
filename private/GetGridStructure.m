%%  GetGridStructure
%%% GetGridStructure
%%% GetGridStructure
function TheGrid=GetGridStructure(Member,id)

    global Debug
    if Debug,fprintf('AdcViz++ Function = %s\n',ThisFunctionName);end
    
    SetUIStatusMessage(['* Getting Grid Structure for ' Member.VariableDisplayName ' ... \n']);
    
    HOME=fileparts(which(mfilename));

    %Instance=getappdata(Handles.MainFigure,'Instance');
    %bbox=getappdata(Handles.MainFigure,'BoundingBox');
    %GridName=GetRunProperty(Connection.RunProperties,'ADCIRCgrid');
    fig=findobj(0,'Tag','MainVizAppFigure');
    TempDataLocation=getappdata(fig,'TempDataLocation');

    if ~exist([TempDataLocation '/' Member.GridHash '_FGS.mat'],'file')
       TheGrid.name=['GridID.eq.' int2str(id)];
       try 
           v=Member.NcTBHandle.variables;
           if any(strcmp(v,'element'))
               TheGrid.e=double(Member.NcTBHandle.data('element'));
               TheGrid.x=Member.NcTBHandle.data('x');
               TheGrid.y=Member.NcTBHandle.data('y');
               TheGrid.bnd=detbndy(TheGrid.e);
           else
               error('element variable not in netCDF')
           end
          
           if any(strcmp(v,'depth'))
               TheGrid.z=Member.NcTBHandle.data('depth');
           end
           
       catch ME
           
           % see if the grid file exist locally in private; this is a
           % fallback when the grid components are not in the solution
           % netCDF files.
%            if exist([HOME '/private/' Instance '_' GridName '.grd'],'file')
%                TheGrid=grd_to_opnml('private/ncfs_nc6b.grd');
%            else
%                disp(['Cant find element list in ' v ' object.  This is Terminal.'])
%                throw(ME);   
%            end
           
       end
       % add element areas and basis function arrays
       TheGrid=el_areas(TheGrid);
       TheGrid=belint(TheGrid);
       save([TempDataLocation '/' Member.GridHash '_FGS.mat'],'TheGrid') 
        
    else
        SetUIStatusMessage('** Loading cached copy of grid structure ...\n')
        load([TempDataLocation '/' Member.GridHash '_FGS.mat']);
     end

%    set(Handles.MainFigure,'Pointer',CurrentPointer);
     SetUIStatusMessage('** Got it. \n')

end

