function storm=GetFieldsNcml(url1)

CF=CF_table;

global Debug

if Debug,fprintf('SSViz++       Function = %s\n',ThisFunctionName);end

storm=struct('NcTBHandle',[],'CdmDataType',[],'Units',[],'VariableDisplayName',[],'VariableType',[],'GridHash',[]);


VariableStandardNames=CF.StandardNames;
nctemp=ncgeodataset(url1);

ThisCdmDataType=nctemp.attribute('cdm_data_type');

jj=0;
for ii=1:length(VariableStandardNames)
    
    ThisVariableStandardName=VariableStandardNames{ii};
    ThisVariableName=nctemp.standard_name(ThisVariableStandardName);
    
    if isempty(ThisVariableName)
        if Debug,fprintf('SSViz++          Variable not found for StdName=%s\n',ThisVariableStandardName);end
    else
        if Debug,fprintf('SSViz++          Found variable for StdName=%s: %s\n',ThisVariableStandardName,ThisVariableName{:});end

        jj=jj+1;
        ncgvar=nctemp{ThisVariableName};
        
        ThisVariableDisplayName=CF.DisplayNames{ii};
        ThisUnits=ncgvar.attribute('units');
        
        ThisVariableType='Scalar';
        ThisFileNetcdfVariableName=ncgvar.name;
        ThisVariableName=ncgvar.name;
        
        storm(jj).NcTBHandle=nctemp;
        storm(jj).Units=ThisUnits;
        storm(jj).VariableName=ThisVariableName;
        storm(jj).VariableDisplayName=ThisVariableDisplayName;
        storm(jj).VariableType=ThisVariableType;
        storm(jj).CdmDataType=ThisCdmDataType;      
        
        if ~isempty(nctemp)  && strcmp(ThisCdmDataType,'ugrid')
            % generate a hash value based on lengths of element and "x"
            % array
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
        else
            % this is cgrid.  Hash is "NaN", since the grid is trivial to
            % compute
            storm(jj).GridHash='NaN';
            temp=size(nctemp.variable(ThisVariableName));

            switch numel(temp)
                case 3
                    a=[temp(2) temp(3)];
                    b=temp(1);
                case 2
                    a=[temp(1) temp(2)];
                    b=1;                
                otherwise
                    error('  A 1-D field variable in a cgrid?  Error.   Terminal.')
            end
            storm(jj).NNodes=a;
            storm(jj).NTimes=b;
            %storm(ii).VariableType=ThisVariableType;
        end
    end  
end

end
