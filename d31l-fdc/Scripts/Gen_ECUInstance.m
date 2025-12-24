function Gen_ECUInstance(Channel_list,MsgLinkFileName,TargetECU,DBCSet)
project_path = pwd;
ScriptVersion = '2024.01.23';

%% Get all CAN PDUs from source arxml
Icnt = 0;
Channel_IPDUCell = {};
Ncnt = 0;
Channel_NPDUCell = {};
for i = 1:length(Channel_list)
    Channel = char(Channel_list(i));
    cd([project_path '/documents/ARXML_output'])
    fileID = fopen([Channel '.arxml']);
    Source_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
    tmpCell = cell(length(Source_arxml{1,1}),1);
    for j = 1:length(Source_arxml{1,1})
        tmpCell{j,1} = Source_arxml{1,1}{j,1};
    end
    Source_arxml = tmpCell;

    for k = 1:length(Source_arxml)
        if contains(Source_arxml(k),'<I-SIGNAL-I-PDU>')
            Icnt = Icnt + 1;
            Channel_IPDUCell(Icnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>','</SHORT-NAME>');
        elseif contains(Source_arxml(k),'<N-PDU>')
            Ncnt = Ncnt + 1;
            Channel_NPDUCell(Ncnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>','</SHORT-NAME>');
        else
            continue
        end
    end
    fclose(fileID);
    cd(project_path);
end

Channel_IPDUCell = categories(categorical(Channel_IPDUCell));
Channel_NPDUCell = categories(categorical(Channel_NPDUCell));

%% Edit admin data
% get ECUInstance_Template
fileID = fopen('ECUInstance_Template.arxml');
Target_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Target_arxml{1,1}),1);
for i = 1:length(Target_arxml{1,1})
    tmpCell{i,1} = Target_arxml{1,1}{i,1};
end
Target_arxml = tmpCell;
fclose(fileID);
cd(project_path);

% modify script version
h = contains(Target_arxml(:,1),'<SD GID="ScriptVersion">');
tmpCell = Target_arxml(h);
OldString = extractBetween(tmpCell,'>','<');
Target_arxml(h) = strrep(tmpCell,OldString,ScriptVersion); % <SD GID="ScriptVersion">0.0.1</SD>

% modify MessageLink version
h = contains(Target_arxml(:,1),'<SD GID="InputFile_Msglink">');
tmpCell = Target_arxml(h);
OldString = char(extractBetween(tmpCell,'>','<'));
NewString = MsgLinkFileName;
Target_arxml(h) = strrep(tmpCell,OldString,NewString); % <SD GID="InputFile">CAN_MessageLinkOut</SD>


for i = 1:length(Channel_list)
    Channel = char(Channel_list(i));
    DBC= DBCSet(i);

    % modify DBC version
    if i == 1
        h = find(contains(Target_arxml,'<SD GID="InputFile_DBC">'));
        OldString = char(extractBetween(Target_arxml(h),'<','<'));
        NewString = ['SD GID="InputFile_DBC_' Channel '">' DBC.Name];
        Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString); % <SD GID="InputFile_DBC_CAN3">D31_ET_V13_CAN3_FUSION_20230421_Fix.dbc</SD>
    else
        h = find(contains(Target_arxml,'<SD GID="InputFile_DBC'),1,'last');
        tmpCell = Target_arxml(h);
        OldString = char(extractBetween(tmpCell,'<','<'));
        NewString = ['SD GID="InputFile_DBC_' Channel '">' DBC.Name];
        tmpCell = strrep(tmpCell,OldString,NewString); % <SD GID="InputFile_DBC">D31_ET_V13_CAN3_FUSION_20230421_Fix.dbc</SD>
        Raw_start = find(contains(Target_arxml,'<SD GID="InputFile_DBC'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell;Target_arxml(Raw_end:end)];
    end
end

%% Modify ASSOCIATED-COM-I-PDU-GROUP-REFS part

h = find(contains(Target_arxml,'<SHORT-NAME>TargetECU</SHORT-NAME>'));
OldString = char(extractBetween(Target_arxml(h),'>','<'));
NewString = TargetECU;
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString); % <SHORT-NAME>FUSION</SHORT-NAME>

