function h=plotcities(varargin)
cities=varargin{1};
varargin(1)=[];


pop=[cities.POP_2000]';
popl=floor(log10(pop));
x=[cities.X]';
y=[cities.Y]';

idx4=find(popl==4);
idx5=find(popl==5);
idx6=find(popl==6);

h(1)=line(x(idx4),y(idx4),ones(size(x(idx4))),'Marker','.','Color','b','LineStyle','none','MarkerSize',5,'Clipping','on',varargin{:});
h(2)=line(x(idx5),y(idx5),ones(size(x(idx5))),'Marker','.','Color','k','LineStyle','none','MarkerSize',10,'Clipping','on',varargin{:});
h(3)=line(x(idx6),y(idx6),ones(size(x(idx6))),'Marker','.','Color','r','LineStyle','none','MarkerSize',15,'Clipping','on',varargin{:});

if nargout==0,clear h, end