function Gen_CanIfSettings(Channel_list,MsgLinkFileName,Channel_list_LIN,LDFSet,DBCSet,TargetECU,RoutingTable)
project_path = pwd;
ScriptVersion = '2024.08.15';

%% Get ECUC original arxml
cd([project_path '/documents/ARXML_splitconfig'])
fileID = fopen('CanIfSettings.arxml');
CanIf_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(CanIf_arxml{1,1}),1);
for i = 1:length(CanIf_arxml{1,1})
    tmpCell{i,1} = CanIf_arxml{1,1}{i,1};
end
CanIf_arxml = tmpCell;
fclose(fileID);
cd(project_path);

%% Get System arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen('System.arxml');
System_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(System_arxml{1,1}),1);
for i = 1:length(System_arxml{1,1})
    tmpCell{i,1} = System_arxml{1,1}{i,1};
end
System_arxml = tmpCell;
fclose(fileID);
cd(project_path);

%% Get HOHSettings arxml
cd([project_path '/documents/ARXML_splitconfig'])
fileID = fopen('HOHSettings.arxml');
HOH_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(HOH_arxml{1,1}),1);
for i = 1:length(HOH_arxml{1,1})
    tmpCell{i,1} = HOH_arxml{1,1}{i,1};
end
HOH_arxml = tmpCell;
fclose(fileID);
cd(project_path);

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

%% Get Routing table Rx Message
cnt = 0;
Routing_RxMsg = {};
for i = 1:length(RoutingTable(:,1))
    if ~strcmp(RoutingTable(i,2),'Invalid') && strcmp(RoutingTable(i,1),'Invalid')
        cnt = cnt +1;
        Routing_RxMsg(cnt,1) = RoutingTable(i,2);
    end
end
Routing_RxMsg = unique(Routing_RxMsg);

%% Get Composition ARXML and get P port R port
P_SG_APP = {};
R_SG_APP = {};
cd([project_path '/documents/ARXML_output'])
fileID = fopen('Composition.arxml');
Source_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Source_arxml{1,1}),1);
for j = 1:length(Source_arxml{1,1})
    tmpCell{j,1} = Source_arxml{1,1}{j,1};
end

Composition_arxml = tmpCell;

h = find(contains(Composition_arxml,'<R-PORT-PROTOTYPE>')) + 1;
R_port_msg = extractBetween(Composition_arxml(h),'<SHORT-NAME>','</SHORT-NAME>');
Channel = extractBetween(R_port_msg,'HALR_','_');
R_port_msg = extractAfter(R_port_msg,10);

R_SG_APP(:,1) = R_port_msg;
R_SG_APP(:,2) = Channel;

% h = find(contains(Composition_arxml,'<P-PORT-PROTOTYPE>')) + 1;
% P_port_msg = extractBetween(Composition_arxml(h),'<SHORT-NAME>','</SHORT-NAME>');
% Channel = extractBetween(P_port_msg,'HALP_','_');
% P_port_msg = extractAfter(P_port_msg,10);
% 
% P_SG_APP(:,1) = P_port_msg;
% P_SG_APP(:,2) = Channel;

% Remove CGW_msg
% h = startsWith(P_SG_APP(:,1),'CGW_');
% P_SG_APP(h,:) = [];

%% %% Get CAN.Rest.ARXML info
h1 = find(contains(HOH_arxml,'<SHORT-NAME>HOH_'));
ECUC_start_array = find(contains(HOH_arxml(:,1),'<ECUC-CONTAINER-VALUE>'));
ECUC_end_array = find(contains(HOH_arxml(:,1),'</SUB-CONTAINERS>'));

HOH_Array = {};
cnt = 0;

