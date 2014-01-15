function deltext
%DELTEXT remove all text objects from the current axes
% DELTEXT a trivial script which removes all text objects from the 
% current axes.  This does NOT affect title, label, and
% axis text objects.  Those belong to the figure.
%
% Call as ">> deltext" or use in functions as "deltext;"

ch_gca=get(gca,'Ch');        %  children of the current axes
textobjs=findobj(ch_gca,'Type','text');
delete(textobjs);
%
%         Brian O. Blanton
%         Curr. in Marine Sciences
%         15-1A Venable Hall
%         CB# 3300
%         Uni. of North Carolina
%         Chapel Hill, NC
%                 27599-3300
%
%         919-962-4466
%         blanton@marine.unc.edu
%
