function Gen_CANSettings(DBC,Channel,MsgLinkFileName,TargetECU,RoutingTable)
project_path = pwd;
ScriptVersion = '2024.07.02';

%% Read messageLink
cd([project_path '/../common/documents']);
MessageLink_Rx = readcell(MsgLinkFileName,'Sheet','InputSignal');
MessageLink_Tx = readcell(MsgLinkFileName,'Sheet','OutputSignal');

% Change channel name from CAN_Dr1 to CANDr1 for Rx
for i = 1:length(MessageLink_Rx(:,2))
    MessageLink_Rx(i,2) = cellstr(erase(char(MessageLink_Rx(i,2)),'_'));
end

% Change channel name from CAN_Dr1 to CANDr1 for Tx
for i = 1:length(MessageLink_Tx(1,:))
    MessageLink_Tx(1,i) = cellstr(erase(char(MessageLink_Tx(1,i)),'_'));
end

%% Get APP related messages
tmpCell = MessageLink_Rx(strcmp(MessageLink_Rx(:,strcmp(MessageLink_Rx(1,:),'CANChannel')),Channel),strcmp(MessageLink_Rx(1,:),'MessageName'));
Rx_MsgLink = categories(categorical(tmpCell));

tmpCell = MessageLink_Tx(2:end,strcmp(MessageLink_Tx(1,:),Channel));
tmpCell(cellfun(@(x) all(ismissing(x)), tmpCell)) = [];
Tx_MsgLink = categories(categorical(tmpCell));

%% Get Tx frame routing messages
if contains(Channel,'Dr')
    Channel_long = [extractBefore(Channel,'Dr') '_' extractAfter(Channel,'CAN')];
else
    Channel_long = Channel;
end
Raw_start = find(contains(RoutingTable(:,4),['distributed messages, target:' Channel_long])) + 2;

tmpCell = {};
cnt = 0;
for i = 1:length(Raw_start)
    Raw_end = Raw_start(i) + find(contains(RoutingTable(Raw_start(i):end,4),'distributed messages, target'),1,'first') - 2;
    if isempty(Raw_end); Raw_end = length(RoutingTable(:,1));end

    for k = Raw_start(i):Raw_end
        if strcmp(RoutingTable(k,4),'Invalid')
            cnt = cnt + 1;
            tmpCell(cnt,1) = RoutingTable(k,5);
        else
            continue
        end
    end
end
tmpCell = categories(categorical(tmpCell));
tmpCell(contains(tmpCell,'Invalid')) = [];
Tx_MsgFrameGW = tmpCell;

%% Get Tx signal routing messages
if contains(Channel,'Dr')
    Channel_long = [extractBefore(Channel,'Dr') '_' extractAfter(Channel,'CAN')];
else
    Channel_long = Channel;
end
Raw_start = find(contains(RoutingTable(:,4),['distributed messages, target:' Channel_long])) + 2;

cnt = 0;
tmpCell = {};
tmpCell2 = {};
for i = 1:length(Raw_start)
    Raw_end = Raw_start(i) + find(contains(RoutingTable(Raw_start(i):end,4),'distributed messages, target'),1,'first') - 2;
    if isempty(Raw_end); Raw_end = length(RoutingTable(:,1));end

    for k = Raw_start(i):Raw_end
        if ~strcmp(RoutingTable(k,4),'Invalid')
            cnt = cnt + 1;
            tmpCell(cnt,1) = RoutingTable(k,5);
            tmpCell2(cnt,1) = RoutingTable(k,4);
        else
            continue
        end
    end
end
tmpCell = categories(categorical(tmpCell));
tmpCell(contains(tmpCell,'Invalid')) = [];
Tx_MsgSignalGW = tmpCell;
Tx_SignalGW = tmpCell2;

% APP and CGW both used message, need two signal group
Tx_MsgMixed = intersect(Tx_MsgLink,Tx_MsgSignalGW);

%% Get signal routing and APP data mixed message and signals

% For routing and SWC mixed transmit message, SG only contains SWC
% calculated signals

% Tx_MsgMixed = intersect(Tx_MsgLink,Tx_MsgSignalGW);
% tmpCell = {};
% cnt = 0;
% for i = 1:length(Tx_MsgMixed)
%     MsgName = char(Tx_MsgMixed(i));
%     ColumnIndex = strcmp(MessageLink_Tx(1,:),Channel);
%
%     for k = 1:length(MessageLink_Tx(:,1))
%         if strcmp(MessageLink_Tx(k,ColumnIndex),MsgName)
%             cnt = cnt + 1;
%             tmpCell(cnt,1) = MessageLink_Tx(k,1);
%         end
%     end
% end
% Tx_SignalMixed = tmpCell;

%% Get Rx frame routing messages
if contains(Channel,'Dr')
    Channel_long = [extractBefore(Channel,'Dr') '_' extractAfter(Channel,'CAN')];
else
    Channel_long = Channel;
end
Raw_start = find(contains(RoutingTable(:,1),['requested signals, source:' Channel_long])) + 2;

tmpCell = {};
cnt = 0;
for i = 1:length(Raw_start)
    Raw_end = Raw_start(i) + find(contains(RoutingTable(Raw_start(i):end,1),'requested signals, source'),1,'first') - 2;
    if isempty(Raw_end); Raw_end = length(RoutingTable(:,1));end

    for k = Raw_start(i):Raw_end
        if strcmp(RoutingTable(k,1),'Invalid')
            cnt = cnt + 1;
            tmpCell(cnt,1) = RoutingTable(k,2);
        else
            continue
        end
    end
end
tmpCell = categories(categorical(tmpCell));
tmpCell(contains(tmpCell,'Invalid')) = [];
Rx_MsgFrameGW = tmpCell;

%% Get Rx signal routing messages
if contains(Channel,'Dr')
    Channel_long = [extractBefore(Channel,'Dr') '_' extractAfter(Channel,'CAN')];
else
    Channel_long = Channel;
end
Raw_start = find(contains(RoutingTable(:,1),['requested signals, source:' Channel_long])) + 2;

tmpCell = {};
cnt = 0;
for i = 1:length(Raw_start)
    Raw_end = Raw_start(i) + find(contains(RoutingTable(Raw_start(i):end,1),'requested signals, source'),1,'first') - 2;
    if isempty(Raw_end); Raw_end = length(RoutingTable(:,1));end

    for k = Raw_start(i):Raw_end
        if ~strcmp(RoutingTable(k,1),'Invalid')
            cnt = cnt + 1;
            tmpCell(cnt,1) = RoutingTable(k,2);
        else
            continue
        end
    end
end
tmpCell = categories(categorical(tmpCell));
tmpCell(contains(tmpCell,'Invalid')) = [];
Rx_MsgSignalGW = tmpCell;

%% Set up messages to ignore
cnt = 0;
IgnoreFilter = {};
for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % keep Diagxxx messages as N-PDU for A-Core use
    % keep signal routing messages
    % keep XNMm messages for workaround
    if startsWith(MsgName,'Diag') || ~all(~strcmp(MsgName,Tx_MsgSignalGW)) ||...
         ~all(~strcmp(MsgName,Rx_MsgSignalGW)) || startsWith(MsgName,'XNMm')
        continue

        % ignore useless messages
    elseif startsWith(MsgName,'NMm_') || startsWith(MsgName,'CCP') || startsWith(MsgName,'XCP') ||...
            all(isempty(DBC.MessageInfo(i).Signals))
        cnt = cnt+1;
        IgnoreFilter{cnt,1} = MsgName;

        % ignore messages belong to frame routing and not in MsgLink(APP not use)
    elseif all(~strcmp(MsgName,Rx_MsgLink)) && all(~strcmp(MsgName,Tx_MsgLink)) &&...
            (~all(~strcmp(MsgName,Tx_MsgFrameGW)) || ~all(~strcmp(MsgName,Rx_MsgFrameGW)))
        cnt = cnt+1;
        IgnoreFilter{cnt,1} = MsgName;

        % ignore Rx messages not in MsgLink(APP not use), not frame and not
        % signal routing
    elseif all(~strcmp(MsgName,Rx_MsgLink)) && all(~strcmp(MsgName,Tx_MsgLink)) &&...
            all(~strcmp(MsgName,Tx_MsgFrameGW)) && all(~strcmp(MsgName,Rx_MsgFrameGW)) &&...
            all(~strcmp(MsgName,Rx_MsgSignalGW)) && ~strcmp(DBC.MessageInfo(i).TxNodes,TargetECU)
        cnt = cnt+1;
        IgnoreFilter{cnt,1} = MsgName;
        
    end
end

%% Edit admin data
% get CAN_Template
fileID = fopen('CAN_Template.arxml');
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
OldString = extractBetween(Target_arxml(h),'>','<');
Target_arxml(h) = strrep(Target_arxml(h),OldString,ScriptVersion); % <SD GID="ScriptVersion">0.0.1</SD>

% modify DBC version
h = contains(Target_arxml(:,1),'<SD GID="InputFile_DBC">');
OldString = char(extractBetween(Target_arxml(h),'>','<'));
NewString = DBC.Name;
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString); % <SD GID="InputFile_DBC">D31_ET_V13_CAN3_FUSION_20230421_Fix.dbc</SD>