for i = 1:length(h1)
    ECUC_start = max(ECUC_start_array(ECUC_start_array<h1(i)));
    ECUC_end = min(ECUC_end_array(ECUC_end_array>h1(i)))+1;

    % HOH name
    h = find(contains(HOH_arxml(ECUC_start:ECUC_end),'<SHORT-NAME>HOH_')) + ECUC_start -1;
    HOH_Name = extractBetween(HOH_arxml(h),'<SHORT-NAME>','</SHORT-NAME>');
    
    % HOH CanObjectType
    h = find(contains(HOH_arxml(ECUC_start:ECUC_end),'/CanObjectType</DEFINITION-REF>')) + ECUC_start -1;
    HOH_CanObjectType = extractBetween(HOH_arxml(h+1),'<VALUE>','</VALUE>');
    
    % HOH CanHwFilterCode
    h = find(contains(HOH_arxml(ECUC_start:ECUC_end),'/CanHwFilterCode</DEFINITION-REF>')) + ECUC_start -1;
    HOH_CanHwFilterCode = extractBetween(HOH_arxml(h+1),'<VALUE>','</VALUE>');
    
    cnt = cnt + 1;
    HOH_Array(cnt,1) = HOH_Name;
    HOH_Array(cnt,2) = HOH_CanObjectType;
    HOH_Array(cnt,3) = HOH_CanHwFilterCode;
end

%% Read DBC info

P_SG_APP = {};
cnt = 0;

for i = 1:length(Channel_list)
    
    DBC = DBCSet(i);
    for k = 1:length(DBC.Messages)

        MsgName = char(DBC.MessageInfo(k).Name);
        TxNode = char(DBC.MessageInfo(k).TxNodes);
        Channel = char(Channel_list(i));

        if startsWith(MsgName,'NMm_FUSION')
            R_SG_APP{end+1,1} = [MsgName '_RX'];
            R_SG_APP{end,2} = num2str('0');
            R_SG_APP{end,3} = char(DBC.MessageInfo(k).ProtocolMode);
            R_SG_APP{end,4} = num2str(DBC.MessageInfo(k).Length);
            R_SG_APP{end,5} = Channel;
            
            cnt = cnt +1;
            P_SG_APP{cnt,1} = [MsgName '_TX'];
            P_SG_APP{cnt,2} = num2str(DBC.MessageInfo(k).ID);
            P_SG_APP{cnt,3} = char(DBC.MessageInfo(k).ProtocolMode);
            P_SG_APP{cnt,4} = num2str(DBC.MessageInfo(k).Length);
            P_SG_APP{cnt,5} = Channel;
        elseif any(strcmp(R_SG_APP(:,1),MsgName)) && ~strcmp(TxNode,'FUSION')
            h = strcmp(R_SG_APP(:,1),MsgName);
            R_SG_APP{h,2} = num2str(DBC.MessageInfo(k).ID);
            R_SG_APP{h,3} = char(DBC.MessageInfo(k).ProtocolMode);
            R_SG_APP{h,4} = num2str(DBC.MessageInfo(k).Length);
            R_SG_APP{h,5} = Channel;
            % R_SG_APP{h,6} = TxNode;
%         elseif any(strcmp(P_SG_APP(:,1),MsgName)) && strcmp(TxNode,'FUSION')
%             h = strcmp(P_SG_APP(:,1),MsgName);
%             P_SG_APP{h,2} = num2str(DBC.MessageInfo(k).ID);
%             P_SG_APP{h,3} = char(DBC.MessageInfo(k).ProtocolMode);
%             P_SG_APP{h,4} = num2str(DBC.MessageInfo(k).Length);
%             P_SG_APP{h,5} = Channel;
%             % P_SG_APP{h,6} = TxNode;
        elseif ~any(strcmp(Routing_RxMsg,MsgName)) && strcmp(TxNode,'FUSION')
            cnt = cnt +1;
            P_SG_APP{cnt,1} = MsgName;
            P_SG_APP{cnt,2} = num2str(DBC.MessageInfo(k).ID);
            P_SG_APP{cnt,3} = char(DBC.MessageInfo(k).ProtocolMode);
            P_SG_APP{cnt,4} = num2str(DBC.MessageInfo(k).Length);
            P_SG_APP{cnt,5} = Channel;
            % P_SG_APP{h,6} = TxNode;
%         elseif (startsWith(MsgName,'Diag') && ~strcmp(TxNode,'FUSION'))
%             R_SG_APP{end+1,1} = MsgName;
%             R_SG_APP{end,2} = num2str(DBC.MessageInfo(k).ID);
%             R_SG_APP{end,3} = char(DBC.MessageInfo(k).ProtocolMode);
%             R_SG_APP{end,4} = num2str(DBC.MessageInfo(k).Length);
%             R_SG_APP{end,5} = Channel;
            % R_SG_APP{end,6} = TxNode;
