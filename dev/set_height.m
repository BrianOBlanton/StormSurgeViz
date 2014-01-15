function set_height(h,newz)

if nargin~=2
  error('SET_HEIGHT needs 2 and only 2 input arguments.')
end

for i=1:length(h)  
   if ~ishandle(h(i))
     error('Handle to SET_HEIGHT is not valid. Terminal.')
   elseif strcmp(get(h(i),'Type'),'text')
      temp=get(h(i),'position');
      set(h(i),'Position',[temp(1) temp(2) newz])
   else
     nz=newz*ones(size(get(h(i),'XData')));
     set(h(i),'ZData',nz)
   end
end
