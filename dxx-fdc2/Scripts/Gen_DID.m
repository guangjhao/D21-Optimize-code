function Gen_DID(FVT_DIDListFileName)
% FVT_DIDListFileName = 'FVT_DIDList.xlsx';    
project_path = pwd;
ScriptVersion = '2024.05.02';

%% Read FVT_DIDList
cd([project_path '/documents']);
FVT_DIDList = (readcell(FVT_DIDListFileName));
DIDList_ArgDatatype = FVT_DIDList(3:end,4);
DIDList_RWMode = FVT_DIDList(3:end,6);
DIDList_SubDataName = FVT_DIDList(3:end,7);
DIDList_CSOPName = FVT_DIDList(3:end,8);
DIDList_DIDlen = FVT_DIDList(3:end,9);  % Input1
DIDList_DIDNum = FVT_DIDList(3:end,10); % Input2
DIDList_DIDSta = FVT_DIDList(3:end,11); % Output1
DIDList_VarNameIn = FVT_DIDList(3:end,12);% Input3
DIDList_VarNameOut = FVT_DIDList(3:end,13);% Output2


%% Get DID_Template
cd([project_path '/documents/Templates']);
fileID = fopen('DID_Template.arxml');
Target_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Target_arxml{1,1}),1);
for i = 1:length(Target_arxml{1,1})
    tmpCell{i,1} = Target_arxml{1,1}{i,1};
end
Target_arxml = tmpCell;
fclose(fileID);
cd(project_path);


%% Modify CLIENT-SERVER-OPERATION (IF_DIDReadCDD)
Raw_start = find(contains(Target_arxml,'<CLIENT-SERVER-OPERATION>'));
Raw_end = find(contains(Target_arxml,'</CLIENT-SERVER-OPERATION>'));
Template = Target_arxml(Raw_start:Raw_end); % extract interface description part
FirstMessage = boolean(1);

for i = 1:length(DIDList_CSOPName)

    if string(DIDList_RWMode(i)) == 'W'

        tmpCell = Template; % initialize temCell

        DIDList_FuncName = char(regexprep(DIDList_CSOPName(i), '^CSOP_', '')); % Remove 'CSOP_'

        line = find(contains(tmpCell,'<CLIENT-SERVER-OPERATION>'))+1;
        OldString = extractBetween(tmpCell(line),'>','<');
        NewString = char(DIDList_CSOPName(i));
        tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <SHORT-NAME>CSOP_DID</SHORT-NAME>

        line = find(contains(tmpCell,'<CLIENT-SERVER-OPERATION>'))+4;
        OldString = extractBetween(tmpCell(line),'>','<');
        NewString = char(DIDList_VarNameOut(i));
        tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <SHORT-NAME>

        line = find(contains(tmpCell,'<CLIENT-SERVER-OPERATION>'))+5;
        OldString = extractBetween(tmpCell(line),'>','<');
        if contains(DIDList_VarNameOut(i),'Array')
            NewString = ['/TypeDef_DID_ARPkg/' char(DIDList_VarNameOut(i)) '_type'];
        else % ~contains(DIDList_VarNameOut(i),'Array')
            NewString = ['/AUTOSAR_Platform/ImplementationDataTypes/' char(DIDList_ArgDatatype(i))];
        end
        tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">

        line = find(contains(tmpCell,'<CLIENT-SERVER-OPERATION>'))+10;
        OldString = extractBetween(tmpCell(line),'>','<');
        NewString = char(DIDList_DIDSta(i));
        tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <SHORT-NAME>

        line = find(contains(tmpCell,'<CLIENT-SERVER-OPERATION>'))+16;
        OldString = extractBetween(tmpCell(line),'>','<');
        NewString = char(DIDList_DIDNum(i));
        tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <SHORT-NAME>

        line = find(contains(tmpCell,'<CLIENT-SERVER-OPERATION>'))+22;
        OldString = extractBetween(tmpCell(line),'>','<');
        NewString = char(DIDList_DIDlen(i));
        tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <SHORT-NAME>        

        if FirstMessage % replace original part
            Raw_start = find(contains(Target_arxml,'<CLIENT-SERVER-OPERATION>'),1,'first');
            Raw_end = find(contains(Target_arxml,'</CLIENT-SERVER-OPERATION>'),1,'first');
            Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
            FirstMessage = boolean(0);
        else % add new part
            LastTwoIndexs = find(contains(Target_arxml,'</CLIENT-SERVER-OPERATION>'),2,'last');
            Raw_start = LastTwoIndexs(1);
            Raw_end = Raw_start + 1;
            Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        end
    end
end


