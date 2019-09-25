function rpcell2dlg(c,ttl)

for i=1:size(c,1) 
    %fmt=sprintf('%%s   :   %%%ds  ',fwidth(j));
    rpt{i}=sprintf('%45s : %s',char(c{i,1}),char(c{i,2}));
end

dfs = get(0, 'DefaultUICOntrolFontSize');
dfn = get(0, 'DefaultUICOntrolFontName');
set(0,'DefaultUICOntrolFontName','Courier')
set(0,'DefaultUICOntrolFontSize',20)


[~,~]=listdlg('Name',sprintf('Run Properties for %s', ttl),...
    'ListString',rpt,'ListSize',[1800 700],'SelectionMode','single');

%'PromptString','Select a Catalog Entry or click Cancel.',...


set(0,'DefaultUICOntrolFontName',dfn)
set(0,'DefaultUICOntrolFontSize',dfs)
