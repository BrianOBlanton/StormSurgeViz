function hp=drawvec(xo,yo,um,vm,varargin)
%DRAWVEC draw arrows for vectors
% DRAWVEC draws vectors on the current axes, given vector origins
% and component magnitudes.  No scaling is performed; use
% VECPLOT to scale and draw the vectors.  This function
% is called primarily by VECPLOT and returns the handle
% of the vector object drawn.
%
% Inputs: xo,yo  - vector origins; arrow eminates from this point
%         um,vm  - vector magnitudes
%
% Outputs: hp    - the handle to the vector object drawn
%
% PN/PV pairs accepted by DRAWVEC:
%       ArrowAngle - angle (in degrees) that the arrow head wings
%                    make with the shaft. default=25
%       ArrowFac   - Length ratio of arrow head relative to
%                    shaft. default=.25
%
% All other pn-pv pairs are passed to LINE
%  
% Call as:  hp=drawvec(xo,yo,um,vm,pn1,pv1,...);
%

fac = 3.14159/180.;

% Default PN/PV for DRAWVEC
ArrowAngle=25;
ArrowFac=.25;

% Strip off parameter/value pairs in varargin not related to
% "line" object properties.
k=1;
while k<length(varargin),
  switch lower(varargin{k}),
    case 'arrowangle',
      ArrowAngle=varargin{k+1};
      varargin([k k+1])=[];
    case 'arrowfac',
      ArrowFac=varargin{k+1};
      varargin([k k+1])=[];
    otherwise
      k=k+2;
  end;
end;
if length(varargin)<2
   varargin={};
end

% Conv to rads
arrowtheta = ArrowAngle*fac;

% columnate the input vectors to ensure they are 
% column-vectors, not row-vectors
xo=xo(:);
yo=yo(:);
um=um(:);
vm=vm(:);

% compute and draw arrow shaft
xe = xo + um;
ye = yo + vm;
arrowmag = ArrowFac*(sqrt((xo-xe).*(xo-xe)+(yo-ye).*(yo-ye)));
shafttheta = -atan2((ye-yo),(xe-xo));
xt = xe-arrowmag.*cos(arrowtheta);
yt = ye-arrowmag.*sin(arrowtheta);
x1 = (xt-xe).*cos(shafttheta)+(yt-ye).*sin(shafttheta)+xe;
y1 = (yt-ye).*cos(shafttheta)-(xt-xe).*sin(shafttheta)+ye;
xt = xe-arrowmag.*cos(-arrowtheta);
yt = ye-arrowmag.*sin(-arrowtheta);
x2 = (xt-xe).*cos(shafttheta)+(yt-ye).*sin(shafttheta)+xe;
y2 = (yt-ye).*cos(shafttheta)-(xt-xe).*sin(shafttheta)+ye;
x=ones(length(xo),6);
y=ones(length(xo),6);
x=[xo xe x1 xe x2 NaN*ones(size(xo))]';
y=[yo ye y1 ye y2 NaN*ones(size(yo))]';
x=x(:);
y=y(:);
hp=line(x,y,varargin{:});

%
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
