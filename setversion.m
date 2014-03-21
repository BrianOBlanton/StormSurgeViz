function setversion
[r,s]=system('git describe --long');
fid=fopen('ThisVersion','w');
fprintf(fid,'JHT AdcircViz %s\n',s);
fclose(fid);

