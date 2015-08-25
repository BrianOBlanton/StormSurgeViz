function setversion
[r,s]=system('git describe --tags');
%[r,s]=system('git tag  | sed -n 1p');
%[r,s2]=system('git status | sed -n 1p |awk ''{print $NF}''');
fid=fopen('ThisVersion','w');
%str=sprintf('JHT StormSurgeViz-Ncml %s : %s',deblank(s),deblank(s2));
str=sprintf('JHT StormSurgeViz-Ncml v:%s',deblank(s));
fprintf(fid,'%s\n',str);
fclose(fid);
disp(str)
%disp(s2)
