%%  GetRunProperty
function retval=GetRunProperty(RP,key)

    idx=find(strcmp(RP{1},key));
    if ~isempty(idx)
        retval=RP{2}{idx};
    else
        retval='Key not found in Run Properties';
    end
end
