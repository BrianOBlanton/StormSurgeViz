function [cout hout]=lcontour2(fem_grid_struct,Q,cval,varargin)
%LCONTOUR contour a scalar on a FEM grid.
%   LCONTOUR contours a scalar field on the input FEM grid.
%   LCONTOUR accepts a vector of values to be contoured 
%   over the provided mesh.  
%
%   INPUT : fem_grid_struct (from LOADGRID, see FEM_GRID_STRUCT)
%           Q    - scalar to be contoured upon; must be a 1-D vector 
%                  or the single character 'z', IN SINGLE QUOTES!!
%           cval - vector of values to contour
%
%           In order to contour the FEM domain bathymetry, pass
%           in the string 'z' in place of an actual scalar field Q.
%           You could, of course, pass in the actual bathymetry as
%           the scalar to contour.  Otherwise, Q must be a 1-D vector
%           with length equal to the number of nodes in the FEM mesh.
%
%           Any property name/value pair that LINE accepts can be 
%           passed to LCONTOUR. See LINE help for details.
%
%  OUTPUT :  h - the handle to the contour line(s) drawn
%
%    CALL : >> h=lcontour(fem_grid_struct,Q,cval,pn1,pv1,pn2,pv2,...)
%     OR    >> h=lcontour(fem_grid_struct,'z',cval,pn1,pv1,pn2,pv2,...)

% Written by : Brian O. Blanton
% 
% 07 Mar, 2004: moved drawing of contours outside of computational
%               loop to speed up rendering of graphics over slow
%               net connections
% 
% 
% 
% VERIFY INCOMING STRUCTURE
%

if ~isstruct(fem_grid_struct)
   msg=str2mat(' ',...
               'First argument to LCONTOUR not a structure.  Perhaps its',...
               'the element list.  If so you should use LCONTOUR4, which',...
               'takes the standard grid arrays (e,x,...).  The first ',...
               'argument to LCONTOUR MUST be a fem_grid_struct.',' ');
   disp(msg)
   error(' ')
end
if ~is_valid_struct(fem_grid_struct)
   error('    fem_grid_struct to LCONTOUR invalid.')
end

e=fem_grid_struct.e;
x=fem_grid_struct.x;
y=fem_grid_struct.y;

% DETERMINE SCALAR TO CONTOUR
%
if ischar(Q)
   Q=fem_grid_struct.z;
else
   % columnate Q
   Q=Q(:);
   [nrowQ,ncolQ]=size(Q);
   if nrowQ ~= length(x)
      error('Length of scalar must be same length as grid coordinates.');
   end   
end
 
% range of scalar quantity to be contoured; columnate cval
Qmax=max(Q);
Qmin=min(Q);
cval=cval(:);
h=[];
c=[];


for kk=1:length(cval)
%parfor (kk=1:length(cval))
 if (cval(kk) > Qmax) || (cval(kk) < Qmin)
      disp(sprintf('%s not within range of scalar field.  Min = %f  :  Max = %f',num2str(cval(kk)),Qmin,Qmax));
      h=[h;NaN];
 else
   
   if nargout>1
    % Call cmex function contmex5
    %keyboard   
      C=contmex5(x,y,e,Q,cval(kk));
      if(size(C,1)*size(C,2)~=1)
              X = [ C(:,1) C(:,3)]';
              Y = [ C(:,2) C(:,4)]';
              XX{kk} = X(:);
              YY{kk} = Y(:);
              len(kk)=length(X(:))/2;
      else
         disp(['CVal ' num2str(cval(kk)) ' within range but still invalid.']);
         h=[h;NaN];
         continue
      end
   
   % Jie:Plot the contours, if nargout is required, then extra sorting of the
   %     contour is required for CLABEL to work.
   
   % Do a temp connection so that the connectivity between 
   % neighbouring segments can be determined
    vecb    = (1:len(kk))';
    m       = 2*vecb-1;
    c1      = 0*m;
    c2      = 0*m;
    c1(m)   = C(:,1);
    c1(m+1) = C(:,3);
    c2(m)   = vecb;
    c2(m+1) = vecb;
    
    % Sort connectivity to place connected edges in sucessive rows
    [c1,i] = sort(c1); c2 = c2(i);
    
    % Connect adjacent adjusted nodes
    k    = 1;
    next = 1;
    while k<(2*len(kk))
        if c1(k)==c1(k+1)
            c1(next) = c2(k);
            c2(next) = c2(k+1);
            next     = next+1;
            k        = k+2;         % Skip over connected edge
        else
            k = k+1;                % Node has only 1 connection - will be picked up above
        end
    end
    ncc          = next-1; 
    c1(next:end) = []; 
    c2(next:end) = [];

