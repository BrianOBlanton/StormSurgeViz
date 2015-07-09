function storm=GetFieldsNcml(url1,CF)
    
    global Debug
    
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    
    VariableStandardNames=CF.StandardNames;
    storm=struct('NcTBHandle',[],'Units',[],'FieldDisplayName',[],'FileNetcdfVariableName',[],'GridHash',[]);
    nctemp=ncgeodataset(url1);

    % populate with small number of variables:
    % max water level
    jj=0;
    for ii=1:length(VariableStandardNames)
        
        ThisVariableStandardName=VariableStandardNames{ii};
        ThisVariableName=nctemp.standard_name(ThisVariableStandardName);
        
        
        if isempty(ThisVariableName)
            if Debug,fprintf('SSViz++    VAriable not found for StdName=%s\n',ThisVariableStandardName);end
        else
            
           jj=jj+1; 
        ncgvar=nctemp{ThisVariableName};
      
        ThisVariableDisplayName=CF.DisplayNames{ii}; 
        ThisUnits=ncgvar.attribute('units');

        %ThisVariableDisplayName=VariableDisplayNames{ii};
        %ThisVariableName=VariableNames{ii};
        %ThisVariableType=VariableType{ii};
        %ThisUnits=VariableUnits{ii};

        ThisVariableType='Scalar';
        ThisFileNetcdfVariableName=ncgvar.name;
        ThisVariableName=ncgvar.name;

        storm(jj).NcTBHandle=nctemp;
        storm(jj).Units=ThisUnits;
        storm(jj).VariableDisplayName=ThisVariableDisplayName;
        storm(jj).FileNetcdfVariableName=ThisFileNetcdfVariableName;

        if ~isempty(nctemp)

            a=prod(double(size(nctemp.variable{'element'})));
            b=prod(double(size(nctemp.variable{'x'})));

            storm(jj).GridHash=DataHash2(a*b);

            if iscell(ThisFileNetcdfVariableName)
                MandN=size(nctemp{ThisFileNetcdfVariableName{1}});
            else
                MandN=size(nctemp{ThisFileNetcdfVariableName});
            end

            if (length(MandN)>1  && ~any(MandN==1))
                m=MandN(2);n=MandN(1);
            else
                m=max(MandN);n=1;
            end
            storm(jj).NNodes=m;
            storm(jj).NTimes=n;
        end

        %storm(ii).VariableType=ThisVariableType;
        end
    end

end