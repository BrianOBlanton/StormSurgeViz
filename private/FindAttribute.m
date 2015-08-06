function res=FindAttribute(obj,name)

if ~(isa(obj,'ncgeovariable') || isa(obj,'ncvariable'))
    error('Object to FindAttribute must be an ncgeovariable | ncvariable')
end

res=[];
atts=obj.attributes;
pat=sprintf('\\w%c%s\\w%c','*',name,'*');
temp=regexp(lower(atts(:,1)),lower(pat),'match');
for i=1:length(temp)
    if ~isempty(temp{i})
        res=[res;atts{i}];
    end
end