%% Modify CLIENT-SERVER-OPERATION (IF_DIDReadCDD)
Raw_start = find(contains(Target_arxml,'<CLIENT-SERVER-OPERATION>'),1,'last');
Raw_end = find(contains(Target_arxml,'</CLIENT-SERVER-OPERATION>'),1,'last');
Template = Target_arxml(Raw_start:Raw_end); % extract interface description part
FirstMessage = boolean(1);

for i = 1:length(DIDList_CSOPName)

    if string(DIDList_RWMode(i)) == 'R'

        tmpCell = Template; % initialize temCell

        DIDList_FuncName = char(regexprep(DIDList_CSOPName(i), '^CSOP_', '')); % Remove 'CSOP_'

        line = find(contains(tmpCell,'<CLIENT-SERVER-OPERATION>'))+1;
        OldString = extractBetween(tmpCell(line),'>','<');
        NewString = char(DIDList_CSOPName(i));
        tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <SHORT-NAME>CSOP_DID</SHORT-NAME>

        line = find(contains(tmpCell,'<CLIENT-SERVER-OPERATION>'))+4;
        OldString = extractBetween(tmpCell(line),'>','<');
        NewString = char(DIDList_DIDNum(i));
        tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <SHORT-NAME>

        line = find(contains(tmpCell,'<CLIENT-SERVER-OPERATION>'))+10;
        OldString = extractBetween(tmpCell(line),'>','<');
        NewString = char(DIDList_DIDlen(i));
        tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <SHORT-NAME>     

        line = find(contains(tmpCell,'<CLIENT-SERVER-OPERATION>'))+16;
        OldString = extractBetween(tmpCell(line),'>','<');
        NewString = char(DIDList_VarNameIn(i));
        tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <SHORT-NAME>

        line = find(contains(tmpCell,'<CLIENT-SERVER-OPERATION>'))+17;
        OldString = extractBetween(tmpCell(line),'>','<');
        if contains(DIDList_VarNameIn(i),'Array')
            NewString = ['/TypeDef_DID_ARPkg/' char(DIDList_VarNameIn(i)) '_type'];
        else % ~contains(DIDList_VarNameIn(i),'Array')
            NewString = ['/AUTOSAR_Platform/ImplementationDataTypes/' char(DIDList_ArgDatatype(i))];
        end
        tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">
   

        if FirstMessage % replace original part
            Raw_start = find(contains(Target_arxml,'<CLIENT-SERVER-OPERATION>'),1,'last');
            Raw_end = find(contains(Target_arxml,'</CLIENT-SERVER-OPERATION>'),1,'last');
            Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
            FirstMessage = boolean(0);
        else % add new part
            Raw_start = find(contains(Target_arxml,'</CLIENT-SERVER-OPERATION>'),1,'last');
            Raw_end = Raw_start + 1;
            Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        end
    end
end


%% Modify OPERATION-INVOKED-EVENT
Raw_start = find(contains(Target_arxml,'<OPERATION-INVOKED-EVENT>'));
Raw_end = find(contains(Target_arxml,'</OPERATION-INVOKED-EVENT>'));
Template = Target_arxml(Raw_start:Raw_end); % extract interface description part
FirstMessage = boolean(1);

