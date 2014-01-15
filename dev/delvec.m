function delvec
%DELVEC delete all objects related to vector plots from VECPLOT
delete(findobj(gca,'Type','line','Tag','vectors'))
delete(findobj(gca,'Type','line','Tag','scalearrow'))
delete(findobj(gca,'Type','text','Tag','scaletext'))
delete(findobj(gca,'Type','line','Tag','stickshafts'))
delete(findobj(gca,'Type','patch','Tag','scalebox'))
delete(findobj(gca,'Type','line','Tag','stickdots'))
delete(findobj(gcf,'Type','axes','Tag','vecscaleaxes'))
