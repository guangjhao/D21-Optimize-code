function Gen_ComSettings(Channel_list,Channel_list_LIN,LDFSet,DBCSet,TargetECU)
project_path = pwd;
ScriptVersion = '2024.07.02';

%% Get ECUC original arxml
fileID = fopen('Com.Rest.arxml');
COM_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(COM_arxml{1,1}),1);
for i = 1:length(COM_arxml{1,1})
    tmpCell{i,1} = COM_arxml{1,1}{i,1};
end
COM_arxml = tmpCell;
fclose(fileID);
cd(project_path);

%% Get Rx timeout time and substitution value
ValueTable = {};
cnt = 0;

for i = 1:length(Channel_list)
    Channel = char(Channel_list(i));
    DBC = DBCSet(i);
    for k = 1:length(DBC.Messages)
        if strcmp(DBC.MessageInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(k).Attributes(:,1),'DiagRequest')).Value,'Yes') ||...
                strcmp(DBC.MessageInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(k).Attributes(:,1),'DiagResponse')).Value,'Yes')
            IsDiag = boolean(1);
        else
            IsDiag = boolean(0);
        end

        MsgName = char(DBC.MessageInfo(k).Name);
        if any(strcmp(DBC.MessageInfo(k).TxNodes,TargetECU)) || IsDiag ||...
                startsWith(MsgName,'NMm_')
            continue
        end

        MsgName = char(DBC.MessageInfo(k).Name);
        MessageID = num2str(DBC.MessageInfo(k).ID);
        CycleTime_ms = DBC.MessageInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(k).Attributes(:,1),'GenMsgCycleTime')).Value;
        Timeout_s = num2str(2.5*CycleTime_ms*0.001);
        cnt = cnt + 1;
        ValueTable{cnt,1} = [Channel '_SG_' MsgName '_' MessageID 'R'];
        ValueTable{cnt,2} = Timeout_s;

        for n = 1:length(DBC.MessageInfo(k).Signals)
            SignalName = char(DBC.MessageInfo(k).Signals(n));
            TimeoutValue = char(DBC.MessageInfo(k).SignalInfo(n).AttributeInfo(strcmp(DBC.MessageInfo(k).SignalInfo(n).Attributes(:,1),'GenSigRoutingTimeoutValue')).Value);
            cnt = cnt + 1;
            ValueTable{cnt,1} = [Channel '_' SignalName '_' MessageID 'R'];
            ValueTable{cnt,2} = ['0x' upper(TimeoutValue)];
        end
    end
end

for i = 1:length(Channel_list_LIN)
    Channel = char(Channel_list_LIN(i));
    LDF = LDFSet{i};
    for k = 1:length(LDF.Messages)
        IsDiag = boolean(0);

        if strcmp(LDF.MessageInfo(k).TxNodes,TargetECU) || IsDiag
            continue
        end

        MsgName = char(LDF.MessageInfo(k).Name);
        MessageID = num2str(LDF.MessageInfo(k).ID);
        CycleTime_ms = str2double(LDF.MessageInfo(k).MsgCycleTime);
        Timeout_s = num2str(2.5*CycleTime_ms*0.001);
        cnt = cnt + 1;
        ValueTable{cnt,1} = [Channel '_SG_' MsgName '_' MessageID 'R'];
        ValueTable{cnt,2} = Timeout_s;

        for n = 1:length(LDF.MessageInfo(k).Signals)
            SignalName = char(LDF.MessageInfo(k).Signals(n));
            TimeoutValue = char(LDF.MessageInfo(k).SignalInfo(n).TimeoutValue);
            cnt = cnt + 1;
            ValueTable{cnt,1} = [Channel '_' SignalName '_' MessageID 'R'];
            ValueTable{cnt,2} = TimeoutValue;
        end
    end
end

