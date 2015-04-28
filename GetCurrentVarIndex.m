function v=GetCurrentVarIndex(Handles)
v=get(Handles.ScalarVarButtonHandles,'Value');
if iscell(v)
    v=find(cell2mat(v)==1);
end