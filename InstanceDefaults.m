% This is the remote InstanceDefaults.m file that sets ASGS instance-specific parameters

switch Instance
    case {'asgs1'}
        %DefaultBoundingBox=[ -88.6050  -88.5420   30.3270   30.3720];  
        DefaultBoundingBox=[-100 -78 17 33];
    case {'hindfor','nodcorps','hfip','gomex'}
        DefaultBoundingBox=[-100 -78 17 33];
    case {'hfip_ec95','hfip_R3','2'}
        DefaultBoundingBox=[-84 -60 20 45];
    case {'wfl'}
        DefaultBoundingBox=[-88 -75 20 31];
    case {'ncfs','hfip_NC'}
        DefaultBoundingBox=[ -83 -63 20 45];
    otherwise
        DefaultBoundingBox=[];
end

