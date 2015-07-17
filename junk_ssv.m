

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     FileNetcdfVariableNames={}; 
%     FilesToOpen={};              
%     VariableDisplayNames={};     
%     VariableNames={};
%     VariableTypes={};
%     VariableUnits={};
%     VariableUnitsFac={};

%     % read the variable list, which is actually an excel spreadsheet
%     % to make it easier to edit.  The first row is the variable names
%     % in this function, declared above as empty cells.
%     ff='AdcircVizVariableList.xls';
%     sheet=SSVizOpts.VariablesTable;
%     [~,~,C] = xlsread(ff,sheet);
%     [m,n]=size(C);
%     vars=C(1,:)';
%     for i=1:n
%         for j=2:m
%             thisvar=vars{i};
%             switch thisvar
%                 case {'VariableUnitsFac.mks','VariableUnitsFac.eng'}
%                     com=sprintf('%s{j-1}=%f;',thisvar, str2num(C{j,i})); %#ok<ST2NM>
%                 otherwise
%                     com=sprintf('%s{j-1}=''%s'';',thisvar,C{j,i});
%             end
%             eval(com)
%         end
%     end
%     % convert any FileNetcdfVariableNames from a 2-string string into a
%     % 2-element cell.
%     for i=1:m-1 
%         if strcmp(VariableTypes{i},'Vector')
%             temp=FileNetcdfVariableNames{i};
%             temp=textscan(temp,'%s %s');
%             temp={char(temp{1}) char(temp{2})};
%             FileNetcdfVariableNames{i}=temp; %#ok<AGROW>
%         end
%     end
    
%     if any(strcmpi(Url.Units,{'english','feet'}))
%         VariableUnitsFac=VariableUnitsFac.eng;
%         VariableUnits=VariableUnits.eng;
%     else
%         VariableUnitsFac=VariableUnitsFac.mks;
%         VariableUnits=VariableUnits.mks;
%     end




%%%%%%%%%%%%%%%%%%%%%%%%%
%    % add bathy as a variable
%     Connections.VariableNames{NVars+1}='Grid Elevation';
%     Connections.VariableDisplayNames{NVars+1}='Grid Elevation';
%     Connections.VariableTypes{1,NVars+1}='Scalar';
%     Connections.members{1,NVars+1}.NcTBHandle=Connections.members{1,1}.NcTBHandle;
%     Connections.members{1,NVars+1}.FieldDisplayName=[];
%     Connections.members{1,NVars+1}.FileNetcdfVariableName='depth';
%     Connections.members{1,NVars+1}.VariableDisplayName='Grid Elevation';
%     Connections.members{1,NVars+1}.NNodes=Connections.members{1,1}.NNodes;
%     Connections.members{1,NVars+1}.NTimes=1;
%     
%     Connections.members{1,NVars+1}.Units='Meters';
%     Connections.VariableUnitsFac{NVars+1}=1;
%     if any(strcmpi(Url.Units,{'english','feet'}))
%         Connections.VariableUnitsFac{NVars+1}=3.2808;
%         Connections.members{1,NVars+1}.Units='Feet';
%     end
