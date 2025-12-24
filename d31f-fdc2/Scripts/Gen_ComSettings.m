function Gen_ComSettings(Channel_list,Channel_list_LIN,LDFSet,DBCSet,TargetECU,RoutingTable)
project_path = pwd;
ScriptVersion = '2024.09.03';

%% Get ECUC original arxml
cd([project_path '/documents/ARXML_splitconfig'])
fileID = fopen('ComSettings.arxml');
COM_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(COM_arxml{1,1}),1);
for i = 1:length(COM_arxml{1,1})
    tmpCell{i,1} = COM_arxml{1,1}{i,1};
end
COM_arxml = tmpCell;
fclose(fileID);
cd(project_path);

%% Get Composition ARXML and get P port R port
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
R_port_msg = extractAfter(R_port_msg,10);

h = find(contains(Composition_arxml,'<P-PORT-PROTOTYPE>')) + 1;
P_port_msg = extractBetween(Composition_arxml(h),'<SHORT-NAME>','</SHORT-NAME>');
P_port_msg = extractAfter(P_port_msg,10);

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

%% Get CAN routing signals
SignalRouting = {};
cnt = 0;
for n = 1:length(Channel_list)
    Channel = char(Channel_list(n));
    if contains(Channel,'Dr')
        Channel_long = [extractBefore(Channel,'Dr') '_' extractAfter(Channel,'CAN')];
    else
        Channel_long = Channel;
    end
    Raw_start = find(contains(RoutingTable(:,1),['requested signals, source:' Channel_long])) + 2;

    for i = 1:length(Raw_start)
        Channel_source = char(RoutingTable(Raw_start(i)-2,1));
        Channel_source = erase(extractAfter(Channel_source,'requested signals, source:'),'_');
        Channel_target = char(RoutingTable(Raw_start(i)-2,4));
        Channel_target = erase(extractAfter(Channel_target,'distributed messages, target:'),'_');
        Raw_end = Raw_start(i) + find(contains(RoutingTable(Raw_start(i):end,4),'distributed messages, target'),1,'first') - 2;
        if isempty(Raw_end); Raw_end = length(RoutingTable(:,1)); end

        for k = Raw_start(i):Raw_end
            if ~strcmp(RoutingTable(k,4),'Invalid')
                cnt = cnt + 1;

                if strcmp(RoutingTable(k,2),'Invalid')
                    h = find(~strcmp(RoutingTable(1:k,2),'Invalid'),1,'last');
                    SourceMsgName = RoutingTable(h,2);
                    SourceMsgID = str2double(string(RoutingTable(h,3)));
                    TxMsgName = RoutingTable(h,5);
                    TxMsgID = str2double(string(RoutingTable(h,6)));
                else
                    SourceMsgName = RoutingTable(k,2);
                    SourceMsgID = str2double(string(RoutingTable(k,3)));
                    TxMsgName = RoutingTable(k,5);
                    TxMsgID = str2double(string(RoutingTable(k,6)));
                end

                SignalRouting(cnt,1) = cellstr(Channel_source); % source signal channel
                SignalRouting(cnt,2) = RoutingTable(k,1); % source signal name
                SignalRouting(cnt,3) = SourceMsgName; % source message name
                SignalRouting(cnt,4) = cellstr(string(SourceMsgID)); % Rx Message ID
                SignalRouting(cnt,5) = cellstr(Channel_target); % target signal channel
                SignalRouting(cnt,6) = RoutingTable(k,4); % target signal name
                SignalRouting(cnt,7) = TxMsgName; % TxMsgName
                SignalRouting(cnt,8) = cellstr(string(TxMsgID)); % TxMsgID
            else
                continue
            end
        end
    end