%         elseif startsWith(MsgName,'Diag') && strcmp(TxNode,'FUSION')
%             P_SG_APP{end+1,1} = MsgName;
%             P_SG_APP{end,2} = num2str(DBC.MessageInfo(k).ID);
%             P_SG_APP{end,3} = char(DBC.MessageInfo(k).ProtocolMode);
%             P_SG_APP{end,4} = num2str(DBC.MessageInfo(k).Length);
%             P_SG_APP{end,5} = Channel;
            % P_SG_APP{end,6} = TxNode;
        else
            continue
        end
    end
end

% Add XCP into R_SG_APP & P_SG_APP
idx = intersect(find(endsWith(HOH_Array(:,1),'Xcp')),find(endsWith(HOH_Array(:,2),'RECEIVE')));
ID = HOH_Array(idx,3);
R_SG_APP{end+1,1} = 'XCP_';
R_SG_APP{end,2} = char(ID);
R_SG_APP{end,3} = 'CAN';
R_SG_APP{end,4} = '0';
R_SG_APP{end,5} = 'CAN_XCP';

idx = intersect(find(endsWith(HOH_Array(:,1),'Xcp')),find(endsWith(HOH_Array(:,2),'TRANSMIT')));
ID = HOH_Array(idx,3);
P_SG_APP{end+1,1} = 'XCP_';
P_SG_APP{end,2} = char(ID);
P_SG_APP{end,3} = 'CAN FD';
P_SG_APP{end,4} = '8';
P_SG_APP{end,5} = 'CAN_XCP';

%% Get template and update CanIf.Rest.ARXML CanIfInitCfg/CanIfInitHohCfg
h = find(contains(CanIf_arxml(:,1),'<SHORT-NAME>CanIfInitHohCfg</SHORT-NAME>'));
ECUC_start_array = find(contains(CanIf_arxml(:,1),'<ECUC-CONTAINER-VALUE>'));
ECUC_end_array = find(contains(CanIf_arxml(:,1),'</ECUC-CONTAINER-VALUE>'));

ECUC_start = min(ECUC_start_array(ECUC_start_array>h));
ECUC_end = min(ECUC_end_array(ECUC_end_array>h));


% Create HOH CanIfHrhCfg
for i = 1:length(HOH_Array(:,1))
    tmpCell = CanIf_arxml(ECUC_start:ECUC_end);
    HOH_Name = HOH_Array(i,1);
    idx = strfind(string(HOH_Name),'_');
    Channel = upper(extractAfter(HOH_Name,idx(end)));

    if contains(HOH_Name,'Can8_Xcp')
        Channel = cellstr('Can8_Xcp');
    end
    
    HOH_Array(i,4) = Channel;


    % HOH Name
    h = find(contains(tmpCell,'<SHORT-NAME>HOH'));
    OldString = extractBetween(tmpCell(h),'<SHORT-NAME>','</SHORT-NAME>');
    NewString = HOH_Name;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % HOH CanIfCtrlDrvCfg
    h = find(contains(tmpCell,'/CanIf/CanIf/CanIfCtrlDrvCfg/'));
    OldString = extractBetween(tmpCell(h),'CanIfCtrlDrvCfg/','</VALUE-REF>');
    NewString = Channel;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % HOH CanConfigSet
    h = find(contains(tmpCell,'/Can/Can/CanConfigSet/'));
    OldString = extractBetween(tmpCell(h),'CanConfigSet/','</VALUE-REF>');
    NewString = HOH_Name;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % CanIfHrhCfg or CanIfHthCfg
    h = find(contains(tmpCell,'CanIfHrh'));
    OldString = 'CanIfHrh';
    if strcmp(HOH_Array(i,2),'RECEIVE')
        NewString = cellstr('CanIfHrh');
    else
        NewString = cellstr('CanIfHth');
    end
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % Remove <PARAMETER-VALUES> for Tx HOH
    if strcmp(HOH_Array(i,2),'TRANSMIT')
        Raw_start = find(contains(tmpCell,'<PARAMETER-VALUES>'));
        Raw_end = find(contains(tmpCell,'</PARAMETER-VALUES>'));
        tmpCell(Raw_start:Raw_end) = [];
    end

    if i == 1
        tmpCell2 = tmpCell;
    else 
        tmpCell2 = [tmpCell2;tmpCell];
    end
end

