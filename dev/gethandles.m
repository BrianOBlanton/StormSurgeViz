function Handles=GetHandles

f=findobj(0,'Tag','MainVizAppFigure');
Handles=get(f,'UserData');