end
%% Get Rx timeout time and substitution value
ValueTable_R = {};
ValueTable_P = {};
cnt_R = 0;
cnt_P = 0;

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
        if IsDiag || startsWith(MsgName,'NMm_')
            continue
        end
        
        if any(strcmp(MsgName,{'FD1_APS3';'FD1_VCU2';'FD1_VCU3';'VMC_FCM1';'FD3_VCU2';'FD3_VCU2_toNIDEC';'FD6_APS3';'FD6_VCU2'}))
            RC_WorkRound_flg = boolean(1);
        else
            RC_WorkRound_flg = boolean(0);
        end


        if any(strcmp(R_port_msg,MsgName)) && ~strcmp(DBC.MessageInfo(k).TxNodes,TargetECU)
            MsgName = char(DBC.MessageInfo(k).Name);
            MessageID = num2str(DBC.MessageInfo(k).ID);
            CycleTime_ms = DBC.MessageInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(k).Attributes(:,1),'GenMsgCycleTime')).Value;
            MsgSendtype = DBC.MessageInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(k).Attributes(:,1),'GenMsgSendType')).Value;
            Timeout_s = num2str(2.5*CycleTime_ms*0.001);
            cnt_R = cnt_R + 1;
            ValueTable_R{cnt_R,1} = [Channel '_SG_' MsgName '_' MessageID 'R'];
            ValueTable_R{cnt_R,2} = Timeout_s;
            ValueTable_R{cnt_R,3} = MsgSendtype;

            for n = 1:length(DBC.MessageInfo(k).Signals)
                SignalName = char(DBC.MessageInfo(k).Signals(n));
                TimeoutValue = num2str(DBC.MessageInfo(k).SignalInfo(n).AttributeInfo(strcmp(DBC.MessageInfo(k).SignalInfo(n).Attributes(:,1),'GenSigRoutingTimeoutValue')).Value);
                StartBit= num2str(DBC.MessageInfo(k).SignalInfo(n).StartBit);
                SignalSize= num2str(DBC.MessageInfo(k).SignalInfo(n).SignalSize);
                SigByteOrder = DBC.MessageInfo(k).SignalInfo(n).ByteOrder;
                SigSendtype = DBC.MessageInfo(k).SignalInfo(n).AttributeInfo(strcmp(DBC.MessageInfo(k).SignalInfo(n).Attributes(:,1),'GenSigSendType')).Value;
                SigStartValue = num2str(hex2dec(DBC.MessageInfo(k).SignalInfo(n).AttributeInfo(strcmp(DBC.MessageInfo(k).SignalInfo(n).Attributes(:,1),'GenSigStartValue')).Value));
                SignalType = upper(DBC.MessageInfo(k).SignalInfo(n).Class);
                
                cnt_R = cnt_R + 1;
                ValueTable_R{cnt_R,1} = [Channel '_' SignalName '_' MessageID 'R'];
                ValueTable_R{cnt_R,2} = ['0x' upper(TimeoutValue)];
                ValueTable_R{cnt_R,3} = SigSendtype;
                ValueTable_R{cnt_R,4} = StartBit;
                ValueTable_R{cnt_R,5} = SignalSize;
                ValueTable_R{cnt_R,6} = SigByteOrder;
                ValueTable_R{cnt_R,7} = SigStartValue;
                ValueTable_R{cnt_R,8} = SignalType;
            end
        % For CGW SG    
        elseif sum(strcmp(erase(P_port_msg,'CGW_'),MsgName)) == 2 && strcmp(DBC.MessageInfo(k).TxNodes,TargetECU)

            % Get CANx ARXML
            cd([project_path '/documents/ARXML_output'])
            fileID = fopen([ Channel '.arxml']);
            CANx_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
            tmpCell = cell(length(CANx_arxml{1,1}),1);
            for i = 1:length(CANx_arxml{1,1})
                tmpCell{i,1} = CANx_arxml{1,1}{i,1};
            end
            CANx_arxml = tmpCell;
            h = find(strcmp(erase(P_port_msg,'CGW_'),MsgName));    

            for g = 1:length(h)
                MsgName = char(P_port_msg(h(g)));
                MessageID = num2str(DBC.MessageInfo(k).ID);
                CycleTime_ms = DBC.MessageInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(k).Attributes(:,1),'GenMsgCycleTime')).Value;
                MsgSendtype = DBC.MessageInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(k).Attributes(:,1),'GenMsgSendType')).Value;
                Timeout_s = num2str(2.5*CycleTime_ms*0.001);
                cnt_P = cnt_P + 1;
                ValueTable_P{cnt_P,1} = [Channel '_SG_' MsgName '_' MessageID 'T'];
                ValueTable_P{cnt_P,2} = Timeout_s;
                ValueTable_P{cnt_P,3} = MsgSendtype;    
                ValueTable_P{cnt_P,4} = num2str(CycleTime_ms*0.001);

                % Get Signals info from CANx ARXML
                h1 = find(contains(CANx_arxml,['<SHORT-NAME>' Channel '_SG_' MsgName '</SHORT-NAME>']),1,'last');
                ECUC_start_array = find(contains(CANx_arxml,'<SYSTEM-SIGNAL-REFS>'));
                ECUC_end_array = find(contains(CANx_arxml,'</SYSTEM-SIGNAL-REFS>'));
                ECUC_start = min(ECUC_start_array(ECUC_start_array>h1))+1;
                ECUC_end = min(ECUC_end_array(ECUC_end_array>h1))-1;
                CGW_SG = extractBetween(CANx_arxml(ECUC_start:ECUC_end),['/Signal/' Channel '_'],'</SYSTEM-SIGNAL-REF>');

                for n = 1:length(DBC.MessageInfo(k).Signals)
                    SignalName = char(DBC.MessageInfo(k).Signals(n));
                    if ~any(strcmp(CGW_SG,SignalName))
                        continue
                    end
                    TimeoutValue = char(DBC.MessageInfo(k).SignalInfo(n).AttributeInfo(strcmp(DBC.MessageInfo(k).SignalInfo(n).Attributes(:,1),'GenSigRoutingTimeoutValue')).Value);
                    StartBit= num2str(DBC.MessageInfo(k).SignalInfo(n).StartBit);
                    SignalSize= num2str(DBC.MessageInfo(k).SignalInfo(n).SignalSize);
                    SigByteOrder = DBC.MessageInfo(k).SignalInfo(n).ByteOrder;
                    SigSendtype = DBC.MessageInfo(k).SignalInfo(n).AttributeInfo(strcmp(DBC.MessageInfo(k).SignalInfo(n).Attributes(:,1),'GenSigSendType')).Value;
                    SigStartValue = num2str(hex2dec(DBC.MessageInfo(k).SignalInfo(n).AttributeInfo(strcmp(DBC.MessageInfo(k).SignalInfo(n).Attributes(:,1),'GenSigStartValue')).Value));
                    SignalType = upper(DBC.MessageInfo(k).SignalInfo(n).Class);
    
                    cnt_P = cnt_P + 1;
                    ValueTable_P{cnt_P,1} = [Channel '_' SignalName '_' MessageID 'T'];
                    ValueTable_P{cnt_P,2} = ['0x' upper(TimeoutValue)];
                    ValueTable_P{cnt_P,3} = SigSendtype;
                    ValueTable_P{cnt_P,4} = StartBit;
                    ValueTable_P{cnt_P,5} = SignalSize;
                    ValueTable_P{cnt_P,6} = SigByteOrder;
                    ValueTable_P{cnt_P,7} = SigStartValue;
                    ValueTable_P{cnt_P,8} = SignalType;
                end
            end
        elseif strcmp(DBC.MessageInfo(k).TxNodes,TargetECU) && ~any(strcmp(Routing_RxMsg,MsgName))
            MsgName = char(DBC.MessageInfo(k).Name);
            MessageID = num2str(DBC.MessageInfo(k).ID);
            CycleTime_ms = DBC.MessageInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(k).Attributes(:,1),'GenMsgCycleTime')).Value;
            MsgSendtype = DBC.MessageInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(k).Attributes(:,1),'GenMsgSendType')).Value;
            
            % Rolling counter work around
            if RC_WorkRound_flg
                MsgSendtype = 'Event';
            end

            Timeout_s = num2str(2.5*CycleTime_ms*0.001);
            cnt_P = cnt_P + 1;
            ValueTable_P{cnt_P,1} = [Channel '_SG_' MsgName '_' MessageID 'T'];
            ValueTable_P{cnt_P,2} = Timeout_s;
            ValueTable_P{cnt_P,3} = MsgSendtype;
            ValueTable_P{cnt_P,4} = num2str(CycleTime_ms*0.001);

            for n = 1:length(DBC.MessageInfo(k).Signals)
                SignalName = char(DBC.MessageInfo(k).Signals(n));
                TimeoutValue = char(DBC.MessageInfo(k).SignalInfo(n).AttributeInfo(strcmp(DBC.MessageInfo(k).SignalInfo(n).Attributes(:,1),'GenSigRoutingTimeoutValue')).Value);
                StartBit= num2str(DBC.MessageInfo(k).SignalInfo(n).StartBit);
                SignalSize= num2str(DBC.MessageInfo(k).SignalInfo(n).SignalSize);
                SigByteOrder = DBC.MessageInfo(k).SignalInfo(n).ByteOrder;
                SigSendtype = DBC.MessageInfo(k).SignalInfo(n).AttributeInfo(strcmp(DBC.MessageInfo(k).SignalInfo(n).Attributes(:,1),'GenSigSendType')).Value;
                SigStartValue = num2str(hex2dec(DBC.MessageInfo(k).SignalInfo(n).AttributeInfo(strcmp(DBC.MessageInfo(k).SignalInfo(n).Attributes(:,1),'GenSigStartValue')).Value));
                SignalType = upper(DBC.MessageInfo(k).SignalInfo(n).Class);
                
                % Rolling counter work around
                if RC_WorkRound_flg
                    SigSendtype = 'OnWrite';
                end

                cnt_P = cnt_P + 1;
                ValueTable_P{cnt_P,1} = [Channel '_' SignalName '_' MessageID 'T'];
                ValueTable_P{cnt_P,2} = ['0x' upper(TimeoutValue)];
                ValueTable_P{cnt_P,3} = SigSendtype;
                ValueTable_P{cnt_P,4} = StartBit;
                ValueTable_P{cnt_P,5} = SignalSize;
                ValueTable_P{cnt_P,6} = SigByteOrder;
                ValueTable_P{cnt_P,7} = SigStartValue;
                ValueTable_P{cnt_P,8} = SignalType;
                ValueTable_P{cnt_P,9} = SignalType;
            end
        else
            continue
        end
    end
end

% for i = 1:length(Channel_list_LIN)
%     Channel = char(Channel_list_LIN(i));
%     LDF = LDFSet{i};
%     for k = 1:length(LDF.Messages)
%         IsDiag = boolean(0);
% 
%         if strcmp(LDF.MessageInfo(k).TxNodes,TargetECU) || IsDiag
%             continue
%         end
% 
%         MsgName = char(LDF.MessageInfo(k).Name);
%         MessageID = num2str(LDF.MessageInfo(k).ID);
%         CycleTime_ms = str2double(LDF.MessageInfo(k).MsgCycleTime);
%         Timeout_s = num2str(2.5*CycleTime_ms*0.001);
%         cnt = cnt + 1;
%         ValueTable{cnt,1} = [Channel '_SG_' MsgName '_' MessageID 'R'];
%         ValueTable{cnt,2} = Timeout_s;
% 
%         for n = 1:length(LDF.MessageInfo(k).Signals)
%             SignalName = char(LDF.MessageInfo(k).Signals(n));
%             TimeoutValue = char(LDF.MessageInfo(k).SignalInfo(n).TimeoutValue);
%             cnt = cnt + 1;
%             ValueTable{cnt,1} = [Channel '_' SignalName '_' MessageID 'R'];
%             ValueTable{cnt,2} = TimeoutValue;
%         end
%     end
% end

%% Create ComGwMapping
h = find(contains(COM_arxml,'<SHORT-NAME>GMCAN'));
Template_GM = COM_arxml(h(1)-1:h(2)-2);

% Extract ComGwDestination part
h = find(contains(Template_GM,'<ECUC-CONTAINER-VALUE>'));
Raw_start = h(2);
h = find(contains(Template_GM,'</ECUC-CONTAINER-VALUE>'));
Raw_end =  h(2);
Template_Dest = Template_GM(Raw_start:Raw_end);

% Remove Template_GM ComGwDestination part
h = find(contains(Template_GM,'<ECUC-CONTAINER-VALUE>'));
Raw_start = h(2);
h = find(contains(Template_GM,'<SHORT-NAME>ComGwSource</SHORT-NAME>')) -2;
Raw_end = h(1);
Template_GM(Raw_start:Raw_end) = [];