% Replace original CanIfInitHohCfg(CanIfHrhCfg & CanIfHthCfg) part
h = find(contains(CanIf_arxml(:,1),'<SHORT-NAME>CanIfInitHohCfg</SHORT-NAME>'));
ECUC_start_array = find(contains(CanIf_arxml(:,1),'<SUB-CONTAINERS>'));
ECUC_end_array = find(contains(CanIf_arxml(:,1),'</SUB-CONTAINERS>'));

ECUC_start = min(ECUC_start_array(ECUC_start_array>h));
ECUC_end = min(ECUC_end_array(ECUC_end_array>h));

CanIf_arxml = [CanIf_arxml(1:ECUC_start);tmpCell2;CanIf_arxml(ECUC_end:end)];

%% Get template and update CanIf.Rest.ARXML CanIfInitCfg/CanIfRxPduCfg
h = find(contains(CanIf_arxml(:,1),'/CanIf/CanIfInitCfg/CanIfRxPduCfg</DEFINITION-REF>'),1,'first');
ECUC_start_array = find(contains(CanIf_arxml(:,1),'<ECUC-CONTAINER-VALUE>'));
ECUC_end_array = find(contains(CanIf_arxml(:,1),'</SUB-CONTAINERS>'))+1;

ECUC_start = max(ECUC_start_array(ECUC_start_array<h));
ECUC_end = min(ECUC_end_array(ECUC_end_array>h));

idx = ~strcmp(HOH_Array(:,2),'TRANSMIT');
RxHOH_Array = HOH_Array(idx,:);

