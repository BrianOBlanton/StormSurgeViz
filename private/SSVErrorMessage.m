%%  SSVErrorMessage
%%% SSVErrorMessage
%%% SSVErrorMessage
function SSVErrorMessage(varargin)

    msg=varargin{1};

    MainFigure=findobj(0,'Tag','MainVizAppFigure');
    Handles=get(MainFigure,'UserData');

    StatusBarHandle=Handles.StatusBar;
    set(StatusBarHandle,'String',['Error: ' msg])
    drawnow
    if getappdata(Handles.MainFigure,'SendDiagnosticsToCommandWindow')
        fprintf('SSViz Error: %s\n',msg)
    end
     
end

