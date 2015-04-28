function v=GetCurrentEnsIndex(Handles)
v=get(Handles.EnsButtonHandles,'Value');
if iscell(v)
    v=find(cell2mat(v)==1);
end




