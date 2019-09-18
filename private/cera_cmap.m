function cmap=cera_cmap(n)

cmap=[
     93    0  255
      0   81  255
     14  244  237
      0  255   25
    251  255    0
    255  145    0
    255   81    0
    151   13   13]/256;
nc=size(cmap,1);
if n>nc
    ii=linspace(1,nc,n);
    tmp(:,1)=interp1(1:nc,cmap(:,1),ii);
    tmp(:,2)=interp1(1:nc,cmap(:,2),ii);
    tmp(:,3)=interp1(1:nc,cmap(:,3),ii);
    cmap=tmp;
end
