function h=plotstates(varargin)
stateshape=varargin{1};
varargin(1)=[];

h=NaN*ones(length(stateshape),1);

for i=1:length(stateshape)
        h(i)=line(stateshape(i).X,stateshape(i).Y,ones(size(stateshape(i).Y)),'Clipping','on',varargin{:});
end
h(isnan(h))=[];

if nargout==0,clear h, end