%%  SetUIStatusMessage
%%% SetUIStatusMessage
%%% SetUIStatusMessage
function SetUIStatusMessage(varargin)

    msg=varargin{1};
    if length(varargin)==2
        sendtocomwin=varargin{2};
    end

    MainFigure=findobj(0,'Tag','MainVizAppFigure');
    Handles=get(MainFigure,'UserData');

    StatusBarHandle=Handles.StatusBar;
    set(StatusBarHandle,'String',strrep(msg,'\n',''))
    drawnow
 
    if getappdata(Handles.MainFigure,'SendDiagnosticsToCommandWindow')
        if exist('sendtocomwin','var')
            if sendtocomwin
                fprintf(msg)
            end
        else
            fprintf(msg)
        end
    end
     
end

