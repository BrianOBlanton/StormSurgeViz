function D=read_adcirc_nws19(f22name)

[storm.basin,storm.sn,storm.dat,junk,storm.typ,storm.hr,lat,lon]=textread(f22name,'%s%d%d%s%s%d%s%s%*[^\n]','delimiter',',');
j=0;
for i=1:length(storm.basin)
    %if strcmp(storm.typ(i),'OFCL')
       j=j+1;
       D.lat(j)= str2double(lat{i}(1:3))/10;
       D.lon(j)=-str2double(lon{i}(1:3))/10;
       temp=sprintf('%d',storm.dat(i));
       yyyy=str2double(temp(1:4));
       mm=str2double(temp(5:6));
       dd=str2double(temp(7:8));
       hr=str2double(temp(9:10));
       D.time(j)=datenum(yyyy,mm,dd,hr,0,0);
       D.hr(j)=storm.hr(i);
    %end
end

