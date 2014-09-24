function hp=drawstick(x,y,u,v,varargin) 
%DRAWSTICK draw sticks for vectors, as opposed to arrows.  
% DRAWSTICK routine to  draw vectors as sticks.
% A line eminates from the vector origins (xo,yo) with 
% "large" dots at the origins. No arrow heads are drawn.  
% Use VECPLOT for arrow heads.
%
% This is a fairly low-level routine in that in does no scaling 
% to the vectors.  This function is called primarily by VECPLOTSTICK 
% and returns the handle of the vector object drawn.
%
% All Input arguments to DRAWSTICK are required.
%
%  Inputs:  x,y     - vector origins
%           u,v     - vector components
%
% Outputs:  A 2-vector of handles to the sticks and dots drawn.
%           The first value is the handle to the dots, the second
%           a handle to the shafts.
%
% PN/PV pairs accepted by DRAWSTICK:
%       DotType - 'Marker' for vector origin, default = '.'
%       DotSize - 'MarkerSize' for vector origin symbol, default = 10
%       DotColor - 'Color' for origin 'Marker', default = 'k'
%
%       All other 'Line' propertyname/value pairs will be used to 
%       draw the sticks.
%
% Call as: >> hp=drawstick(x,y,u,v,pn1,pv1,...);
%

% Default option values
% Used only if VecType=='stick';
DotColor='k';
DotSize=6;
DotStyle='.';

% Strip off parameter/value pairs in varargin not related to
% "line" object properties.
k=1;
while k<length(varargin),
  switch lower(varargin{k}),
    case 'dotcolor',
      DotColor=varargin{k+1};
      varargin([k k+1])=[];
    case 'dotsize',
      DotSize=varargin{k+1};
      varargin([k k+1])=[];
    case 'dotstyle',
      DotStyle=varargin{k+1};
      varargin([k k+1])=[];
    otherwise
      k=k+2;
  end;
end;
if length(varargin)<2
   varargin={};
end

% COLUMNATE INPUT
%
x=x(:);y=y(:);u=u(:);v=v(:);

% DRAW STICK ORIGINS AS DOTS
%
ht=line(x,y,'Marker',DotStyle,'LineStyle','none',...
            'Color',DotColor,'Markersize',DotSize);
set(ht,'Tag','stickdots');

% COMPUTE SHAFT ENDS
%
xe = x + u;
ye = y + v;   
xe=xe(:);ye=ye(:); 
  
% BUILD PLOT MATRIX
%
xs=[x xe NaN*ones(size(x))]';
ys=[y ye NaN*ones(size(y))]';
xs=xs(:);
ys=ys(:);

hp=line(xs,ys,varargin{:});
set(hp,'Tag','stickshafts');
hp=[ht(:);hp(:)];
%
%LabSig  Brian O. Blanton
%        Department of Marine Sciences
%        12-7 Venable Hall
%        CB# 3300
%        University of North Carolna
%        Chapel Hill, NC
%                 27599-3300
%
%        brian_blanton@unc.edu
%


