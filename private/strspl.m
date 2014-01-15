function p=strspl(s)
if ~ischar(s)
    error('argument to strspl must be a string');
end
p=regexp(s,'([^ ]+)','match');