% Form connectivity for the contour, connecting 
% its segments (rows in cc) with its vertices.

        ndx = ones(len(kk),1);
        n2e = zeros(len(kk),2);
        for k = 1:ncc
            % Vertices
            n1 = c1(k); n2 = c2(k);
            % Connectivity
            n2e(n1,ndx(n1)) = k; ndx(n1) = ndx(n1)+1;
            n2e(n2,ndx(n2)) = k; ndx(n2) = ndx(n2)+1;
        end        
        bndn = n2e(:,2)==0;         % Boundary nodes
        bnde = bndn(c1)|bndn(c2);   % Boundary edges
        % Alloc some space
        tmpv = zeros(1,ncc);
        
        % Loop through the points at the current contour level (cval(kk))
        % Try to assemble the CS data structure introduced in "contours.m"
        % so that clabel will work. Assemble CS by "walking" around each 
        % subcontour segment contiguously.
        ce    = 1;
        start = ce;
        next  = 2;
        cn    = c2(1);
        flag  = false(ncc,1);        
        xx     = tmpv; xx(1) =   C(c1(ce),3);
        yy     = tmpv; yy(1) =   C(c1(ce),4);
        
        for k = 1:ncc
            
            % Checked this edge
            flag(ce) = true;           
            % Add vertices to patch data

            if C(cn,1) == xx(next-1) 
            xx(next) = C(cn,3);
            yy(next) = C(cn,4);
            else
            xx(next) = C(cn,1);
            yy(next) = C(cn,2);                
            end
            next    = next+1;
            
            % Find edge (that is not ce) joined to cn
            if ce==n2e(cn,1)
                ce = n2e(cn,2);
            else
                ce = n2e(cn,1);
            end
            
            % Check the new edge
            if (ce==0)||(ce==start)||(flag(ce))     
               
                % Plot current subcontour as a patch and save handles
                xx   = xx(1:next-1);
                yy   = yy(1:next-1);
                zz   = cval(kk)*ones(1,next); 
              h   = [h; patch('XData',[xx,NaN],'YData',[yy,NaN],'ZData',zz, ...
                              'CData',-zz,'facecolor','none','linewidth',1,varargin{:})]; hold on  
%                 h   = [h; patch('Xdata',[xx,NaN],'Ydata',[yy,NaN],...
%                                'Cdata',zz,'facecolor','none','edgecolor','flat','linewidth',1)]; hold on  

                % Update the CS data structure as per "contours.m"
                % so that clabel works
                c = horzcat(c,[cval(kk), xx; next-1, yy]);
                
                if all(flag)    % No more points at cval(kk)
                    break
                else            % More points, but need to start a new subcontour
                    
                    % Find the unflagged edges
                    edges = find(~flag);
                    ce    = edges(1);
                    % Try to select a boundary edge so that we are 
                    % not repeatedly running into the boundary
                    for i = 1:length(edges)
                        if bnde(edges(i))
                            ce = edges(i); break
                        end
                    end
                    % Reset counters
                    start = ce;
                    next  = 2;
                    % Get the non bnd node in ce
                    if bndn(c2(ce))
                        cn = c1(ce);
                        % New patch vectors
                        xx = tmpv; xx(1) = C(c2(ce),3); 
                        yy = tmpv; yy(1) = C(c2(ce),4);
                    else
                        cn = c2(ce);
                        % New patch vectors
                        xx = tmpv; xx(1) = C(c1(ce),3);
                        yy = tmpv; yy(1) = C(c1(ce),4);
                    end                    
                end
            else                            
                % Find node (that is not cn) in ce
                if cn==c1(ce)
                    cn = c2(ce);
                else
                    cn = c1(ce);
                end
            end
        end    
  
   else  % no output, just plot the un-sorted contour
       % Call cmex function contmex5
       %keyboard

      C=contmex5(x,y,e,Q,cval(kk));
      if(size(C,1)*size(C,2)~=1)
              X = [ C(:,1) C(:,3) NaN*ones(size(C(:,1)))]';
              Y = [ C(:,2) C(:,4) NaN*ones(size(C(:,1)))]';
              XX{kk} = X(:);
              YY{kk} = Y(:);
              len(kk)=length(X(:));
              h(kk)=patch(XX{kk},YY{kk},ones(1,length(XX{kk}))*log(cval(kk))/5,'UserData',cval(kk),'Tag','contour');
      else
         disp(['CVal ' num2str(cval(kk)) ' within range but still invalid.']);
         h(kk)=NaN;
      end
%           if ~isnan(h(kk))
%            h(kk)=line(XX{kk},YY{kk},varargin{:},'UserData',cval(kk),'Tag','contour');
%              h(kk)=patch(XX{kk},YY{kk},ones(1,length(XX{kk}))*log(cval(kk))/5,'UserData',cval(kk),'Tag','contour');
%           end
   end   
 end
end
if nargout>1
    cout=c;  %Jie
%     cout=c(~isnan(c));
    hout=h(~isnan(h));
else
    cout=[];
    hout=h(~isnan(h));
end
return

%LabSig  Brian O. Blanton
%        Department of Marine Sciences
%        12-7 Venable Hall
%        CB# 3300
%        University of North Carolina
%        Chapel Hill, NC
%                 27599-3300
%
%        brian_blanton@unc.edu
%
%        Summer 1997
%            Mod 08 Mar, 2004   





 