% Create it
for i = 1: length(SignalRouting(:,1))
    GWSourceSignal_Name = char(SignalRouting(i,2));
    GWSourceMsg_Name = char(SignalRouting(i,3));
    SourceChannel = char(SignalRouting(i,1));
    SourceID = char(SignalRouting(i,4)); 
    
    % GW mapping source signal
    h = find(contains(Template_GM,'<SHORT-NAME>GM'));
    OldString = extractBetween(Template_GM(h),'>','<');
    NewString = ['GM' SourceChannel '_' GWSourceSignal_Name '_' SourceID 'R_' SourceChannel '_SG_' GWSourceMsg_Name '_' SourceID 'R'];
    Template_GM(h) = strrep(Template_GM(h),OldString,NewString);

    % GW mapping source signal ComConfig
    h = find(contains(Template_GM,'<VALUE-REF DEST="ECUC-CONTAINER-VALUE">/Com/Com/ComConfig/'));
    OldString = extractBetween(Template_GM(h),'/ComConfig/','/');
    NewString = ['GR' SourceChannel '_SG_' GWSourceMsg_Name '_' SourceID 'R'];
    Template_GM(h) = strrep(Template_GM(h),OldString,NewString);

    OldString = extractBetween(Template_GM(h),[char(NewString) '/'],'</VALUE-REF>');
    NewString = [SourceChannel '_' GWSourceSignal_Name '_' SourceID 'R'];
    Template_GM(h) = strrep(Template_GM(h),OldString,NewString);

    h = find(strcmp(SignalRouting(:,2),GWSourceSignal_Name));
    if i ~= h(1) % Not the first time create
        continue
    else
        tmpCell1 = {};
        for k = 1:length(h)
            GWTargetSignal_Name = char(SignalRouting(h(k),6));
            GWTargetMsg_Name = char(SignalRouting(h(k),7));
            TargetChannel = char(SignalRouting(h(k),5));
            TargetID = char(SignalRouting(h(k),8)); 
            
            % Check CGW message
            h = sum(contains(ValueTable_P(:,1),GWTargetMsg_Name));
            if h > 1
                GWTargetMsg_Name = ['CGW_' GWTargetMsg_Name];
            end

            % GW mapping source signal
            h = find(contains(Template_Dest,'<SHORT-NAME>CAN'));
            OldString = extractBetween(Template_Dest(h),'>','<');
            NewString = [TargetChannel '_' GWTargetSignal_Name '_' TargetID 'T_' TargetChannel '_SG_' GWTargetMsg_Name '_' TargetID 'T'];
            Template_Dest(h) = strrep(Template_Dest(h),OldString,NewString);

            % GW mapping Target signal ComConfig
            h = find(contains(Template_Dest,'<VALUE-REF DEST="ECUC-CONTAINER-VALUE">/Com/Com/ComConfig/'));
            OldString = extractBetween(Template_Dest(h),'/ComConfig/','/');
            NewString = ['GR' TargetChannel '_SG_' GWTargetMsg_Name '_' TargetID 'T'];
            Template_Dest(h) = strrep(Template_Dest(h),OldString,NewString);
        
            OldString = extractBetween(Template_Dest(h),[char(NewString) '/'],'</VALUE-REF>');
            NewString = [TargetChannel '_' GWTargetSignal_Name '_' TargetID 'T'];
            Template_Dest(h) = strrep(Template_Dest(h),OldString,NewString);

            if k==1
                tmpCell1 = Template_Dest;
            else
                tmpCell1 = [tmpCell1;Template_Dest];
            end
            h = find(strcmp(SignalRouting(:,2),GWSourceSignal_Name));
        end   
    end
    
    h = find(contains(Template_GM,'<SHORT-NAME>ComGwSource</SHORT-NAME>'));
    Raw_start = h(1)-2;
    tempcell2 = [Template_GM(1:Raw_start);tmpCell1;Template_GM(Raw_start+1:end)];

    if i ==1
        tempcell_Final = tempcell2;
    else
        tempcell_Final = [tempcell_Final;tempcell2];
    end
end

% Replace oringal part
Raw_start = find(contains(COM_arxml,'<SHORT-NAME>GMCAN'),1,'first')-2;
Raw_end = find(contains(COM_arxml,' <SHORT-NAME>PDCAN'),1,'first')-1;

COM_arxml = [COM_arxml(1:Raw_start);tempcell_Final;COM_arxml(Raw_end:end)];

%% Create ALL Rx PDU ComsignalGroup
h = find(contains(COM_arxml,'/ComSignalGroupDirection</DEFINITION-REF>'));

% Get Rx ComsignalGroup template
for i = 1:length(h)
    if contains(COM_arxml(h(i)+1),'<VALUE>RECEIVE</VALUE>')
        ECUC_start_array = find(contains(COM_arxml,'/ComSignalGroup</DEFINITION-REF>'));
        ECUC_end_array = find(contains(COM_arxml,'</SUB-CONTAINERS>'));
        ECUC_start = max(ECUC_start_array(ECUC_start_array<h(i)))-2;
        ECUC_end = min(ECUC_end_array(ECUC_end_array>h(i)))+1;
        break
    end
end

Template_Comsigroup_R = COM_arxml(ECUC_start:ECUC_end);

% ComHandleId template
template_ComSignalGroupHandleId = {}; 
template_ComSignalGroupHandleId{1,1} = char('                    <ECUC-NUMERICAL-PARAM-VALUE>');
template_ComSignalGroupHandleId{2,1} = char('                      <DEFINITION-REF DEST="ECUC-INTEGER-PARAM-DEF">/TS_TxDxM6I3R0/Com/ComConfig/ComSignalGroup/ComHandleId</DEFINITION-REF>');
template_ComSignalGroupHandleId{3,1} = char('                      <VALUE>0</VALUE>');
template_ComSignalGroupHandleId{4,1} = char('                    </ECUC-NUMERICAL-PARAM-VALUE>');

template_ComGroupSignalHandleId = {};
template_ComGroupSignalHandleId{1,1} = char('                        <ECUC-NUMERICAL-PARAM-VALUE>');
template_ComGroupSignalHandleId{2,1} = char('                          <DEFINITION-REF DEST="ECUC-INTEGER-PARAM-DEF">/TS_TxDxM6I3R0/Com/ComConfig/ComSignalGroup/ComGroupSignal/ComHandleId</DEFINITION-REF>');
template_ComGroupSignalHandleId{3,1} = char('                          <VALUE>0</VALUE>');
template_ComGroupSignalHandleId{4,1} = char('                        </ECUC-NUMERICAL-PARAM-VALUE>');

% Get Rx ComGroupSignal template
h = find(contains(Template_Comsigroup_R,'<SUB-CONTAINERS>'));
ECUC_start_array = find(contains(Template_Comsigroup_R,'<ECUC-CONTAINER-VALUE>'));
ECUC_end_array = find(contains(Template_Comsigroup_R,'</ECUC-CONTAINER-VALUE>'));

ECUC_start = min(ECUC_start_array(ECUC_start_array>h));
ECUC_end = min(ECUC_end_array(ECUC_end_array>h));
Template_Comgroupsignal_R = Template_Comsigroup_R(ECUC_start:ECUC_end);

% Remove ComGroupSignal part of ComsignalGroup
SUB_start = find(contains(Template_Comsigroup_R,'<SUB-CONTAINERS>'),1,'last')+1;
SUB_end = find(contains(Template_Comsigroup_R,'</SUB-CONTAINERS>'),1,'last')+1;
Template_Comsigroup_R(SUB_start:SUB_end) = [];

% Add ComTimeoutSubstitutionValue Value
h = find(contains(Template_Comgroupsignal_R,'/ComTimeoutSubstitutionValue</DEFINITION-REF>')) + 1;
if ~contains(Template_Comgroupsignal_R(h),'<VALUE>')
    Template_Comgroupsignal_R = [Template_Comgroupsignal_R(1:h-1);cellstr('                          <VALUE></VALUE>');Template_Comgroupsignal_R(h:end)];
end

% Create ComsignalGroup & ComGroupSignal
Msg_idx =  find(contains(ValueTable_R(:,1),'_SG_'));
Msg_idx(end+1) = length(ValueTable_R);

