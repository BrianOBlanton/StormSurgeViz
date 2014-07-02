function S=PlotAtcfShapefile(S)

co=get(gca,'ColorOrder');

j=0;
if isfield(S,'lin')  
    for i=1:length(S.lin)
        j=j+1;
        h(j)=line(S.lin(i).X,S.lin(i).Y,2*ones(size(S.lin(i).Y)),...
            'Color',co(i,:),'Tag','AtcfTrackShape','LineWidth',2,...
            'LineStyle','--','Clipping','on');
    end
end

if isfield(S,'pgn')
    for i=1:length(S.pgn)
        j=j+1;
        h(j)=line(S.pgn(i).X,S.pgn(i).Y,2*ones(size(S.pgn(i).Y)),...
            'Color',co(i,:),'Linewidth',2,'Tag','AtcfTrackShape',...
            'Clipping','on');
    end
end

if isfield(S,'pts')
    for i=1:length(S.pts)
        j=j+1;
        h(j)=line(S.pts(i).X,S.pts(i).Y,2*ones(size(S.pts(i).Y)),'Color','k','Marker','o','LineStyle','none','Tag','AtcfTrackShape','Clipping','on');
    end
end


% if isfield(S,'ww')
%     for i=1:length(S.ww)
%         j=j+1;
%         switch S.ww(i).TCWW
%             case 'HWR'  %  Hurricane Warning
%                 c='r';
%             case 'HWA'  %  Hurricane Watch  
%                 c=[251 216 201]/256;
%             case 'TWR'  % Tropical Storm Warning
%                 c='b';
%             case 'TWA'  % Tropical Storm Watch
%                 c='y';
%         end
%         h(j)=line(S.ww(i).X,S.ww(i).Y,2*ones(size(S.ww(i).Y)),'Color',c,'Linewidth',2,'Tag','AtcfTrackShape','Clipping','on');
%     end
% end


