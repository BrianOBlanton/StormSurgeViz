function [SS,edges,spec]=MakeAdcircShape(fgs,q,bin_centers,varargin)
% [SS,spec,edges]=MakeShape(fgs,q,bin_centers,p1,v1,p2,v2,...);
%
%   WriteShape(SS,OutName)
%   ShowShape(SS,edges,spec)
%
% SplitElements - if true, split elements into smaller triangles if 
%                 that contain the contour value; if false, only group
%                 elements by element-average values, results in ragged
%                 edges to the polygons
%
% Brian Blanton
% Renaissance Computing Institute
% The University of North Carolina at Chapel Hill
% Initial Code: March 2013

FeatureName='WaterLevel';

SplitElements=true;
ClipToNans=true;
PolygonLengthMinimum=10;
Verbose=true;
Verbose2=false;

% Strip off propertyname/value pairs in varargin not related to
% "line" object properties.
k=1;
while k<length(varargin),
  switch lower(varargin{k}),
    case 'featurename',
      FeatureName=varargin{k+1};
      varargin([k k+1])=[];
    otherwise
      k=k+2;
  end;
end;

% if length(varargin)<2
%    varargin={};
% end

% get rid of whitespace and special characters 
FeatureName(regexp(FeatureName,'[^a-zA-Z0-9]'))=[];

%Threshold=1e-10;
%Fuzz=0;  % percent slop in nodal values

x=fgs.x;
y=fgs.y;
e=fgs.e;
[m,~]=size(x);
%origq=q;

if length(bin_centers)==1  % spec's the bin center interval
    db=bin_centers;
    e0=floor(min(q/db))*db;  
    e1=ceil(max(q/db))*db;
    bin_centers=e0:db:e1;
    
else
    if max(diff(bin_centers)) ~= min(diff(bin_centers))
        error('Cant handle unequally spaced bins yet.')
    end
    db=bin_centers(2)-bin_centers(1);
    e0=bin_centers(1);
    e1=bin_centers(end);
end

edges=e0-db/2:db:e1+db/2;

if ClipToNans
    q(q>max(edges))=NaN;
    q(q<min(edges))=NaN;
else
    q(q>max(edges))=max(edges);
    q(q<min(edges))=min(edges);
end

% use a sparse matrix to keep track of which 
% edges have been split by contour values; make it 
% twice as big as the number of nodes in the grid.
% if an edge is split, the new node number is added 
% to ConnSP at the i,j for the node numbers for the edge. 
ConnSP=sparse(2*m,2*m);