cnt_SignalID = 0;
% Create ComsignalGroup
for i = 1:length(Msg_idx)-1
    Gr_Name = ['GR' char(ValueTable_R(Msg_idx(i),1))];
    Timeout_s = char(ValueTable_R(Msg_idx(i),2));

    First_timeout_s = cellstr('0.005');
    idx = strfind(string(Gr_Name),'_');
    ComTimeoutNotification = [erase(char(extractBefore(Gr_Name,idx(end))),'GR') '_ComTimeoutNotification'];
    ComNotification = [erase(char(extractBefore(Gr_Name,idx(end))),'GR') '_ComNotification'];

    if strcmp(ValueTable_R(Msg_idx(i),3),'CE')
        ComTransferProperty_Msg = cellstr('TRIGGERED_ON_CHANGE');
    elseif strcmp(ValueTable_R(Msg_idx(i),3),'Cycle')
        ComTransferProperty_Msg = cellstr('PENDING');
    elseif strcmp(ValueTable_R(Msg_idx(i),3),'Event')
        ComTransferProperty_Msg = cellstr('TRIGGERED');
    else
        error([Gr_Name ' has Unrecognized Messgae send type']);
    end
    
    idx = strfind(string(ValueTable_R(Msg_idx(i),1)),'_');
    Channel = char(extractBefore(ValueTable_R(Msg_idx(i),1),idx(1)));
    SG_Name = char(extractBefore(ValueTable_R(Msg_idx(i),1),idx(end)));
    PDU_Name = erase(SG_Name,{'SG_';'CGW_'});

    % GR Name
    h = find(contains(Template_Comsigroup_R,'<SHORT-NAME>GRCAN'),1,'first');
    OldString = extractBetween(Template_Comsigroup_R(h),'>','<');
    NewString = Gr_Name;
    Template_Comsigroup_R(h) = strrep(Template_Comsigroup_R(h),OldString,NewString);

    % ComFirstTimeout
    h = find(contains(Template_Comsigroup_R,'/ComFirstTimeout</DEFINITION-REF>'))+1;
    OldString = extractBetween(Template_Comsigroup_R(h),'>','<');
    NewString = First_timeout_s;
    Template_Comsigroup_R(h) = strrep(Template_Comsigroup_R(h),OldString,NewString);

    % ComNotification
    h = find(contains(Template_Comsigroup_R,'/ComNotification</DEFINITION-REF>'))+1;
    OldString = extractBetween(Template_Comsigroup_R(h),'>','<');
    NewString = ComNotification;
    Template_Comsigroup_R(h) = strrep(Template_Comsigroup_R(h),OldString,NewString);

    % ComTimeout
    if str2double(Timeout_s) <= 300
        h = find(contains(Template_Comsigroup_R,'/ComTimeout</DEFINITION-REF>'))+1;
        OldString = extractBetween(Template_Comsigroup_R(h),'>','<');
        NewString = Timeout_s;
        Template_Comsigroup_R(h) = strrep(Template_Comsigroup_R(h),OldString,NewString);
    end

    % ComTimeoutNotification
    h = find(contains(Template_Comsigroup_R,'/ComTimeoutNotification</DEFINITION-REF>'))+1;
    OldString = extractBetween(Template_Comsigroup_R(h),'>','<');
    NewString = ComTimeoutNotification;
    Template_Comsigroup_R(h) = strrep(Template_Comsigroup_R(h),OldString,NewString);

    % ComTransferProperty
    h = find(contains(Template_Comsigroup_R,'/ComTransferProperty</DEFINITION-REF>'))+1;
    OldString = extractBetween(Template_Comsigroup_R(h),'>','<');
    NewString = ComTransferProperty_Msg;
    Template_Comsigroup_R(h) = strrep(Template_Comsigroup_R(h),OldString,NewString);

    % I-SIGNAL-I-PDU PDU MAPPING
    h = find(contains(Template_Comsigroup_R,'/ComSystemTemplateSignalGroupRef</DEFINITION-REF>'))+1;
    OldString = extractBetween(Template_Comsigroup_R(h),'DEST="I-SIGNAL-TO-I-PDU-MAPPING">','<');
    NewString = ['/' Channel '/PDU/' PDU_Name '/' SG_Name];
    Template_Comsigroup_R(h) = strrep(Template_Comsigroup_R(h),OldString,NewString);
    
    if i ~= length(Msg_idx)-1
        Signal_idx = Msg_idx(i)+1:Msg_idx(i+1)-1;
    else
        Signal_idx = Msg_idx(i)+1:Msg_idx(i+1);
    end
    
    % ComHandleId(ComSignalGroup)
    h = find(contains(Template_Comsigroup_R,'/ComSignalGroup/ComHandleId</DEFINITION-REF>'));
    if isempty(h) 
        OldString = extractBetween(template_ComSignalGroupHandleId(h+1),'<VALUE>','</VALUE>');
        NewString = num2str(i-1);
        template_ComSignalGroupHandleId(h+1) = strrep(template_ComSignalGroupHandleId(h+1),OldString,NewString);
        % Add into <PARAMETER-VALUES>
        h = find(contains(Template_Comsigroup_R,'</PARAMETER-VALUES>'));
        Template_Comsigroup_R = [Template_Comsigroup_R(1:h-1);template_ComSignalGroupHandleId;Template_Comsigroup_R(h:end)];
    else
        OldString = extractBetween(Template_Comsigroup_R(h+1),'<VALUE>','</VALUE>');
        NewString = num2str(i-1);
        Template_Comsigroup_R(h+1) = strrep(Template_Comsigroup_R(h+1),OldString,NewString);
    end

    % Create ComGroupSignal
    for k = 1:length(Signal_idx)
        SGr_Name = char(ValueTable_R(Signal_idx(k),1));
        ComBitSize = ValueTable_R(Signal_idx(k),5);
        Bitsize = str2double(cell2mat(ComBitSize));
        StartBit = str2double(cell2mat(ValueTable_R(Signal_idx(k),4)));
        n = floor(StartBit/8);
        m = floor((Bitsize + StartBit-1)/8) - n;

        % Cross byte ComBitPosition
        if floor((Bitsize + StartBit-1)/8) ~= n
            ComBitPosition = cellstr(string((8*(n-m)) + (Bitsize - ((8*(n+m)) - StartBit)) -1));
        else
            ComBitPosition = cellstr(string(Bitsize + StartBit -1));
        end

        if strcmp(ValueTable_R(Signal_idx(k),6),'BigEndian')
            ComSignalEndianness = cellstr('BIG_ENDIAN');
        else
            ComSignalEndianness = cellstr('LITTLE_ENDIAN');
        end
        ComSignalInitValue = ValueTable_R(Signal_idx(k),7);
        ComSignalType= ValueTable_R(Signal_idx(k),8);
        ComTimeoutSubstitutionValue = ValueTable_R(Signal_idx(k),2);

        if strcmp(ComTransferProperty_Msg,'PENDING')
            ComTransferProperty_Sig  = cellstr('TRIGGERED_ON_CHANGE'); % PDU PENDING Default, cannot select Sgnal ComTransferProperty
        elseif strcmp(ValueTable_R(Signal_idx(k),3),'OnChange')
            ComTransferProperty_Sig  = cellstr('TRIGGERED_ON_CHANGE');
        elseif strcmp(ValueTable_R(Signal_idx(k),3),'Cycle')
            ComTransferProperty_Sig  = cellstr('PENDING');
        else
            error([ Gr_Name '::' SGr_Name ' has Unrecognized Messgae send type']);
        end
        
        idx = strfind(string(SGr_Name),'_');
        SigPDU_Name = ['/' Channel '/PDU/' PDU_Name '/' char(extractBefore(SGr_Name,idx(end)))];
    
        % SGR Name
        h = find(contains(Template_Comgroupsignal_R,'<SHORT-NAME>CAN'),1,'first');
        OldString = extractBetween(Template_Comgroupsignal_R(h),'>','<');
        NewString = SGr_Name;
        Template_Comgroupsignal_R(h) = strrep(Template_Comgroupsignal_R(h),OldString,NewString);
        
        % ComBitPosition
        h = find(contains(Template_Comgroupsignal_R,'/ComBitPosition</DEFINITION-REF>')) + 1;
        OldString = extractBetween(Template_Comgroupsignal_R(h),'>','<');
        NewString = ComBitPosition;
        Template_Comgroupsignal_R(h) = strrep(Template_Comgroupsignal_R(h),OldString,NewString);    
    
        % ComBitSize
        h = find(contains(Template_Comgroupsignal_R,'/ComBitSize</DEFINITION-REF>')) + 1;
        OldString = extractBetween(Template_Comgroupsignal_R(h),'>','<');
        NewString = ComBitSize;
        Template_Comgroupsignal_R(h) = strrep(Template_Comgroupsignal_R(h),OldString,NewString);  
    
        % ComSignalEndianness
        h = find(contains(Template_Comgroupsignal_R,'/ComSignalEndianness</DEFINITION-REF>')) + 1;
        OldString = extractBetween(Template_Comgroupsignal_R(h),'>','<');
        NewString = ComSignalEndianness;
        Template_Comgroupsignal_R(h) = strrep(Template_Comgroupsignal_R(h),OldString,NewString); 

        % ComSignalInitValue
        h = find(contains(Template_Comgroupsignal_R,'/ComSignalInitValue</DEFINITION-REF>')) + 1;
        OldString = extractBetween(Template_Comgroupsignal_R(h),'>','<');
        NewString = ComSignalInitValue;
        Template_Comgroupsignal_R(h) = strrep(Template_Comgroupsignal_R(h),OldString,NewString);

        % ComSignalType
        h = find(contains(Template_Comgroupsignal_R,'/ComSignalType</DEFINITION-REF>')) + 1;
        OldString = extractBetween(Template_Comgroupsignal_R(h),'>','<');
        NewString = ComSignalType;
        Template_Comgroupsignal_R(h) = strrep(Template_Comgroupsignal_R(h),OldString,NewString);

        % ComTimeoutSubstitutionValue
        h = find(contains(Template_Comgroupsignal_R,'/ComTimeoutSubstitutionValue</DEFINITION-REF>')) + 1;
        OldString = extractBetween(Template_Comgroupsignal_R(h),'>','<');
        NewString = ComTimeoutSubstitutionValue;
        Template_Comgroupsignal_R(h) = strrep(Template_Comgroupsignal_R(h),OldString,NewString);

        % ComTransferProperty
        h = find(contains(Template_Comgroupsignal_R,'/ComTransferProperty</DEFINITION-REF>')) + 1;
        OldString = extractBetween(Template_Comgroupsignal_R(h),'>','<');
        NewString = ComTransferProperty_Sig ;
        Template_Comgroupsignal_R(h) = strrep(Template_Comgroupsignal_R(h),OldString,NewString);

        % ComHandleId(ComGroupSignal)
        h = find(contains(Template_Comgroupsignal_R,'/ComGroupSignal/ComHandleId</DEFINITION-REF>'));
        if isempty(h) 
            OldString = extractBetween(template_ComGroupSignalHandleId(h+1),'<VALUE>','</VALUE>');
            NewString = num2str(cnt_SignalID);
            template_ComGroupSignalHandleId(h+1) = strrep(template_ComGroupSignalHandleId(h+1),OldString,NewString);
            % Add into <PARAMETER-VALUES>
            h = find(contains(Template_Comgroupsignal_R,'</PARAMETER-VALUES>'));
            Template_Comgroupsignal_R = [Template_Comgroupsignal_R(1:h-1);template_ComGroupSignalHandleId;Template_Comgroupsignal_R(h:end)];
        else
            OldString = extractBetween(Template_Comgroupsignal_R(h+1),'<VALUE>','</VALUE>');
            NewString = num2str(cnt_SignalID);
            Template_Comgroupsignal_R(h+1) = strrep(Template_Comgroupsignal_R(h+1),OldString,NewString);
        end
        cnt_SignalID = cnt_SignalID +1;

        % I-SIGNAL-I-PDU PDU MAPPING
        h = find(contains(Template_Comgroupsignal_R,'/ComSystemTemplateSystemSignalRef</DEFINITION-REF>'))+1;
        OldString = extractBetween(Template_Comgroupsignal_R(h),'DEST="I-SIGNAL-TO-I-PDU-MAPPING">','<');
        NewString = SigPDU_Name;
        Template_Comgroupsignal_R(h) = strrep(Template_Comgroupsignal_R(h),OldString,NewString);

        if k == 1
            tmpCell_Sig = Template_Comgroupsignal_R;
        else
            tmpCell_Sig = [tmpCell_Sig;Template_Comgroupsignal_R];
        end
    end

    % End add </SUB-CONTAINERS> & </ECUC-CONTAINER-VALUE>
    tmpCell_Msg = [Template_Comsigroup_R;tmpCell_Sig];
    tmpCell_Msg(end+1) = cellstr(['                  </SUB-CONTAINERS>']);
    tmpCell_Msg(end+1) = cellstr(['                </ECUC-CONTAINER-VALUE>']);

    if i == 1
        tmpCell_allRxMsg = tmpCell_Msg;
    else
        tmpCell_allRxMsg = [tmpCell_allRxMsg;tmpCell_Msg];
    end
