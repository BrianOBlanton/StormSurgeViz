%function test

    url='http://mrtee.europa.renci.org:8080/thredds/dodsC/testAll/Complete_gcmplt.nc';
    url='http://opendap.renci.org:1935/thredds/dodsC/ASGS/gonzalo/22/nc_inundation_v9.99/hatteras.renci.org/livegahm/nhcConsensus/00_dir.ncml';
    %url='http://opendap.renci.org:1935/thredds/dodsC/ASGS/gonzalo/22/nc_inundation_v9.99/hatteras.renci.org/livegahm/nhcConsensus/maxele.63.nc';
%    url='http://milas.marine.ie/thredds/dodsC/IMI_ROMS_HYDRO/AGGREGATE';
   % url='http://mrtee.europa.renci.org:8080/thredds/dodsC/testAll/2015042900.nc'; 
    url='http://mrtee.europa.renci.org:8080/thredds/dodsC/testAll/2015042900.ncml'; 
    
    url='http://opendap.renci.org:1935/thredds/dodsC/Test/2015042900.ncml';

    nc=ncgeodataset(url);

    c=0;
    % look for "water level" variables
    disp('Looking for water level variables ...')
    % possible standard names
    stdnames={'sea_surface_height_above_sea_level',...
        'sea_surface_height_above_geoid',...
        'sea_surface_elevation_anomaly',...
        'sea_surface_height_above_reference_ellipsoid',...
        'sea_surface_height',...
        'maximum_sea_surface_height_above_geoid'};
    
    str=GetVariableName(nc,stdnames);
    if isempty(str)
        error('No water level variable found in %s.\n\nWhat''s the point!!\n\n',url)
    end
    c=c+1;
    VariableNames{c}=str;
    v=nc{str};
    VariableLongNames{c}=v.attribute('long_name');
    VariableUnits{c}=v.attribute('units');
    VariableStandardNames{c}=v.attribute('standard_name'); 
    VariableDisplayNames{c}=v.attribute('long_name');
    VariableTypes{c}='scalar';
    VariableUnitsFac{c}=1.;
    
    % look for "atmos pressure" variables
    disp('Looking for atmos pressure  variables ...')
    % possible standard names
    stdnames={'air_pressure_at_sea_level'};
    str=GetVariableName(nc,stdnames);
    if isempty(str)
        fprintf('No atmospheric pressure variable found in %s.\n\nContinuing without it...!!\n\n',url)
    else
        c=c+1;
        VariableNames{c}=str;
        v=nc{str};
        VariableLongNames{c}=v.attribute('long_name');
        VariableUnits{c}=v.attribute('units');
        VariableStandardNames{c}=v.attribute('standard_name');
        VariableDisplayNames{c}=v.attribute('long_name');
        VariableTypes{c}='scalar';
        VariableUnitsFac{c}=1.;
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
        VariableNames{c}=str;
        v=nc{str};
        VariableLongNames{c}=v.attribute('long_name');
        VariableUnits{c}=v.attribute('units');
        VariableStandardNames{c}=v.attribute('standard_name');
        VariableDisplayNames{c}=v.attribute('long_name');
        VariableTypes{c}='scalar';
        VariableUnitsFac{c}=1.;
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
        VariableNames{c}=str;
        v=nc{str};
        VariableLongNames{c}=v.attribute('long_name');
        VariableUnits{c}=v.attribute('units');
        VariableStandardNames{c}=v.attribute('standard_name');
        VariableDisplayNames{c}=v.attribute('long_name');
        VariableTypes{c}='scalar';
        VariableUnitsFac{c}=1.;
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
        VariableNames{c}=str;
        v=nc{str};
        VariableLongNames{c}=v.attribute('long_name');
        VariableUnits{c}=v.attribute('units');
        VariableStandardNames{c}=v.attribute('standard_name');
        VariableDisplayNames{c}=v.attribute('long_name');
        VariableTypes{c}='scalar';
        VariableUnitsFac{c}=1.;
    end
    
