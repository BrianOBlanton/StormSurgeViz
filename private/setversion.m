function setversion
Version=0;
[status,Revision]=system('svn info | grep Revision: | awk ''{print $2}''');
Revision=str2double(Revision);
AppName=sprintf('Adcirc Viz Tool Version %02d.%3d', Version,Revision+1);
fid=fopen('ThisVersion','w');
fprintf(fid,'%s\n',AppName);
fclose(fid);