end

%% Create ALL Tx PDU ComsignalGroup
h = find(contains(COM_arxml,'/ComSignalGroupDirection</DEFINITION-REF>'));

% Get Tx ComsignalGroup template
for i = 1:length(h)
    if contains(COM_arxml(h(i)+1),'<VALUE>SEND</VALUE>')
        ECUC_start_array = find(contains(COM_arxml,'/ComSignalGroup</DEFINITION-REF>'));
        ECUC_end_array = find(contains(COM_arxml,'</SUB-CONTAINERS>'));
        ECUC_start = max(ECUC_start_array(ECUC_start_array<h(i)))-2;
        ECUC_end = min(ECUC_end_array(ECUC_end_array>h(i)))+1;
        break
    end
end

Template_Comsigroup_P = COM_arxml(ECUC_start:ECUC_end);

% Get Tx ComGroupSignal template
h = find(contains(Template_Comsigroup_P,'<SUB-CONTAINERS>'));
ECUC_start_array = find(contains(Template_Comsigroup_P,'<ECUC-CONTAINER-VALUE>'));
ECUC_end_array = find(contains(Template_Comsigroup_P,'</ECUC-CONTAINER-VALUE>'));

ECUC_start = min(ECUC_start_array(ECUC_start_array>h));
ECUC_end = min(ECUC_end_array(ECUC_end_array>h));
Template_Comgroupsignal_P = Template_Comsigroup_P(ECUC_start:ECUC_end);

% Remove ComGroupSignal part of ComsignalGroup
SUB_start = find(contains(Template_Comsigroup_P,'<SUB-CONTAINERS>'),1,'last')+1;
SUB_end = find(contains(Template_Comsigroup_P,'</SUB-CONTAINERS>'),1,'last')+1;
Template_Comsigroup_P(SUB_start:SUB_end) = [];

% Create ComsignalGroup & ComGroupSignal
Msg_idx =  find(contains(ValueTable_P(:,1),'_SG_'));
Msg_idx(end+1) = length(ValueTable_P);

