function setversion
[r,s]=system('git describe --tags');
[r,s2]=system('git status | sed -n 1p |awk ''{print $NF}''');
fid=fopen('ThisVersion','w');
%str=sprintf('JHT StormSurgeViz-Ncml %s : %s',deblank(s),deblank(s2));
str=sprintf('JHT StormSurgeViz-Ncml %s',deblank(s));
fprintf(fid,'%s\n',str);
fclose(fid);

