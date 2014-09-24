function  retval=vecplot(xin,yin,uin,vin,varargin)
%VECPLOT draw vectors on the current axes  
% VECPLOT draws vectors on the current axes, given 
% vector origins (x,y) and vector magnitudes (u,v).
%
% VECPLOT scales the magnitude of 
% (u,v) by the magnitude of max(abs(u,v)) and then 
% forces a vector of magnitude sc to be 10% of the x data
% range.  By default, sc = 1., so that a 1 m/s vector will
% be scaled to 10% of the x data range.  If sc=.5, then
% a vector magnitude of 50 cm/s  will be scaled to 10% of the 
% x data range.  Decreasing sc serves to make the vectors
% appear larger.  VECPLOT draws a vector scale according to
% the user input (see below).
%      
%   INPUT:   x,y    - vector origins
%            u,v    - vector amplitudes
%            'help' - if the only argument to VECPLOT is 'help'
%                     additional information on its usage is returned
%                     to the screen.
%
%  OUTPUT:   h - vector of handles to the vector lines drawn, the 
%                the scale vector text, and the scale vector handles.
%                Type >> vecplot('help') for details.
%                If the 'stick' method is used, then h is ordered like:
%                h(1) -> vector shaft object (Tag=vectors')
%                h(2) -> stick vector origin object (Tag=vecrots')
%                h(3) -> scale vector text object (Tag=scaletext')
%                h(4) -> scale vector shaft object (Tag=scalearrow')
%                h(5) -> scale vector origin object (Tag=scalearrow')
%                If the 'arrow' method is used, then h is ordered like:
%                h(1) -> vector object (Tag=vectors')
%                h(2) -> scale vector text object (Tag=scaletext')
%                h(3) -> scale vector object (Tag=scalearrow')
%
% PN/PV pairs accepted by VECPLOT:
%    ArrowAngle - angle (in degrees) that the arrow head wings
%                 make with the shaft. Default=25
%    DotColor   - origin symbol color, for VecType=='stick'. Default='k'.
%    DotSize    - origin symbol size, for VecType=='stick'. Default=10.
%    DotStyle   - origin symbol, or VecType=='stick'. Default='.'.
%    MaxThresh  - Maximum vector magnitude to plot. Default=Inf.
%    MinThresh  - Minimum vector magnitude to plot. Default=0.
%    PctAxis    - Percent of axis for scale length. Default=10.
%    ScaleFac   - vector scaling factor. Default=1.
%    ScaleLabel - label for vector scale; 'no scale' prevents scale
%                 from being drawn; Default='m/s'.
%    ScaleType  - how to draw the vector scale, either 'fixed' or
%                 'floating'; Default='fixed'.
%    ScaleXor   - scale x-origin; Default=[].
%    ScaleYor   - scale y-origin; Default=[].
%    Stride     - amount to stride over in drawing vectors. Default=1, 
%                 meaning no stride.
%    VecType    - vector drawing method, either 'arrow' or 'stick';
%                 Default='arrow'.
%          
%   NOTES:   VECPLOT requires atleast 2 coordinates and vectors.
%
%    CALL:   hv=vecplot(x,y,u,v,pn1,pv1,...);
%
% Written by : Brian O. Blanton
%

% DEFINE ERROR STRINGS
err1=['Invalid number of input arguments to VECPLOT'];
err2=['VECPLOT no longer can accept a fem_grid_struct.'];
err3=['Lengths of x,y,u,v must be the same'];
err4=['Length of (x,y) must equal length of (u,v).'];
err5=['Alteast 3 arguments are required if first is a fem_grid_struct.'];
err6=['Alteast 4 arguments are required if first two are x,y.'];
err7=['Second optional argument (sclab) must be a string.'];
err8=['Both x- and y-coords of vector scale must be specified.'];

if nargin==0,disp('Call as: hv=vecplot(x,y,u,v,pn1,pv1,...)');return;end
if nargin==1,vecplothelp(xin);return;end

if nargin<4
   error(err1)
end

if isstruct(xin)
   error(err2)
end

% Check lengths of x,y,u,v
if length(uin)~=length(vin) | length(xin)~=length(yin) | length(xin)~=length(uin)
  error(err3)
end

% Default propertyname values
MinThresh=0.;
MaxThresh=Inf;
ScaleLabel='m/s';
ScaleType='fixed';
Stride=1;
VecType='arrow';
ScaleFac=1.;
ScaleXor=[];
ScaleYor=[];
PctAxis=10;
MsgHandle=[];

% Strip off propertyname/value pairs in varargin not related to
% "line" object properties.
k=1;
while k<length(varargin),
  switch lower(varargin{k}),
    case 'maxthresh',
      MaxThresh=varargin{k+1};
      varargin([k k+1])=[];
    case 'minthresh',
      MinThresh=varargin{k+1};
      varargin([k k+1])=[];
    case 'stride',
      Stride=varargin{k+1};
      varargin([k k+1])=[];
    case 'scaletype',
      ScaleType=varargin{k+1};
      varargin([k k+1])=[];
    case 'scalexor',
      ScaleXor=varargin{k+1};
      varargin([k k+1])=[];
    case 'scaleyor',
      ScaleYor=varargin{k+1};
      varargin([k k+1])=[];
    case 'scalelabel',
      ScaleLabel=varargin{k+1};
      varargin([k k+1])=[];
    case 'scalefac',
      ScaleFac=varargin{k+1};
      varargin([k k+1])=[];
    case 'pctaxis',
      PctAxis=varargin{k+1};
      varargin([k k+1])=[];
    case 'msghandle',
      MsgHandle=varargin{k+1};
      varargin([k k+1])=[];
    case 'vectype',
      VecType=lower(varargin{k+1});
      if strcmp(VecType,{'arrow','stick'})
         error('Invalid VecType to VECPLOT.')
      end
      varargin([k k+1])=[];
    otherwise
      k=k+2;
  end;
end;

if length(varargin)<2
   varargin={};
end

if xor(isempty(ScaleXor),isempty(ScaleYor))
   error(err8)
end

%
% save the current value of the current figure's WindowButtonDownFcn,
% WindowButtonMotionFcn, and WindowButtonUpFcn
%
% WindowButtonDownFcn=get(gcf,'WindowButtonDownFcn');
% WindowButtonMotionFcn=get(gcf,'WindowButtonMotionFcn');
% WindowButtonUpFcn=get(gcf,'WindowButtonUpFcn');
% set(gcf,'WindowButtonDownFcn','');
% set(gcf,'WindowButtonMotionFcn','');
% set(gcf,'WindowButtonUpFcn','');


% SCALE VELOCITY DATA TO RENDERED WINDOW SCALE 
%
RLs= get(gca,'XLim');
xr=RLs(2)-RLs(1);
X1=RLs(1);
X2=RLs(2);
RLs= get(gca,'YLim');
yr=RLs(2)-RLs(1);
Y1=RLs(1);
Y2=RLs(2);

% IF RenderLimits NOT SET, USE RANGE OF DATA
%
if(xr==0||yr==0)
   error('Axes must have been previously set for VECPLOT to work');
end
pct10=(PctAxis/100)*xr;   


% determine striding, if needed
[m,n]=size(xin);
if Stride >1
   if any([m n]==1)
      i=1:Stride:length(xin);
      x=xin(i);
      y=yin(i);
      u=uin(i);
      v=vin(i);
   else
      %BOB, fixed bug in striding when inputs are
      % not in row-vectors 6 Mar, 2004
      i=(1:Stride:m)';
      j=(1:Stride:n)';
      x=xin(i,j);
      y=yin(i,j);
      u=uin(i,j);
      v=vin(i,j);
   end
else
%   i=1:Stride:length(xin);
   x=xin;
   y=yin;
   u=uin;
   v=vin;
end

x=x(:);
y=y(:);
u=u(:);
v=v(:);

%FILTER DATA THROUGH VIEWING WINDOW
%
filt=find(x>=X1&x<=X2&y>=Y1&y<=Y2);
x=x(filt);
y=y(filt);
u=u(filt);
v=v(filt);

% Delete any NaN's
mag=sqrt(u.*u+v.*v);   % Unit mag
%mag=mag/max(mag);
iding=find(isnan(mag));

% Further eliminate vectors whose magnitude is at or below MinThresh.
%iding=[iding;find(mag<=MinThresh/100)];
iding=[iding;find(mag<=MinThresh)];

% Further eliminate vectors whose magnitude is at or above MaxThresh.
%iding=[iding;find(mag>=MaxThresh)];
iding=[iding;find(mag>=MaxThresh)];
x(iding)=[];
y(iding)=[];
u(iding)=[];
v(iding)=[];

% SCALE BY ScaleFac IN U AND V
%
us=u/ScaleFac;
vs=v/ScaleFac;

% SCALE TO 10 PERCENT OF X RANGE
%
us=us*pct10;
vs=vs*pct10;

% SEND VECTORS TO DRAWVEC ROUTINE
%
switch VecType
   case 'arrow'
      %Strip out attributes not used in arrow mode.
      k=1;
      while k<length(varargin),
	 switch lower(varargin{k}),
	    case 'dotcolor',
	      varargin([k k+1])=[];
	    case 'dotsize',
	       varargin([k k+1])=[];
	    case 'dotstyle',
	       varargin([k k+1])=[];
	    otherwise
	       k=k+2;
	 end
      end
      if length(varargin)<2
	 varargin={};
      end
      
      hp=drawvec(x,y,us,vs,varargin{:});
      set(hp,'UserData',[xin yin uin vin]);
   case 'stick'
      hp=drawstick(x,y,us,vs,varargin{:});
      set(hp(1),'UserData',[xin yin uin vin]);
   otherwise
      error('Invalid VecType Property Value to VECPLOT.')
end      
set(hp,'Tag','vectors');

nz=2*ones(size(get(hp,'XData')));
set(hp,'ZData',nz);
drawnow



% COLOR LARGEST VECTOR RED
%[trash,imax]=max(sqrt(us.*us+vs.*vs));
%hvmax=drawvec(x(imax),y(imax),us(imax),vs(imax),25,'r');
%set(hvmax,'Tag','scalearrow');


if ~strcmp(blank(ScaleLabel),'no scale')
   [ht1,scaletext,scaleaxes]=drawvecscale(ScaleLabel,ScaleXor,ScaleYor,...
          VecType,ScaleType,ScaleFac,pct10,Y1,Y2,varargin{:}); 
else
   ht1=[];scaletext=[];scaleaxes=[];
end

% OUTPUT IF DESIRED
%

if nargout==1,retval=[hp; scaletext; ht1(:); scaleaxes];,end

%
% return the saved values of the current figure's WindowButtonDownFcn,
% WindowButtonMotionFcn, and WindowButtonUpFcn to the current figure
%
% set(gcf,'WindowButtonDownFcn',WindowButtonDownFcn);
% set(gcf,'WindowButtonMotionFcn',WindowButtonMotionFcn);
% set(gcf,'WindowButtonUpFcn',WindowButtonUpFcn);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%  PRIVATE FUNCTION TO DRAW VECTOR SCALE   %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ht1,scaletext,scale_axes]=drawvecscale(ScaleLabel,...
          ScaleXor,ScaleYor,...
          VecType,ScaleType,ScaleFac,pct10,Y1,Y2,varargin)

% PLACE SCALE WITH MOUSE ON SCREEN
%
CurrentPointer=get(gcf,'Pointer');
if (isempty(ScaleXor) || isempty(ScaleYor)) && strcmp(ScaleType,'fixed')
    %disp('place scale on plot with a mouse button');
    set(gcf,'Pointer','cross');
    waitforbuttonpress;
    cp=get(gca,'CurrentPoint');
    ScaleXor=cp(1);ScaleYor=cp(3);
end

% switch lower(ScaleType)
%     
%     case 'fixed'
        
        sctext=[num2str(ScaleFac) ScaleLabel];
        scaletext=text((ScaleXor+ScaleXor+pct10)/2,ScaleYor-(Y2-Y1)*(.025),3,sctext,'Clipping','off');
        set(scaletext,'HorizontalAlignment','center');
        set(scaletext,'VerticalAlignment','middle');
        set(scaletext,'Tag','scaletext','FontSize',15,'FontWeight','bold');

        dx=pct10/10;
        dy=pct10/3;
        bx=[ScaleXor-dx ScaleXor+pct10+dx ScaleXor+pct10+dx ScaleXor-dx       ScaleXor-dx];
        by=[ScaleYor-dy ScaleYor-dy       ScaleYor+dy       ScaleYor+dy       ScaleYor-dy];
        scale_axes=patch(bx,by,3*ones(size(by)),'k');
        set(scale_axes,'CDataMapping','scaled','EdgeColor','k','LineWidth',2,'FaceColor',[1 1 1]*.5,'Tag','scalebox','Clipping','off')
        set(scale_axes,'EdgeAlpha',0,'FaceAlpha',0)
        
        switch VecType
            case 'arrow'
                ht1=drawvec(ScaleXor,ScaleYor,pct10,0.,varargin{:},'Clipping','off');
            case 'stick'
                ht1=drawstick(ScaleXor,ScaleYor,pct10,0.,varargin{:},'Clipping','off');
        end
        nz=3*ones(size(get(ht1,'XData')));
        set(ht1,'ZData',nz);
        set(ht1,'Tag','scalearrow');
        
           
%     case 'floating'
%         mainax=gca;
%         % Draw vector scale
%         data_axis=axis;
%         xdif=data_axis(2)-data_axis(1);
%         ydif=data_axis(4)-data_axis(3);
%         dx1=data_axis(1)+xdif*.8;
%         dx2=data_axis(2);
%         dy1=data_axis(3);
%         dy2=data_axis(3)+ydif*.1;
%         
%         cur_units=get(gca,'Units');
%         set(gca,'Units','normalized');
%         axnorm=get(gca,'Position');
%         
%         if isempty(ScaleXor)
%             xstart=0;
%             ystart=0;
%         else
%             xtemp=(ScaleXor-data_axis(1))/xdif;
%             ytemp=(ScaleYor-data_axis(3))/ydif;
%             oldfigunits=get(gcf,'Units');
%             set(gcf,'Units','pixels');
%             figpixunits=get(gcf,'Position');
%             set(gcf,'Units',oldfigunits);
%             oldaxesunits=get(gca,'Units');
%             set(gca,'Units','pixels');
%             axespixunits=get(gca,'Position');
%             set(gca,'Units',oldaxesunits);
%             
%             xstart=(xtemp*axespixunits(3)+axespixunits(1))/figpixunits(3);
%             ystart=(ytemp*axespixunits(4)+axespixunits(2))/figpixunits(4);
%             
%         end
%         
%         dx=axnorm(3)*.1;
%         dy=axnorm(4)*.1;
%         scale_axes=axes('Units','normalized','Position',[xstart ystart dx dy]);
%         %scale_axes=axes('Units','normalized','Position',[0 0 dx dy]);
%         axis([dx1 dx2 dy1 dy2])
%         sc_or_x=dx1+(dx2-dx1)/10;
%         switch VecType
%             case 'arrow'
%                 ht1=drawvec(sc_or_x,(dy1+dy2)/2.,pct10,0.,varargin{:});
%             case 'stick'
%                 ht1=drawstick(sc_or_x,(dy1+dy2)/2.,pct10,0.,varargin{:});
%         end
%         
%         set(ht1,'Tag','scalearrow');
%         sctext=[num2str(ScaleFac) ScaleLabel];
%         scaletext=text((dx1+dx2)/2,dy1+(dy2-dy1)/8,sctext);
%         set(scaletext,'HorizontalAlignment','center');
%         set(scaletext,'VerticalAlignment','middle');
%         set(scaletext,'Tag','scaletext');
%         drawnow
%         set(scale_axes,'XTick',[],'YTick',[],'Box','on')
%         set(scale_axes,'Tag','vecscaleaxes');
%         set(scale_axes,'ButtonDownFcn','selectmoveresize');
%         %set(scale_axes,'Color',(get(mainax,'Color')))
%         set(scale_axes,'Visible','on')
%         axes(mainax)
%     otherwise
%         error('Invalid ScaleType Property Value in VECPLOT.')
% end
set(gcf,'Pointer',CurrentPointer);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%  PRIVATE FUNCTION FOR VECPLOT HELP   %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function vecplothelp(arg)

if ~isstr(arg)
    error('invalid help string to VECPLOT')
end

switch arg
    case 'help'
        disp('VECPLOT additional help section')
        str=[];
        str=[str sprintf('\n')];
        str=[str sprintf('VECPLOT returns a vector of handles to objects\n')];
        str=[str sprintf('drawn in the current axes.  The vector contains: \n')];
        str=[str sprintf('   If the ''stick'' method is used, then h is ordered like:\n')];
        str=[str sprintf('      h(1) -> vector shaft object (Tag=vectors)\n')];
        str=[str sprintf('      h(2) -> stick vector origin object (Tag=vecrots)\n')];
        str=[str sprintf('      h(3) -> scale vector text object (Tag=scaletext)\n')];
        str=[str sprintf('      h(4) -> scale vector shaft object (Tag=scalearrow)\n')];
        str=[str sprintf('      h(5) -> scale vector origin object (Tag=scalearrow)\n')];
        str=[str sprintf('\n   If the ''arrow'' method is used, then h is ordered like:\n')];
        str=[str sprintf('      h(1) -> vector object (Tag=vectors)\n')];
        str=[str sprintf('      h(2) -> scale vector text object (Tag=scaletext)\n')];
        str=[str sprintf('      h(3) -> scale vector object (Tag=scalearrow)\n')];
        
        str=[str sprintf('\nPN/PV pairs accepted by VECPLOT:\n')];
        str=[str sprintf('    ArrowAngle - angle (in degrees) that the arrow head wings\n')];
        str=[str sprintf('                             make with the shaft. Default=25.\n')];
        str=[str sprintf('    DotColor   - origin symbol color, for VecType==''stick''. Default=''k''\n')];
        str=[str sprintf('    DotSize    - origin symbol size, for VecType==''stick''. Default=10\n')];
        str=[str sprintf('    DotStyle   - origin symbol, or VecType==''stick''. Default=''.''\n')];
        str=[str sprintf('    MaxThresh  - Maximum vector magnitude to plot. Default=Inf.\n')];
        str=[str sprintf('    MinThresh  - Minimum vector magnitude to plot. Default=0.\n')];
        str=[str sprintf('    ScaleFac   - vector scaling factor. Default=1.\n')];
        str=[str sprintf('    ScaleLabel - label for vector scale; ''no scale'' prevents scale\n')];
        str=[str sprintf('		               from being drawn; Default=''m/s''.\n')];
        str=[str sprintf('    ScaleType  - how to draw the vector scale, either ''fixed'' or\n')];
        str=[str sprintf('		               ''floating''; Default=''fixed''.\n')];
        str=[str sprintf('    ScaleXor  - scale x-origin; Default=[].\n')];
        str=[str sprintf('    ScaleYor  - scale y-origin; Default=[].\n')];
        str=[str sprintf('    Stride     - amount to stride over in drawing vectors. Default=1,\n')];
        str=[str sprintf('		               meaning no stride. Stride=2 skips every other point.\n')];
        str=[str sprintf('    VecType    - vector drawing method, either ''arrow'' or ''stick'';\n')];
        str=[str sprintf('		               Default=''arrow''.\n')];
        title1='VECPLOT Additional Help';
        
    otherwise
        error('invalid help string to VECPLOT')
end

if ~isempty(str)
    helpwin(str,title1);
end

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
%        SUMMER 1998
%
