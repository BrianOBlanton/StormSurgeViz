function setversion
[r,s]=system('git describe --tags');
fid=fopen('ThisVersion','w');
fprintf(fid,'JHT AdcircViz %s\n',s);
fclose(fid);

