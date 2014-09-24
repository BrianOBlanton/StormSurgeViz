function mystr=ComputeStrTree(fgs)
% Call as:  StrTree=ComputeStrTree(fgs)

% import java.io.ObjectOutputStream;
% import java.io.FileOutputStream;

ne=size(fgs.e,1);
%fprintf('Computing STRtree for %d elements ... \n',ne);
FuzzFac=100;
xmin=min(fgs.x(fgs.e),[],2);    
xmax=max(fgs.x(fgs.e),[],2);    
ymin=min(fgs.y(fgs.e),[],2);    
ymax=max(fgs.y(fgs.e),[],2);        
tic
mystr=com.vividsolutions.jts.index.strtree.STRtree;
for j=1:ne
    %if mod(j-1,10000)==0,fprintf('%d\n',j),end
    dx=xmax(j)-xmin(j);    
    dy=ymax(j)-ymin(j);
    % add fuzz to envelope
    x1=xmin(j)-dx/FuzzFac;
    x2=xmax(j)+dx/FuzzFac;
    y1=ymin(j)-dy/FuzzFac;
    y2=ymax(j)+dy/FuzzFac;
    e=com.vividsolutions.jts.geom.Envelope(x1,x2,y1,y2);
    mystr.insert(e,j);
end
t=toc;
fprintf('STRtree for %d elements computed in %.1f secs\n',ne,t);

% fos = FileOutputStream('test.out')

% out = ObjectOutputStream(fos);
% out.writeObject(mystr);


