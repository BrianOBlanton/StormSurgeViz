function str=GetVariableName(nc,stdnames)

for i=1:length(stdnames)
    stdnm=stdnames{i};
    str=nc.standard_name(stdnm);
    if ~isempty(str),break;end
end
