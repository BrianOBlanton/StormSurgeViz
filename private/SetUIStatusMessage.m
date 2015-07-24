%%  SetUIStatusMessage
%%% SetUIStatusMessage
%%% SetUIStatusMessage
function SetUIStatusMessage(varargin)

    msg=varargin{1};

    MainFigure=findobj(0,'Tag','MainVizAppFigure');
    Handles=get(MainFigure,'UserData');

    StatusBarHandle=Handles.StatusBar;
    set(StatusBarHandle,'String',msg)
 
    if getappdata(Handles.MainFigure,'SendDiagnosticsToCommandWindow')
        fprintf('SSViz-- %s\n',msg)
    end
     
end