if SplitElements
    % For all elements that contain a bin edge, split into 3 smaller
    % elements, delete larger element, add new elements to element list,
    % add new nodes to node list. Add new node number to the ConnSP sparse
    % matrix.

    % loop over each bin edge
    for i=1:length(edges)
            
        if Verbose,fprintf('Splitting intersecting elements for edge=%f ... ',edges(i));end

        % get the scalar values for each element vertex
        % since elements may be added on each loop, this needs 
        % to be done each time.
        qe=q(e);                % This is the scalar value at each node in e
        minqe=min(qe,[],2);     % This is the minimum scalar value on the element
        maxqe=max(qe,[],2);     % This is the maximum scalar value on the element

        % find elements that contain (in their minqe, maxqe) the bin edge.
        idx=find(minqe<edges(i) & maxqe>edges(i));
        if isempty(idx)
            if Verbose,fprintf('\n');end
            continue
        end
        
        % allocate space for new elements and nodes
        newe=NaN*ones(10*length(find(idx)),3);
        newx=NaN*ones(5*length(find(idx)),1);
        newy=newx;
        newq=newx;
               
        NumberOfOriginalNodes=length(x);
        NumberOfOriginalElements=size(e,1);
        ElementsToDelete=false(NumberOfOriginalElements,1);
       
        newnodes=0;
        newelems=0;
        
        % get list of elements and nodes for this bin edge
        es=e(idx,:);
        xs=x(es);
        ys=y(es);
        qs=q(es);
        
        % This is the inefficient part. 
        % for each element in idx, find which edges contain the contour
        % value
        for j=1:length(idx)
            
            if Verbose,if mod(j,500)==0,fprintf('%d ',j);end,end
            
            thisqs=qs(j,:)-edges(i);                % subtract the bin edge value from the node values. 
            idx2=prod(thisqs([1 2;2 3;3 1]),2)<0;   % multiply this delta between nodes.  If negative,
                                                    % that edge is split.
            thisx=xs(j,:);
            thisy=ys(j,:);
            thisq=qs(j,:);
            
            if any(isnan(thisq))  % skip if one or more nodes are NaN
                continue
            end
            
            node1=es(j,1);
            node2=es(j,2);
            node3=es(j,3);
                       
            if idx2(1) && idx2(2)  % contour segment intersects edges 1,2 and 2,3
                
                % 1,2 vertex pair
                a=full(ConnSP(node1,node2));  % if a ~=0, then this edge has been previously split
                if a==0                       % Otherwise, edge not split; calculate new node and q
                    % new node
                    t=thisqs(2)-thisqs(1);    % linear interpolation
                    b1=abs(thisqs(2)/t);
                    b2=abs(thisqs(1)/t);
                    newx12=b1*thisx(1)+b2*thisx(2);
                    newy12=b1*thisy(1)+b2*thisy(2);
                    newq12=b1*thisq(1)+b2*thisq(2);
                    newnodes=newnodes+1;
                    a=newnodes+NumberOfOriginalNodes;
                    newx(newnodes)=newx12;   % add new node to list (elements added later).
                    newy(newnodes)=newy12;
                    newq(newnodes)=newq12;
                    ConnSP(node1,node2)=a;   % add new node to ConnSP 
                    ConnSP(node2,node1)=a;   % also add in reverse order!!
                end
                               
                % 2,3 vertex pair
                b=full(ConnSP(node2,node3));
                if b==0  % edge not split
                    % new node
                    t=thisqs(3)-thisqs(2);
                    b1=abs(thisqs(3)/t);
                    b2=abs(thisqs(2)/t);
                    newx23=b1*thisx(2)+b2*thisx(3);
                    newy23=b1*thisy(2)+b2*thisy(3);
                    newq23=b1*thisq(2)+b2*thisq(3);
                    newnodes=newnodes+1;
                    b=newnodes+NumberOfOriginalNodes;
                    newx(newnodes)=newx23;
                    newy(newnodes)=newy23;
                    newq(newnodes)=newq23;
                    ConnSP(node2,node3)=b;  
                    ConnSP(node3,node2)=b;  
                end
                
                newe1=[a es(j,2) b      ];     % these are the new elements, composed of  
                newe2=[b es(j,3) a      ];     % the a,b nodes and the omitted vertex
                newe3=[a es(j,3) es(j,1)];
                
            elseif idx2(2) && idx2(3) % contour segment intersects edges 2,3 and 3,1
                
                % 2,3 vertex pair
                a=full(ConnSP(node2,node3));
                if a==0  % edge not split, new node
                    t=thisqs(3)-thisqs(2);
                    b1=abs(thisqs(3)/t);
                    b2=abs(thisqs(2)/t);
                    newx23=b1*thisx(2)+b2*thisx(3);
                    newy23=b1*thisy(2)+b2*thisy(3);
                    newq23=b1*thisq(2)+b2*thisq(3);
                    newnodes=newnodes+1;
                    a=newnodes+NumberOfOriginalNodes;
                    newx(newnodes)=newx23;
                    newy(newnodes)=newy23;
                    newq(newnodes)=newq23;
                    ConnSP(node2,node3)=a;  
                    ConnSP(node3,node2)=a;  
                end
                
                % 3,1 vertex pair
                b=full(ConnSP(node3,node1));
                if b==0 
                    t=thisqs(1)-thisqs(3);
                    b1=abs(thisqs(1)/t);
                    b2=abs(thisqs(3)/t);
                    newx31=b1*thisx(3)+b2*thisx(1);
                    newy31=b1*thisy(3)+b2*thisy(1);
                    newq31=b1*thisq(3)+b2*thisq(1);
                    newnodes=newnodes+1;
                    b=newnodes+NumberOfOriginalNodes;
                    newx(newnodes)=newx31;
                    newy(newnodes)=newy31;
                    newq(newnodes)=newq31;
                    ConnSP(node3,node1)=b;  
                    ConnSP(node1,node3)=b;  
                end
                
                newe1=[a es(j,3) b      ];
                newe2=[a b       es(j,1)];
                newe3=[a es(j,1) es(j,2)];
                
            elseif idx2(3) && idx2(1) % contour segment intersects edges 3,1 and 1,2
                
                % 3,1 vertex pair
                a=full(ConnSP(node3,node1));
                if a==0 
                    t=thisqs(1)-thisqs(3);
                    b1=abs(thisqs(1)/t);
                    b2=abs(thisqs(3)/t);
                    newx31=b1*thisx(3)+b2*thisx(1);
                    newy31=b1*thisy(3)+b2*thisy(1);
                    newq31=b1*thisq(3)+b2*thisq(1);
                    newnodes=newnodes+1;
                    a=newnodes+NumberOfOriginalNodes;
                    newx(newnodes)=newx31;
                    newy(newnodes)=newy31;
                    newq(newnodes)=newq31;
                    ConnSP(node3,node1)=a;
                    ConnSP(node1,node3)=a;  
                end
                
                % 1,2 vertex pair
                b=full(ConnSP(node1,node2));
                if b==0  % edge not split
                    t=thisqs(2)-thisqs(1);
                    b1=abs(thisqs(2)/t);
                    b2=abs(thisqs(1)/t);
                    newx12=b1*thisx(1)+b2*thisx(2);
                    newy12=b1*thisy(1)+b2*thisy(2);
                    newq12=b1*thisq(1)+b2*thisq(2);
                    newnodes=newnodes+1;
                    b=newnodes+NumberOfOriginalNodes;
                    newx(newnodes)=newx12;
                    newy(newnodes)=newy12;
                    newq(newnodes)=newq12;
                    ConnSP(node1,node2)=b;  
                    ConnSP(node2,node1)=b;  
                end
                
                newe1=[a es(j,1) b      ];
                newe2=[a b       es(j,2)];
                newe3=[a es(j,2) es(j,3)];
            else
                fprintf('Sign fallthrough at j=%d\n',j);
            end
            
            % new element
            
            % replace current element with this new element;
            ElementsToDelete(idx(j))=true;
            
            % add 3 new elements to newelements list
            newe(newelems+1,:)=newe1;
            newe(newelems+2,:)=newe2;
            newe(newelems+3,:)=newe3;
            newelems=newelems+3;
            
        end   % end of loop over elements in this bin
        
        if Verbose,fprintf('\n');end

        % add new elements and nodes to originals; this is also inefficient
        % since it required reallocation of x,y,q,e.  
        temp=newx(isfinite(newx));
        x=[x;temp];
        temp=newy(isfinite(newy));
        y=[y;temp];
        temp=newq(isfinite(newq));
        q=[q;temp];
        e(ElementsToDelete,:)=[];
        idx=isfinite(newe(:,1));
        temp=newe(idx,:);
        e=[e;temp];
        
    end   % end of loop over bins
    
    if Verbose,fprintf('\n');end