for i = 1:length(DIDList_CSOPName)

    tmpCell = Template; % initialize temCell
    
    DIDList_FuncName = char(regexprep(DIDList_CSOPName(i), '^CSOP_', '')); % Remove 'CSOP_'

    line = find(contains(tmpCell,'<OPERATION-INVOKED-EVENT>'))+1;
    OldString = extractBetween(tmpCell(line),'>','<');
    if string(DIDList_RWMode(i)) == 'W'
        NewString = ['oie_P_DIDReadCDD_' char(DIDList_CSOPName(i))];
    else % string(DIDList_RWMode(i)) == 'R'
        NewString = ['oie_P_DIDWriteCDD_' char(DIDList_CSOPName(i))];
    end
    tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <SHORT-NAME>run_DID</SHORT-NAME>

    line = find(contains(tmpCell,'<OPERATION-INVOKED-EVENT>'))+2;
    OldString = extractBetween(tmpCell(line),'>','<');
    NewString = ['/SWC_DID_ARPkg/SWC_DID_type/SWC_DID_type_IB/run_' DIDList_FuncName];
    tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <START-ON-EVENT-REF DEST="RUNNABLE-ENTITY">

    line = find(contains(tmpCell,'<OPERATION-INVOKED-EVENT>'))+4;
    OldString = extractBetween(tmpCell(line),'>','<');
    if string(DIDList_RWMode(i)) == 'W'
        NewString = '/SWC_DID_ARPkg/SWC_DID_type/P_DIDReadCDD';
    else % string(DIDList_RWMode(i)) == 'R'
        NewString = '/SWC_DID_ARPkg/SWC_DID_type/P_DIDWriteCDD';
    end
    tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <CONTEXT-P-PORT-REF DEST="P-PORT-PROTOTYPE">

    line = find(contains(tmpCell,'<OPERATION-INVOKED-EVENT>'))+5;
    OldString = extractBetween(tmpCell(line),'>','<');
    if string(DIDList_RWMode(i)) == 'W'
        NewString = ['/Interface_DID_ARPkg/IF_DIDReadCDD/' char(DIDList_CSOPName(i))];
    else % string(DIDList_RWMode(i)) == 'R'
        NewString = ['/Interface_DID_ARPkg/IF_DIDWriteCDD/' char(DIDList_CSOPName(i))];
    end
    tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <TARGET-PROVIDED-OPERATION-REF DEST="CLIENT-SERVER-OPERATION">

    
    if FirstMessage % replace original part
        Raw_start = find(contains(Target_arxml,'<OPERATION-INVOKED-EVENT>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</OPERATION-INVOKED-EVENT>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
        FirstMessage = boolean(0);
    else % add new part
        Raw_start = find(contains(Target_arxml,'</OPERATION-INVOKED-EVENT>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end

end


%% Modify RUNNABLE-ENTITY
Raw_start = find(contains(Target_arxml,'<RUNNABLE-ENTITY>'));
Raw_end = find(contains(Target_arxml,'</RUNNABLE-ENTITY>'));
Template = Target_arxml(Raw_start:Raw_end); % extract interface description part
FirstMessage = boolean(1);

for i = 1:length(DIDList_CSOPName)

    tmpCell = Template; % initialize temCell

    DIDList_FuncName = char(regexprep(DIDList_CSOPName(i), '^CSOP_', '')); % Remove 'CSOP_'

    line = find(contains(tmpCell,'<RUNNABLE-ENTITY>'))+1;
    OldString = extractBetween(tmpCell(line),'>','<');
    NewString = ['run_' DIDList_FuncName];
    tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <SHORT-NAME>run_DID</SHORT-NAME>

    line = find(contains(tmpCell,'<RUNNABLE-ENTITY>'))+4;
    OldString = extractBetween(tmpCell(line),'>','<');
    NewString = ['run_' DIDList_FuncName];
    tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <SYMBOL>run_DID</SYMBOL>

    if FirstMessage % replace original part
        Raw_start = find(contains(Target_arxml,'<RUNNABLE-ENTITY>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</RUNNABLE-ENTITY>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
        FirstMessage = boolean(0);
    else % add new part
        Raw_start = find(contains(Target_arxml,'</RUNNABLE-ENTITY>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end

end


%% Modify IMPLEMENTATION-DATA-TYPE
Raw_start = find(contains(Target_arxml,'<IMPLEMENTATION-DATA-TYPE>'));
Raw_end = find(contains(Target_arxml,'</IMPLEMENTATION-DATA-TYPE>'));
Template = Target_arxml(Raw_start:Raw_end); % extract interface description part
FirstMessage = boolean(1);

for i = 1:length(DIDList_CSOPName)

    if contains(string(DIDList_VarNameIn(i)),'Array')

        tmpCell = Template; % initialize temCell

        DIDList_FuncName = char(regexprep(DIDList_CSOPName(i), '^CSOP_', '')); % Remove 'CSOP_'

        line = find(contains(tmpCell,'<IMPLEMENTATION-DATA-TYPE>'))+1;
        OldString = extractBetween(tmpCell(line),'>','<');
        NewString = [char(DIDList_VarNameIn(i)) '_type'];
        tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <SHORT-NAME>run_DID</SHORT-NAME>

        line = find(contains(tmpCell,'<IMPLEMENTATION-DATA-TYPE>'))+12;
        OldString = extractBetween(tmpCell(line),'<ARRAY-SIZE>','</ARRAY-SIZE>');
        ArraySize = (regexp(DIDList_VarNameIn(i), 'Array(\d+)_', 'tokens'));
        NewString = ArraySize{1}{1};
        tmpCell(line) = strrep(tmpCell(line),OldString,NewString); % <ARRAY-SIZE>

        if FirstMessage % replace original part
            Raw_start = find(contains(Target_arxml,'<IMPLEMENTATION-DATA-TYPE>'),1,'first');
            Raw_end = find(contains(Target_arxml,'</IMPLEMENTATION-DATA-TYPE>'),1,'first');
            Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
            FirstMessage = boolean(0);
        else % add new part
            Raw_start = find(contains(Target_arxml,'</IMPLEMENTATION-DATA-TYPE>'),1,'last');
            Raw_end = Raw_start + 1;
            Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        end
    end
end


%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen( 'FVT_DID.arxml','w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);

%%
end