cnt_SignalID = 0;
% Create ComsignalGroup
for i = 1:length(Msg_idx)-1
    Gr_Name = ['GR' char(ValueTable_P(Msg_idx(i),1))];
    Timeout_s = char(ValueTable_P(Msg_idx(i),2));
    if str2double(Timeout_s) > 300; end

    % First_timeout_s = cellstr('0.005');
    % idx = strfind(string(Gr_Name),'_');
    % ComTimeoutNotification = [erase(char(extractBefore(Gr_Name,idx(end))),'GR') '_ComTimeoutNotification'];
    % ComNotification = [erase(char(extractBefore(Gr_Name,idx(end))),'GR') '_ComNotification'];

    if strcmp(ValueTable_P(Msg_idx(i),3),'CE')
        ComTransferProperty_Msg = cellstr('TRIGGERED_ON_CHANGE');
    elseif strcmp(ValueTable_P(Msg_idx(i),3),'Cycle')
        ComTransferProperty_Msg = cellstr('PENDING');
    elseif strcmp(ValueTable_P(Msg_idx(i),3),'Event')
        ComTransferProperty_Msg = cellstr('TRIGGERED');
    else
        error([Gr_Name ' has Unrecognized Messgae send type']);
    end
    
    idx = strfind(string(ValueTable_P(Msg_idx(i),1)),'_');
    Channel = char(extractBefore(ValueTable_P(Msg_idx(i),1),idx(1)));
    SG_Name = char(extractBefore(ValueTable_P(Msg_idx(i),1),idx(end)));
    PDU_Name = erase(SG_Name,{'SG_';'CGW_'});

    % GR Name
    h = find(contains(Template_Comsigroup_P,'<SHORT-NAME>GRCAN'),1,'first');
    OldString = extractBetween(Template_Comsigroup_P(h),'>','<');
    NewString = Gr_Name;
    Template_Comsigroup_P(h) = strrep(Template_Comsigroup_P(h),OldString,NewString);

    % ComTransferProperty
    h = find(contains(Template_Comsigroup_P,'/ComTransferProperty</DEFINITION-REF>'))+1;
    OldString = extractBetween(Template_Comsigroup_P(h),'>','<');
    NewString = ComTransferProperty_Msg;
    Template_Comsigroup_P(h) = strrep(Template_Comsigroup_P(h),OldString,NewString);

    % I-SIGNAL-I-PDU PDU MAPPING
    h = find(contains(Template_Comsigroup_P,'/ComSystemTemplateSignalGroupRef</DEFINITION-REF>'))+1;
    OldString = extractBetween(Template_Comsigroup_P(h),'DEST="I-SIGNAL-TO-I-PDU-MAPPING">','<');
    NewString = ['/' Channel '/PDU/' PDU_Name '/' SG_Name];
    Template_Comsigroup_P(h) = strrep(Template_Comsigroup_P(h),OldString,NewString);

    if i ~= length(Msg_idx)-1
        Signal_idx = Msg_idx(i)+1:Msg_idx(i+1)-1;
    else
        Signal_idx = Msg_idx(i)+1:Msg_idx(end);
    end

    % ComHandleId(ComSignalGroup)
    h = find(contains(Template_Comsigroup_P,'/ComSignalGroup/ComHandleId</DEFINITION-REF>'));
    if isempty(h) 
        OldString = extractBetween(template_ComSignalGroupHandleId(h+1),'<VALUE>','</VALUE>');
        NewString = num2str(i-1);
        template_ComSignalGroupHandleId(h+1) = strrep(template_ComSignalGroupHandleId(h+1),OldString,NewString);
        % Add into <PARAMETER-VALUES>
        h = find(contains(Template_Comsigroup_P,'</PARAMETER-VALUES>'));
        Template_Comsigroup_P = [Template_Comsigroup_P(1:h-1);template_ComSignalGroupHandleId;Template_Comsigroup_P(h:end)];
    else
        OldString = extractBetween(Template_Comsigroup_P(h+1),'<VALUE>','</VALUE>');
        NewString = num2str(i-1);
        Template_Comsigroup_P(h+1) = strrep(Template_Comsigroup_P(h+1),OldString,NewString);
    end

    % Create ComGroupSignal
    for k = 1:length(Signal_idx)
        SGr_Name = char(ValueTable_P(Signal_idx(k),1));
        ComBitSize = ValueTable_P(Signal_idx(k),5);
        Bitsize = str2double(cell2mat(ComBitSize));
        StartBit = str2double(cell2mat(ValueTable_P(Signal_idx(k),4)));
        n = floor(StartBit/8);
        m = floor((Bitsize + StartBit-1)/8) - n;

        % Cross byte ComBitPosition
        if floor((Bitsize + StartBit-1)/8) ~= n
            ComBitPosition = cellstr(string((8*(n-m)) + (Bitsize - ((8*(n+m)) - StartBit)) -1));
        else
            ComBitPosition = cellstr(string(Bitsize + StartBit -1));
        end
        
        if strcmp(ValueTable_P(Signal_idx(k),6),'BigEndian')
            ComSignalEndianness = cellstr('BIG_ENDIAN');
        else
            ComSignalEndianness = cellstr('LITTLE_ENDIAN');
        end
        ComSignalInitValue = ValueTable_P(Signal_idx(k),7);
        ComSignalType= ValueTable_P(Signal_idx(k),8);
        % ComTimeoutSubstitutionValue = ValueTable_P(Signal_idx(k),2);
        if strcmp(ComTransferProperty_Msg,'PENDING')
            ComTransferProperty_Sig  = cellstr('TRIGGERED_ON_CHANGE'); % PDU PENDING Default, cannot select Sgnal ComTransferProperty
        elseif strcmp(ValueTable_P(Signal_idx(k),3),'OnChange')
            ComTransferProperty_Sig = cellstr('TRIGGERED_ON_CHANGE');
        elseif strcmp(ValueTable_P(Signal_idx(k),3),'Cycle')
            ComTransferProperty_Sig = cellstr('PENDING');
        elseif strcmp(ValueTable_P(Signal_idx(k),3),'OnWrite')
            ComTransferProperty_Sig = cellstr('TRIGGERED');
        else
            error([ Gr_Name '::' SGr_Name ' has Unrecognized Messgae send type']);
        end
        
        idx = strfind(string(SGr_Name),'_');
        SigPDU_Name = ['/' Channel '/PDU/' PDU_Name '/' char(extractBefore(SGr_Name,idx(end)))];
    
        % SGR Name
        h = find(contains(Template_Comgroupsignal_P,'<SHORT-NAME>CAN'),1,'first');
        OldString = extractBetween(Template_Comgroupsignal_P(h),'>','<');
        NewString = SGr_Name;
        Template_Comgroupsignal_P(h) = strrep(Template_Comgroupsignal_P(h),OldString,NewString);
        
        % ComBitPosition
        h = find(contains(Template_Comgroupsignal_P,'/ComBitPosition</DEFINITION-REF>')) + 1;
        OldString = extractBetween(Template_Comgroupsignal_P(h),'>','<');
        NewString = ComBitPosition;
        Template_Comgroupsignal_P(h) = strrep(Template_Comgroupsignal_P(h),OldString,NewString);    
    
        % ComBitSize
        h = find(contains(Template_Comgroupsignal_P,'/ComBitSize</DEFINITION-REF>')) + 1;
        OldString = extractBetween(Template_Comgroupsignal_P(h),'>','<');
        NewString = ComBitSize;
        Template_Comgroupsignal_P(h) = strrep(Template_Comgroupsignal_P(h),OldString,NewString);  
    
        % ComSignalEndianness
        h = find(contains(Template_Comgroupsignal_P,'/ComSignalEndianness</DEFINITION-REF>')) + 1;
        OldString = extractBetween(Template_Comgroupsignal_P(h),'>','<');
        NewString = ComSignalEndianness;
        Template_Comgroupsignal_P(h) = strrep(Template_Comgroupsignal_P(h),OldString,NewString); 

        % ComSignalInitValue
        h = find(contains(Template_Comgroupsignal_P,'/ComSignalInitValue</DEFINITION-REF>')) + 1;
        OldString = extractBetween(Template_Comgroupsignal_P(h),'>','<');
        NewString = ComSignalInitValue;
        Template_Comgroupsignal_P(h) = strrep(Template_Comgroupsignal_P(h),OldString,NewString);

        % ComSignalType
        h = find(contains(Template_Comgroupsignal_P,'/ComSignalType</DEFINITION-REF>')) + 1;
        OldString = extractBetween(Template_Comgroupsignal_P(h),'>','<');
        NewString = ComSignalType;
        Template_Comgroupsignal_P(h) = strrep(Template_Comgroupsignal_P(h),OldString,NewString);

        % ComTransferProperty
        h = find(contains(Template_Comgroupsignal_P,'/ComTransferProperty</DEFINITION-REF>')) + 1;
        OldString = extractBetween(Template_Comgroupsignal_P(h),'>','<');
        NewString = ComTransferProperty_Sig;
        Template_Comgroupsignal_P(h) = strrep(Template_Comgroupsignal_P(h),OldString,NewString);

        % ComHandleId(ComGroupSignal)
        h = find(contains(Template_Comgroupsignal_P,'/ComGroupSignal/ComHandleId</DEFINITION-REF>'));
        if isempty(h) 
            OldString = extractBetween(template_ComGroupSignalHandleId(h+1),'<VALUE>','</VALUE>');
            NewString = num2str(cnt_SignalID);
            template_ComGroupSignalHandleId(h+1) = strrep(template_ComGroupSignalHandleId(h+1),OldString,NewString);
            % Add into <PARAMETER-VALUES>
            h = find(contains(Template_Comgroupsignal_P,'</PARAMETER-VALUES>'));
            Template_Comgroupsignal_P = [Template_Comgroupsignal_P(1:h-1);template_ComGroupSignalHandleId;Template_Comgroupsignal_P(h:end)];
        else
            OldString = extractBetween(Template_Comgroupsignal_P(h+1),'<VALUE>','</VALUE>');
            NewString = num2str(cnt_SignalID);
            Template_Comgroupsignal_P(h+1) = strrep(Template_Comgroupsignal_P(h+1),OldString,NewString);
        end
        cnt_SignalID = cnt_SignalID +1;

        % I-SIGNAL-I-PDU PDU MAPPING
        h = find(contains(Template_Comgroupsignal_P,'/ComSystemTemplateSystemSignalRef</DEFINITION-REF>'))+1;
        OldString = extractBetween(Template_Comgroupsignal_P(h),'DEST="I-SIGNAL-TO-I-PDU-MAPPING">','<');
        NewString = SigPDU_Name;
        Template_Comgroupsignal_P(h) = strrep(Template_Comgroupsignal_P(h),OldString,NewString);

        if k == 1
            tmpCell_Sig = Template_Comgroupsignal_P;
        else
            tmpCell_Sig = [tmpCell_Sig;Template_Comgroupsignal_P];
        end
    end
    
    % End add </SUB-CONTAINERS> & </ECUC-CONTAINER-VALUE>
    tmpCell_Msg = [Template_Comsigroup_P;tmpCell_Sig];
    tmpCell_Msg(end+1) = cellstr(['                  </SUB-CONTAINERS>']);
    tmpCell_Msg(end+1) = cellstr(['                </ECUC-CONTAINER-VALUE>']);

    if i == 1
        tmpCell_allTxMsg = tmpCell_Msg;
    else
        tmpCell_allTxMsg = [tmpCell_allTxMsg;tmpCell_Msg];
    end
