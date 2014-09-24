function j=FindElementsInStrTree(fgs,points_x,points_y,TOL)
% Call as:  j=FindElementsInStrTree(fgs,points_x,points_y);

[m,n]=size(points_x);
j=NaN*ones(m,n);
if ~exist('TOL')
    TOL=1e-4;
end

%%
%tic;
for i=1:m
    %parfor (i=1:m)
    
    for ii=1:n
        px=points_x(i,ii);
        py=points_y(i,ii);
        p=com.vividsolutions.jts.geom.Coordinate(px,py);
        e=com.vividsolutions.jts.geom.Envelope(p);
        l=fgs.strtree.query(e);
        if l.size==0
            %fprintf('no potential elements found for %f, %f\n',px,py);
        else
            for k=0:l.size-1
                teste=l.get(k);
                phi=basis2d(fgs,[px py],teste);
                if all(phi<=1+TOL & phi>=0-TOL),j(i,ii)=teste;break;end
            end
        end
    end
end

%t=toc;
%disp(sprintf('Containing elements for %d point(s) found in %.1f secs',m*n,t));