% Modify I-PDU group reference
for i = 1:length(Channel_list)
    Channel = char(Channel_list(i));

    h = find(contains(Target_arxml,'<ASSOCIATED-COM-I-PDU-GROUP-REF DEST="I-SIGNAL-I-PDU-GROUP">'),1,'first');
    tmpCell = Target_arxml(h);
    OldString = char(extractBetween(tmpCell,'>','<'));
    NewString = ['/PduGroups/' TargetECU '_' Channel '_Tx'];
    tmpCell = strrep(tmpCell,OldString,NewString); % /PduGroups/FUSION_CAN3_Tx

    if i == 1 % to replase original part

        Target_arxml(h) = tmpCell;

    else % to add new part
        Raw_start = find(contains(Target_arxml,'<ASSOCIATED-COM-I-PDU-GROUP-REF DEST="I-SIGNAL-I-PDU-GROUP">'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell;Target_arxml(Raw_end:end)];
    end

    OldString = char(extractBetween(tmpCell,'>','<'));
    NewString = ['/PduGroups/' TargetECU '_' Channel '_Rx'];
    tmpCell = strrep(tmpCell,OldString,NewString); % /PduGroups/FUSION_CAN3_Rx

    Raw_start = find(contains(Target_arxml,'<ASSOCIATED-COM-I-PDU-GROUP-REF DEST="I-SIGNAL-I-PDU-GROUP">'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell;Target_arxml(Raw_end:end)];
end

%% Modify COMM-CONTROLLERS part
Raw_start = find(contains(Target_arxml,'<CAN-COMMUNICATION-CONTROLLER>'),1,'first');
Raw_end = find(contains(Target_arxml,'</CAN-COMMUNICATION-CONTROLLER>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:length(Channel_list)
    Channel = char(Channel_list(i));

    tmpCell = Template;
    h = contains(tmpCell,'<SHORT-NAME>ChannelName</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = Channel;
    tmpCell = strrep(tmpCell,OldString,NewString); % <SHORT-NAME>CAN1</SHORT-NAME>

    if i == 1 % to replace original part
        Raw_start = find(contains(Target_arxml,'<CAN-COMMUNICATION-CONTROLLER>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</CAN-COMMUNICATION-CONTROLLER>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];

    else % to add new part
        Raw_start = find(contains(Target_arxml,'</CAN-COMMUNICATION-CONTROLLER>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

%% Modify CONNECTORS part
Raw_start = find(contains(Target_arxml,'<CAN-COMMUNICATION-CONNECTOR>'),1,'first');
Raw_end = find(contains(Target_arxml,'</CAN-COMMUNICATION-CONNECTOR>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);
FirstChannel = boolean(1);

for i = 1:length(Channel_list)
    Channel = char(Channel_list(i));
    DBC= DBCSet(i);
    tmpCell = Template; % initialize tmpCell

    h = contains(tmpCell,'<SHORT-NAME>CANCommunicationConnector</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['Conn' Channel];
    tmpCell = strrep(tmpCell,OldString,NewString); % <SHORT-NAME>CAN1</SHORT-NAME>

    h = contains(tmpCell,'<COMM-CONTROLLER-REF DEST="CAN-COMMUNICATION-CONTROLLER">');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['/ECU/' TargetECU '/' Channel];
    tmpCell = strrep(tmpCell,OldString,NewString); % /ECU/FUSION/CAN1

    FirstMessage = boolean(1);

    for n = 1:length(DBC.Messages)
        MsgName = char(DBC.MessageInfo(n).Name);

        % Message judgement, ignore messages not in CANx.arxml
        if all(~strcmp([Channel '_' MsgName],Channel_IPDUCell)) && all(~strcmp([Channel '_' MsgName],Channel_NPDUCell))
            continue
        end

        CycleTime_ms = DBC.MessageInfo(n).AttributeInfo(strcmp(DBC.MessageInfo(n).Attributes(:,1),'GenMsgCycleTime')).Value;
        Timeout_s = num2str(2.5*CycleTime_ms*0.001);

        if strcmp(DBC.MessageInfo(n).TxNodes,TargetECU)
            Direction = 'OUT';
        else
            Direction = 'IN';
        end

        % Modify I-PDU-PORT, FRAME-PORT and I-SIGNAL-PORT for signal group
        Raw_start = find(contains(Template,'<I-PDU-PORT>'),1,'first');
        Raw_end = find(contains(Template,'</I-SIGNAL-PORT>'),1,'last');
        tmpCell2 = Template(Raw_start:Raw_end);

        h = contains(tmpCell2,'<SHORT-NAME>PDUPort</SHORT-NAME>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = ['PP_' Channel '_' MsgName '_' Direction];
        tmpCell2 = strrep(tmpCell2,OldString,NewString); % <SHORT-NAME>PP_CAN1_ABM1_IN</SHORT-NAME>

        h = contains(tmpCell2,'<SHORT-NAME>FramePort</SHORT-NAME>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = ['FP_' Channel '_' MsgName '_' Direction];
        tmpCell2 = strrep(tmpCell2,OldString,NewString); % <SHORT-NAME>FP_CAN1_ABM1_IN</SHORT-NAME>

        h = contains(tmpCell2,'<SHORT-NAME>SignalGroupPort</SHORT-NAME>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = ['SP_' Channel '_SG_' MsgName '_' Direction];
        tmpCell2 = strrep(tmpCell2,OldString,NewString); % <SHORT-NAME>SP_CAN1_SG_ABM1_IN</SHORT-NAME>

        % Modify I-SIGNAL-PORT for signals
        for k = 1:length(DBC.MessageInfo(n).Signals)
            Raw_start = find(contains(Template,'<I-SIGNAL-PORT>'),1,'last');
            Raw_end = find(contains(Template,'</I-SIGNAL-PORT>'),1,'last');
            tmpCell3 = Template(Raw_start:Raw_end); % initialize tmpCell3
            SignalName = char(DBC.MessageInfo(n).Signals(k));

            h = contains(tmpCell3,'<SHORT-NAME>SignalPort</SHORT-NAME>');
            OldString = char(extractBetween(tmpCell3(h),'>','<'));
            NewString = ['SP_' Channel '_' SignalName '_' Direction];
            tmpCell3 = strrep(tmpCell3,OldString,NewString); % <SHORT-NAME>SP_CAN1_AirBagFailCmd_IN</SHORT-NAME>

            if k == 1 % to replace original part
                Raw_start = find(contains(tmpCell2,'<I-SIGNAL-PORT>'),1,'last');
                Raw_end = find(contains(tmpCell2,'</I-SIGNAL-PORT>'),1,'last');
                tmpCell2 = [tmpCell2(1:Raw_start-1);tmpCell3(1:end);tmpCell2(Raw_end+1:end)];
            else % to add new part
                Raw_start = find(contains(tmpCell2,'</I-SIGNAL-PORT>'),1,'last');
                Raw_end = Raw_start + 1;
                tmpCell2 = [tmpCell2(1:Raw_start);tmpCell3(1:end);tmpCell2(Raw_end:end)];
            end
        end

        % to write all directions withing this message
        h = find(contains(tmpCell2,'<COMMUNICATION-DIRECTION>'));
        for j = 1:length(h)
            OldString = char(extractBetween(tmpCell2(h(j)),'>','<'));
            NewString = Direction;
            tmpCell2(h(j)) = strrep(tmpCell2(h(j)),OldString,NewString); % <COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>
        end

        % to write all message timeout value
        % Causion: EB Tresos use uint_16 as timeout counter data type
        % and has max. value of 65535. CAN_Rx time base is 0.005ms.
        % This means max. timeout judgement value is 65535*0.005 =
        % 327.675s. Here will filter out any timeout value greater
        % than 300s.

        h = find(contains(tmpCell2,'<TIMEOUT>0.02</TIMEOUT>'));
        if str2double(Timeout_s) <= 300
            for j = 1:length(h)
                OldString = char(extractBetween(tmpCell2(h(j)),'>','<'));
                NewString = Timeout_s;
                tmpCell2(h(j)) = strrep(tmpCell2(h(j)),OldString,NewString); % <TIMEOUT>0.02</TIMEOUT>
            end
        else
            for j = length(h):-1:1
                tmpCell2(h(j)) = [];
            end
        end

        % delete I-SIGNAL-PORT part for NM and N-PDU
        if startsWith(MsgName,'NMm_') || startsWith(MsgName,'Diag')
            Raw_start = find(contains(tmpCell2,'<I-SIGNAL-PORT>'),1,'first');
            Raw_end = find(contains(tmpCell2,'</I-SIGNAL-PORT>'),1,'last');
            tmpCell2(Raw_start:Raw_end) = [];
        end

        if FirstMessage % to replace original part
            Raw_start = find(contains(tmpCell,'<I-PDU-PORT>'),1,'first');
            Raw_end = find(contains(tmpCell,'</I-SIGNAL-PORT>'),1,'last');
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
        else % to add new part
            if isempty(find(contains(tmpCell,'</I-SIGNAL-PORT>'),1,'last'))
                Raw_start = find(contains(tmpCell,'</FRAME-PORT>'),1,'last');
            else
                Raw_start = find(contains(tmpCell,'</I-SIGNAL-PORT>'),1,'last');
            end
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end

        FirstMessage = boolean(0);
    end

    if FirstChannel % to replace original part
        Raw_start = find(contains(Target_arxml,'<CAN-COMMUNICATION-CONNECTOR>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</CAN-COMMUNICATION-CONNECTOR>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];

    else
        Raw_start = find(contains(Target_arxml,'</CAN-COMMUNICATION-CONNECTOR>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end

    FirstChannel = boolean(0);
end


%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen( 'ECUInstance.arxml','w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);


end