function fn=ThisFunctionName

[ST,I]=dbstack;
fn={ST.name};
fn=fn(~strcmp(fn,'ThisFunctionName'));
if isempty(fn)
    fn={'Main'};
else
    fn=fn{1};
end
%fprintf('Function = %s\n',n{1});
