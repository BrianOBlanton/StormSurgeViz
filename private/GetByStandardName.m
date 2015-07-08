function ncgvar=GetByStandardName(obj,stdname)

vars=obj.variables;

for i=1:length(vars)
    eval(sprintf('v=obj{''%s''};',vars{i}))
    stdnames{i}=value4key(v.attributes,'standard_name');
end

idx=strcmp(stdnames,stdname);

temp=vars{idx};
eval(sprintf('v=obj{''%s''};',temp))
ncgvar=v;

end
