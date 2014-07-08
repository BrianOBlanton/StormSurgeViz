function fem_grid_struct=grd_to_opnml(fort14name,verbose)
%GRD_TO_OPNML Convert an ADCIRC grd file to an OPNML fem_grid_struct.
% Convert an ADCIRC grd file to an OPNML fem_grid_struct.
% ADCIRC grid information assumed in "fort.14" format.
% The boundary/island information at the tail of the fort.14
% file is ignored.
%
% Input:  fort14name - path/name of fort.14 file;  if not passed,
%                      assumes fort.14 in the currect working dir.
% Output: fem_grid_struct - OPNML grid structure
%
% Call:   fem_grid_struct=grd_to_opnml(fort14name);
%         fem_grid_struct=grd_to_opnml;


if ~exist('verbose')
   verbose=false;
end

if ~islogical(verbose)
   error('Verbose arg to grd_to_opnml must be logical')
end


if ~exist('fort14name')
   % assume fort.14 filename in the current wd.
   fort14name='fort.14';
end
if verbose, fprintf('Scanning %s : ',fort14name), end

% Open fort.14 file
[f14,message]=fopen(fort14name,'r');
if (f14<0)
   error(message)
end

% Get grid info
gridname=fgetl(f14);

l=fgetl(f14);
[ne,the_rest]=strtok(l,' ');
ne=str2num(ne);
nn=str2num(strtok(the_rest));

% Get node locations
if verbose, fprintf('\nnodes = '),end
temp=fscanf(f14,'%d %f %f %f',[4 nn])';
x=temp(:,2);
y=temp(:,3);
z=temp(:,4);
if verbose, fprintf('%d ... ',nn),end

% Get elements
if verbose, fprintf('   elements = '),end 
temp=fscanf(f14,'%d %d %d %d %d',[5 ne])';
e=temp(:,3:5);
if verbose, fprintf('%d ... ',ne),end

fem_grid_struct.name=strtrim(gridname);
fem_grid_struct.x=x;
fem_grid_struct.y=y;
fem_grid_struct.z=z;
fem_grid_struct.e=e;
fem_grid_struct.bnd=detbndy(e);
fem_grid_struct.nn=length(x);
fem_grid_struct.ne=length(e);

% scan open boundary
if verbose, fprintf('   open boundary = '), end
fem_grid_struct.nopenboundaries=fscanf(f14,'%d',1);fgets(f14);
fem_grid_struct.elevation=fscanf(f14,'%d',1);fgets(f14);
if (fem_grid_struct.nopenboundaries==0)   
   fem_grid_struct.nopenboundarynodes=0;
   fem_grid_struct.ob={0};  
else

for i=1:fem_grid_struct.nopenboundaries
       fem_grid_struct.nopennodes{i}=fscanf(f14,'%d',1);
       fgets(f14);
       temp=fscanf(f14,'%d',fem_grid_struct.nopennodes{i});
       fem_grid_struct.ob{i}=temp;
    end
end
if verbose, fprintf('%d ... ',fem_grid_struct.nopenboundaries),end

% scan land boundary
if verbose, fprintf('\nland boundary segments = '),end 
fem_grid_struct.nland=fscanf(f14,'%d',1);fgets(f14);
fem_grid_struct.nlandnodestotal=fscanf(f14,'%d',1);fgets(f14);
if verbose, fprintf('%d ... ',fem_grid_struct.nland),end

n24=0;
n23=0;
n0=0;
n23nodes=0;
n24pairs=0;

%fem_grid_struct.nfluxnodes=[0];
fem_grid_struct.nlandnodes=[0];
fem_grid_struct.ibtype=[0];
fem_grid_struct.ln={0};
fem_grid_struct.weirheights={0};

for i=1:fem_grid_struct.nland

   temp=fscanf(f14,'%d',2);
   fgets(f14); % get remainder of line

   fem_grid_struct.nlandnodes(i)=temp(1);
   fem_grid_struct.ibtype(i)    =temp(2);

   switch fem_grid_struct.ibtype(i)    % On ibtype
   
   case {0, 1, 2, 10, 11, 12, 20, 21, 22, 30, 52} 
       temp=NaN*ones(fem_grid_struct.nlandnodes(i),1);
       for j=1:fem_grid_struct.nlandnodes(i)
          temp(j)=fscanf(f14,'%d',1);
          fgets(f14);
       end
      %temp=fscanf(f14,'%d',fem_grid_struct.nlandnodes(i));
      fem_grid_struct.ln{i}=temp;

   case {3, 13, 23}          % Exterior Boundary 
      n23=n23+1;
      temp=fscanf(f14,'%d %f %f',[3 fem_grid_struct.nlandnodes(i)])';
      n23nodes=n23nodes+fem_grid_struct.nlandnodes(i);
      fem_grid_struct.ln{i}=temp(:,1);
     
   case {4, 24}          % Node pairs for weirs
      n24=n24+1;
      temp=fscanf(f14,'%d %d %f %f %f',[5 fem_grid_struct.nlandnodes(i)])';
      n24pairs=n24pairs+fem_grid_struct.nlandnodes(i);
      fem_grid_struct.ln{i}=temp(:,1:2);
      fem_grid_struct.weirheights{i}=temp(:,3);
      
   otherwise
      disp(['Boundary type not coded: ' int2str(temp(2))])
   end
end

fclose(f14);

fem_grid_struct.n23nodes=n23nodes;
fem_grid_struct.n24pairs=n24pairs;
fem_grid_struct.nweir=n24;

fem_grid_struct=belint(fem_grid_struct);
fem_grid_struct=el_areas(fem_grid_struct);


if verbose, fprintf('Number of Weir segments = %d \n',n24), end

return
