function setversion
[r,s]=system('git describe --tags');
[r,s2]=system('git status | sed -n 1p |awk ''{print $NF}''');
fid=fopen('ThisVersion','w');
fprintf(fid,'JHT AdcircViz %s : %s\n',deblank(s),deblank(s2));
fclose(fid);