% modify Messagelink version
h = contains(Target_arxml(:,1),'<SD GID="InputFile_Msglink">');
OldString = char(extractBetween(Target_arxml(h),'>','<'));
NewString = MsgLinkFileName;
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString);% <SD GID="InputFile_Msglink">CAN_MessageLinkOut_202305241017.xlsx</SD>

%% Modify channel name
h = contains(Target_arxml(:,1),'<SHORT-NAME>PutChannelHere</SHORT-NAME>');
tmpCell = Target_arxml(h);
OldString = char(extractBetween(tmpCell,'>','<'));
NewString = Channel;
Target_arxml(h) = strrep(tmpCell,OldString,NewString);

%% Modify CAN-FRAME
FirstMessage = boolean(1);
Raw_start = find(contains(Target_arxml,'<CAN-FRAME>'),1,'first');
Raw_end = find(contains(Target_arxml,'</CAN-FRAME>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end); % extract CAN frame part
NM_PDUCnt = 0;

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);
    tmpCell = Template; % initialize tmpCell
    
    if startsWith(MsgName,'NMm')
       NM_PDUCnt = NM_PDUCnt + 1; 
    end

    % Message judgement, ignore PDUs that should not exist in arxml
    if any(strcmp(MsgName,IgnoreFilter))
        continue
    end
    
    if startsWith(MsgName,'Diag')
        MsgType = 'N-PDU'; % for DoIP message from A core
    else
        MsgType = 'I-SIGNAL-I-PDU';
    end
    FRAMELENGTH = num2str(DBC.MessageInfo(i).Length);

    h = find(contains(tmpCell,'<SHORT-NAME>FrameName</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN1_FD_VCU1</SHORT-NAME>

    h = find(contains(tmpCell,'<FRAME-LENGTH>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = FRAMELENGTH;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <FRAME-LENGTH>8</FRAME-LENGTH>

    h = find(contains(tmpCell,'<PDU-TO-FRAME-MAPPING>'))+1;
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN1_FD_VCU1</SHORT-NAME>

    h = find(contains(tmpCell,'<PDU-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = MsgType;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <PDU-REF DEST="I-SIGNAL-I-PDU">

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/PDU/' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN3/PDU/CAN1_FD_VCU1</PDU-REF>

    if FirstMessage
        Raw_start = find(contains(Target_arxml,'<CAN-FRAME>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</CAN-FRAME>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];

        FirstMessage = boolean(0);
    else
        Raw_start = find(contains(Target_arxml,'</CAN-FRAME>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

% Add NM-Frame
if NM_PDUCnt ~= 0
    for i = 1:2
        if i == 1
            Direction = 'TX';
        else
            Direction = 'RX';
        end
    
        tmpCell = Template;
    
        h = find(contains(tmpCell,'<SHORT-NAME>FrameName</SHORT-NAME>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = [Channel '_NMm_' TargetECU '_' Direction];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CANx_NMm_FDC_TX</SHORT-NAME>
    
        h = find(contains(tmpCell,'SHORT-NAME>FD_VCU1</SHORT-NAME>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = [Channel '_NMm_' TargetECU '_' Direction];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CANx_NMm_FDC_TX</SHORT-NAME>
    
        h = find(contains(tmpCell,'<FRAME-LENGTH>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = '8'; % NM message is CAN2.0
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <FRAME-LENGTH>8</FRAME-LENGTH>
    
        h = find(contains(tmpCell,'<PDU-REF DEST='));
        OldString = extractBetween(tmpCell(h),'"','"');
        NewString = 'NM-PDU';
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <<PDU-REF DEST="NM-PDU">
    
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/' Channel '/PDU/' Channel '_NMm_' TargetECU '_' Direction];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANx/PDU/CANx_NMm_FDC_TX
    
        Raw_start = find(contains(Target_arxml,'</CAN-FRAME>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

%% Modify PDU description
NM_PDUCnt = 0;
N_PDUCnt = 0;

% Edit I-SIGNAL-I-PDU part
Raw_start = find(contains(Target_arxml,'<I-SIGNAL-I-PDU>'),1,'first'); % <I-SIGNAL-I-PDU>
Raw_end = Raw_start + find(contains(Target_arxml(Raw_start:end),'</I-SIGNAL-I-PDU>'),1,'first') - 1; % </I-SIGNAL-I-PDU>
Template = Target_arxml(Raw_start:Raw_end); % extract IPDU part

Raw_start = find(contains(Template,'<I-SIGNAL-TO-I-PDU-MAPPING>'),1,'first'); % <I-SIGNAL-I-PDU>
Raw_end = find(contains(Template,'</I-SIGNAL-TO-I-PDU-MAPPING>'),1,'first');
Template_SG = Template(Raw_start:Raw_end); % extract SG part

FirstIPDU = boolean(1);
for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);
    tmpCell = Template;
    
    if startsWith(MsgName,'NMm')
       NM_PDUCnt = NM_PDUCnt + 1; 
    end

    % Message judgement, Diag PDUs are N-PDU, not I-PDU
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    CycleTime = DBC.MessageInfo(i).AttributeInfo(strcmp(DBC.MessageInfo(i).Attributes(:,1),'GenMsgCycleTime')).Value;
    FRAMELENGTH = num2str(DBC.MessageInfo(i).Length);
    MsgSendType = DBC.MessageInfo(i).AttributeInfo(strcmp(DBC.MessageInfo(i).Attributes(:,1),'GenMsgSendType')).Value;
    %     NumberOfRepetition = DBC.MessageInfo(i).AttributeInfo(strcmp(DBC.MessageInfo(i).Attributes(:,1),'GenMsgNrOfRepetition')).Value;
    %     RepetitionPeriod = DBC.MessageInfo(i).AttributeInfo(strcmp(DBC.MessageInfo(i).Attributes(:,1),'GenMsgCycleTimeFast')).Value;

    if strcmp(MsgSendType,'Cycle')
        TransferProperty_SG = 'PENDING';
    elseif strcmp(MsgSendType,'CE')
        TransferProperty_SG = 'TRIGGERED-ON-CHANGE';
    elseif strcmp(MsgSendType,'Event')
        TransferProperty_SG = 'TRIGGERED';
    else
        error(['MsgSendType of ' Channel '_' MsgName ' unrecognize'])
    end

    h = find(contains(tmpCell,'<SHORT-NAME>IPDUName</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN1_FD_VCU1</SHORT-NAME>

    h = find(contains(tmpCell,'<LENGTH>8</LENGTH>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = FRAMELENGTH;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <LENGTH>8</LENGTH>

    h = find(contains(tmpCell,'<TIME-PERIOD>'))+1;
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = num2str(CycleTime/1000); % convert ms from DBC to s in arxml
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <VALUE>0.01</VALUE>

    % Delete cyclic timing description for event message
    if strcmp(TransferProperty_SG,'TRIGGERED')
        Raw_start = find(contains(tmpCell,'<CYCLIC-TIMING>'));
        Raw_end = find(contains(tmpCell,'</CYCLIC-TIMING>'));
        tmpCell(Raw_start:Raw_end) = [];
    end
    
    h = find(contains(tmpCell,'<NUMBER-OF-REPETITIONS>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = '0'; % FVT does not use this attribute
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <NUMBER-OF-REPETITIONS>1</NUMBER-OF-REPETITIONS>

    h = find(contains(tmpCell,'<REPETITION-PERIOD>')) + 1;
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = '0'; % FVT does not use this attribute
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <VALUE>0.01</VALUE>

    if any(strcmp(MsgName,Tx_MsgMixed)) % Need 2 signal groups
        tmpCell2 = Template_SG;

        % Add APP used SG
        h = find(contains(tmpCell2,'<SHORT-NAME>SignalGroup</SHORT-NAME>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = [Channel '_SG_' MsgName];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>CAN3_SG_BMS1</SHORT-NAME>

        h = find(contains(tmpCell2,'<I-SIGNAL-GROUP-REF DEST="I-SIGNAL-GROUP">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' Channel '/ISignalGroup/' Channel '_SG_' MsgName]; % /CAN3/ISignalGroup/CAN3_SG_BMS1
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <I-SIGNAL-GROUP-REF DEST="I-SIGNAL-GROUP">/CAN3/ISignalGroup/CAN3_SG_BMS1</I-SIGNAL-GROUP-REF>

        % to define transfer property of this SG, default as pending
        TransferProperty_SG = 'PENDING';
        for k = 1:length(DBC.MessageInfo(i).Signals)
            SignalName = char(DBC.MessageInfo(i).Signals(k));

            if any(strcmp(SignalName,Tx_SignalGW))
                continue
            else
                SignalSendType = DBC.MessageInfo(i).SignalInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(i).SignalInfo(k).Attributes(:,1),'GenSigSendType')).Value;
                if strcmp(SignalSendType,'OnChange')
                    TransferProperty_SG = 'TRIGGERED-ON-CHANGE';
                    break
                end
            end
        end

        h = find(contains(tmpCell2,'<TRANSFER-PROPERTY>SignalGroupTransfer</TRANSFER-PROPERTY>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = TransferProperty_SG;
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <TRANSFER-PROPERTY>PENDING</TRANSFER-PROPERTY>

        % Replace first SG description
        Raw_start = find(contains(tmpCell,'<I-SIGNAL-TO-I-PDU-MAPPING>'),1,'first'); % <I-SIGNAL-TO-I-PDU-MAPPING>
        Raw_end = find(contains(tmpCell,'</I-SIGNAL-TO-I-PDU-MAPPING>'),1,'first'); % </I-SIGNAL-TO-I-PDU-MAPPING>
        tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];

        tmpCell2 = Template_SG;

        % Add CGW used SG
        h = find(contains(tmpCell2,'<SHORT-NAME>SignalGroup</SHORT-NAME>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = [Channel '_SG_CGW_' MsgName];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>CAN3_SG_BMS1</SHORT-NAME>

        h = find(contains(tmpCell2,'<I-SIGNAL-GROUP-REF DEST="I-SIGNAL-GROUP">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' Channel '/ISignalGroup/' Channel '_SG_CGW_' MsgName]; % /CAN3/ISignalGroup/CAN3_SG_BMS1
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <I-SIGNAL-GROUP-REF DEST="I-SIGNAL-GROUP">/CAN3/ISignalGroup/CAN3_SG_BMS1</I-SIGNAL-GROUP-REF>

        % to define transfer property of this SG, default as pending
        TransferProperty_SG = 'PENDING';
        for k = 1:length(DBC.MessageInfo(i).Signals)
            SignalName = char(DBC.MessageInfo(i).Signals(k));

            if ~any(strcmp(SignalName,Tx_SignalGW))
                continue
            else
                SignalSendType = DBC.MessageInfo(i).SignalInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(i).SignalInfo(k).Attributes(:,1),'GenSigSendType')).Value;
                if strcmp(SignalSendType,'OnChange')
                    TransferProperty_SG = 'TRIGGERED-ON-CHANGE';
                    break
                end
            end
        end

        h = find(contains(tmpCell2,'<TRANSFER-PROPERTY>SignalGroupTransfer</TRANSFER-PROPERTY>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = TransferProperty_SG;
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <TRANSFER-PROPERTY>PENDING</TRANSFER-PROPERTY>

        % Add second SG description
        Raw_start = find(contains(tmpCell,'</I-SIGNAL-TO-I-PDU-MAPPING>'),1,'first'); % <I-SIGNAL-TO-I-PDU-MAPPING>
        Raw_end = Raw_start + 1; % </I-SIGNAL-TO-I-PDU-MAPPING>
        tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];

    else
        tmpCell2 = Template_SG;
        h = find(contains(tmpCell2,'<SHORT-NAME>SignalGroup</SHORT-NAME>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = [Channel '_SG_' MsgName];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>CAN3_SG_BMS1</SHORT-NAME>

        h = find(contains(tmpCell2,'<I-SIGNAL-GROUP-REF DEST="I-SIGNAL-GROUP">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' Channel '/ISignalGroup/' Channel '_SG_' MsgName]; % /CAN3/ISignalGroup/CAN3_SG_BMS1
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <I-SIGNAL-GROUP-REF DEST="I-SIGNAL-GROUP">/CAN3/ISignalGroup/CAN3_SG_BMS1</I-SIGNAL-GROUP-REF>

        % to define transfer property of this SG
        if strcmp(MsgSendType,'Cycle')
            TransferProperty_SG = 'PENDING';
        elseif strcmp(MsgSendType,'CE')
            TransferProperty_SG = 'TRIGGERED-ON-CHANGE';
        elseif strcmp(MsgSendType,'Event')
            TransferProperty_SG = 'TRIGGERED';
        else
            error(['MsgSendType of ' Channel '_' MsgName ' unrecognize'])
        end

        h = find(contains(tmpCell2,'<TRANSFER-PROPERTY>SignalGroupTransfer</TRANSFER-PROPERTY>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = TransferProperty_SG;
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <TRANSFER-PROPERTY>PENDING</TRANSFER-PROPERTY>

        % Replace first SG description
        Raw_start = find(contains(tmpCell,'<I-SIGNAL-TO-I-PDU-MAPPING>'),1,'first'); % <I-SIGNAL-TO-I-PDU-MAPPING>
        Raw_end = find(contains(tmpCell,'</I-SIGNAL-TO-I-PDU-MAPPING>'),1,'first'); % </I-SIGNAL-TO-I-PDU-MAPPING>
        tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
    end

    % extract I-SIGNAL-TO-I-PDU-MAPPING part to fill out all message signals
    Raw_start = find(contains(tmpCell,'<SHORT-NAME>Signals</SHORT-NAME>'))-1; % <I-SIGNAL-TO-I-PDU-MAPPING>
    Raw_end = find(contains(tmpCell,'</I-SIGNAL-TO-I-PDU-MAPPING>'),1,'last'); % </I-SIGNAL-TO-I-PDU-MAPPING>
    tmpCell2 = tmpCell(Raw_start:Raw_end);

    for k = 1:length(DBC.MessageInfo(i).Signals)
        SignalSendType = DBC.MessageInfo(i).SignalInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(i).SignalInfo(k).Attributes(:,1),'GenSigSendType')).Value;
        SignalName = char(DBC.MessageInfo(i).Signals(k));
        Startbit = DBC.MessageInfo(i).SignalInfo(k).StartBit;
        ByteOrder = DBC.MessageInfo(i).SignalInfo(k).ByteOrder; % BigEndian = motorola, LittleEndian = intel
        SignalLength = DBC.MessageInfo(i).SignalInfo(k).SignalSize;

        if strcmp(ByteOrder,'BigEndian')
            PackingByteOrder = 'MOST-SIGNIFICANT-BYTE-FIRST';

            % convert start bit to Motorola format
            LSB_Byte = floor(Startbit/8);
            remainlength = SignalLength-(8-rem(Startbit,8));

            if remainlength <= 0
                Startbit = Startbit + SignalLength - 1;
            else
                MSB_Byte = LSB_Byte - ceil(remainlength/8);
                if rem(remainlength,8) == 0
                    Startbit = (8*MSB_Byte) + 7;
                else
                    Startbit = (8*MSB_Byte) + rem(remainlength,8) - 1;
                end
            end
        elseif strcmp(ByteOrder,'LittleEndian')

            PackingByteOrder = 'MOST-SIGNIFICANT-BYTE-LAST';
        end

        h = find(contains(tmpCell2,'<SHORT-NAME>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = [Channel '_' SignalName];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>CAN3_PwrSta</SHORT-NAME>

        h = find(contains(tmpCell2,'<I-SIGNAL-REF DEST="I-SIGNAL">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' Channel '/ISignal/' Channel '_' SignalName]; % /CAN3/ISignal/CAN3_PwrSta
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <I-SIGNAL-REF DEST="I-SIGNAL">/CAN3/ISignal/CAN3_PwrSta</I-SIGNAL-REF>

        h = find(contains(tmpCell2,'<PACKING-BYTE-ORDER>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = PackingByteOrder;
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString);

        h = find(contains(tmpCell2,'<START-POSITION>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = num2str(Startbit);
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <START-POSITION>375</START-POSITION>

        h = find(contains(tmpCell2,'<TRANSFER-PROPERTY>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        if strcmp(SignalSendType,'Cycle')
            TransferProperty_Signal = 'PENDING';
        elseif strcmp(SignalSendType,'OnChange')
            TransferProperty_Signal = 'TRIGGERED-ON-CHANGE';
        elseif contains(SignalSendType,'OnWrite')
            TransferProperty_Signal = 'TRIGGERED';
        else
            error(['The signal "' SignalName '"' 'in ' Channel '_' MsgName ' GenSigSendType unrecognize'])
        end
        tmpCell2(h) = strrep(tmpCell2(h),OldString,TransferProperty_Signal); % <TRANSFER-PROPERTY>PENDING</TRANSFER-PROPERTY>

        if k == 1 % to replace original part
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
        else % to add new part
            Raw_start = find(contains(tmpCell,'</I-SIGNAL-TO-I-PDU-MAPPING>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    if strcmp(MsgSendType,'Cycle') % delete CE message part
        Raw_start = find(contains(tmpCell,'<EVENT-CONTROLLED-TIMING>'),1,'first');
        Raw_end = find(contains(tmpCell,'</EVENT-CONTROLLED-TIMING>'),1,'first');
        tmpCell(Raw_start:Raw_end) = [];
    end

    if FirstIPDU
        Raw_start = find(contains(Target_arxml,'<I-SIGNAL-I-PDU>'),1,'first'); % find the first <I-SIGNAL-I-PDU>
        Raw_end = find(contains(Target_arxml,'</I-SIGNAL-I-PDU>'),1,'first'); % find the last </I-SIGNAL-I-PDU>
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
        FirstIPDU = boolean(0);
    else
        Raw_start = find(contains(Target_arxml,'</I-SIGNAL-I-PDU>'),1,'last'); % find the last </I-SIGNAL-I-PDU>
        Raw_end = Raw_start +1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

% Edit N-PDU and DCM-I-PDU part
Raw_start = find(contains(Target_arxml,'<N-PDU>'),1,'first'); % <N-PDU>
Raw_end = find(contains(Target_arxml,'</N-PDU>'),1,'first');
Template_NPDU = Target_arxml(Raw_start:Raw_end); % extract N-PDU part

Raw_start = find(contains(Target_arxml,'<DCM-I-PDU>'),1,'first'); % <DCM-I-PDU>
Raw_end = find(contains(Target_arxml,'</DCM-I-PDU>'),1,'first');
Template_DCMIPDU = Target_arxml(Raw_start:Raw_end); % extract DCM-I-PDU part
FirstNPDU = boolean(1);
for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);
    tmpCell = Template_NPDU;
    tmpCell2 = Template_DCMIPDU;

    % Message judgement, only Diag PDUs are N-PDU
    if any(strcmp(MsgName,IgnoreFilter)) || ~startsWith(MsgName,'Diag')
        continue
    end

    % In CANIf, it will ignore all frames that length <= frame length definition
    % Diagnostic messages can have variable length from 8~64, so the length definition should be 8.
    FRAMELENGTH = '8';
    N_PDUCnt = N_PDUCnt + 1;

    if strcmp(DBC.MessageInfo(i).TxNodes,TargetECU)
        Direction = 'DIAG-RESPONSE';
    else
        Direction = 'DIAG-REQUEST';
    end

    h = find(contains(tmpCell,'<SHORT-NAME>NPDUName</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN3_DiagRespFromShifter</SHORT-NAME>

    h = find(contains(tmpCell,'<LENGTH>8</LENGTH>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = FRAMELENGTH;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <LENGTH>8</LENGTH>

    h = find(contains(tmpCell2,'<SHORT-NAME>DCMIPDUName</SHORT-NAME>'));
    OldString = extractBetween(tmpCell2(h),'>','<');
    NewString = [Channel '_SDU_' MsgName];
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>CAN3_SDU_DiagRespFromShifter</SHORT-NAME>

    h = find(contains(tmpCell2,'<LENGTH>4095</LENGTH>'));
    OldString = extractBetween(tmpCell2(h),'>','<');
    NewString = '4095';
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <LENGTH>4095</LENGTH>

    h = find(contains(tmpCell2,'<DIAG-PDU-TYPE>DIAG-REQUEST</DIAG-PDU-TYPE>'));
    OldString = extractBetween(tmpCell2(h),'>','<');
    NewString = Direction;
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <DIAG-PDU-TYPE>DIAG-REQUEST</DIAG-PDU-TYPE>

    if FirstNPDU
        Raw_start = find(contains(Target_arxml,'<N-PDU>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</N-PDU>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];

        Raw_start = find(contains(Target_arxml,'<DCM-I-PDU>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</DCM-I-PDU>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell2(1:end);Target_arxml(Raw_end+1:end)];
        FirstNPDU = boolean(0);
    else
        Raw_start = find(contains(Target_arxml,'</N-PDU>'),1,'last');
        Raw_end = Raw_start +1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];

        Raw_start = find(contains(Target_arxml,'</DCM-I-PDU>'),1,'last');
        Raw_end = Raw_start +1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell2(1:end);Target_arxml(Raw_end:end)];
    end
end

% Edit NM-PDU part
Raw_start = find(contains(Target_arxml,'<NM-PDU>'),1,'first'); % find the first <NM-PDU>
Raw_end = find(contains(Target_arxml,'</NM-PDU>'),1,'first'); % find the last </NM-PDU>;
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:2
    tmpCell = Template;
    if i == 1; Direction = 'TX'; else; Direction = 'RX'; end

    h = find(contains(tmpCell,'<SHORT-NAME>NmPDUName</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [Channel '_NMm_' TargetECU '_' Direction];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CANx_NMm_FDC_TX</SHORT-NAME>

    if i == 1 % Replace original
        Raw_start = find(contains(Target_arxml,'<NM-PDU>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</NM-PDU>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];

    else % Add new part
        Raw_start = find(contains(Target_arxml,'</NM-PDU>'),1,'last');
        Raw_end = Raw_start +1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

% delete NM-PDU part if no NM-PDU exist
if NM_PDUCnt == 0
    Raw_start = find(contains(Target_arxml,'<NM-PDU>'),1,'first'); % find the first <NM-PDU>
    Raw_end = find(contains(Target_arxml,'</NM-PDU>'),1,'last'); % find the last </NM-PDU>;
    Target_arxml(Raw_start:Raw_end) = [];
end

% delete N-PDU part if no N-PDU exist
if N_PDUCnt == 0
    Raw_start = find(contains(Target_arxml,'<N-PDU>'),1,'first'); % find the first <N-PDU>
    Raw_end = find(contains(Target_arxml,'</N-PDU>'),1,'last'); % find the last </N-PDU>;
    Target_arxml(Raw_start:Raw_end) = [];

    Raw_start = find(contains(Target_arxml,'<DCM-I-PDU>'),1,'first'); % find the first <DCM-I-PDU>
    Raw_end = find(contains(Target_arxml,'</DCM-I-PDU>'),1,'last'); % find the last <DCM-I-PDU>;
    Target_arxml(Raw_start:Raw_end) = [];
end
%% Modify I-Signal
FirstMessage = boolean(1);
Raw_start = find(contains(Target_arxml,'<I-SIGNAL>'));
Raw_end = find(contains(Target_arxml,'</I-SIGNAL>'));
tmpCell = Target_arxml(Raw_start:Raw_end); % extract ISignal part

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % Message judgement, Diag PDUs are N-PDU, not I-PDU
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    for k = 1:length(DBC.MessageInfo(i).Signals)
        SignalName = char(DBC.MessageInfo(i).Signals(k));
        SignalLength = DBC.MessageInfo(i).SignalInfo(k).SignalSize;

        % determine signal base and implementation data type
        if rem(SignalLength,8) == 0 && SignalLength <= 16
            SignalType = ['uint' num2str(SignalLength)];
        elseif floor(SignalLength/8) <= 1
            SignalType = ['uint' num2str(8*(floor(SignalLength/8)+1))]; % uint8 or uint16
        elseif floor(SignalLength/8) <= 4
            SignalType = 'uint32';
        else
            SignalType = 'uint64';
        end

        h = find(contains(tmpCell,'<SHORT-NAME>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = [Channel '_' SignalName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN1_PwrSta</SHORT-NAME>

        h = find(contains(tmpCell,'<CONSTANT-REF DEST="CONSTANT-SPECIFICATION">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/' Channel '/ConstantSpecification/Init_' Channel '_' SignalName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <CONSTANT-REF DEST="CONSTANT-SPECIFICATION">/CAN1/ConstantSpecification/Init_CAN1_PwrSta</CONSTANT-REF>

        h = find(contains(tmpCell,'<LENGTH>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = num2str(SignalLength);
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <LENGTH>3</LENGTH>

        h = find(contains(tmpCell,'<BASE-TYPE-REF DEST="SW-BASE-TYPE">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/AUTOSAR_Platform/BaseTypes/' SignalType];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <BASE-TYPE-REF DEST="SW-BASE-TYPE">/AUTOSAR_Platform/BaseTypes/uint8</BASE-TYPE-REF>

        h = find(contains(tmpCell,'<IMPLEMENTATION-DATA-TYPE-REF DEST="IMPLEMENTATION-DATA-TYPE">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/AUTOSAR_Platform/ImplementationDataTypes/' SignalType];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <IMPLEMENTATION-DATA-TYPE-REF DEST="IMPLEMENTATION-DATA-TYPE">/AUTOSAR_Platform/ImplementationDataTypes/uint8</IMPLEMENTATION-DATA-TYPE-REF>

        h = find(contains(tmpCell,'<SYSTEM-SIGNAL-REF DEST="SYSTEM-SIGNAL">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/' Channel '/Signal/' Channel '_' SignalName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SYSTEM-SIGNAL-REF DEST="SYSTEM-SIGNAL">/CAN1/Signal/CAN1_PwrSta</SYSTEM-SIGNAL-REF>

        if FirstMessage && k == 1 % to replace original part
            Raw_start = find(contains(Target_arxml,'<I-SIGNAL>'));
            Raw_end = find(contains(Target_arxml,'</I-SIGNAL>'));
            Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
        else % to add new part
            Raw_start = find(contains(Target_arxml,'</I-SIGNAL>'),1,'last');
            Raw_end = Raw_start + 1;
            Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        end
    end
    FirstMessage = boolean(0);
end

%% Modify ISignalGroup
FirstMessage = boolean(1);
Raw_start = find(contains(Target_arxml,'<I-SIGNAL-GROUP>'));
Raw_end = find(contains(Target_arxml,'</I-SIGNAL-GROUP>'));
Template = Target_arxml(Raw_start:Raw_end); % extract ISignalGroup part

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % Message judgement, Diag PDUs are N-PDU, not I-PDU
    % Ignore pure signal routing Tx messages.
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    if any(strcmp(MsgName,Tx_MsgMixed)) % Need 2 signal groups
        Need2SG = boolean(1);
        SGName = {[Channel '_SG_' MsgName];[Channel '_SG_CGW_' MsgName]};
    else
        Need2SG = boolean(0);
        SGName = {[Channel '_SG_' MsgName]};
    end

    for n = 1:length(SGName)
        tmpCell = Template;

        h = find(contains(tmpCell,'<SHORT-NAME>TargetSignalGroup</SHORT-NAME>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = char(SGName(n));
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN3_SG_BMS1</SHORT-NAME>

        h = find(contains(tmpCell,'<SYSTEM-SIGNAL-GROUP-REF DEST="SYSTEM-SIGNAL-GROUP">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/' Channel '/SignalGroup/' char(SGName(n))]; % /CAN3/SignalGroup/CAN3_SG_BMS1
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

        h = find(contains(tmpCell,'<I-SIGNAL-REF DEST="I-SIGNAL">'),1,'first');
        tmpCell2 = tmpCell(h); % extract signal group reference part

        FirstSignal = boolean(1);
        for k = 1:length(DBC.MessageInfo(i).Signals)
            SignalName = char(DBC.MessageInfo(i).Signals(k));

            % First SG only contains SWC calculated signals/undefined source signals
            if Need2SG && n == 1 && any(strcmp(SignalName,Tx_SignalGW))
                continue
            elseif Need2SG && n == 2 && ~any(strcmp(SignalName,Tx_SignalGW))
                continue
            end

            h = find(contains(tmpCell2,'<I-SIGNAL-REF DEST="I-SIGNAL">'));
            OldString = extractBetween(tmpCell2(h),'>','<');
            NewString = ['/' Channel '/ISignal/' Channel '_' SignalName];
            tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <I-SIGNAL-REF DEST="I-SIGNAL">/CAN1/ISignal/CAN1_PwrSta</I-SIGNAL-REF>

            if FirstSignal % to replace original part
                tmpCell(contains(tmpCell,'<I-SIGNAL-REF DEST="I-SIGNAL">')) = tmpCell2(h);
                FirstSignal = boolean(0);
            else % to add new part
                Raw_start = find(contains(tmpCell,'<I-SIGNAL-REF DEST="I-SIGNAL">'),1,'last');
                Raw_end = Raw_start + 1;
                tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
            end
        end

        % Update target arxml
        if FirstMessage % to replace original part
            Raw_start = find(contains(Target_arxml,'<I-SIGNAL-GROUP>'),1,'first');
            Raw_end = find(contains(Target_arxml,'</I-SIGNAL-GROUP>'),1,'first');
            Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
            FirstMessage = boolean(0);
        else % to add new part
            Raw_start = find(contains(Target_arxml,'</I-SIGNAL-GROUP>'),1,'last');
            Raw_end = Raw_start + 1;
            Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        end
    end
end

%% Modify system signal
FirstMessage = boolean(1);
Raw_start = find(contains(Target_arxml,'<SYSTEM-SIGNAL>'));
Raw_end = find(contains(Target_arxml,'</SYSTEM-SIGNAL>'));
tmpCell = Target_arxml(Raw_start:Raw_end); % extract ISignal frame part

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % Message judgement, Diag PDUs are N-PDU, not I-PDU
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    FirstSignal = boolean(1);
    for k = 1:length(DBC.MessageInfo(i).Signals)
        SignalName = char(DBC.MessageInfo(i).Signals(k));

        h = find(contains(tmpCell,'<SHORT-NAME>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = [Channel '_' SignalName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN1_PwrSta</SHORT-NAME>

        if FirstMessage && FirstSignal % to replace original part
            Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
            FirstSignal = boolean(0);
        else % to add new part
            Raw_start = find(contains(Target_arxml,'</SYSTEM-SIGNAL>'),1,'last');
            Raw_end = Raw_start + 1;
            Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        end
    end
    FirstMessage = boolean(0);
end

%% Modify System Signal Group
FirstMessage = boolean(1);
Raw_start = find(contains(Target_arxml,'<SYSTEM-SIGNAL-GROUP>'));
Raw_end = find(contains(Target_arxml,'</SYSTEM-SIGNAL-GROUP>'));
Template = Target_arxml(Raw_start:Raw_end); % extract ISignalGroup part

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % Message judgement, Diag PDUs are N-PDU, not I-PDU
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    if any(strcmp(MsgName,Tx_MsgMixed)) % Need 2 signal groups
        Need2SG = boolean(1);
        SGName = {[Channel '_SG_' MsgName];[Channel '_SG_CGW_' MsgName]};
    else
        Need2SG = boolean(0);
        SGName = {[Channel '_SG_' MsgName]};
    end

    for n = 1:length(SGName)
        tmpCell = Template;

        h = find(contains(tmpCell,'<SHORT-NAME>TargetSystemSignalGroup</SHORT-NAME>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = char(SGName(n));
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN3_SG_BMS1</SHORT-NAME>

        h = find(contains(tmpCell,'<SYSTEM-SIGNAL-REF DEST="SYSTEM-SIGNAL">'),1,'first');
        tmpCell2 = tmpCell(h); % extract signal group reference part

        FirstSignal = boolean(1);
        for k = 1:length(DBC.MessageInfo(i).Signals)
            SignalName = char(DBC.MessageInfo(i).Signals(k));

            % First SG only contains SWC calculated signals/undefined source signals
            if Need2SG && n == 1 && any(strcmp(SignalName,Tx_SignalGW))
                continue
            elseif Need2SG && n == 2 && ~any(strcmp(SignalName,Tx_SignalGW))
                continue
            end

            h = find(contains(tmpCell2,'<SYSTEM-SIGNAL-REF DEST="SYSTEM-SIGNAL">'));
            OldString = extractBetween(tmpCell2(h),'>','<');
            NewString = ['/' Channel '/Signal/' Channel '_' SignalName];
            tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString);

            if FirstSignal % to replace original part
                tmpCell(contains(tmpCell,'<SYSTEM-SIGNAL-REF DEST="SYSTEM-SIGNAL">')) = tmpCell2(h);
                FirstSignal = boolean(0);
            else % to add new part
                Raw_start = find(contains(tmpCell,'<SYSTEM-SIGNAL-REF DEST="SYSTEM-SIGNAL">'),1,'last');
                Raw_end = Raw_start + 1;
                tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
            end
        end

        % Update target arxml
        if FirstMessage % to replace original part
            Raw_start = find(contains(Target_arxml,'<SYSTEM-SIGNAL-GROUP>'),1,'first');
            Raw_end = find(contains(Target_arxml,'</SYSTEM-SIGNAL-GROUP>'),1,'first');
            Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
            FirstMessage = boolean(0);
        else % to add new part
            Raw_start = find(contains(Target_arxml,'</SYSTEM-SIGNAL-GROUP>'),1,'last');
            Raw_end = Raw_start + 1;
            Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        end
    end
end

%% Edit cluster
% Cluster contains 4 parts:
% 1. Channel description
% 2. Frame triggerings
% 3. ISignal triggerings
% 4. PDU triggerings
% It's too complicated to modify all 4 parts in one for-loop,
% so it will be separated to several for-loops

% Modify Channel description part
h = find(contains(Target_arxml,'<SHORT-NAME>CANChannel</SHORT-NAME>'));
OldString = extractBetween(Target_arxml(h),'>','<');
NewString = Channel;
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString); % <SHORT-NAME>CAN1</SHORT-NAME>

h = find(contains(Target_arxml,'<SHORT-NAME>PhysicalChannel</SHORT-NAME>'));
OldString = extractBetween(Target_arxml(h),'>','<');
NewString = Channel;
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString); % <SHORT-NAME>CAN1</SHORT-NAME>

h = find(contains(Target_arxml,'<COMMUNICATION-CONNECTOR-REF DEST="CAN-COMMUNICATION-CONNECTOR">'));
OldString = extractBetween(Target_arxml(h),'>','<');
NewString = ['/ECU/' TargetECU '/Conn' Channel];
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString); % /ECU/FUSION/ConnCAN3

% Modify frame triggering part
Raw_start = find(contains(Target_arxml,'<CAN-FRAME-TRIGGERING>'));
Raw_end = find(contains(Target_arxml,'</CAN-FRAME-TRIGGERING>'));
Template = Target_arxml(Raw_start:Raw_end); % extract frame triggering template part
FirstMessage = boolean(1);

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % Message judgement, all CAN-FRAME should have FRAME-TRIGGERING
    if any(strcmp(MsgName,IgnoreFilter))
        continue
    end

    if strcmp(DBC.MessageInfo(i).TxNodes,TargetECU)
        Direction = 'OUT';
    else
        Direction = 'IN';
    end

    CANMode = DBC.MessageInfo(i).ProtocolMode;
    MessageID = DBC.MessageInfo(i).ID;

    if MessageID > 4095
        AddressMode = 'EXTENDED';
    else
        AddressMode = 'STANDARD';
    end

    tmpCell = Template; % re-initialize tmpCell

    h = find(contains(tmpCell,'<SHORT-NAME>FrameTriggering</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['FT_' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>FT_CAN1_FD_VCU1</SHORT-NAME>

    h = find(contains(tmpCell,'<FRAME-PORT-REF DEST="FRAME-PORT">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/ECU/' TargetECU '/Conn' Channel '/FP_' Channel '_' MsgName '_' Direction];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /ECU/FUSION/ConnCAN1/FP_CAN1_FD_VCU1_OUT

    h = find(contains(tmpCell,'<FRAME-REF DEST="CAN-FRAME">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/Frame/' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/Frame/CAN1_FD_VCU1

    h = find(contains(tmpCell,'<PDU-TRIGGERING-REF DEST="PDU-TRIGGERING">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/Cluster/' Channel '/' Channel '/PT_' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN3/Cluster/CAN3/CAN3/PT_CAN3_FD_VCU1

    if strcmp(CANMode,'CAN FD')
        h = find(contains(tmpCell,'<CAN-ADDRESSING-MODE>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = AddressMode;
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <CAN-ADDRESSING-MODE>EXTENDED</CAN-ADDRESSING-MODE>

        h = find(contains(tmpCell,'<CAN-FD-FRAME-SUPPORT>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = 'true';
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <CAN-FD-FRAME-SUPPORT>true</CAN-FD-FRAME-SUPPORT>

        h = find(contains(tmpCell,'<CAN-FRAME-RX-BEHAVIOR>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = 'CAN-FD';
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <CAN-FRAME-RX-BEHAVIOR>CAN-FD</CAN-FRAME-RX-BEHAVIOR>

        h = find(contains(tmpCell,'<CAN-FRAME-TX-BEHAVIOR>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = 'CAN-FD';
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <CAN-FRAME-TX-BEHAVIOR>CAN-FD</CAN-FRAME-TX-BEHAVIOR>

    else
        h = find(contains(tmpCell,'<CAN-ADDRESSING-MODE>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = AddressMode;
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <CAN-ADDRESSING-MODE>EXTENDED</CAN-ADDRESSING-MODE>
        
        h = find(contains(tmpCell,'<CAN-FD-FRAME-SUPPORT>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = 'false';
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <CAN-FD-FRAME-SUPPORT>false</CAN-FD-FRAME-SUPPORT>

        h = find(contains(tmpCell,'<CAN-FRAME-RX-BEHAVIOR>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = 'CAN-20';
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <CAN-FRAME-RX-BEHAVIOR>CAN-20</CAN-FRAME-RX-BEHAVIOR>

        h = find(contains(tmpCell,'<CAN-FRAME-TX-BEHAVIOR>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = 'CAN-20';
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <CAN-FRAME-TX-BEHAVIOR>CAN-20</CAN-FRAME-TX-BEHAVIOR>
    end

    h = find(contains(tmpCell,'<IDENTIFIER>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = num2str(MessageID);
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <IDENTIFIER>278</IDENTIFIER>

    if startsWith(MsgName,'NMm_') || startsWith(MsgName,'Diag')
        Raw_start = find(contains(tmpCell,'<PDU-TRIGGERINGS>'),1,'first');
        Raw_end = find(contains(tmpCell,'</PDU-TRIGGERINGS>'),1,'first');
        tmpCell(Raw_start:Raw_end) = [];
    end

    if FirstMessage % to replace original part
        Raw_start = find(contains(Target_arxml,'<CAN-FRAME-TRIGGERING>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</CAN-FRAME-TRIGGERING>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
        FirstMessage = boolean(0);
    else % to add new part
        Raw_start = find(contains(Target_arxml,'</CAN-FRAME-TRIGGERING>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

% Add Frame triggerring for NM
if NM_PDUCnt ~= 0
    for i = 1:2
        tmpCell2 = Template; % re-initialize tmpCell2
        Raw_start = find(contains(tmpCell2,'<PDU-TRIGGERINGS>'),1,'first');
        Raw_end = find(contains(tmpCell2,'</PDU-TRIGGERINGS>'),1,'first');
        tmpCell2(Raw_start:Raw_end) = [];
    
        if i == 1; Direction = 'TX'; else; Direction = 'RX'; end
        if i == 1; Direction_Port = 'OUT'; else; Direction_Port = 'IN'; end
    
        h = find(contains(tmpCell2,'<SHORT-NAME>FrameTriggering</SHORT-NAME>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['FT_' Channel '_NMm_' TargetECU '_' Direction];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>FT_CANx_NMm_FDC_TX</SHORT-NAME>
    
        h = find(contains(tmpCell2,'<FRAME-PORT-REF DEST="FRAME-PORT">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/ECU/' TargetECU '/Conn' Channel '/FP_' Channel '_NMm_' TargetECU '_' Direction '_' Direction_Port];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /ECU/FDC/ConnCANx/FP_CANx_NMm_FDC_DR_TX_OUT
    
        h = find(contains(tmpCell2,'<FRAME-REF DEST="CAN-FRAME">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' Channel '/Frame/' Channel '_NMm_' TargetECU '_' Direction];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CANx/Frame/CANx_NMm_FDC_TX
    
        h = find(contains(tmpCell2,'<CAN-FD-FRAME-SUPPORT>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = 'false';
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <CAN-FD-FRAME-SUPPORT>true</CAN-FD-FRAME-SUPPORT>
    
        h = find(contains(tmpCell2,'<CAN-FRAME-RX-BEHAVIOR>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = 'CAN-20';
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <CAN-FRAME-RX-BEHAVIOR>CAN-20</CAN-FRAME-RX-BEHAVIOR>
    
        h = find(contains(tmpCell2,'<CAN-FRAME-TX-BEHAVIOR>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = 'CAN-20';
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <CAN-FRAME-TX-BEHAVIOR>CAN-20</CAN-FRAME-TX-BEHAVIOR>
    
        h = find(contains(tmpCell2,'<IDENTIFIER>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = '1280';
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <IDENTIFIER>278</IDENTIFIER>
    
        Raw_start = find(contains(Target_arxml,'</CAN-FRAME-TRIGGERING>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell2(1:end);Target_arxml(Raw_end:end)];
    end
end

%% Modify ISignal triggering part
Raw_start = find(contains(Target_arxml,'<I-SIGNAL-TRIGGERING>'),1,'first');
Raw_end = find(contains(Target_arxml,'</I-SIGNAL-TRIGGERING>'),1,'first');
Template_SG = Target_arxml(Raw_start:Raw_end);

Raw_start = find(contains(Target_arxml,'<SHORT-NAME>SignalTriggering</SHORT-NAME>'),1,'first') -1;
Raw_end = find(contains(Target_arxml,'</I-SIGNAL-TRIGGERING>'),1,'last');
Template_Sig = Target_arxml(Raw_start:Raw_end);
Target_arxml(Raw_start:Raw_end) = []; % Delete unnecessary pary after get template

FirstMessage = boolean(1);

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % Message judgement, Diag PDUs are N-PDU, not I-PDU
    % NM message has no ISignalTriggerring
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag') || startsWith(MsgName,'NMm_')
        continue
    end

    if strcmp(DBC.MessageInfo(i).TxNodes,TargetECU)
        Direction = 'OUT';
    else
        Direction = 'IN';
    end

    if any(strcmp(MsgName,Tx_MsgMixed)) % Need 2 signal groups
        Need2SG = boolean(1);
        SGName = {[Channel '_SG_' MsgName];[Channel '_SG_CGW_' MsgName]};
    else
        Need2SG = boolean(0);
        SGName = {[Channel '_SG_' MsgName]};
    end

    % Modify I signal group triggerring
    for n = 1:length(SGName)
        tmpCell = Template_SG; % re-initialize tmpCell for signal group triggering

        h = find(contains(tmpCell,'<SHORT-NAME>SignalGroupTriggering</SHORT-NAME>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['ST_' char(SGName(n))];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>ST_CAN1_SG_FD_VCU1</SHORT-NAME>

        h = find(contains(tmpCell,'<I-SIGNAL-GROUP-REF DEST="I-SIGNAL-GROUP">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/' Channel '/ISignalGroup/' char(SGName(n))]; % /CAN1/ISignalGroup/CAN1_SG_FD_VCU1
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

        h = find(contains(tmpCell,'<I-SIGNAL-PORT-REF DEST="I-SIGNAL-PORT">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/ECU/' TargetECU '/Conn' Channel '/SP_' char(SGName(n)) '_' Direction]; % /ECU/FUSION/ConnCAN1/SP_CAN1_SG_FD_VCU1_OUT
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

        if FirstMessage % to replace original part
            Raw_start = find(contains(Target_arxml,'<I-SIGNAL-TRIGGERING>'),1,'first');
            Raw_end = find(contains(Target_arxml,'</I-SIGNAL-TRIGGERING>'),1,'first');
            Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
            FirstMessage = boolean(0);
        else % to add new part
            Raw_start = find(contains(Target_arxml,'</I-SIGNAL-TRIGGERING>'),1,'last');
            Raw_end = Raw_start + 1;
            Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        end
    end

    % Modify I signal triggerring.
    for k = 1:length(DBC.MessageInfo(i).Signals)
        tmpCell = Template_Sig; % re-initialize tmpCell for signal triggering
        SignalName = char(DBC.MessageInfo(i).Signals(k));

        h = find(contains(tmpCell,'<SHORT-NAME>SignalTriggering</SHORT-NAME>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['ST_' Channel '_' SignalName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>ST_CAN1_PwrSta</SHORT-NAME>

        h = find(contains(tmpCell,'<I-SIGNAL-PORT-REF DEST="I-SIGNAL-PORT">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/ECU/' TargetECU '/Conn' Channel '/SP_' Channel '_' SignalName '_' Direction];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /ECU/FUSION/ConnCAN1/SP_CAN1_PwrSta_OUT

        h = find(contains(tmpCell,'<I-SIGNAL-REF DEST="I-SIGNAL">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/' Channel '/ISignal/' Channel '_' SignalName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/ISignal/CAN1_PwrSta

        % Update arxml
        Raw_start = find(contains(Target_arxml,'</I-SIGNAL-TRIGGERING>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

%% Modify PDU triggering part
Raw_start = find(contains(Target_arxml,'<PDU-TRIGGERING>'),1,'first');
Raw_end = find(contains(Target_arxml,'</PDU-TRIGGERING>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end); % extract PDU triggering template part

FirstMessage = boolean(1);

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);
    FirstSG = boolean(1);

    % Message judgement, Diag PDUs are N-PDU and have PDU-TRIGGERRING
    if any(strcmp(MsgName,IgnoreFilter))
        continue
    end

    if startsWith(MsgName,'NMm_')
        MsgType = 'NM-PDU';
    elseif startsWith(MsgName,'Diag')
        MsgType = 'N-PDU';
    else
        MsgType = 'I-SIGNAL-I-PDU';
    end

    if strcmp(DBC.MessageInfo(i).TxNodes,TargetECU)
        Direction = 'OUT';
    else
        Direction = 'IN';
    end

    if any(strcmp(MsgName,Tx_MsgMixed)) % Need 2 signal groups
        Need2SG = boolean(1);
        SGName = {[Channel '_SG_' MsgName];[Channel '_SG_CGW_' MsgName]};
    else
        Need2SG = boolean(0);
        SGName = {[Channel '_SG_' MsgName]};
    end

    tmpCell = Template; % re-initialize tmpCell for PDU triggering

    Raw_start = find(contains(tmpCell,'<I-SIGNAL-TRIGGERING-REF-CONDITIONAL>'),1,'first');
    Raw_end = find(contains(tmpCell,'</I-SIGNAL-TRIGGERING-REF-CONDITIONAL>'),1,'first');
    tmpCell2 = tmpCell(Raw_start:Raw_end);

    h = find(contains(tmpCell,'<SHORT-NAME>PDUTriggerings</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['PT_' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>PT_CAN1_FD_VCU1</SHORT-NAME>

    h = find(contains(tmpCell,'<I-PDU-PORT-REF DEST="I-PDU-PORT">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/ECU/' TargetECU '/Conn' Channel '/PP_' Channel '_' MsgName '_' Direction];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /ECU/FUSION/ConnCAN1/PP_CAN1_FD_VCU1_OUT;

    h = find(contains(tmpCell,'<I-PDU-REF DEST="I-SIGNAL-I-PDU">'));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = MsgType;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <PDU-REF DEST="I-SIGNAL-I-PDU">

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/PDU/' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/PDU/CAN1_FD_VCU1

    for n = 1:length(SGName)

        h = find(contains(tmpCell2,'<I-SIGNAL-TRIGGERING-REF DEST="I-SIGNAL-TRIGGERING">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' Channel '/Cluster/' Channel '/' Channel '/ST_' char(SGName(n))];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/Cluster/CAN1/CAN1/ST_CAN1_SG_FD_VCU1

        % Update tmpCell
        if FirstSG % to replace original part
            Raw_start = find(contains(tmpCell,'<I-SIGNAL-TRIGGERING-REF-CONDITIONAL>'),1,'first');
            Raw_end = find(contains(tmpCell,'</I-SIGNAL-TRIGGERING-REF-CONDITIONAL>'),1,'first');
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
            FirstSG = boolean(0);
        else % to add new part
            Raw_start = find(contains(tmpCell,'</I-SIGNAL-TRIGGERING-REF-CONDITIONAL>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    for k = 1:length(DBC.MessageInfo(i).Signals)
        SignalName = char(DBC.MessageInfo(i).Signals(k));

        h = find(contains(tmpCell2,'<I-SIGNAL-TRIGGERING-REF DEST="I-SIGNAL-TRIGGERING">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' Channel '/Cluster/' Channel '/' Channel '/ST_' Channel '_' SignalName];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN3/Cluster/CAN3/CAN3/ST_CAN3_PwrSta

        Raw_start = find(contains(tmpCell,'</I-SIGNAL-TRIGGERING-REF-CONDITIONAL>'),1,'last');
        Raw_end = Raw_start + 1;
        tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
    end

    if strcmp(MsgType,'NM-PDU') || strcmp(MsgType,'N-PDU') % NM-PDU and N-PDU has no ISignal triggering
        Raw_start = find(contains(tmpCell,'<I-SIGNAL-TRIGGERINGS>'),1,'first');
        Raw_end = find(contains(tmpCell,'</I-SIGNAL-TRIGGERINGS>'),1,'first');
        tmpCell(Raw_start:Raw_end) = [];
    end

    % Update arxml
    if FirstMessage % to replace original part
        Raw_start = find(contains(Target_arxml,'<PDU-TRIGGERING>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</PDU-TRIGGERING>'),1,'last');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
        FirstMessage = boolean(0);
    else % to add new part
        Raw_start = find(contains(Target_arxml,'</PDU-TRIGGERING>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end

    % N-PDU has no ISignal triggering and need extra DCM-I-PDU triggerring
    if strcmp(MsgType,'N-PDU')

        tmpCell = Template; % re-initialize tmpCell for PDU triggering

        h = find(contains(tmpCell,'<SHORT-NAME>PDUTriggerings</SHORT-NAME>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['PT_' Channel '_SDU_' MsgName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>PT_CAN4_SDU_DiagRespFromZONE_DR</SHORT-NAME>

        h = find(contains(tmpCell,'<I-PDU-PORT-REF DEST="I-PDU-PORT">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/ECU/' TargetECU '/Conn' Channel '/PP_' Channel '_SDU_' MsgName '_' Direction];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /ECU/ZONE_DR/ConnCAN4/PP_CAN4_SDU_DiagRespFromZONE_DR_OUT;

        h = find(contains(tmpCell,'<I-PDU-REF DEST="I-SIGNAL-I-PDU">'));
        OldString = extractBetween(tmpCell(h),'"','"');
        NewString = 'DCM-I-PDU';
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <PDU-REF DEST="DCM-I-PDU">

        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/' Channel '/PDU/' Channel '_SDU_' MsgName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN4/PDU/CAN4_SDU_DiagRespFromZONE_DR

        Raw_start = find(contains(tmpCell,'<I-SIGNAL-TRIGGERINGS>'),1,'first');
        Raw_end = find(contains(tmpCell,'</I-SIGNAL-TRIGGERINGS>'),1,'first');
        tmpCell(Raw_start:Raw_end) = [];

        % Update arxml
        Raw_start = find(contains(Target_arxml,'</PDU-TRIGGERING>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

% Add NM PDU triggerring
if NM_PDUCnt ~= 0
    for i = 1:2
        tmpCell2 = Template; % re-initialize tmpCell2
        Raw_start = find(contains(tmpCell2,'<I-SIGNAL-TRIGGERINGS>'),1,'first');
        Raw_end = find(contains(tmpCell2,'</I-SIGNAL-TRIGGERINGS>'),1,'first');
        tmpCell2(Raw_start:Raw_end) = [];
    
        if i == 1; Direction = 'TX'; else; Direction = 'RX'; end
        if i == 1; Direction_Port = 'OUT'; else; Direction_Port = 'IN'; end
    
        h = find(contains(tmpCell2,'<SHORT-NAME>PDUTriggerings</SHORT-NAME>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['PT_' Channel '_NMm_' TargetECU '_' Direction];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>PT_CANx_NMm_FDC_TX</SHORT-NAME>
    
        h = find(contains(tmpCell2,'<I-PDU-PORT-REF DEST="I-PDU-PORT">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/ECU/' TargetECU '/Conn' Channel '/PP_' Channel '_NMm_' TargetECU '_' Direction '_' Direction_Port];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /ECU/ZONE_DR/ConnCAN4/PP_CANx_NMm_FDC_TX_OUT
    
        h = find(contains(tmpCell2,'<I-PDU-REF DEST="I-SIGNAL-I-PDU">'));
        OldString = extractBetween(tmpCell2(h),'"','"');
        NewString = 'NM-PDU';
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <I-PDU-REF DEST="NM-PDU">
    
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' Channel '/PDU/' Channel '_NMm_' TargetECU '_' Direction];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CANx/PDU/CANx_NMm_FDC_RX
    
        Raw_start = find(contains(Target_arxml,'</PDU-TRIGGERING>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell2(1:end);Target_arxml(Raw_end:end)];
    end
end

%% Modify signal constant specification
Raw_start = find(contains(Target_arxml,'<CONSTANT-SPECIFICATION>'),1,'first');
Raw_end = find(contains(Target_arxml,'</CONSTANT-SPECIFICATION>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end); % extract constant specification description
FirstMessage = boolean(1);

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % Message judgement, Diag PDUs are N-PDU, not I-PDU
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    for k = 1:length(DBC.MessageInfo(i).Signals)

        tmpCell = Template;
        SignalName = char(DBC.MessageInfo(i).Signals(k));
        Initvalue = DBC.MessageInfo(i).SignalInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(i).SignalInfo(k).Attributes(:,1),'GenSigStartValue')).Value;
        Initvalue = hex2dec(Initvalue); % convert hex to dec for initial value

        % Modify signal initial value part
        h = find(contains(tmpCell,'<SHORT-NAME>SignalInitialValue</SHORT-NAME>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['Init_' Channel '_' SignalName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>Init_CAN1_PwrSta</SHORT-NAME>

        h = find(contains(tmpCell,'<VALUE>0</VALUE>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = num2str(Initvalue);
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <VALUE>0</VALUE>

        if k == 1 && FirstMessage % to replace original part
            Raw_start = find(contains(Target_arxml,'<CONSTANT-SPECIFICATION>'),1,'first');
            Raw_end = find(contains(Target_arxml,'</CONSTANT-SPECIFICATION>'),1,'first');
            Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
            FirstMessage = boolean(0);
        else
            Raw_start = find(contains(Target_arxml,'<CONSTANT-SPECIFICATION>'),1,'last')-1; % Minus 1 here!!
            Raw_end = Raw_start + 1;
            Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        end
    end
end

%% Modify signal group initial value part
Raw_start = find(contains(Target_arxml,'<CONSTANT-SPECIFICATION>'),1,'last');
Raw_end = find(contains(Target_arxml,'</CONSTANT-SPECIFICATION>'),1,'last');
Template = Target_arxml(Raw_start:Raw_end); % extract signal group initial value part
FirstMessage = boolean(1);

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % Message judgement, Diag PDUs are N-PDU, not I-PDU
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    if any(strcmp(MsgName,Tx_MsgMixed)) % Need 2 signal groups
        Need2SG = boolean(1);
        SGName = {[Channel '_SG_' MsgName];[Channel '_SG_CGW_' MsgName]};
    else
        Need2SG = boolean(0);
        SGName = {[Channel '_SG_' MsgName]};
    end

    for n = 1:length(SGName)
        tmpCell = Template;

        h = find(contains(tmpCell,'<SHORT-NAME>SignalGroupInitialValues</SHORT-NAME>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['Init_' char(SGName(n))];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>Init_CAN1_SG_FD_VCU1</SHORT-NAME>

        Raw_start = find(contains(tmpCell,'<CONSTANT-REFERENCE>'),1,'first');
        Raw_end = find(contains(tmpCell,'</CONSTANT-REFERENCE>'),1,'first');
        tmpCell2 = tmpCell(Raw_start:Raw_end);

        FirstSignal = boolean(1);
        for k = 1:length(DBC.MessageInfo(i).Signals)
            SignalName = char(DBC.MessageInfo(i).Signals(k));

            % First SG only contains SWC calculated signals/undefined source signals
            if Need2SG && n == 1 && any(strcmp(SignalName,Tx_SignalGW))
                continue
            elseif Need2SG && n == 2 && ~any(strcmp(SignalName,Tx_SignalGW))
                continue
            end

            h = find(contains(tmpCell2,'<CONSTANT-REF DEST="CONSTANT-SPECIFICATION">'));
            OldString = extractBetween(tmpCell2(h),'>','<');
            NewString = ['/' Channel '/ConstantSpecification/Init_' Channel '_' SignalName];
            tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>Init_CAN1_SG_FD_VCU1</SHORT-NAME>

            if FirstSignal % to replace original part
                Raw_start = find(contains(tmpCell,'<CONSTANT-REFERENCE>'));
                Raw_end = find(contains(tmpCell,'</CONSTANT-REFERENCE>'));
                tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
                FirstSignal = boolean(0);
            else % to add new part
                Raw_start = find(contains(tmpCell,'</CONSTANT-REFERENCE>'),1,'last');
                Raw_end = Raw_start + 1;
                tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
            end
        end

        if FirstMessage
            Raw_start = find(contains(Target_arxml,'<CONSTANT-SPECIFICATION>'),1,'last');
            Raw_end = find(contains(Target_arxml,'</CONSTANT-SPECIFICATION>'),1,'last');
            Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
            FirstMessage = boolean(0);
        else
            Raw_start = find(contains(Target_arxml,'</CONSTANT-SPECIFICATION>'),1,'last');
            Raw_end = Raw_start + 1;
            Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        end
    end
end

%% Modify implementation data type part
Raw_start = find(contains(Target_arxml,'<IMPLEMENTATION-DATA-TYPE>'),1,'first');
Raw_end = find(contains(Target_arxml,'</IMPLEMENTATION-DATA-TYPE>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

Raw_start = find(contains(Target_arxml,'<IMPLEMENTATION-DATA-TYPE-ELEMENT>'),1,'first');
Raw_end = find(contains(Target_arxml,'</IMPLEMENTATION-DATA-TYPE-ELEMENT>'),1,'first');
Template_Element = Target_arxml(Raw_start:Raw_end);

FirstMessage = boolean(1);

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % Message judgement
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    if any(strcmp(MsgName,Tx_MsgMixed)) % Need 2 signal groups
        Need2SG = boolean(1);
        SGName = {[Channel '_SG_' MsgName];[Channel '_SG_CGW_' MsgName]};
    else
        Need2SG = boolean(0);
        SGName = {[Channel '_SG_' MsgName]};
    end

    for n = 1:length(SGName)
        tmpCell = Template;

        h = find(contains(tmpCell,'<SHORT-NAME>SignalGroupDataType</SHORT-NAME>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['DT_' char(SGName(n))];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>DT_CAN1_SG_FD_VCU1</SHORT-NAME>

        FirstSignal = boolean(1);
        for k = 1:length(DBC.MessageInfo(i).Signals)
            tmpCell2 = Template_Element;
            SignalName = char(DBC.MessageInfo(i).Signals(k));
            SignalLength = DBC.MessageInfo(i).SignalInfo(k).SignalSize;

            % First SG only contains SWC calculated signals/undefined source signals
            if Need2SG && n == 1 && any(strcmp(SignalName,Tx_SignalGW))
                continue
            elseif Need2SG && n == 2 && ~any(strcmp(SignalName,Tx_SignalGW))
                continue
            end

            % determine signal base and implementation data type
            if rem(SignalLength,8) == 0 && SignalLength <= 16
                SignalType = ['uint' num2str(SignalLength)];
            elseif floor(SignalLength/8) <= 1
                SignalType = ['uint' num2str(8*(floor(SignalLength/8)+1))]; % uint8 or uint16
            elseif floor(SignalLength/8) <= 4
                SignalType = 'uint32';
            else
                SignalType = 'uint64';
            end

            h = find(contains(tmpCell2,'<SHORT-NAME>SignalsInSignalGroup</SHORT-NAME>'));
            OldString = extractBetween(tmpCell2(h),'>','<');
            NewString = [Channel '_' SignalName];
            tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>CAN1_PwrSta</SHORT-NAME>

            h = find(contains(tmpCell2,'<IMPLEMENTATION-DATA-TYPE-REF DEST="IMPLEMENTATION-DATA-TYPE">'));
            OldString = extractBetween(tmpCell2(h),'>','<');
            NewString = ['/AUTOSAR_Platform/ImplementationDataTypes/' SignalType];
            tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>CAN1_PwrSta</SHORT-NAME>

            if FirstSignal % to replace original part
                Raw_start = find(contains(tmpCell,'<IMPLEMENTATION-DATA-TYPE-ELEMENT>'),1,'first');
                Raw_end = find(contains(tmpCell,'</IMPLEMENTATION-DATA-TYPE-ELEMENT>'),1,'first');
                tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
                FirstSignal = boolean(0);
            else % to add new part
                Raw_start = find(contains(tmpCell,'</IMPLEMENTATION-DATA-TYPE-ELEMENT>'),1,'last');
                Raw_end = Raw_start + 1;
                tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
            end
        end

        if FirstMessage
            Raw_start = find(contains(Target_arxml,'<IMPLEMENTATION-DATA-TYPE>'),1,'first');
            Raw_end = find(contains(Target_arxml,'</IMPLEMENTATION-DATA-TYPE>'),1,'first');
            Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
            FirstMessage = boolean(0);
        else
            Raw_start = find(contains(Target_arxml,'</IMPLEMENTATION-DATA-TYPE>'),1,'last');
            Raw_end = Raw_start + 1;
            Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        end
    end
end

%% Define BUS type

BUSType = DBC.AttributeInfo(find(strcmp(DBC.Attributes,'BusType'))).Value;
if strcmp(BUSType,'CAN')
    Target_arxml(contains(Target_arxml,'<CAN-FD-BAUDRATE>2000</CAN-FD-BAUDRATE>')) = [];
end

%% Delete DCM description
if any(find(contains(Target_arxml,'<DCM-I-PDU>')))
    Raw_start = find(contains(Target_arxml,'<DCM-I-PDU>'),1,'first');
    Raw_end = find(contains(Target_arxml,'</DCM-I-PDU>'),1,'last');
    Target_arxml(Raw_start:Raw_end) = [];
end

if any(find(contains(Target_arxml,'<I-PDU-REF DEST="DCM-I-PDU">')))
    h = find(contains(Target_arxml,'<I-PDU-REF DEST="DCM-I-PDU">'));
    for i = 1:length(h)
        Raw_start = find(contains(Target_arxml,'<I-PDU-REF DEST="DCM-I-PDU">'),1,'first') - 5;
        Raw_end = Raw_start + 6;
        Target_arxml(Raw_start:Raw_end) = [];
    end
end

%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen([Channel '.arxml'],'w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);


end