end

% OK, we're done with edge splitting 
if Verbose,
    fgs2.name='test';
    fgs2.e=e;
    fgs2.x=x;
    fgs2.y=y;
    fgs2.z=q;
    fgs2.bnd=detbndy(e);
end
 
% recompute mqe with new elements
mqe=mean(q(e),2);
nbins=length(bin_centers);
list=cell(nbins,1);
c=0;
for i=1:nbins
    list{i}=find(mqe>=edges(i) & mqe<edges(i+1));
    c=c+length(list{i});
end

%%
if Verbose2,figure,end
c=0;
SS=struct([]);
for ii=1:length(list)
    
    if Verbose,fprintf('Processing bin %3d.  %8d elements \n',ii,length(list{ii}));end
    
    if isempty(list{ii}),continue,end  % go to next ii if this list{ii} is empty (no elements in this bin)
    
    ee=list{ii};
    eee=e(ee,:);
    
    % compute the boundary of this (possibly disconnected) set of elements. 
    % detbndy works by 
    % 1) forming the adjacency matrix for the elements in eee. Each edge will add a 1 to this matrix. 
    % 2) add the transpose and keep only the upper triangular part. 
    % 3) wherever there is a 1, the edge was NOT repeated, and hence on the
    %    boundary of the set of elements. 
    bnd=detbndy2(eee);
    
    % however, the list of boundary segments bnd is not connected
    % end-to-end.  bnd_conn2 will connect the boundary segments into closed
    % polygons and return them in Conn
    [Conn,kk]=bnd_conn2(bnd,x,y);
    
    % now we need to determine which polygons are inside of others.  This
    % is to find the "holes" in the main polygons that need to be removed
    % from the shapes.  these holes will be removed by reversing their
    % order (from cw to ccw) in the shape specification of the polygon 
    % sort closed polygons based on area of bboxs
    bbox=NaN*ones(kk,4);
    bbox_areas=NaN*ones(kk,1);
    lConn=bbox_areas;
    
    % get bounding box for all closed boundaries in Conn
    for j=1:kk
        bbox(j,:)=[min(x(Conn{j})) max(x(Conn{j})) min(y(Conn{j})) max(y(Conn{j}))];
        bbox_areas(j)=(bbox(j,2)-bbox(j,1))*(bbox(j,4)-bbox(j,3));
        lConn(j)=length(Conn{j});
    end
    
    % sort into descending bounding box areas
    [~,b]=sort(bbox_areas,'Descend');
    bbox=bbox(b,:);
    Conn=Conn(b);
    lConn=lConn(b);
    % delete polygons with lengths less than PolygonLengthMinimum
    iding=lConn<PolygonLengthMinimum;
    Conn(iding)=[];
    bbox(iding,:)=[];
    
    done=false;
    if isempty(Conn)
        done=true;
    end
    current_poly=1;

    while ~done
        c=c+1;
        if Verbose2,fprintf('   Starting feature %d ...\n',c);end
        iring=0;
        
        % look for polys in this bounding box
        
        % coords of main (biggest) polygon
        p1x=x(Conn{current_poly});  
        p1y=y(Conn{current_poly});

        % in GIS shapefiles, the main polygon is specified in cw order.
        % Holes in this polygon are specified ccw.  The breaks between the
        % main and holes are specified as the cumulative number of the
        % segments (iring below)
        
        % reverse if ~cw
        if ~ispolycw(p1x,p1y)
            p1x=flipud(p1x);
            p1y=flipud(p1y);
        end

        %clf
        if Verbose2,line(p1x,p1y,'Color','r');drawnow;end
        
        bbox1=bbox(current_poly,:);
        if Verbose2,boxx(bbox1);drawnow;end
        
        % length of next segment
        next_iring=length(Conn{current_poly});
        
        for k=current_poly+1:length(Conn)
            
            bbox2=bbox(k,:);
            if Verbose2,boxx(bbox2);drawnow;end

            if bbox2(1)>bbox1(1) && bbox2(2)<bbox1(2) && bbox2(3)>bbox1(3) && bbox2(4)<bbox1(4) 
                
                % OK, we're in the bounding box of the main polygon
                % next, check if this polygon is actually within the main
                % polygon, and not just within the bounding box...
                inpoly=inpolygon(x(Conn{k}),y(Conn{k}),x(Conn{current_poly}),y(Conn{current_poly}));
                
                % if all points in x(Conn{k}),y(Conn{k}) are in the main
                % polygon, add length to iring, flip order if needed, add
                % to coord list (with NaN separating segments)
                % IT turns out that we don't really need iring for MATLAB's
                % ShapeWrite, but we may for other libraries (java,
                % python, etc)....
                if all(inpoly)
                    
                    iring=[iring next_iring];
                    
                    p2x=x(Conn{k});
                    p2y=y(Conn{k});
                    if ispolycw(p2x,p2y)
                        p2x=flipud(p2x);
                        p2y=flipud(p2y);
                    end
                    if Verbose2,line(p2x,p2y,'Color','g');drawnow;end
                    
                    p1x=[p1x; NaN; p2x];
                    p1y=[p1y; NaN; p2y];
                    
                    next_iring=length(Conn{k});
                    Conn{k}=[];
                end
                
            end
        end
        
        if Verbose2,fprintf('   %d polygons merged into one.\n',length(iring));end
        
        % construct the shape for this bin level.  
        SS(c).Geometry='Polygon';
        SS(c).BoundingBox=[min(x(Conn{current_poly})) max(x(Conn{current_poly})); min(y(Conn{current_poly})) max(y(Conn{current_poly}))];
        %SS(c).NumParts=length(iring);
        %SS(c).NumPoints=length(p1x);
        %SS(c).Parts=iring;
        SS(c).Lon=p1x';
        SS(c).Lat=p1y';
        com=sprintf('SS(c).%s=(bin_centers(ii));',FeatureName);
        eval(com);
