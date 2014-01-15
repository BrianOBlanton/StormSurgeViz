%%  LoadRunProperties
function RunProperties=LoadRunProperties(file)

    fid=fopen(file,'r');
    RunProperties=textscan(fid,'%s %s','Delimiter',':');
    for j=1:length(RunProperties{1})
        RunProperties{1}{j}=deblank(RunProperties{1}{j});
    end
    fclose(fid);
    
end

