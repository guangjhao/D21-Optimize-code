function Gen_CANSettings(DBC,Channel,MsgLinkFileName,TargetECU,RoutingTable)
project_path = pwd;
ScriptVersion = '2024.01.23';

%% Read messageLink
cd([project_path '/documents/MessageLink']);
MessageLink_Rx = readcell(MsgLinkFileName,'Sheet','InputSignal');
MessageLink_Tx = readcell(MsgLinkFileName,'Sheet','OutputSignal');

%% Get APP related messages
tmpCell = MessageLink_Rx(strcmp(MessageLink_Rx(:,strcmp(MessageLink_Rx(1,:),'CANChannel')),Channel),strcmp(MessageLink_Rx(1,:),'MessageName'));
Rx_MsgLink = categories(categorical(tmpCell));

tmpCell = MessageLink_Tx(2:end,strcmp(MessageLink_Tx(1,:),Channel));
tmpCell(cellfun(@(x) all(ismissing(x)), tmpCell)) = [];
Tx_MsgLink = categories(categorical(tmpCell));

%% Get Tx frame routing messages
if strcmp(Channel,'CANDr1')
    Raw_start = find(contains(RoutingTable(:,4),'distributed messages, target:CAN_Dr1')) + 2;
else
    Raw_start = find(contains(RoutingTable(:,4),['distributed messages, target:' Channel])) + 2;
end
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
if strcmp(Channel,'CANDr1')
    Raw_start = find(contains(RoutingTable(:,4),'distributed messages, target:CAN_Dr1')) + 2;
else
    Raw_start = find(contains(RoutingTable(:,4),['distributed messages, target:' Channel])) + 2;
end
tmpCell = {};
cnt = 0;
for i = 1:length(Raw_start)
    Raw_end = Raw_start(i) + find(contains(RoutingTable(Raw_start(i):end,4),'distributed messages, target'),1,'first') - 2;
    if isempty(Raw_end); Raw_end = length(RoutingTable(:,1));end

    for k = Raw_start(i):Raw_end
        if ~strcmp(RoutingTable(k,4),'Invalid')
            cnt = cnt + 1;
            tmpCell(cnt,1) = RoutingTable(k,5);
        else
            continue
        end
    end
end
tmpCell = categories(categorical(tmpCell));
tmpCell(contains(tmpCell,'Invalid')) = [];
Tx_MsgSignalGW = tmpCell;

%% Get Rx frame routing messages
if strcmp(Channel,'CANDr1')
    Raw_start = find(contains(RoutingTable(:,1),'requested signals, source:CAN_Dr1')) + 2;
else
    Raw_start = find(contains(RoutingTable(:,1),['requested signals, source:' Channel])) + 2;
end
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
if strcmp(Channel,'CANDr1')
    Raw_start = find(contains(RoutingTable(:,1),'requested signals, source:CAN_Dr1')) + 2;
else
    Raw_start = find(contains(RoutingTable(:,1),['requested signals, source:' Channel])) + 2;
end
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
% get APPInterface_Template
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

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);
    tmpCell = Template; % initialize tmpCell

    % Message judgement, ignore PDUs that should not exist in arxml
    if any(strcmp(MsgName,IgnoreFilter))
        continue
    end

    if startsWith(MsgName,'NMm_')
        MsgType = 'NM-PDU';
    elseif startsWith(MsgName,'Diag')
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

%% Modify PDU description
NM_PDUCnt = 0;
N_PDUCnt = 0;

% Edit I-SIGNAL-I-PDU part
Raw_start = find(contains(Target_arxml,'<I-SIGNAL-I-PDU>'),1,'first'); % <I-SIGNAL-I-PDU>
Raw_end = Raw_start + find(contains(Target_arxml(Raw_start:end),'</I-SIGNAL-I-PDU>'),1,'first') - 1; % </I-SIGNAL-I-PDU>
Template = Target_arxml(Raw_start:Raw_end); % extract IPDU part
FirstIPDU = boolean(1);
for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);
    tmpCell = Template;

    % Message judgement, Diag PDUs are N-PDU, not I-PDU
    % Workaround: XNM messages are I PDU
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    CycleTime = DBC.MessageInfo(i).AttributeInfo(strcmp(DBC.MessageInfo(i).Attributes(:,1),'GenMsgCycleTime')).Value;
    FRAMELENGTH = num2str(DBC.MessageInfo(i).Length);
    MsgSendType = DBC.MessageInfo(i).AttributeInfo(strcmp(DBC.MessageInfo(i).Attributes(:,1),'GenMsgSendType')).Value;
    
    % FOXTRON does not use this attribute
