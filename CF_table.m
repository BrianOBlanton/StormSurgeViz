function CF=CF_table

    m2f= 3.280839895;   %meters to feet;
    mps2mph= 2.2369;    %meters/sec to miles/hour;

    CF.StandardNames={
        'maximum_sea_surface_height_above_geoid'
        'sea_surface_height_above_geoid'
        'maximum_sea_surface_wave_significant_height'
        'sea_surface_wave_significant_height'
        'maximum_wind'
        'eastward_wind'
        'northward_wind'
        'air_pressure_at_sea_level'
        'depth_below_geoid'
        };
   
    CF.DisplayNames={
        'Max Water Level'
        'Water Level'
        'Max Sig Wave Height'
        'Sig Wave Height'
        'Max Wind Speed'
        'East Wind'
        'North Wind'
        'Sea Level Pressure'
        'Bathy/Topo'
        };

    CF.UnitsConversion={
        m2f
        m2f
        m2f
        m2f
        mps2mph
        mps2mph
        mps2mph
        1
        m2f
        };
    
    CF.EnglishUnits={
        'feet'
        'feet'
        'feet'
        'feet'
        'mph'
        'mph'
        'mph'
        'NaN'
        'feet'
        };
     
    CF.Vectors(1).u='eastward_wind';
    CF.Vectors(1).v='northward_wind';
    CF.Vectors(1).name='Wind Velocity';
    CF.Vectors(1).units='m/s';
    CF.Vectors(1).Englistunits='mph';

%      
%     CF.StandardNamesVectors={
%         {'eastward_wind','northward_wind'}
%         };
%     CF.DisplayNamesVectors={
%         'Wind'
%         };     
%     CF.UnitsConversionVectors={
%         mps2mph
%         };
    
end