%        SS(c).WaterLevel=(bin_centers(ii));

        % delete used polygons
        Conn{current_poly}=[];
        for k=length(Conn):-1:1
            if isempty(Conn{k})
                Conn(k)=[];
                bbox(k,:)=[];
            end
        end
        
        if isempty(Conn)
            done=true;
            break
        end
    end

end

% create a symbol specification for plotting this shape file in MATLAB.  
% this is specific to MATLAB
if nargout==3
    arg='makesymbolspec(''Polygon''';
    cmap=jet(length(bin_centers));
    % generate a spec file for mapview
    for i=1:length(list)
        c=sprintf('[%f %f %f]',cmap(i,:));
        temp=sprintf('{\''%s\'',%.5f,\''%s\'',%s}',FeatureName,mean(edges(i:i+1)),'FaceColor',c);
        arg=sprintf('%s,%s',arg,temp);
    end
    spec=sprintf('%s)',arg);
    spec=eval(spec);
end



end % end of main function



function h=boxx(ax,varargin)

    h=line(ax(:,[1 2 2 1 1])',ax(:,[3 3 4 4 3])',varargin{:});

end


function [Conn,kk]=bnd_conn2(bnd,x,y)
    %
    % BND_CONN computes ordered boundary connectivity lists
    %
    %	output vars:
    %		conn	- structure containing ordered boundary
    %			  lists for each closed boundary
    %		kk	- number of boundaries found
    %
    %	[conn,kk]=bnd_conn(fem_struct);
    %
    % Calls: coastline/comparea
    %
    % Catherine R. Edwards
    % Last modified: 31 Jul 2001
    %

    tmpbnd=bnd;
    kk=0;
    %maxar=0;
    while(~isempty(tmpbnd))
        connected=false;
        strnn=tmpbnd(1,1);
        nextnn=tmpbnd(1,2);
        %conbnd=NaN*ones(length(fem_struct.bnd),1);
        conbnd=[tmpbnd(1,1) nextnn];
        tmpbnd=tmpbnd(2:end,:);
        %prevnn=0;

        %hh=line(x(strnn),y(strnn),'Marker','*','Color','b','MarkerSize',20);
        while ~connected

            [i,j]=find(tmpbnd==nextnn);
            if length(i)>1
                %fprintf('here: %d\n',kk)
                jj=rem(j,2)+1;
                possible_connections=NaN*ones(length(i),1);
                for ii=1:length(i)
                    possible_connections(ii)=tmpbnd(i(ii),jj(ii));
                end
                dx=x(isfinite(possible_connections))-x(nextnn);
                dy=y(isfinite(possible_connections))-y(nextnn);
                ang=atan2(dy,dx)*180/pi;
                idx=ang<0;
                ang(idx)=ang(idx)+360;
                [~,idx]=min(ang);
                i=i(idx);
            end

            connr=setdiff(tmpbnd(i,:),nextnn);
            %line(x(connr),y(connr),'Marker','o','Color','r','MarkerSize',16);
            %drawnow
            %disp([prevnn nextnn connr])
            conbnd=[conbnd connr];
            tmpbnd(i,:)=[];
            if connr==strnn  % reached the starting node number.  loop is closed
                connected=true;
                kk=kk+1;
                %line(x(conbnd),y(conbnd),'LineStyle','-','Color','g','LineWidth',2)
                %drawnow
            end
            %prevnn=nextnn;
            nextnn=connr;
        end
        %delete(hh)
        %     % do area check to determine whether points are ordered CW/CCW; flip CW
        %     conbnd=conbnd(:);
        %     ar=comparea(x(conbnd),y(conbnd))
        %     iscw=sign(ar);
        %     if(iscw>0)
        %         conbnd=flipud(conbnd);
        %     end
        %
        Conn{kk}=conbnd;

    end