end

% Add tmpCell_allRxMsg tmpCell_allTxMsg in ARXML cell
ECUC_start = find(contains(COM_arxml,'<SHORT-NAME>GRCAN'),1,'first')-2;
ECUC_end = find(contains(COM_arxml,'<SHORT-NAME>ComTimeBase</SHORT-NAME>'),1,'first')-1;

COM_arxml = [COM_arxml(1:ECUC_start);tmpCell_allRxMsg;tmpCell_allTxMsg;COM_arxml(ECUC_end:end)]; 

%% Create Rx Com-I-PDU
h = find(contains(COM_arxml,'/ComIPduDirection</DEFINITION-REF>'));

% Get Tx ComIPDU template
for i = 1:length(h)
    if contains(COM_arxml(h(i)+1),'<VALUE>RECEIVE</VALUE>')
        ECUC_start_array = find(contains(COM_arxml,'<ECUC-CONTAINER-VALUE>'));
        ECUC_end_array = find(contains(COM_arxml,'</SUB-CONTAINERS>'));
        ECUC_start = max(ECUC_start_array(ECUC_start_array<h(i)));
        ECUC_end = min(ECUC_end_array(ECUC_end_array>h(i)))+1;
        break
    end
end

% ComHandleId template
template_ComIPduHandleId = {}; 
template_ComIPduHandleId{1,1} = char('                    <ECUC-NUMERICAL-PARAM-VALUE>');
template_ComIPduHandleId{2,1} = char('                      <DEFINITION-REF DEST="ECUC-INTEGER-PARAM-DEF">/TS_TxDxM6I3R0/Com/ComConfig/ComIPdu/ComIPduHandleId</DEFINITION-REF>');
template_ComIPduHandleId{3,1} = char('                      <VALUE>30</VALUE>');
template_ComIPduHandleId{4,1} = char('                    </ECUC-NUMERICAL-PARAM-VALUE>');

Template_ComIPDU_R = COM_arxml(ECUC_start:ECUC_end);
Msg_idx =  find(contains(ValueTable_R(:,1),'_SG_'));
cnt_PDUID = 0;

for i = 1:length(Msg_idx)
    PD_Name = ['PD' char(erase(ValueTable_R(Msg_idx(i),1),'SG_'))];    
    idx = strfind(string(ValueTable_R(Msg_idx(i),1)),'_');
    Channel = char(extractBefore(ValueTable_R(Msg_idx(i),1),idx(1)));
    SG_Name = ['GR' char(ValueTable_R(Msg_idx(i),1))];
    ECUC_Name = char(erase(ValueTable_R(Msg_idx(i),1),'SG_'));

    % PD Name
    h = find(contains(Template_ComIPDU_R,'<SHORT-NAME>PDCAN'),1,'first');
    OldString = extractBetween(Template_ComIPDU_R(h),'>','<');
    NewString = PD_Name;
    Template_ComIPDU_R(h) = strrep(Template_ComIPDU_R(h),OldString,NewString);
    
    % ComIPduGroupRef
    h = find(contains(Template_ComIPDU_R,'/ComIPdu/ComIPduGroupRef</DEFINITION-REF>'),1,'first') + 1;
    OldString = extractBetween(Template_ComIPDU_R(h),'/Com/Com/ComConfig/','</VALUE-REF>');
    NewString = [TargetECU '_' Channel '_Rx' ];
    Template_ComIPDU_R(h) = strrep(Template_ComIPDU_R(h),OldString,NewString);

    % ComIPduSignalGroupRef
    h = find(contains(Template_ComIPDU_R,'/ComIPdu/ComIPduSignalGroupRef</DEFINITION-REF>'),1,'first') + 1;
    OldString = extractBetween(Template_ComIPDU_R(h),'/Com/Com/ComConfig/','</VALUE-REF>');
    NewString = SG_Name;
    Template_ComIPDU_R(h) = strrep(Template_ComIPDU_R(h),OldString,NewString);

    % ComPduIdRef
    h = find(contains(Template_ComIPDU_R,'/ComIPdu/ComPduIdRef</DEFINITION-REF>'),1,'first') + 1;
    OldString = extractBetween(Template_ComIPDU_R(h),'/EcuC/EcuC/EcucPduCollection/','</VALUE-REF>');
    NewString = ECUC_Name;
    Template_ComIPDU_R(h) = strrep(Template_ComIPDU_R(h),OldString,NewString);
  
    % ComHandleId(ComGroupSignal)
    h = find(contains(Template_ComIPDU_R,'/ComIPdu/ComIPduHandleId</DEFINITION-REF>'));
    if isempty(h)
        OldString = extractBetween(template_ComIPduHandleId(3),'<VALUE>','</VALUE>');
        NewString = num2str(cnt_PDUID);
        template_ComIPduHandleId(3) = strrep(template_ComIPduHandleId(3),OldString,NewString);
        % Add into <PARAMETER-VALUES>
        h = find(contains(Template_ComIPDU_R,'</PARAMETER-VALUES>'),1,'first');
        Template_ComIPDU_R = [Template_ComIPDU_R(1:h-1);template_ComIPduHandleId;Template_ComIPDU_R(h:end)];
    else
        OldString = extractBetween(Template_ComIPDU_R(h+1),'<VALUE>','</VALUE>');
        NewString = num2str(cnt_PDUID);
        Template_ComIPDU_R(h+1) = strrep(Template_ComIPDU_R(h+1),OldString,NewString);
    end
    cnt_PDUID = cnt_PDUID +1;
    
    if i == 1
        tmpCell_allRxMsg = Template_ComIPDU_R;
    else
        tmpCell_allRxMsg = [tmpCell_allRxMsg;Template_ComIPDU_R];
    end
end

%% Create Tx Com-I-PDU
h = find(contains(COM_arxml,'/ComIPduDirection</DEFINITION-REF>'));

% Get Tx ComIPDU template
for i = 1:length(h)
    if contains(COM_arxml(h(i)+1),'<VALUE>SEND</VALUE>')
        ECUC_start_array = find(contains(COM_arxml,'<ECUC-CONTAINER-VALUE>'));
        ECUC_end_array = find(contains(COM_arxml,'</SUB-CONTAINERS>'));
        ECUC_start = max(ECUC_start_array(ECUC_start_array<h(i)));
        ECUC_end = min(ECUC_end_array(ECUC_end_array>h(i)))+5;
        break
    end
end

tempcell = COM_arxml(ECUC_start:ECUC_end);

