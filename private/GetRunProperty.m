%%  GetRunProperty
function retval=GetRunProperty(RP,key)

    retval='unknown';
    idx=find(strcmpi(RP{1},key));
    if ~isempty(idx)
        retval=RP{2}{idx};
    end
end