%     NumberOfRepetition = DBC.MessageInfo(i).AttributeInfo(strcmp(DBC.MessageInfo(i).Attributes(:,1),'GenMsgNrOfRepetition')).Value;
    RepetitionPeriod = DBC.MessageInfo(i).AttributeInfo(strcmp(DBC.MessageInfo(i).Attributes(:,1),'GenMsgCycleTimeFast')).Value;

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

    h = find(contains(tmpCell,'<NUMBER-OF-REPETITIONS>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = '0'; % FOXTRON does not use this attribute
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <NUMBER-OF-REPETITIONS>1</NUMBER-OF-REPETITIONS>

    h = find(contains(tmpCell,'<REPETITION-PERIOD>')) + 1;
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = num2str(RepetitionPeriod/1000);
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <VALUE>0.01</VALUE>

    h = find(contains(tmpCell,'<SHORT-NAME>SignalGroup</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [Channel '_SG_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN3_SG_BMS1</SHORT-NAME>

    h = find(contains(tmpCell,'<I-SIGNAL-GROUP-REF DEST="I-SIGNAL-GROUP">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/ISignalGroup/' Channel '_SG_' MsgName]; % /CAN3/ISignalGroup/CAN3_SG_BMS1
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <I-SIGNAL-GROUP-REF DEST="I-SIGNAL-GROUP">/CAN3/ISignalGroup/CAN3_SG_BMS1</I-SIGNAL-GROUP-REF>

    h = find(contains(tmpCell,'<TRANSFER-PROPERTY>SignalGroupTransfer</TRANSFER-PROPERTY>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = TransferProperty_SG;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <TRANSFER-PROPERTY>PENDING</TRANSFER-PROPERTY>

    % Delete cyclic timing description for event message
    if strcmp(TransferProperty_SG,'TRIGGERED')
        Raw_start = find(contains(tmpCell,'<CYCLIC-TIMING>'));
        Raw_end = find(contains(tmpCell,'</CYCLIC-TIMING>'));
        tmpCell(Raw_start:Raw_end) = [];
    end

    % extract I-SIGNAL-TO-I-PDU-MAPPING part to fill out all message signals
    Raw_start = find(contains(tmpCell,'<SHORT-NAME>Signals</SHORT-NAME>'))-1; % <I-SIGNAL-TO-I-PDU-MAPPING>
    Raw_end = find(contains(tmpCell,'</I-SIGNAL-TO-I-PDU-MAPPING>'),1,'last'); % </I-SIGNAL-TO-I-PDU-MAPPING>
    tmpCell2 = tmpCell(Raw_start:Raw_end);

    for k = 1:length(DBC.MessageInfo(i).Signals)
        SignalSendType = DBC.MessageInfo(i).SignalInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(i).SignalInfo(k).Attributes(:,1),'GenSigSendType')).Value;
        SignalName = char(DBC.MessageInfo(i).Signals(k));
        Startbit = DBC.MessageInfo(i).SignalInfo(k).StartBit;
        SignalLength = DBC.MessageInfo(i).SignalInfo(k).SignalSize;

        % convert start bit to Motorola backward format
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

        h = find(contains(tmpCell2,'<SHORT-NAME>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = [Channel '_' SignalName];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>CAN3_PwrSta</SHORT-NAME>

        h = find(contains(tmpCell2,'<I-SIGNAL-REF DEST="I-SIGNAL">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' Channel '/ISignal/' Channel '_' SignalName]; % /CAN3/ISignal/CAN3_PwrSta
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <I-SIGNAL-REF DEST="I-SIGNAL">/CAN3/ISignal/CAN3_PwrSta</I-SIGNAL-REF>

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
        elseif strcmp(SignalSendType,'OnWrite')
            TransferProperty_Signal = 'TRIGGERED';
        else
            error(['The signal "' SignalName '"' 'in ' Channel '_' MsgName ' GenSigSendType unrecognize'])
        end
        tmpCell2(h) = strrep(tmpCell2(h),OldString,TransferProperty_Signal); % <TRANSFER-PROPERTY>PENDING</TRANSFER-PROPERTY>

        if k == 1 % to repkase original part
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

% Edit N-PDU part
Raw_start = find(contains(Target_arxml,'<N-PDU>'),1,'first'); % <N-PDU>
Raw_end = Raw_start + find(contains(Target_arxml(Raw_start:end),'</N-PDU>'),1,'first') - 1;
Template = Target_arxml(Raw_start:Raw_end); % extract N-PDU part
FirstNPDU = boolean(1);
for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);
    tmpCell = Template;

    % Message judgement, only Diag PDUs are N-PDU
    if any(strcmp(MsgName,IgnoreFilter)) || ~startsWith(MsgName,'Diag')
        continue
    end

    N_PDUCnt = N_PDUCnt + 1;
    FRAMELENGTH = num2str(DBC.MessageInfo(i).Length);

    h = find(contains(tmpCell,'<SHORT-NAME>NPDUName</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN3_DiagRespFromShifter</SHORT-NAME>

    h = find(contains(tmpCell,'<LENGTH>8</LENGTH>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = FRAMELENGTH;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <LENGTH>8</LENGTH>

    if FirstNPDU
        Raw_start = find(contains(Target_arxml,'<N-PDU>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</N-PDU>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
        FirstNPDU = boolean(0);
    else
        Raw_start = find(contains(Target_arxml,'</N-PDU>'),1,'last');
        Raw_end = Raw_start +1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

% Edit NM-PDU part


% delete NM-PDU part if no NM-PDU exist
if NM_PDUCnt == 0
    Raw_start = find(contains(Target_arxml,'<NM-PDU>'),1,'first'); % find the first <NM-PDU>
    Raw_end = find(contains(Target_arxml,'</NM-PDU>'),1,'last'); % find the last </NM-PDU>;
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
    % Workaround: XNM messages are I PDU
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
    % Workaround: XNM messages are I PDU
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    tmpCell = Template;

    h = find(contains(tmpCell,'<SHORT-NAME>TargetSignalGroup</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [Channel '_SG_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN3_SG_BMS1</SHORT-NAME>

    h = find(contains(tmpCell,'<SYSTEM-SIGNAL-GROUP-REF DEST="SYSTEM-SIGNAL-GROUP">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/SignalGroup/' Channel '_SG_' MsgName]; % /CAN3/SignalGroup/CAN3_SG_BMS1
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SYSTEM-SIGNAL-GROUP-REF DEST="SYSTEM-SIGNAL-GROUP">/CAN3/SignalGroup/SG_FD_VCU1</SYSTEM-SIGNAL-GROUP-REF>

    h = find(contains(tmpCell,'<I-SIGNAL-REF DEST="I-SIGNAL">'),1,'first');
    tmpCell2 = tmpCell(h); % extract signal group reference part

    for k = 1:length(DBC.MessageInfo(i).Signals)
        SignalName = char(DBC.MessageInfo(i).Signals(k));

        h = find(contains(tmpCell2,'<I-SIGNAL-REF DEST="I-SIGNAL">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' Channel '/ISignal/' Channel '_' SignalName];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <I-SIGNAL-REF DEST="I-SIGNAL">/CAN1/ISignal/CAN1_PwrSta</I-SIGNAL-REF>

        if k == 1 % to replace original part
            tmpCell(contains(tmpCell,'<I-SIGNAL-REF DEST="I-SIGNAL">')) = tmpCell2(h);
        else % to add new part
            Raw_start = find(contains(tmpCell,'<I-SIGNAL-REF DEST="I-SIGNAL">'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    if FirstMessage % to replace original part
        Raw_start = find(contains(Target_arxml,'<I-SIGNAL-GROUP>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</I-SIGNAL-GROUP>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
    else % to add new part
        Raw_start = find(contains(Target_arxml,'</I-SIGNAL-GROUP>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end

    FirstMessage = boolean(0);
end

%% Modify system signal
FirstMessage = boolean(1);
Raw_start = find(contains(Target_arxml,'<SYSTEM-SIGNAL>'));
Raw_end = find(contains(Target_arxml,'</SYSTEM-SIGNAL>'));
tmpCell = Target_arxml(Raw_start:Raw_end); % extract ISignal frame part

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % Message judgement, Diag PDUs are N-PDU, not I-PDU
    % Workaround: XNM messages are I PDU
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    for k = 1:length(DBC.MessageInfo(i).Signals)
        SignalName = char(DBC.MessageInfo(i).Signals(k));

        h = find(contains(tmpCell,'<SHORT-NAME>'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = [Channel '_' SignalName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN1_PwrSta</SHORT-NAME>

        if FirstMessage && k == 1 % to replace original part
            Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
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
    % Workaround: XNM messages are I PDU
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    tmpCell = Template;

    h = find(contains(tmpCell,'<SHORT-NAME>TargetSystemSignalGroup</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [Channel '_SG_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN3_SG_BMS1</SHORT-NAME>

    h = find(contains(tmpCell,'<SYSTEM-SIGNAL-REF DEST="SYSTEM-SIGNAL">'),1,'first');
    tmpCell2 = tmpCell(h); % extract signal group reference part

    for k = 1:length(DBC.MessageInfo(i).Signals)
        SignalName = char(DBC.MessageInfo(i).Signals(k));

        h = find(contains(tmpCell2,'<SYSTEM-SIGNAL-REF DEST="SYSTEM-SIGNAL">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' Channel '/Signal/' Channel '_' SignalName];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <I-SIGNAL-REF DEST="I-SIGNAL">/CAN1/ISignal/CAN1_PwrSta</I-SIGNAL-REF>

        if k == 1 % to replace original part
            tmpCell(contains(tmpCell,'<SYSTEM-SIGNAL-REF DEST="SYSTEM-SIGNAL">')) = tmpCell2(h);
        else % to add new part
            Raw_start = find(contains(tmpCell,'<SYSTEM-SIGNAL-REF DEST="SYSTEM-SIGNAL">'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    if FirstMessage % to replace original part
        Raw_start = find(contains(Target_arxml,'<SYSTEM-SIGNAL-GROUP>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</SYSTEM-SIGNAL-GROUP>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
    else % to add new part
        Raw_start = find(contains(Target_arxml,'</SYSTEM-SIGNAL-GROUP>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end

    FirstMessage = boolean(0);
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
Raw_start = find(contains(Target_arxml,'<CAN-CLUSTER>'));
Raw_end = find(contains(Target_arxml,'</CAN-CLUSTER>'));
tmpCell = Target_arxml(Raw_start:Raw_end); % extract cluster description

h = find(contains(tmpCell,'<SHORT-NAME>CANChannel</SHORT-NAME>'));
OldString = extractBetween(tmpCell(h),'>','<');
NewString = Channel;
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN1</SHORT-NAME>

h = find(contains(tmpCell,'<SHORT-NAME>PhysicalChannel</SHORT-NAME>'));
OldString = extractBetween(tmpCell(h),'>','<');
NewString = Channel;
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN1</SHORT-NAME>

h = find(contains(tmpCell,'<COMMUNICATION-CONNECTOR-REF DEST="CAN-COMMUNICATION-CONNECTOR">'));
OldString = extractBetween(tmpCell(h),'>','<');
NewString = ['/ECU/' TargetECU '/Conn' Channel];
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /ECU/FUSION/ConnCAN3

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

    tmpCell2 = Template; % re-initialize tmpCell2

    h = find(contains(tmpCell2,'<SHORT-NAME>FrameTriggering</SHORT-NAME>'));
    OldString = extractBetween(tmpCell2(h),'>','<');
    NewString = ['FT_' Channel '_' MsgName];
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>FT_CAN1_FD_VCU1</SHORT-NAME>

    h = find(contains(tmpCell2,'<FRAME-PORT-REF DEST="FRAME-PORT">'));
    OldString = extractBetween(tmpCell2(h),'>','<');
    NewString = ['/ECU/' TargetECU '/Conn' Channel '/FP_' Channel '_' MsgName '_' Direction];
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /ECU/FUSION/ConnCAN1/FP_CAN1_FD_VCU1_OUT

    h = find(contains(tmpCell2,'<FRAME-REF DEST="CAN-FRAME">'));
    OldString = extractBetween(tmpCell2(h),'>','<');
    NewString = ['/' Channel '/Frame/' Channel '_' MsgName];
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/Frame/CAN1_FD_VCU1

    h = find(contains(tmpCell2,'<PDU-TRIGGERING-REF DEST="PDU-TRIGGERING">'));
    OldString = extractBetween(tmpCell2(h),'>','<');
    NewString = ['/' Channel '/Cluster/' Channel '/' Channel '/PT_' Channel '_' MsgName];
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN3/Cluster/CAN3/CAN3/PT_CAN3_FD_VCU1

    if strcmp(CANMode,'CAN FD')
        h = find(contains(tmpCell2,'<CAN-FD-FRAME-SUPPORT>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = 'true';
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <CAN-FD-FRAME-SUPPORT>true</CAN-FD-FRAME-SUPPORT>

        h = find(contains(tmpCell2,'<CAN-FRAME-RX-BEHAVIOR>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = 'CAN-FD';
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <CAN-FRAME-RX-BEHAVIOR>CAN-FD</CAN-FRAME-RX-BEHAVIOR>

        h = find(contains(tmpCell2,'<CAN-FRAME-TX-BEHAVIOR>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = 'CAN-FD';
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <CAN-FRAME-TX-BEHAVIOR>CAN-FD</CAN-FRAME-TX-BEHAVIOR>

    else
        h = find(contains(tmpCell2,'<CAN-FD-FRAME-SUPPORT>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = 'false';
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <CAN-FD-FRAME-SUPPORT>false</CAN-FD-FRAME-SUPPORT>

        h = find(contains(tmpCell2,'<CAN-FRAME-RX-BEHAVIOR>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = 'CAN-20';
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <CAN-FRAME-RX-BEHAVIOR>CAN-20</CAN-FRAME-RX-BEHAVIOR>

        h = find(contains(tmpCell2,'<CAN-FRAME-TX-BEHAVIOR>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = 'CAN-20';
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <CAN-FRAME-TX-BEHAVIOR>CAN-20</CAN-FRAME-TX-BEHAVIOR>
    end

    h = find(contains(tmpCell2,'<IDENTIFIER>'));
    OldString = extractBetween(tmpCell2(h),'>','<');
    NewString = num2str(MessageID);
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <IDENTIFIER>278</IDENTIFIER>

    if startsWith(MsgName,'NMm_') || startsWith(MsgName,'Diag')
        Raw_start = find(contains(tmpCell2,'<PDU-TRIGGERINGS>'),1,'first');
        Raw_end = find(contains(tmpCell2,'</PDU-TRIGGERINGS>'),1,'first');
        tmpCell2(Raw_start:Raw_end) = [];
    end

    if FirstMessage % to replace original part
        Raw_start = find(contains(tmpCell,'<CAN-FRAME-TRIGGERING>'),1,'first');
        Raw_end = find(contains(tmpCell,'</CAN-FRAME-TRIGGERING>'),1,'first');
        tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
    else % to add new part
        Raw_start = find(contains(tmpCell,'</CAN-FRAME-TRIGGERING>'),1,'last');
        Raw_end = Raw_start + 1;
        tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
    end

    FirstMessage = boolean(0);
end

% Modify ISignal triggering part
Raw_start = find(contains(tmpCell,'<I-SIGNAL-TRIGGERING>'),1,'first');
Raw_end = find(contains(tmpCell,'</I-SIGNAL-TRIGGERING>'),1,'last');
Template = tmpCell(Raw_start:Raw_end); % extract ISignal triggering template part, contains signal group triggering and signal triggering

FirstMessage = boolean(1);

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % Message judgement, Diag PDUs are N-PDU, not I-PDU
    % Workaround: XNM messages are I PDU
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    if strcmp(DBC.MessageInfo(i).TxNodes,TargetECU)
        Direction = 'OUT';
    else
        Direction = 'IN';
    end

    tmpCell2 = Template; % re-initialize tmpCell2 for signal group triggering

    if startsWith(MsgName,'NMm_')
        Raw_start = find(contains(tmpCell2,'<I-SIGNAL-TRIGGERING>'),1,'first');
        Raw_end = find(contains(tmpCell2,'</I-SIGNAL-TRIGGERING>'),1,'first');
        tmpCell2(Raw_start:Raw_end) = [];
    else

        h = find(contains(tmpCell2,'<SHORT-NAME>SignalGroupTriggering</SHORT-NAME>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['ST_' Channel '_SG_' MsgName];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>ST_CAN1_SG_FD_VCU1</SHORT-NAME>

        h = find(contains(tmpCell2,'<I-SIGNAL-GROUP-REF DEST="I-SIGNAL-GROUP">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' Channel '/ISignalGroup/' Channel '_SG_' MsgName]; % /CAN1/ISignalGroup/CAN1_SG_FD_VCU1
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString);

        h = find(contains(tmpCell2,'<I-SIGNAL-PORT-REF DEST="I-SIGNAL-PORT">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/ECU/' TargetECU '/Conn' Channel '/SP_' Channel '_SG_' MsgName '_' Direction]; % /ECU/FUSION/ConnCAN1/SP_CAN1_SG_FD_VCU1_OUT
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString);
    end

    for k = 1:length(DBC.MessageInfo(i).Signals)

        Raw_start = find(contains(Template,'<I-SIGNAL-TRIGGERING>'),1,'last');
        Raw_end = find(contains(Template,'</I-SIGNAL-TRIGGERING>'),1,'last');
        tmpCell3 = Template(Raw_start:Raw_end);% re-initialize tmpCell3 for signal triggering
        SignalName = char(DBC.MessageInfo(i).Signals(k));

        h = find(contains(tmpCell3,'<SHORT-NAME>SignalTriggering</SHORT-NAME>'));
        OldString = extractBetween(tmpCell3(h),'>','<');
        NewString = ['ST_' Channel '_' SignalName];
        tmpCell3(h) = strrep(tmpCell3(h),OldString,NewString); % <SHORT-NAME>ST_CAN1_PwrSta</SHORT-NAME>

        h = find(contains(tmpCell3,'<I-SIGNAL-PORT-REF DEST="I-SIGNAL-PORT">'));
        OldString = extractBetween(tmpCell3(h),'>','<');
        NewString = ['/ECU/' TargetECU '/Conn' Channel '/SP_' Channel '_' SignalName '_' Direction];
        tmpCell3(h) = strrep(tmpCell3(h),OldString,NewString); % /ECU/FUSION/ConnCAN1/SP_CAN1_PwrSta_OUT

        h = find(contains(tmpCell3,'<I-SIGNAL-REF DEST="I-SIGNAL">'));
        OldString = extractBetween(tmpCell3(h),'>','<');
        NewString = ['/' Channel '/ISignal/' Channel '_' SignalName];
        tmpCell3(h) = strrep(tmpCell3(h),OldString,NewString); % /CAN1/ISignal/CAN1_PwrSta

        if k == 1 % to replace original part
            Raw_start = find(contains(tmpCell2,'<I-SIGNAL-TRIGGERING>'),1,'last');
            Raw_end = find(contains(tmpCell2,'</I-SIGNAL-TRIGGERING>'),1,'last');
            tmpCell2 = [tmpCell2(1:Raw_start-1);tmpCell3(1:end);tmpCell2(Raw_end+1:end)];
        else
            Raw_start = find(contains(tmpCell2,'</I-SIGNAL-TRIGGERING>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell2 = [tmpCell2(1:Raw_start);tmpCell3(1:end);tmpCell2(Raw_end:end)];
        end
    end

    if FirstMessage % to replace original part
        Raw_start = find(contains(tmpCell,'<I-SIGNAL-TRIGGERING>'),1,'first');
        Raw_end = find(contains(tmpCell,'</I-SIGNAL-TRIGGERING>'),1,'last');
        tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
    else % to add new part
        Raw_start = find(contains(tmpCell,'</I-SIGNAL-TRIGGERING>'),1,'last');
        Raw_end = Raw_start + 1;
        tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
    end
    FirstMessage = boolean(0);
end

% Modify PDU triggering part
Raw_start = find(contains(tmpCell,'<PDU-TRIGGERING>'),1,'first');
Raw_end = find(contains(tmpCell,'</PDU-TRIGGERING>'),1,'last');
Template = tmpCell(Raw_start:Raw_end); % extract PDU triggering template part

FirstMessage = boolean(1);

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

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

    tmpCell2 = Template; % re-initialize tmpCell2 for PDU triggering

    Raw_start = find(contains(tmpCell2,'<I-SIGNAL-TRIGGERING-REF-CONDITIONAL>'),1,'first');
    Raw_end = find(contains(tmpCell2,'</I-SIGNAL-TRIGGERING-REF-CONDITIONAL>'),1,'first');
    tmpCell3 = tmpCell2(Raw_start:Raw_end);

    h = find(contains(tmpCell2,'<SHORT-NAME>PDUTriggerings</SHORT-NAME>'));
    OldString = extractBetween(tmpCell2(h),'>','<');
    NewString = ['PT_' Channel '_' MsgName];
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>PT_CAN1_FD_VCU1</SHORT-NAME>

    h = find(contains(tmpCell2,'<I-PDU-PORT-REF DEST="I-PDU-PORT">'));
    OldString = extractBetween(tmpCell2(h),'>','<');
    NewString = ['/ECU/' TargetECU '/Conn' Channel '/PP_' Channel '_' MsgName '_' Direction];
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /ECU/FUSION/ConnCAN1/PP_CAN1_FD_VCU1_OUT;

    h = find(contains(tmpCell2,'<I-PDU-REF DEST="I-SIGNAL-I-PDU">'));
    OldString = extractBetween(tmpCell2(h),'"','"');
    NewString = MsgType;
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <PDU-REF DEST="I-SIGNAL-I-PDU">

    OldString = extractBetween(tmpCell2(h),'>','<');
    NewString = ['/' Channel '/PDU/' Channel '_' MsgName];
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/PDU/CAN1_FD_VCU1

    h = find(contains(tmpCell2,'<I-SIGNAL-TRIGGERING-REF DEST="I-SIGNAL-TRIGGERING">'));
    OldString = extractBetween(tmpCell2(h),'>','<');
    NewString = ['/' Channel '/Cluster/' Channel '/' Channel '/ST_' Channel '_SG_' MsgName];
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/Cluster/CAN1/CAN1/ST_CAN1_SG_FD_VCU1

    for k = 1:length(DBC.MessageInfo(i).Signals)
        SignalName = char(DBC.MessageInfo(i).Signals(k));

        h = find(contains(tmpCell3,'<I-SIGNAL-TRIGGERING-REF DEST="I-SIGNAL-TRIGGERING">'));
        OldString = extractBetween(tmpCell3(h),'>','<');
        NewString = ['/' Channel '/Cluster/' Channel '/' Channel '/ST_' Channel '_' SignalName];
        tmpCell3(h) = strrep(tmpCell3(h),OldString,NewString); % /CAN3/Cluster/CAN3/CAN3/ST_CAN3_PwrSta

        Raw_start = find(contains(tmpCell2,'</I-SIGNAL-TRIGGERING-REF-CONDITIONAL>'),1,'last');
        Raw_end = Raw_start + 1;
        tmpCell2 = [tmpCell2(1:Raw_start);tmpCell3(1:end);tmpCell2(Raw_end:end)];
    end

    if strcmp(MsgType,'NM-PDU') || strcmp(MsgType,'N-PDU') % NM-PDU has no ISignal triggering
        Raw_start = find(contains(tmpCell2,'<I-SIGNAL-TRIGGERINGS>'),1,'first');
        Raw_end = find(contains(tmpCell2,'</I-SIGNAL-TRIGGERINGS>'),1,'first');
        tmpCell2(Raw_start:Raw_end) = [];
    end

    if FirstMessage % to replace original part
        Raw_start = find(contains(tmpCell,'<PDU-TRIGGERING>'),1,'first');
        Raw_end = find(contains(tmpCell,'</PDU-TRIGGERING>'),1,'last');
        tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
    else % to add new part
        Raw_start = find(contains(tmpCell,'</PDU-TRIGGERING>'),1,'last');
        Raw_end = Raw_start + 1;
        tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
    end
    FirstMessage = boolean(0);
end
Raw_start = find(contains(Target_arxml,'<CAN-CLUSTER>'));
Raw_end = find(contains(Target_arxml,'</CAN-CLUSTER>'));
Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];

%% Modify constant specification
Raw_start = find(contains(Target_arxml,'<CONSTANT-SPECIFICATION>'),1,'first');
Raw_end = find(contains(Target_arxml,'</CONSTANT-SPECIFICATION>'),1,'last');
Template = Target_arxml(Raw_start:Raw_end); % extract constant specification description
tmpCell = Template;
FirstMessage = boolean(1);

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % Message judgement, Diag PDUs are N-PDU, not I-PDU
    % Workaround: XNM messages are I PDU
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    for k = 1:length(DBC.MessageInfo(i).Signals)

        Raw_start = find(contains(Template,'<CONSTANT-SPECIFICATION>'),1,'first');
        Raw_end = find(contains(Template,'</CONSTANT-SPECIFICATION>'),1,'first');
        tmpCell2 = Template(Raw_start:Raw_end); % extract signal initial value part

        SignalName = char(DBC.MessageInfo(i).Signals(k));
        Initvalue = DBC.MessageInfo(i).SignalInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(i).SignalInfo(k).Attributes(:,1),'GenSigStartValue')).Value;
        Initvalue = hex2dec(Initvalue); % convert hex to dec for initial value

        % Modify signal initial value part
        h = find(contains(tmpCell2,'<SHORT-NAME>SignalInitialValue</SHORT-NAME>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['Init_' Channel '_' SignalName];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>Init_CAN1_PwrSta</SHORT-NAME>

        h = find(contains(tmpCell2,'<VALUE>0</VALUE>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = num2str(Initvalue);
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <VALUE>0</VALUE>

        if k == 1 && FirstMessage % to replace original part
            Raw_end = find(contains(tmpCell,'</CONSTANT-SPECIFICATION>'),1,'first');
            tmpCell = [tmpCell2(1:end);tmpCell(Raw_end+1:end)]; % tmpCell and tmpCell2 has the same Raw_start here!!
        elseif k > 1 && FirstMessage % to insert new part
            Raw_start = find(contains(tmpCell,'<CONSTANT-SPECIFICATION>'),1,'last')-1; % Minus 1 here!!
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        else
            Raw_start = find(contains(tmpCell,'</CONSTANT-SPECIFICATION>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    % Modify signal group initial value part
    Raw_start = find(contains(Template,'</CONSTANT-SPECIFICATION>'),1,'first')+1;
    Raw_end = find(contains(Template,'</CONSTANT-SPECIFICATION>'),1,'last');
    tmpCell2 = Template(Raw_start:Raw_end); % extract signal group initial value part

    h = find(contains(tmpCell2,'<SHORT-NAME>SignalGroupInitialValues</SHORT-NAME>'));
    OldString = extractBetween(tmpCell2(h),'>','<');
    NewString = ['Init_' Channel '_SG_' MsgName];
    tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>Init_CAN1_SG_FD_VCU1</SHORT-NAME>

    Raw_start = find(contains(tmpCell2,'<CONSTANT-REFERENCE>'),1,'first');
    Raw_end = find(contains(tmpCell2,'</CONSTANT-REFERENCE>'),1,'last');
    tmpCell3 = tmpCell2(Raw_start:Raw_end);

    for k = 1:length(DBC.MessageInfo(i).Signals)

        SignalName = char(DBC.MessageInfo(i).Signals(k));

        h = find(contains(tmpCell3,'<CONSTANT-REF DEST="CONSTANT-SPECIFICATION">'));
        OldString = extractBetween(tmpCell3(h),'>','<');
        NewString = ['/' Channel '/ConstantSpecification/Init_' Channel '_' SignalName];
        tmpCell3(h) = strrep(tmpCell3(h),OldString,NewString); % <SHORT-NAME>Init_CAN1_SG_FD_VCU1</SHORT-NAME>

        if k == 1 % to replace original part
            Raw_start = find(contains(tmpCell2,'<CONSTANT-REFERENCE>'));
            Raw_end = find(contains(tmpCell2,'</CONSTANT-REFERENCE>'));
            tmpCell2 = [tmpCell2(1:Raw_start-1);tmpCell3(1:end);tmpCell2(Raw_end+1:end)];
        else % to add new part
            Raw_start = find(contains(tmpCell2,'</CONSTANT-REFERENCE>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell2 = [tmpCell2(1:Raw_start);tmpCell3(1:end);tmpCell2(Raw_end:end)];
        end
    end

    if FirstMessage
        Raw_start = find(contains(tmpCell,'<CONSTANT-SPECIFICATION>'),1,'last')-1;
        tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end)]; % tmpCell and tmpCell2 here has the same end
    else
        Raw_start = find(contains(tmpCell,'</CONSTANT-SPECIFICATION>'),1,'last');
        tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end)];
    end

    FirstMessage = boolean(0);
end
Raw_start = find(contains(Target_arxml,'<CONSTANT-SPECIFICATION>'),1,'first');
Raw_end = find(contains(Target_arxml,'</CONSTANT-SPECIFICATION>'),1,'last');
Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];

%% Modify implementation data type part
Raw_start = find(contains(Target_arxml,'<IMPLEMENTATION-DATA-TYPE>'),1,'first');
Raw_end = find(contains(Target_arxml,'</IMPLEMENTATION-DATA-TYPE>'),1,'last');
Template = Target_arxml(Raw_start:Raw_end);
FirstMessage = boolean(1);

for i = 1:length(DBC.Messages)
    MsgName = char(DBC.MessageInfo(i).Name);

    % Message judgement, Diag PDUs are N-PDU, not I-PDU
    % Workaround: XNM messages are I PDU
    if any(strcmp(MsgName,IgnoreFilter)) || startsWith(MsgName,'Diag')
        continue
    end

    tmpCell = Template;

    h = find(contains(tmpCell,'<SHORT-NAME>SignalGroupDataType</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['DT_' Channel '_SG_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>DT_CAN1_SG_FD_VCU1</SHORT-NAME>

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

        Raw_start = find(contains(Template,'<IMPLEMENTATION-DATA-TYPE-ELEMENT>'));
        Raw_end = find(contains(Template,'</IMPLEMENTATION-DATA-TYPE-ELEMENT>'));
        tmpCell2 = Template(Raw_start:Raw_end); % initialise tmpCell2 for implementation data type element part

        h = find(contains(tmpCell2,'<SHORT-NAME>SignalsInSignalGroup</SHORT-NAME>'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = [Channel '_' SignalName];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>CAN1_PwrSta</SHORT-NAME>

        h = find(contains(tmpCell2,'<IMPLEMENTATION-DATA-TYPE-REF DEST="IMPLEMENTATION-DATA-TYPE">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/AUTOSAR_Platform/ImplementationDataTypes/' SignalType];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>CAN1_PwrSta</SHORT-NAME>

        if k == 1 % to replace original part
            Raw_start = find(contains(tmpCell,'<IMPLEMENTATION-DATA-TYPE-ELEMENT>'));
            Raw_end = find(contains(tmpCell,'</IMPLEMENTATION-DATA-TYPE-ELEMENT>'));
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
        else % to add new part
            Raw_start = find(contains(tmpCell,'</IMPLEMENTATION-DATA-TYPE-ELEMENT>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    if FirstMessage
        Raw_start = find(contains(Target_arxml,'<IMPLEMENTATION-DATA-TYPE>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</IMPLEMENTATION-DATA-TYPE>'),1,'last');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
    else
        Raw_start = find(contains(Target_arxml,'</IMPLEMENTATION-DATA-TYPE>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end

    FirstMessage = boolean(0);
end

%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen([Channel '.arxml'],'w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);


end