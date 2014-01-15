function h=plotroads(varargin)
roads=varargin{1};
varargin(1)=[];


for i=1:length(roads)
    h(i)=line(roads(i).X,roads(i).Y,ones(size(roads(i).X)),'Color',[1 1 1]*.6,'Clipping','on',varargin{:});
end
if nargout==0,clear h, end