end


% function area = comparea(x,y,dim)
%     %COMPAREA Area of polygon.
%     %
%     %   COMPAREA is a modified version of the Matlab supplied POLYAREA. The
%     %      area of a polygon is negative if the points are ordered
%     %      counter-clockwise
%     
%     if nargin==1, error('Not enough inputs.'); end
%     
%     if ~isequal(size(x),size(y)), error('X and Y must be the same size.'); end
%     
%     if nargin==2,
%         [x,nshifts] = shiftdim(x);
%         y = shiftdim(y);
%     elseif nargin==3,
%         perm = [dim:max(length(size(x)),dim) 1:dim-1];
%         x = permute(x,perm);
%         y = permute(y,perm);
%     end
%     
%     siz = size(x);
%     if ~isempty(x),
%         area = reshape((sum( (x([2:siz(1) 1],:) - x(:,:)).* ...
%             (y([2:siz(1) 1],:) + y(:,:)))/2),[1 siz(2:end)]);
%     else
%         area = sum(x); % SUM produces the right value for all empty cases
%     end
%     
%     if nargin==2,
%         area = shiftdim(area,-nshifts);
%     elseif nargin==3,
%         area = ipermute(area,perm);
%     end
% 
% end
% 


function bnd=detbndy2(in)
    %DETBNDY compute a boundary segment list for a FEM domain
    % DETBNDY bnd=detbndy(e);
    %         This function computes a boundary for the FEM domain
    %         described a file containing element connectivity list (e).
    %
    % Input:  ele -  element list; 3 (.tri) or 4 (.ele) columns wide
    % Output: bnd -  a 2-column list of boundary-node numbers, returned
    %                to the local workspace
    %
    %         The output boundary list are pairs of node numbers, not
    %         coordinates, describing the edges of elements on the
    %         exterior of the domain, including islands.  The segments
    %         are not connected.
    %
    %         Call as: bnd=detbndy(e);
    %
    % Written by : Brian O. Blanton at The University of North Carolina
    %              at Chapel Hill, Mar 1995.
    %

    % DEFINE ERROR STRINGS
    err1='Only one input argument to DETBNDY. Type "help detbndy"';
    err2='Element list passed to DETBNDY does not have 3 or 4 columns';

    % check argument list
    if nargin~=1
        error(err1);
    end

    % Check size of element list
    [~,ncol]=size(in);
    if ncol < 3 || ncol > 4
        error(err2);
    elseif ncol==4
        in=in(:,2:4);
    end

    % Form (i,j) connection list from .ele element list
    %
    i=in;
    j=circshift(in,[0 -1]);

    % Form the sparse adjacency matrix and add transpose.
    %
    n = max(max(i(:)),max(j(:)));
    A = sparse(i,j,1,n,n);
    A = A + A';

    % Consider only the upper part of A, since A is symmetric
    %
    %A=A.*triu(A);
    A=triu(A);

    % The boundary segments are A's with value == 1
    % Interior segments (shared by 2 elements) are at value == 2
    %B=A==1;
    %Bi=A==2;

    % Extract the row,col from B for the boundary list.
    %
    [ib,jb,~]=find(A==1);
    bnd=[ib(:),jb(:)];
    
end


