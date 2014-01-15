function delcont
%DELCONT remove all contours (drawn by LCONTOUR) from current axes
% DELCONT a trivial script which removes all contours from the 
% current axes.
%
% Call as ">> delcont"
%
ch_gca=get(gca,'Ch');        %  children of the current axes
cont_objs=findobj(ch_gca,'Tag','contour');
delete(cont_objs);

%         Brian O. Blanton
%         Department of Marine Sciences
%         15-1A Venable Hall
%         CB# 3300
%         Uni. of North Carolina
%         Chapel Hill, NC
%                 27599-3300
%
%         919-962-4466
%         blanton@marine.unc.edu
