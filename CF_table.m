function CF=CF_table

    CF.StandardNames={'maximum_sea_surface_height_above_geoid_xyz'
        'sea_surface_height_above_geoid'
        'maximum_sea_surface_wave_significant_height'
        'eastward_wind'
        'northward_wind'
        'air_pressure_at_sea_level'};

    CF.VectorCombinations={[4 5]};
    
    CF.DisplayNames={'Max Water Level'
        'Water Level'
        'Max Sig Wave Height'
        'East Wind'
        'North Wind'
        'Sea Level Pressure'};

end