% Add ComHandleId part if don't have in ARXMl
h = contains(tempcell,'/ComIPdu/ComIPduHandleId</DEFINITION-REF>');
if ~any(h) 
    h = find(contains(tempcell,'</PARAMETER-VALUES>'));
    tempcell = [tempcell(1:h-1);template_ComIPduHandleId;tempcell(h:end)];
end

Msg_idx =  find(contains(ValueTable_P(:,1),'_SG_'));
cnt_PDUID = 0;

for i = 1:length(Msg_idx)
    if any(contains(ValueTable_P(Msg_idx(i),1),'_SG_CGW_'))
        continue
    end
    Template_ComIPDU_P = tempcell;
    PD_Name = ['PD' char(erase(ValueTable_P(Msg_idx(i),1),'SG_'))];
    TimePeriod = char(ValueTable_P(Msg_idx(i),4));

    if strcmp(ValueTable_P(Msg_idx(i),3),'CE')
        ComTxModeMode = cellstr('MIXED');
        ComTxModeNumberOfRepetitions = '0';
    elseif strcmp(ValueTable_P(Msg_idx(i),3),'Cycle')
        ComTxModeMode = cellstr('PERIODIC');
        ComTxModeNumberOfRepetitions = '1';
    elseif strcmp(ValueTable_P(Msg_idx(i),3),'Event')
        ComTxModeMode = cellstr('DIRECT');
        ComTxModeNumberOfRepetitions = '0';
    else
        error([PD_Name ' has Unrecognized Messgae send type']);
    end
    
    idx = strfind(string(ValueTable_P(Msg_idx(i),1)),'_');
    Channel = char(extractBefore(ValueTable_P(Msg_idx(i),1),idx(1)));
    SG_Name = ['GR' char(ValueTable_P(Msg_idx(i),1))];
    ECUC_Name = char(erase(ValueTable_P(Msg_idx(i),1),'SG_'));

    % PD Name
    h = find(contains(Template_ComIPDU_P,'<SHORT-NAME>PDCAN'),1,'first');
    OldString = extractBetween(Template_ComIPDU_P(h),'>','<');
    NewString = PD_Name;
    Template_ComIPDU_P(h) = strrep(Template_ComIPDU_P(h),OldString,NewString);
    
    % ComIPduGroupRef
    h = find(contains(Template_ComIPDU_P,'/ComIPdu/ComIPduGroupRef</DEFINITION-REF>'),1,'first') + 1;
    OldString = extractBetween(Template_ComIPDU_P(h),'/Com/Com/ComConfig/','</VALUE-REF>');
    NewString = [TargetECU '_' Channel '_Tx' ];
    Template_ComIPDU_P(h) = strrep(Template_ComIPDU_P(h),OldString,NewString);

    % ComIPduSignalGroupRef
    h = find(contains(Template_ComIPDU_P,'/ComIPdu/ComIPduSignalGroupRef</DEFINITION-REF>'),1,'first') + 1;
    OldString = extractBetween(Template_ComIPDU_P(h),'/Com/Com/ComConfig/','</VALUE-REF>');
    NewString = SG_Name;
    Template_ComIPDU_P(h) = strrep(Template_ComIPDU_P(h),OldString,NewString);

    if sum(strcmp(erase(ValueTable_P(Msg_idx),'_CGW'),ValueTable_P(Msg_idx(i),1))) == 2 % For CGW I Signal Group Ref to PDU
        h = find(strcmp(erase(ValueTable_P(Msg_idx),'_CGW'),ValueTable_P(Msg_idx(i),1)));
        h = setdiff(h, i);
        CGW_SGName = ['GR' char(ValueTable_P(Msg_idx(h),1))];
        % ComIPduSignalGroupRef
        Raw_start = find(contains(Template_ComIPDU_P,'/ComIPdu/ComIPduSignalGroupRef</DEFINITION-REF>'),1,'first')- 1;
        Raw_end = Raw_start+3;
        CGW_tempcell =  Template_ComIPDU_P(Raw_start:Raw_end);
        
        h = find(contains(CGW_tempcell,'/ComIPdu/ComIPduSignalGroupRef</DEFINITION-REF>'),1,'first') + 1;
        OldString = extractBetween(CGW_tempcell(h),'/Com/Com/ComConfig/','</VALUE-REF>');
        NewString = CGW_SGName;
        CGW_tempcell(h) = strrep(CGW_tempcell(h),OldString,NewString);

        Template_ComIPDU_P = [Template_ComIPDU_P(1:Raw_end);CGW_tempcell;Template_ComIPDU_P(Raw_end+1:end)];
    end

    % ComPduIdRef
    h = find(contains(Template_ComIPDU_P,'/ComIPdu/ComPduIdRef</DEFINITION-REF>'),1,'first') + 1;
    OldString = extractBetween(Template_ComIPDU_P(h),'/EcuC/EcuC/EcucPduCollection/','</VALUE-REF>');
    NewString = ECUC_Name;
    Template_ComIPDU_P(h) = strrep(Template_ComIPDU_P(h),OldString,NewString);

    % ComTxModeMode
    h = find(contains(Template_ComIPDU_P,'/ComTxMode/ComTxModeMode</DEFINITION-REF>'),1,'first') + 1;
    OldString = extractBetween(Template_ComIPDU_P(h),'>','<');
    NewString = ComTxModeMode;
    Template_ComIPDU_P(h) = strrep(Template_ComIPDU_P(h),OldString,NewString);
    
    % ComTxModeNumberOfRepetitions
    h = find(contains(Template_ComIPDU_P,'/ComTxMode/ComTxModeNumberOfRepetitions</DEFINITION-REF>'),1,'first') + 1;
    OldString = extractBetween(Template_ComIPDU_P(h),'>','<');
    NewString = ComTxModeNumberOfRepetitions;
    Template_ComIPDU_P(h) = strrep(Template_ComIPDU_P(h),OldString,NewString);

    % ComTxModeTimePeriod
    h = find(contains(Template_ComIPDU_P,'/ComTxMode/ComTxModeTimePeriod</DEFINITION-REF>'),1,'first') + 1;
    OldString = extractBetween(Template_ComIPDU_P(h),'>','<');
    if rem(str2double(TimePeriod),1) == 0 % For integer, 1 -> 1.0
        TimePeriod = [TimePeriod '.0'];
    end
    NewString = TimePeriod;
    Template_ComIPDU_P(h) = strrep(Template_ComIPDU_P(h),OldString,NewString);

    % ComHandleId(ComGroupSignal)
    h = find(contains(Template_ComIPDU_P,'/ComIPdu/ComIPduHandleId</DEFINITION-REF>'));
    OldString = extractBetween(Template_ComIPDU_P(h+1),'<VALUE>','</VALUE>');
    NewString = num2str(cnt_PDUID);
    Template_ComIPDU_P(h+1) = strrep(Template_ComIPDU_P(h+1),OldString,NewString);

    cnt_PDUID = cnt_PDUID +1;
    
    if i == 1
        tmpCell_allTxMsg = Template_ComIPDU_P;
    else
        tmpCell_allTxMsg = [tmpCell_allTxMsg;Template_ComIPDU_P];
    end
end

% Add tmpCell_allRxMsg tmpCell_allTxMsg in ARXML cell
ECUC_start = find(contains(COM_arxml,'<SHORT-NAME>PDCAN'),1,'first')-2;
ECUC_end = find(contains(COM_arxml,'<SHORT-NAME>GRCAN'),1,'first')-1;

COM_arxml = [COM_arxml(1:ECUC_start);tmpCell_allRxMsg;tmpCell_allTxMsg;COM_arxml(ECUC_end:end)];

%% Enable ComSignalGwEnable
h = find(contains(COM_arxml,'ComSignalGwEnable</DEFINITION-REF>'));
OldString = extractBetween(COM_arxml(h+1),'<VALUE>','</VALUE>');
NewString = '1';
COM_arxml(h+1) = strrep(COM_arxml(h+1),OldString,NewString);

%% Output COM_arxml
cd([project_path '/documents/ARXML_splitconfig'])
fileID = fopen('ComSettings.arxml','w');
for i = 1:length(COM_arxml(:,1))
    fprintf(fileID,'%s\n',char(COM_arxml(i,1)));
end
fclose(fileID);
end