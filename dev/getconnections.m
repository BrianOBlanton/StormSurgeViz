function Connections=GetConnections

f=findobj(0,'Tag','MainVizAppFigure');
Connections=getappdata(f,'Connections');

