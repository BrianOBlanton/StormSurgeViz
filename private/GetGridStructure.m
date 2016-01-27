%%  GetGridStructure
%%% GetGridStructure
%%% GetGridStructure
function TheGrid=GetGridStructure(Member,id)

global Debug
if Debug,fprintf('SSViz++       Function = %s\n',ThisFunctionName);end

SetUIStatusMessage(['* Getting Grid Structure for ' Member.VariableDisplayName ' ... ']);

%HOME=fileparts(which(mfilename));

%Instance=getappdata(Handles.MainFigure,'Instance');
%bbox=getappdata(Handles.MainFigure,'BoundingBox');
%GridName=GetRunProperty(Connection.RunProperties,'ADCIRCgrid');
fig=findobj(0,'Tag','MainVizAppFigure');
TempDataLocation=getappdata(fig,'TempDataLocation');
SSVizOpts=getappdata(fig,'SSVizOpts');

nc=Member.NcTBHandle;

switch lower(Member.CdmDataType)
    case 'ugrid'
        if ~exist([TempDataLocation '/' Member.GridHash '_FGS.mat'],'file')
            TheGrid.name=['GridID.eq.' int2str(id)];
            %try
            v=Member.NcTBHandle.variables;
            if any(strcmp(v,'element'))
                TheGrid.e=double(nc.data('element'));
                TheGrid.x=nc.data('x');
                TheGrid.y=nc.data('y');
                TheGrid.bnd=detbndy(TheGrid.e);
            else
                error('element variable not in netCDF')
            end
            
            if any(strcmp(v,'depth'))
                TheGrid.z=nc.data('depth');
            end
            
            %catch ME
            
            % see if the grid file exist locally in private; this is a
            % fallback when the grid components are not in the solution
            % netCDF files.
            %            if exist([HOME '/private/' Instance '_' GridName '.grd'],'file')
            %                TheGrid=grd_to_opnml('private/ncfs_nc6b.grd');
            %            else
            %                disp(['Cant find element list in ' v ' object.  This is Terminal.'])
            %                throw(ME);
            %            end
            
            %end
            
            % add element areas and basis function arrays
            TheGrid=el_areas(TheGrid);
            TheGrid=belint(TheGrid);
            
            if SSVizOpts.UseStrTree
                if Debug,fprintf('SSViz++ Computing Strtree for grid %s\n',Member.GridHash);end
                TheGrid.strtree=ComputeStrTree(TheGrid);
            end
            
            save([TempDataLocation '/' Member.GridHash '_FGS.mat'],'TheGrid')
            
        else
            SetUIStatusMessage('** Loading cached copy of grid structure ...')
            load([TempDataLocation '/' Member.GridHash '_FGS.mat']);
        end
        
    case 'cgrid'
        
        % build triangular grid for cgrid...
        SetUIStatusMessage('** Generating grid for cgrid ...')
        TheGrid.name='GridID.eq.xyz';
        
        TheGrid.e=elgen(Member.NNodes(2),Member.NNodes(1));
        TheGrid.bnd=detbndy(TheGrid.e);
        
        temp=nc.standard_name('longitude');
        temp=nc.data(temp);
        TheGrid.True_X=temp;
        TheGrid.x=cast(temp,'double');
        
        temp=nc.standard_name('latitude');
        temp=nc.data(temp);
        TheGrid.True_Y=temp;
        TheGrid.y=cast(temp,'double');
        
        % check to see if there are mask arrays in the netCDF file
        % we've specified that the water level mask array needs a
        % standard_name of sea_surface_height_mask (probably via ncml)
        wmask=[];
        temp=nc.standard_name('sea_surface_height_mask');
        if ~isempty(temp)
            temp=nc.data(temp);
            wmask=temp==0;
            TheGrid.x(wmask)=NaN;
            TheGrid.y(wmask)=NaN;
        end
         
        % if both x and y are 1-D, assume rectangular grid and replicate
        % e.g., IMI ROMS
        if ( size(TheGrid.x,1)==1 || size(TheGrid.x,2)==1 ) && ...
           ( size(TheGrid.y,1)==1 || size(TheGrid.y,2)==1 ) 
             m=length(TheGrid.y);
             n=length(TheGrid.x);
             x=repmat(TheGrid.x',[m 1]);
             y=repmat(TheGrid.y,[1 n]);
             TheGrid.x=x(:);
             TheGrid.y=y(:);
        else
            TheGrid.x=TheGrid.x(:);
            TheGrid.y=TheGrid.y(:);
        end
        
        temp=nc.standard_name('depth_below_geoid');
        if isempty(temp)
            SetUIStatusMessage('**** No depth variable found.  Setting depths to NaN...')
            TheGrid.z=NaN(size(TheGrid.x));
        else
            temp=nc.data(temp);
            temp(wmask)=NaN;
            TheGrid.z=cast(temp(:),'double');
        end
        
        % attempt to put grid in west-is-negative ...
        if max(TheGrid.x>0) && min(TheGrid.x)>0
            TheGrid.x=TheGrid.x-360;
        end
        
        TheGrid=el_areas(TheGrid);
        TheGrid=belint(TheGrid);
        
    otherwise
        
        SetUIStatusMessage(sprintf('**** cdm_data_type %s not yet supported.',Member.CdmDataType))

           
end
        %    set(Handles.MainFigure,'Pointer',CurrentPointer);
        SetUIStatusMessage('** Got it.')     
end

