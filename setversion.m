function setversion
[r,s]=system('git describe --tags');
s(end)=[];
[r2,s2]=system('git status | sed  1q | awk ''{print $3}''');
s2(end)=[];
fid=fopen('ThisVersion','w');
fprintf(fid,'JHT StormSurgeViz %s - %s',s,s2);
fclose(fid);