%% Get Com path
h = contains(COM_arxml,'<DEFINITION-REF DEST="ECUC-MODULE-DEF">');
ComPath = char(extractBetween(COM_arxml(h),'>','<'));
%% Add timeout value for all Rx PDUs
for i = 1:length(ValueTable(:,1))
    if ~contains(char(ValueTable(i,1)),'_SG_')
        continue
    end

    % Causion: EB Tresos use uint_16 as timeout counter data type
    % and has max. value of 65535. CAN_Rx time base is 0.005ms.
    % This means max. timeout judgement value is 65535*0.005 =
    % 327.675s. Here will filter out any timeout value greater
    % than 300s.

    h = find(contains(COM_arxml,['>GR' char(ValueTable(i,1))]));
    if isempty(h)
        disp(['CAUTION: ' char(ValueTable(i,1)) ' not defined in arxml'])
        continue
    end
    
    Timeout_s = char(ValueTable(i,2));
    if isempty(h) || str2double(Timeout_s) > 300; continue; end

    Raw_start = find(contains(COM_arxml(h:end),'<PARAMETER-VALUES>'),1,'first');
    Raw_end = find(contains(COM_arxml(h:end),'</PARAMETER-VALUES>'),1,'first');
    Template_AllParameters = COM_arxml(Raw_start+h-1:Raw_end+h-1);

    Raw_start = find(contains(Template_AllParameters,'<ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
    Raw_end = find(contains(Template_AllParameters,'</ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
    tmpCell = Template_AllParameters(Raw_start:Raw_end);

    h = find(contains(tmpCell,'ECUC-TEXTUAL-PARAM-VALUE'),1,'first');
    OldString = extractBetween(tmpCell(h),'<','>');
    NewString = 'ECUC-NUMERICAL-PARAM-VALUE';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    h = find(contains(tmpCell,'/ECUC-TEXTUAL-PARAM-VALUE'),1,'first');
    OldString = extractBetween(tmpCell(h),'</','>');
    NewString = 'ECUC-NUMERICAL-PARAM-VALUE';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    h = find(contains(tmpCell,'<DEFINITION-REF DEST="ECUC-ENUMERATION-PARAM-DEF">'));
    OldString = extractBetween(tmpCell(h),'"','">');
    NewString = 'ECUC-FLOAT-PARAM-DEF';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [ComPath '/ComConfig/ComSignalGroup/ComTimeout'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    h = find(contains(tmpCell,'<VALUE>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = Timeout_s;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    if isempty(find(contains(Template_AllParameters,'ComTimeout<'), 1)) % Add new description
        Raw_start = find(contains(Template_AllParameters,'<PARAMETER-VALUES>'),1,'first');
        Raw_end = Raw_start + 1;
        Template_AllParameters = [Template_AllParameters(1:Raw_start);tmpCell(1:end);Template_AllParameters(Raw_end:end)];

    else % Replace original description
        h = find(contains(Template_AllParameters,'ComTimeout<'));
        Raw_start = find(contains(Template_AllParameters(1:h),'<ECUC-NUMERICAL-PARAM-VALUE>'),1,'last');
        Raw_end = find(contains(Template_AllParameters(h:end),'</ECUC-NUMERICAL-PARAM-VALUE>'),1,'first');
        Raw_end = h + Raw_end - 1;
        Template_AllParameters = [Template_AllParameters(1:Raw_start-1);tmpCell(1:end);Template_AllParameters(Raw_end+1:end)];
    end

    % Put parameters back to Com_arxml
    h = find(contains(COM_arxml,['>GR' char(ValueTable(i,1))]));
    Raw_start = find(contains(COM_arxml(h:end),'<PARAMETER-VALUES>'),1,'first');
    Raw_end = find(contains(COM_arxml(h:end),'</PARAMETER-VALUES>'),1,'first');
    COM_arxml = [COM_arxml(1:Raw_start+h-2);Template_AllParameters(1:end);COM_arxml(Raw_end+h:end)];
end

%% Add ComRxDataTimeoutAction and callback function for all Rx message

for i = 1:length(ValueTable(:,1))
    if ~contains(char(ValueTable(i,1)),'_SG_')
        continue
    end

    h = find(contains(COM_arxml,['>GR' char(ValueTable(i,1))]));
    if isempty(h);continue;end

    Raw_start = find(contains(COM_arxml(h:end),'<PARAMETER-VALUES>'),1,'first');
    Raw_end = find(contains(COM_arxml(h:end),'</PARAMETER-VALUES>'),1,'first');
    Template_AllParameters = COM_arxml(Raw_start+h-1:Raw_end+h-1);

    % Add "SUBSTITUDE" parameter into SG description
    Raw_start = find(contains(Template_AllParameters,'<ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
    Raw_end = find(contains(Template_AllParameters,'</ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
    tmpCell = Template_AllParameters(Raw_start:Raw_end);

    h = find(contains(tmpCell,'<DEFINITION-REF DEST="ECUC-ENUMERATION-PARAM-DEF">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [ComPath '/ComConfig/ComSignalGroup/ComRxDataTimeoutAction'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /TS_TxDxM6I3R0/Com/ComConfig/ComSignalGroup/ComRxDataTimeoutAction

    h = find(contains(tmpCell,'<VALUE>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = 'SUBSTITUTE';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <VALUE>SUBSTITUTE</VALUE>

    if isempty(find(contains(Template_AllParameters,'ComRxDataTimeoutAction'), 1)) % Add new description
        Raw_start = find(contains(Template_AllParameters,'<PARAMETER-VALUES>'),1,'first');
        Raw_end = Raw_start + 1;
        Template_AllParameters = [Template_AllParameters(1:Raw_start);tmpCell(1:end);Template_AllParameters(Raw_end:end)];

    else % Replace original description
        h = find(contains(Template_AllParameters,'ComRxDataTimeoutAction'));
        Raw_start = find(contains(Template_AllParameters(1:h),'<ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
        Raw_end = find(contains(Template_AllParameters(h:end),'</ECUC-TEXTUAL-PARAM-VALUE>'),1,'first');
        Raw_end = h + Raw_end - 1;
        Template_AllParameters = [Template_AllParameters(1:Raw_start-1);tmpCell(1:end);Template_AllParameters(Raw_end+1:end)];
    end

    % Add ComTimeoutNotification callback
    Raw_start = find(contains(Template_AllParameters,'<ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
    Raw_end = find(contains(Template_AllParameters,'</ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
    tmpCell = Template_AllParameters(Raw_start:Raw_end);

    h = find(contains(tmpCell,'<DEFINITION-REF DEST="ECUC-ENUMERATION-PARAM-DEF">'));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'ECUC-FUNCTION-NAME-DEF';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [ComPath '/ComConfig/ComSignalGroup/ComTimeoutNotification'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /TS_TxDxM6I3R0/Com/ComConfig/ComSignalGroup/ComTimeoutNotification

    h = find(contains(tmpCell,'<VALUE>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [extractBefore(char(ValueTable(i,1)),find(char(ValueTable(i,1)) == '_',1,'last')) '_ComTimeoutNotification'];    
%     NewString = ['Timeout_' char(ValueTable(i,1))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <VALUE>Timeout_CAN4_SG_FD_OTA1</VALUE>

    if isempty(find(contains(Template_AllParameters,'ComTimeoutNotification'), 1)) % Add new description
        Raw_start = find(contains(Template_AllParameters,'<PARAMETER-VALUES>'),1,'first');
        Raw_end = Raw_start + 1;
        Template_AllParameters = [Template_AllParameters(1:Raw_start);tmpCell(1:end);Template_AllParameters(Raw_end:end)];

    else % Replace original description
        h = find(contains(Template_AllParameters,'ComTimeoutNotification'));
        Raw_start = find(contains(Template_AllParameters(1:h),'<ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
        Raw_end = find(contains(Template_AllParameters(h:end),'</ECUC-TEXTUAL-PARAM-VALUE>'),1,'first');
        Raw_end = h + Raw_end - 1;
        Template_AllParameters = [Template_AllParameters(1:Raw_start-1);tmpCell(1:end);Template_AllParameters(Raw_end+1:end)];
    end

    % Put parameters back to Com_arxml
    h = find(contains(COM_arxml,['>GR' char(ValueTable(i,1))]));
    Raw_start = find(contains(COM_arxml(h:end),'<PARAMETER-VALUES>'),1,'first');
    Raw_end = find(contains(COM_arxml(h:end),'</PARAMETER-VALUES>'),1,'first');
    COM_arxml = [COM_arxml(1:Raw_start+h-2);Template_AllParameters(1:end);COM_arxml(Raw_end+h:end)];
end

%% Add ComNotification callback function for all Rx message

for i = 1:length(ValueTable(:,1))
    if ~contains(char(ValueTable(i,1)),'_SG_')
        continue
    end

    h = find(contains(COM_arxml,['>GR' char(ValueTable(i,1))]));
    if isempty(h);continue;end

    Raw_start = find(contains(COM_arxml(h:end),'<PARAMETER-VALUES>'),1,'first');
    Raw_end = find(contains(COM_arxml(h:end),'</PARAMETER-VALUES>'),1,'first');
    Template_AllParameters = COM_arxml(Raw_start+h-1:Raw_end+h-1);

    % Add ComNotification callback
    Raw_start = find(contains(Template_AllParameters,'<ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
    Raw_end = find(contains(Template_AllParameters,'</ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
    tmpCell = Template_AllParameters(Raw_start:Raw_end);

    h = find(contains(tmpCell,'<DEFINITION-REF DEST="ECUC-ENUMERATION-PARAM-DEF">'));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'ECUC-FUNCTION-NAME-DEF';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [ComPath '/ComConfig/ComSignalGroup/ComNotification'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /TS_TxDxM6I3R0/Com/ComConfig/ComSignalGroup/ComNotification

    h = find(contains(tmpCell,'<VALUE>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [extractBefore(char(ValueTable(i,1)),find(char(ValueTable(i,1)) == '_',1,'last')) '_ComNotification'];
%     NewString = ['RxAck_' char(ValueTable(i,1))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <VALUE>RxAck_CAN4_SG_FD_OTA1</VALUE>

    if isempty(find(contains(Template_AllParameters,'ComNotification'), 1)) % Add new description
        Raw_start = find(contains(Template_AllParameters,'<PARAMETER-VALUES>'),1,'first');
        Raw_end = Raw_start + 1;
        Template_AllParameters = [Template_AllParameters(1:Raw_start);tmpCell(1:end);Template_AllParameters(Raw_end:end)];

    else % Replace original description
        h = find(contains(Template_AllParameters,'ComNotification'));
        Raw_start = find(contains(Template_AllParameters(1:h),'<ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
        Raw_end = find(contains(Template_AllParameters(h:end),'</ECUC-TEXTUAL-PARAM-VALUE>'),1,'first');
        Raw_end = h + Raw_end - 1;
        Template_AllParameters = [Template_AllParameters(1:Raw_start-1);tmpCell(1:end);Template_AllParameters(Raw_end+1:end)];
    end

    % Put parameters back to Com_arxml
    h = find(contains(COM_arxml,['>GR' char(ValueTable(i,1))]));
    Raw_start = find(contains(COM_arxml(h:end),'<PARAMETER-VALUES>'),1,'first');
    Raw_end = find(contains(COM_arxml(h:end),'</PARAMETER-VALUES>'),1,'first');
    COM_arxml = [COM_arxml(1:Raw_start+h-2);Template_AllParameters(1:end);COM_arxml(Raw_end+h:end)];
end

%% Add ComFirstTimeout for all Rx message

for i = 1:length(ValueTable(:,1))
    if ~contains(char(ValueTable(i,1)),'_SG_')
        continue
    end

    h = find(contains(COM_arxml,['>GR' char(ValueTable(i,1))]));
    if isempty(h);continue;end

    Raw_start = find(contains(COM_arxml(h:end),'<PARAMETER-VALUES>'),1,'first');
    Raw_end = find(contains(COM_arxml(h:end),'</PARAMETER-VALUES>'),1,'first');
    Template_AllParameters = COM_arxml(Raw_start+h-1:Raw_end+h-1);

    % Add ComFirstTimeout time = 5ms
    Raw_start = find(contains(Template_AllParameters,'<ECUC-NUMERICAL-PARAM-VALUE>'),1,'last');
    Raw_end = find(contains(Template_AllParameters,'</ECUC-NUMERICAL-PARAM-VALUE>'),1,'last');
    tmpCell = Template_AllParameters(Raw_start:Raw_end);

    h = find(contains(tmpCell,'<DEFINITION-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'ECUC-FLOAT-PARAM-DEF';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [ComPath '/ComConfig/ComSignalGroup/ComFirstTimeout'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /TS_TxDxM6I3R0/Com/ComConfig/ComSignalGroup/ComFirstTimeout

    h = find(contains(tmpCell,'<VALUE>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = '0.005'; 
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <VALUE>RxAck_CAN4_SG_FD_OTA1</VALUE>

    if isempty(find(contains(Template_AllParameters,'ComFirstTimeout'), 1)) % Add new description
        Raw_start = find(contains(Template_AllParameters,'<PARAMETER-VALUES>'),1,'first');
        Raw_end = Raw_start + 1;
        Template_AllParameters = [Template_AllParameters(1:Raw_start);tmpCell(1:end);Template_AllParameters(Raw_end:end)];

    else % Replace original description
        h = find(contains(Template_AllParameters,'ComFirstTimeout'));
        Raw_start = find(contains(Template_AllParameters(1:h),'<ECUC-NUMERICAL-PARAM-VALUE>'),1,'last');
        Raw_end = find(contains(Template_AllParameters(h:end),'</ECUC-NUMERICAL-PARAM-VALUE>'),1,'first');
        Raw_end = h + Raw_end - 1;
        Template_AllParameters = [Template_AllParameters(1:Raw_start-1);tmpCell(1:end);Template_AllParameters(Raw_end+1:end)];
    end

    % Put parameters back to Com_arxml
    h = find(contains(COM_arxml,['>GR' char(ValueTable(i,1))]));
    Raw_start = find(contains(COM_arxml(h:end),'<PARAMETER-VALUES>'),1,'first');
    Raw_end = find(contains(COM_arxml(h:end),'</PARAMETER-VALUES>'),1,'first');
    COM_arxml = [COM_arxml(1:Raw_start+h-2);Template_AllParameters(1:end);COM_arxml(Raw_end+h:end)];
end

%% Add ComTimeoutSubstitutionValue for all signals
for i = 1:length(ValueTable(:,1))
    if contains(char(ValueTable(i,1)),'_SG_')
        continue
    end

    h = find(contains(COM_arxml,['>' char(ValueTable(i,1))]));
    if isempty(h);continue;end

    TOValue = char(ValueTable(i,2));
    Raw_start = find(contains(COM_arxml(h:end),'<PARAMETER-VALUES>'),1,'first');
    Raw_end = find(contains(COM_arxml(h:end),'</PARAMETER-VALUES>'),1,'first');
    Template_AllParameters = COM_arxml(Raw_start+h-1:Raw_end+h-1);

    % Add ComTimeoutSubstitutionValue
    Raw_start = find(contains(Template_AllParameters,'<ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
    Raw_end = find(contains(Template_AllParameters,'</ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
    tmpCell = Template_AllParameters(Raw_start:Raw_end);

    h = find(contains(tmpCell,'<DEFINITION-REF DEST="ECUC-ENUMERATION-PARAM-DEF">'));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'ECUC-STRING-PARAM-DEF';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [ComPath '/ComConfig/ComSignalGroup/ComGroupSignal/ComTimeoutSubstitutionValue'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /TS_TxDxM6I3R0/Com/ComConfig/ComSignalGroup/ComGroupSignal/ComTimeoutSubstitutionValue

    h = find(contains(tmpCell,'<VALUE>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = TOValue;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <VALUE>0x7F</VALUE>

    if isempty(find(contains(Template_AllParameters,'ComTimeoutSubstitutionValue'), 1)) % Add new description
        Raw_start = find(contains(Template_AllParameters,'<PARAMETER-VALUES>'),1,'first');
        Raw_end = Raw_start + 1;
        Template_AllParameters = [Template_AllParameters(1:Raw_start);tmpCell(1:end);Template_AllParameters(Raw_end:end)];

    else % Replace original description
        h = find(contains(Template_AllParameters,'ComTimeoutSubstitutionValue'));
        Raw_start = find(contains(Template_AllParameters(1:h),'<ECUC-TEXTUAL-PARAM-VALUE>'),1,'last');
        Raw_end = find(contains(Template_AllParameters(h:end),'</ECUC-TEXTUAL-PARAM-VALUE>'),1,'first');
        Raw_end = h + Raw_end - 1;
        Template_AllParameters = [Template_AllParameters(1:Raw_start-1);tmpCell(1:end);Template_AllParameters(Raw_end+1:end)];
    end

    % Put parameter back to Com_arxml
    h = find(contains(COM_arxml,['>' char(ValueTable(i,1))]));
    Raw_start = find(contains(COM_arxml(h:end),'<PARAMETER-VALUES>'),1,'first');
    Raw_end = find(contains(COM_arxml(h:end),'</PARAMETER-VALUES>'),1,'first');
    COM_arxml = [COM_arxml(1:Raw_start+h-2);Template_AllParameters(1:end);COM_arxml(Raw_end+h:end)];
end

%% To delete unnecessary description
h = find(contains(COM_arxml, [ComPath '/ComConfig/ComSignalGroup/ComGroupSignal/ComTimeoutSubstitutionValue']));
cnt = 0;

for i = 1:length(h)
    if ~contains(COM_arxml(h(i)+1),'<VALUE>')
        if cnt == 0
            cnt = cnt + 1;
        else
            cnt = cnt + 3;
        end
        Raw_to_delete(cnt,1) = h(i) - 1;
        Raw_to_delete(cnt+1,1) = h(i);
        Raw_to_delete(cnt+2,1) = h(i) + 1;
    end
end

for i = length(Raw_to_delete):-1:1
    COM_arxml(Raw_to_delete(i)) = [];
end

%% Enable ComSignalGwEnable
h = find(contains(COM_arxml,'ComSignalGwEnable</DEFINITION-REF>'));
OldString = extractBetween(COM_arxml(h+1),'<VALUE>','</VALUE>');
NewString = '1';
COM_arxml(h+1) = strrep(COM_arxml(h+1),OldString,NewString);

%% Output COM_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen('ComSettings.arxml','w');
for i = 1:length(COM_arxml(:,1))
    fprintf(fileID,'%s\n',char(COM_arxml(i,1)));
end
fclose(fileID);
end