for i = 1:length(R_SG_APP(:,1))
    Channel = char(R_SG_APP(i,5));
    MsgID = char(R_SG_APP(i,2));
    MsgDLC = R_SG_APP(i,4);
    tmpCell = CanIf_arxml(ECUC_start:ECUC_end);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Nm and XCP name
    if strcmp(R_SG_APP(i,1),'NMm_FUSION_RX')
        RxPDUName = [Channel '_' char(R_SG_APP(i,1)) '_1280R'];
    elseif startsWith(R_SG_APP(i,1),'XCP_')
        RxPDUName = [char(R_SG_APP(i,1)) MsgID 'R'];
    else
        RxPDUName = [Channel '_' char(R_SG_APP(i,1)) '_' MsgID 'R'];
    end 
    
    % CAN type
    if strcmp(R_SG_APP(i,3),'CAN FD')
        CanIfRxPduCanIdType = cellstr('STANDARD_FD_CAN');
    elseif startsWith(R_SG_APP(i,1),'XCP_')
        CanIfRxPduCanIdType = cellstr('STANDARD_CAN');
    else
        CanIfRxPduCanIdType = cellstr('STANDARD_NO_FD_CAN');
    end
    
    % CDD, PDUR, CAN_NM
    if startsWith(R_SG_APP(i,1),'NMm_FUSION_RX')
        CanIfRxPduUserRxIndicationUL = cellstr('CAN_NM');
    elseif startsWith(R_SG_APP(i,1),'XCP_')
        CanIfRxPduUserRxIndicationUL = cellstr('CDD');
    else
        CanIfRxPduUserRxIndicationUL = cellstr('PDUR');
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PDUR Name
    h = find(contains(tmpCell,'/CanIfRxPduCfg</DEFINITION-REF>')) - 1;
    OldString = extractBetween(tmpCell(h),'<SHORT-NAME>','</SHORT-NAME>');
    NewString = RxPDUName;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % PDUR ID
    h = find(contains(tmpCell,'/CanIfRxPduCanId</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = MsgID;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % CanIfRxPduCanIdType
    h = find(contains(tmpCell,'/CanIfRxPduCanIdType</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = CanIfRxPduCanIdType;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % CanIfRxPduDlc
    h = find(contains(tmpCell,'/CanIfRxPduDlc</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = MsgDLC;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % CanIfRxPduReadNotifyStatus
    h = find(contains(tmpCell,'/CanIfRxPduReadNotifyStatus</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    if startsWith(R_SG_APP(i,1),'DiagResp')
        NewString = cellstr('1');
    else
        NewString = cellstr('0');
    end
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % CanIfRxPduUserRxIndicationUL
    h = find(contains(tmpCell,'/CanIfRxPduUserRxIndicationUL</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = CanIfRxPduUserRxIndicationUL;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % CanIfRxPduId
    h = find(contains(tmpCell,'/CanIfRxPduId</DEFINITION-REF>'));

    if isempty(h)
        h = find(contains(tmpCell,'/CanIfRxPduUserRxIndicationUL</DEFINITION-REF>'));
        tmpCell_PduId = tmpCell(h-1:h+2);

        h = find(contains(tmpCell_PduId,'/CanIfRxPduUserRxIndicationUL</DEFINITION-REF>'));
        OldString = extractBetween(tmpCell_PduId(h),'CanIfInitCfg/CanIfRxPduCfg/','</DEFINITION-REF>');
        NewString = cellstr('CanIfRxPduId');
        tmpCell_PduId(h) = strrep(tmpCell_PduId(h),OldString,NewString);

        OldString = extractBetween(tmpCell_PduId(h+1),'<VALUE>','</VALUE>');
        NewString = num2str(i-1);
        tmpCell_PduId(h+1) = strrep(tmpCell_PduId(h+1),OldString,NewString);

        % Add into <PARAMETER-VALUES>
        h = find(contains(tmpCell,'</PARAMETER-VALUES>'));
        tmpCell = [tmpCell(1:h-1);tmpCell_PduId;tmpCell(h:end)];
    else
        OldString = extractBetween(tmpCell(h+1),'<VALUE>','</VALUE>');
        NewString = num2str(i-1);
        tmpCell(h+1) = strrep(tmpCell(h+1),OldString,NewString);
    end

    if startsWith(R_SG_APP(i,1),'DiagResp')
        h = find(contains(tmpCell,'/CanIfRxPduUserRxIndicationUL</DEFINITION-REF>')) + 1;
        tmpCell(h-2:h+1) = [];
    end

    % CanIfInitHohCfg (HOH name)
    h = find(contains(tmpCell,'/CanIf/CanIf/CanIfInitCfg/CanIfInitHohCfg/'));
    OldString = extractBetween(tmpCell(h),'CanIfInitHohCfg/','</VALUE-REF>');
    if strcmp(R_SG_APP(i,1),'NMm_FUSION_RX')
        idx = intersect(find(strcmp(RxHOH_Array(:,3),MsgID)),find(strcmp(RxHOH_Array(:,4),Channel)));
        idx1 = find(~startsWith(RxHOH_Array(:,1),'HOH_TX_LOGGING'));
        idx = intersect(idx,idx1);
    else
        idx = strcmp(RxHOH_Array(:,3),MsgID);
    end
    HOH_Name = RxHOH_Array(idx,1);
    NewString = HOH_Name;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % EcucPduCollection
    h = find(contains(tmpCell,'/EcuC/EcuC/EcucPduCollection/'));
    OldString = extractBetween(tmpCell(h),'/EcuC/EcuC/EcucPduCollection/','</VALUE-REF>');
    NewString = RxPDUName;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % CanIfRxPduUpperLayerRef and CanIfRxPduTargetPduID (XCP only)
    if startsWith(R_SG_APP(i,1),'XCP_')
        h = find(contains(tmpCell,'CanIfRxPduUpperLayerRef</DEFINITION-REF>'));
        NewString = {'                      <VALUE-REF DEST="ECUC-CONTAINER-VALUE">/CanIf/CanIf/XCP</VALUE-REF>'};
        tmpCell = [tmpCell(1:h);NewString;tmpCell(h+1:end)];

        h = find(contains(tmpCell,'/CanIfRxPduTargetPduID</DEFINITION-REF>'));
        NewString = {'                      <VALUE>0</VALUE>'};
        tmpCell = [tmpCell(1:h);NewString;tmpCell(h+1:end)];
    end

    % CanIfRxPduUpperLayerRef (NMm only)
    if startsWith(R_SG_APP(i,1),'NMm_FUSION_RX')
        h = find(contains(CanIf_arxml(:,1),'CanIfRxPduCanIdRange'),1,'first');
        ECUC_start_array = find(contains(CanIf_arxml(:,1),'<ECUC-CONTAINER-VALUE>'));
        ECUC_end_array = find(contains(CanIf_arxml(:,1),'</ECUC-CONTAINER-VALUE>'));        
        ECUC_start_Nm = max(ECUC_start_array(ECUC_start_array<h));
        ECUC_end_Nm = min(ECUC_end_array(ECUC_end_array>h));
        
        temCell_NM = CanIf_arxml(ECUC_start_Nm:ECUC_end_Nm);
        h = find(contains(tmpCell,'<SHORT-NAME>CanIfTTRxFrameTriggering</SHORT-NAME>'))-2;
        tmpCell = [tmpCell(1:h);temCell_NM;tmpCell(h+1:end)];
    end

    if i == 1
        tmpCell2 = tmpCell;
    else 
        tmpCell2 = [tmpCell2;tmpCell];
    end
end

% Replace original CanIfRxPduCfg
ECUC_start = find(contains(CanIf_arxml(:,1),'/CanIf/CanIfInitCfg/CanIfRxPduCfg</DEFINITION-REF>'),1,'first') -3;
ECUC_end = find(contains(CanIf_arxml(:,1),'/CanIf/CanIfInitCfg/CanIfTxPduCfg</DEFINITION-REF>'),1,'first') -2; 

CanIf_arxml = [CanIf_arxml(1:ECUC_start);tmpCell2;CanIf_arxml(ECUC_end:end)];

%% Get template and update CanIf.Rest.ARXML CanIfInitCfg/CanIfTxPduCfg
h = find(contains(CanIf_arxml(:,1),'/CanIf/CanIfInitCfg/CanIfTxPduCfg</DEFINITION-REF>'),1,'first');
ECUC_start_array = find(contains(CanIf_arxml(:,1),'<ECUC-CONTAINER-VALUE>'));
ECUC_end_array = find(contains(CanIf_arxml(:,1),'</SUB-CONTAINERS>'))+1;

ECUC_start = max(ECUC_start_array(ECUC_start_array<h));
ECUC_end = min(ECUC_end_array(ECUC_end_array>h));

idx = ~strcmp(HOH_Array(:,2),'RECEIVE');
TxHOH_Array = HOH_Array(idx,:);
cnt = 0;
for i = 1:length(P_SG_APP(:,1))
    Channel = char(P_SG_APP(i,5));
    MsgID = char(P_SG_APP(i,2));
    MsgDLC = P_SG_APP(i,4);
    tmpCell = CanIf_arxml(ECUC_start:ECUC_end);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Nm and XCP name
    if strcmp(P_SG_APP(i,1),'NMm_FUSION_TX')
        TxPDUName = [Channel '_' char(P_SG_APP(i,1)) '_1280T'];
    elseif startsWith(P_SG_APP(i,1),'XCP_')
        TxPDUName = [char(P_SG_APP(i,1)) MsgID 'T'];
    else
        TxPDUName = [Channel '_' char(P_SG_APP(i,1)) '_' MsgID 'T'];
    end 
    
    % CAN type
    if strcmp(P_SG_APP(i,3),'CAN FD')
        CanIfTxPduCanIdType = cellstr('STANDARD_FD_CAN');
    else
        CanIfTxPduCanIdType = cellstr('STANDARD_CAN');
    end
    
    % CDD, PDUR, CAN_NM
    if startsWith(P_SG_APP(i,1),'NMm_FUSION_TX')
        CanIfTxPduUserTxConfirmationUL = cellstr('CAN_NM');
    elseif startsWith(P_SG_APP(i,1),'XCP_') || startsWith(P_SG_APP(i,1),'Diag')
        CanIfTxPduUserTxConfirmationUL = cellstr('CDD');
    else
        CanIfTxPduUserTxConfirmationUL = cellstr('PDUR');
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PDUR Name
    h = find(contains(tmpCell,'/CanIfTxPduCfg</DEFINITION-REF>')) - 1;
    OldString = extractBetween(tmpCell(h),'<SHORT-NAME>','</SHORT-NAME>');
    NewString = TxPDUName;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % PDUR ID
    h = find(contains(tmpCell,'/CanIfTxPduCanId</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = MsgID;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % CanIfTxPduCanIdType
    h = find(contains(tmpCell,'/CanIfTxPduCanIdType</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = CanIfTxPduCanIdType;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % CanIfTxPduDlc
    h = find(contains(tmpCell,'/CanIfTxPduDlc</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = MsgDLC;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % CanIfTxPduSourcePduID (XCP & Diag only)
    if startsWith(P_SG_APP(i,1),'XCP_') || startsWith(P_SG_APP(i,1),'Diag')
        if startsWith(P_SG_APP(i,1),'XCP_')
            NewString = cellstr('0');
        else
            NewString = num2str(cnt);
            cnt = cnt+1;
        end

        h = find(contains(tmpCell,'/CanIfTxPduSourcePduID</DEFINITION-REF>'));
        if contains(tmpCell(h+1,1),'<VALUE>')
            OldString = extractBetween(tmpCell(h+1),'<VALUE>','</VALUE>');
            tmpCell(h+1) = strrep(tmpCell(h+1),OldString,NewString);
        else
            NewString = ['                      <VALUE>' cnt '</VALUE>'];
            tmpCell = [tmpCell(1:h);NewString;tmpCell(h+1:end)];
        end
    else
        h = find(contains(tmpCell,'/CanIfTxPduSourcePduID</DEFINITION-REF>'));
        if contains(tmpCell(h+1,1),'<VALUE>')
            tmpCell(h+1) = [];
        end
    end


    % CanIfTxPduUserTxConfirmationUL
    h = find(contains(tmpCell,'/CanIfTxPduUserTxConfirmationUL</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = CanIfTxPduUserTxConfirmationUL;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);   

    % CanIfTxPduBufferRef (HOH name)
    h = find(contains(tmpCell,'/CanIfTxPduBufferRef</DEFINITION-REF>'));
    OldString = extractBetween(tmpCell(h+1),'/CanIf/CanIfInitCfg/','</VALUE-REF>');
    if strcmp(P_SG_APP(i,1),'XCP_')
        idx = find(strcmp(TxHOH_Array(:,4),'Can8_Xcp'));
    else
        idx = strcmp(TxHOH_Array(:,4),Channel);
    end
    HOH_Name = TxHOH_Array(idx,1);
    NewString = HOH_Name;
    tmpCell(h+1) = strrep(tmpCell(h+1),OldString,NewString);

    % EcucPduCollection
    h = find(contains(tmpCell,'/EcuC/EcuC/EcucPduCollection/'));
    OldString = extractBetween(tmpCell(h),'/EcuC/EcuC/EcucPduCollection/','</VALUE-REF>');
    NewString = TxPDUName;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % CanIfTxPduUpperLayerRef (XCP & Diag only)
    if startsWith(P_SG_APP(i,1),'XCP_') || startsWith(P_SG_APP(i,1),'Diag')
        if startsWith(P_SG_APP(i,1),'XCP_')
            NewString = cellstr('XCP');
        else
            NewString = cellstr('CAN_PASS');
        end

        h = find(contains(tmpCell,'/CanIfTxPduUpperLayerRef</DEFINITION-REF>'));
        if contains(tmpCell(h+1,1),'/CanIf/CanIf/')
            OldString = extractBetween(tmpCell(h+1),'/CanIf/CanIf/','</VALUE-REF>');
            tmpCell(h+1) = strrep(tmpCell(h+1),OldString,NewString);
        else
            NewString = ['                      <VALUE-REF DEST="ECUC-CONTAINER-VALUE">/CanIf/CanIf/' char(NewString) '</VALUE-REF>'];
            tmpCell = [tmpCell(1:h);NewString;tmpCell(h+1:end)];
        end
    else
        h = find(contains(tmpCell,'/CanIfTxPduUpperLayerRef</DEFINITION-REF>'));
        if contains(tmpCell(h+1,1),'/CanIf/CanIf/')
            tmpCell(h+1) = [];
        end
    end

    if i == 1
        tmpCell2 = tmpCell;
    else 
        tmpCell2 = [tmpCell2;tmpCell];
    end
end

% Replace original CanIfRxPduCfg
ECUC_start = find(contains(CanIf_arxml(:,1),'/CanIf/CanIfInitCfg/CanIfTxPduCfg</DEFINITION-REF>'),1,'first') -3;
ECUC_end = find(contains(CanIf_arxml(:,1),'<SHORT-NAME>CanIfMirroringSupport</SHORT-NAME>'),1,'first') -3; 

CanIf_arxml = [CanIf_arxml(1:ECUC_start);tmpCell2;CanIf_arxml(ECUC_end:end)];

%% Output COM_arxml
cd([project_path '/documents/ARXML_splitconfig'])
fileID = fopen('CanIfSettings.arxml','w');
for i = 1:length(CanIf_arxml(:,1))
    fprintf(fileID,'%s\n',char(CanIf_arxml(i,1)));
end
fclose(fileID);
end