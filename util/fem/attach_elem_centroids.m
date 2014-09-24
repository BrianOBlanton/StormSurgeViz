function fgsout=attach_elem_centroids(fgsin)
%ATTACH_ELEM_CENTROIDS attach element centroids to a fem_grid_struct
% Call as: fgsout=attach_elem_centroids(fgsin);


if nargin==0 & nargout==0
   disp('fgsout=attach_elem_centroids(fgsin);')
   return
end

% Copy incoming fem_grid_struct for operations
fgsout=fgsin;

fgsout.xecen=mean(fgsin.x(fgsin.e'))';
fgsout.yecen=mean(fgsin.y(fgsin.e'))';
fgsout.zecen=mean(fgsin.z(fgsin.e'))';


