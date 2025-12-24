function Gen_System(Channel_list,MsgLinkFileName,TargetECU,DBCSet)
project_path = pwd;
ScriptVersion = '2024.05.15';

%% Define target ECU name
if strcmp(TargetECU,'FUSION'); TargetECU_Abb = 'FDC'; end

%% Read messageLink
cd([project_path '/documents/MessageLink']);
MessageLink_Rx = readcell(MsgLinkFileName,'Sheet','InputSignal');
MessageLink_Tx = readcell(MsgLinkFileName,'Sheet','OutputSignal');

%% Get APP related messages
% Signal routing Rx messages will be defined in MsgLink, but Tx not.
% To do: Need to read routing table Tx signal routing messages and 
% define P_Port in SWC.
Tx_Messages = {};
Rx_Messages = {};
cntR = 0;
cntT = 0;
for k = 1:length(Channel_list)
    Channel = char(Channel_list(k));
    tmpCell = MessageLink_Rx(strcmp(MessageLink_Rx(:,strcmp(MessageLink_Rx(1,:),'CANChannel')),Channel),strcmp(MessageLink_Rx(1,:),'MessageName'));
    Rx_MsgLink = categories(categorical(tmpCell));
    for i = 1:length(Rx_MsgLink)
        cntR = cntR + 1;
        Rx_Messages{cntR,1} = [Channel '_' char(Rx_MsgLink(i))];
    end

    tmpCell = MessageLink_Tx(2:end,strcmp(MessageLink_Tx(1,:),Channel));
    tmpCell(cellfun(@(x) all(ismissing(x)), tmpCell)) = [];
    Tx_MsgLink = categories(categorical(tmpCell));
    for i = 1:length(Tx_MsgLink)
        cntT = cntT + 1;
        Tx_Messages{cntT,1} = [Channel '_' char(Tx_MsgLink(i))];
    end
end
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
            Channel_IPDUCell(Icnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
        elseif contains(Source_arxml(k),'<N-PDU>')
            Ncnt = Ncnt + 1;
            Channel_NPDUCell(Ncnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
        else
            continue
        end
    end
    fclose(fileID);
    cd(project_path);
end

%% Edit admin data
% get System_Template
fileID = fopen('System_Template.arxml');
Template_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Template_arxml{1,1}),1);
for i = 1:length(Template_arxml{1,1})
    tmpCell{i,1} = Template_arxml{1,1}{i,1};
end
Template_arxml = tmpCell;

% get System_ARXML
cd([project_path '/documents/ARXML_output'])
fileID = fopen('System.arxml');
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
OldString = char(extractBetween(Target_arxml(h),'>','<'));
NewString = MsgLinkFileName;
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString); % <SD GID="InputFile_Msglink">CAN_MessageLinkOut</SD>

% erase previous DBC
h = find(contains(Target_arxml,'<SD GID="InputFile_DBC_CAN1">'));
OldString = char(extractBetween(Target_arxml(h),'<','<'));
NewString = 'SD GID="InputFile_DBC">dbc';
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString);

h = contains(Target_arxml,'<SD GID="InputFile_DBC_CAN');
Target_arxml(h) = [];


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
        tmpCell = strrep(tmpCell,OldString,NewString); % <SD GID="InputFile_DBC_CAN3">D31_ET_V13_CAN3_FUSION_20230421_Fix.dbc</SD>
        Raw_start = find(contains(Target_arxml,'<SD GID="InputFile_DBC'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell;Target_arxml(Raw_end:end)];
    end
end

%% Modify System name
% Return System name
h = find(contains(Target_arxml(:,1),'<SHORT-NAME>System'),1,'first');
OldString = char(extractBetween(Target_arxml(h),'>','<'));
NewString = ['SystemName'];
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString);

h = contains(Target_arxml(:,1),'<SHORT-NAME>SystemName</SHORT-NAME>');
OldString = char(extractBetween(Target_arxml(h),'>','<'));
NewString = ['System_' TargetECU_Abb];
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString); % <SHORT-NAME>System_FDC</SHORT-NAME>

%% Modify Fibex elements
% Return <FIBEX-ELEMENT-REF-CONDITIONAL>
Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL'),1,'first') + 1;
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENTS>'),1,'first') - 1;
Target_arxml(Raw_start:Raw_end) = [];

Raw_start = find(contains(Target_arxml,'<FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

% Edit ECU-instance
h = contains(Target_arxml(:,1),'<FIBEX-ELEMENT-REF DEST="ECU-INSTANCE">');
OldString = char(extractBetween(Target_arxml(h),'>','<'));
NewString = ['/ECU/' TargetECU];
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString); % /ECU/FUSION

% Edit CAN cluster fibex element
for i = 1:length(Channel_list)
    tmpCell = Template; % initialize tmpCell
    Channel = char(Channel_list(i));
    DBC= DBCSet(i);

    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'CAN-CLUSTER';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="CAN-CLUSTER"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/Cluster/' Channel];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/Cluster/CAN1

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];

    % Edit PDU group fibex element
    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'I-SIGNAL-I-PDU-GROUP';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="CAN-CLUSTER"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/PduGroups/' TargetECU '_' Channel '_Tx'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /PduGroups/ZONE_DR_CAN4_Tx

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];

    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'I-SIGNAL-I-PDU-GROUP';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="CAN-CLUSTER"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/PduGroups/' TargetECU '_' Channel '_Rx'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /PduGroups/ZONE_DR_CAN4_Rx

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];

    for k = 1:length(DBC.Messages)
        MsgName = char(DBC.MessageInfo(k).Name);

        % Message judgement, ignore messages not in CANx.arxml
        if all(~strcmp([Channel '_' MsgName],Channel_IPDUCell)) && all(~strcmp([Channel '_' MsgName],Channel_NPDUCell))
            continue
        end

        tmpCell = Template; % initialize tmpCell        

        if startsWith(MsgName,'NMm_')
            MsgType = 'NM-PDU';
        elseif startsWith(MsgName,'Diag')
            MsgType = 'N-PDU';
        else
            MsgType = 'I-SIGNAL-I-PDU';
        end

        % Add CAN-FRAME fibex element
        h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
        OldString = extractBetween(tmpCell(h),'"','"');
        NewString = 'CAN-FRAME';
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="CAN-FRAME"

        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/' Channel '/Frame/' Channel '_' MsgName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/Frame/CAN1_ABM1

        Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];

        % Add PDU fibex element
        h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
        OldString = extractBetween(tmpCell(h),'"','"');
        NewString = MsgType;
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="I-SIGNAL-I-PDU"

        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/' Channel '/PDU/' Channel '_' MsgName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/PDU/CAN1_ABM1

        Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];

        % Add signal group fibex element
        if strcmp(MsgType,'I-SIGNAL-I-PDU')

            h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
            OldString = extractBetween(tmpCell(h),'"','"');
            NewString = 'I-SIGNAL-GROUP';
            tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="I-SIGNAL-GROUP"

            OldString = extractBetween(tmpCell(h),'>','<');
            NewString = ['/' Channel '/ISignalGroup/' Channel '_SG_' MsgName];
            tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/ISignalGroup/CAN1_SG_ABM1

            Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
            Raw_end = Raw_start + 1;
            Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        end

        % Add I-SIGNAL fibex element
        if strcmp(MsgType,'I-SIGNAL-I-PDU') || strcmp(MsgType,'NM-PDU')
            for n = 1:length(DBC.MessageInfo(k).Signals)
                SignalName = char(DBC.MessageInfo(k).Signals(n));

                h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
                OldString = extractBetween(tmpCell(h),'"','"');
                NewString = 'I-SIGNAL';
                tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="I-SIGNAL"

                OldString = extractBetween(tmpCell(h),'>','<');
                NewString = ['/' Channel '/ISignal/' Channel '_' SignalName];
                tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/ISignal/CAN1_AirBagFailCmd

                Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
                Raw_end = Raw_start + 1;
                Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
            end
        end
    end
end

%% Modify SWC system mapping
% SWC will not change everytime, maintain SWC mppings in template.

%% Modify Signal mapping
% Return SignalMappings
Raw_start = find(contains(Target_arxml,'</SYSTEM-MAPPING>'),1,'first') + 2;
Raw_end = find(contains(Target_arxml,'</SYSTEM-MAPPING>'),1,'last') - 1;
Target_arxml(Raw_start:Raw_end) = [];

% Get template part
Raw_start = find(contains(Template_arxml,'<SYSTEM-MAPPING>'),1,'last');
Raw_end = find(contains(Template_arxml,'</SYSTEM-MAPPING>'),1,'last');
Template = Template_arxml(Raw_start:Raw_end);
FirstMessage = boolean(1);

for i = 1:length(Channel_list)
    Channel = char(Channel_list(i));
    DBC= DBCSet(i);

    for k = 1:length(DBC.Messages)
        MsgName = char(DBC.MessageInfo(k).Name);

        % Message judgement, ignore messages not on MessageLinkOut
        % Currently signal routing implemented in APP, so APP need to Rx
        % and Tx all messages in CANx.arxml, independent from MsgLink
        if (all(~strcmp([Channel '_' MsgName],Tx_Messages)) && all(~strcmp([Channel '_' MsgName],Rx_Messages)))...
                || startsWith(MsgName,'XNMm')
            continue
        end

        if strcmp(DBC.MessageInfo(k).TxNodes,TargetECU)
            Direction = 'OUT';
        else
            Direction = 'IN';
        end

        tmpCell = Template; % initialize tmpCell

        h = find(contains(tmpCell,'<SHORT-NAME>SignalMappings</SHORT-NAME>'),1,'first');
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['MAP_' Channel '_' MsgName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>

        h = find(contains(tmpCell,'<COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>'),1,'first');
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = Direction;
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>

        if contains(MsgName,'_OTA1')
            h = find(contains(tmpCell,'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'),1,'first');
            OldString = extractBetween(tmpCell(h),'>','<');
            NewString = ['/Comp_' TargetECU_Abb '_ARPkg/Comp_' TargetECU_Abb '_main/SWC_VES'];
            tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_VES

        else
            h = find(contains(tmpCell,'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'),1,'first');
            OldString = extractBetween(tmpCell(h),'>','<');
            NewString = ['/Comp_' TargetECU_Abb '_ARPkg/Comp_' TargetECU_Abb '_main/SWC_' TargetECU_Abb];
            tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_FDC
        end

        h = find(contains(tmpCell,'<CONTEXT-COMPOSITION-REF DEST="ROOT-SW-COMPOSITION-PROTOTYPE">'),1,'first');
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/SysEnv_ARPkg/System_' TargetECU_Abb '/root_' TargetECU_Abb];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SysEnv_ARPkg/System_FDC/root_FDC

        if strcmp(Direction,'OUT')
            if contains(MsgName,'_OTA1')
                h = find(contains(tmpCell,'<CONTEXT-PORT-REF DEST="P-PORT-PROTOTYPE">'),1,'first');
                OldString = extractBetween(tmpCell(h),'>','<');
                NewString = ['/SWC_VES_ARPkg/SWC_VES_type/P_' Channel '_' MsgName];
                tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_VES_ARPkg/SWC_VES_type/P_CAN2_FD_OTA1

            else
                h = find(contains(tmpCell,'<CONTEXT-PORT-REF DEST="P-PORT-PROTOTYPE">'),1,'first');
                OldString = extractBetween(tmpCell(h),'>','<');
                NewString = ['/SWC_' TargetECU_Abb '_ARPkg/SWC_' TargetECU_Abb '_type/P_' Channel '_' MsgName];
                tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_FDC_ARPkg/SWC_FDC_type/P_CAN1_FD_BCM1
            end

            h = find(contains(tmpCell,'<CONTEXT-PORT-REF DEST="P-PORT-PROTOTYPE">'),1,'first');
            OldString = extractBetween(tmpCell(h),'"','"');
            NewString = 'P-PORT-PROTOTYPE';
            tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <CONTEXT-PORT-REF DEST="P-PORT-PROTOTYPE">
        else
            h = find(contains(tmpCell,'<CONTEXT-PORT-REF DEST="P-PORT-PROTOTYPE">'),1,'first');
            OldString = extractBetween(tmpCell(h),'>','<');
            NewString = ['/SWC_' TargetECU_Abb '_ARPkg/SWC_' TargetECU_Abb '_type/R_' Channel '_' MsgName];
            tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_FDC_ARPkg/SWC_FDC_type/R_CAN1_FD_BCM1

            h = find(contains(tmpCell,'<CONTEXT-PORT-REF DEST="P-PORT-PROTOTYPE">'),1,'first');
            OldString = extractBetween(tmpCell(h),'"','"');
            NewString = 'R-PORT-PROTOTYPE';
            tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <CONTEXT-PORT-REF DEST="R-PORT-PROTOTYPE">
        end

        h = find(contains(tmpCell,'<TARGET-DATA-PROTOTYPE-REF DEST="VARIABLE-DATA-PROTOTYPE">'),1,'first');
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/CANInterface_ARPkg/IF_' Channel '_SG_' MsgName '/' Channel '_SG_' MsgName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_FD_BCM1/CAN1_SG_FD_BCM1

        h = find(contains(tmpCell,'<SIGNAL-GROUP-REF DEST="SYSTEM-SIGNAL-GROUP">'),1,'first');
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/' Channel '/SignalGroup/' Channel '_SG_' MsgName];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/SignalGroup/CAN1_SG_FD_BCM1

        for m = 1:length(DBC.MessageInfo(k).Signals)
            SignalName = char(DBC.MessageInfo(k).Signals(m));
            Raw_start = find(contains(Template,'<SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'first');
            Raw_end = find(contains(Template,'</SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'first');
            tmpCell2 = Template(Raw_start:Raw_end); % initialize tmpCell2

            h = find(contains(tmpCell2,'<IMPLEMENTATION-RECORD-ELEMENT-REF DEST="IMPLEMENTATION-DATA-TYPE-ELEMENT">'));
            OldString = extractBetween(tmpCell2(h),'>','<');
            NewString = ['/' Channel '/ImplementationDataTypes/DT_' Channel '_SG_' MsgName '/' Channel '_' SignalName];
            tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/ImplementationDataTypes/DT_CAN1_SG_FD_BCM1/CAN1_AllDoorSW

            h = find(contains(tmpCell2,'<SYSTEM-SIGNAL-REF DEST="SYSTEM-SIGNAL">'));
            OldString = extractBetween(tmpCell2(h),'>','<');
            NewString = ['/' Channel '/Signal/' Channel '_' SignalName];
            tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/Signal/CAN1_AllDoorSW

            if m == 1 % to replace original part
                Raw_start = find(contains(Template,'<SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'first');
                Raw_end = find(contains(Template,'</SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'first');
                tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
            else % too add new part
                Raw_start = find(contains(Template,'</SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'last');
                Raw_end = Raw_start + 1;
                tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
            end
        end

        if FirstMessage % to replace original part
            Raw_start = find(contains(Target_arxml,'<SYSTEM-MAPPING>'),1,'last');
            Raw_end = find(contains(Target_arxml,'</SYSTEM-MAPPING>'),1,'last');
            Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
            FirstMessage = boolean(0);
        else % too add new part
            Raw_start = find(contains(Target_arxml,'</SYSTEM-MAPPING>'),1,'last');
            Raw_end = Raw_start + 1;
            Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        end
    end
end

%% Modify root software composition
% Get template part
Raw_start = find(contains(Template_arxml,'<ROOT-SOFTWARE-COMPOSITIONS>'));
Raw_end = find(contains(Template_arxml,'</ROOT-SOFTWARE-COMPOSITIONS>'));
tmpCell = Template_arxml(Raw_start:Raw_end);

Raw_start = find(contains(Target_arxml,'<ROOT-SOFTWARE-COMPOSITIONS>'));
Raw_end = find(contains(Target_arxml,'</ROOT-SOFTWARE-COMPOSITIONS>'));

h = find(contains(tmpCell,'<SHORT-NAME>RootComositionPrototypeName</SHORT-NAME>'));
OldString = extractBetween(tmpCell(h),'>','<');
NewString = ['root_' TargetECU_Abb];
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>root_FDC</SHORT-NAME>

h = find(contains(tmpCell,'<FLAT-MAP-REF DEST="FLAT-MAP">'));
OldString = extractBetween(tmpCell(h),'>','<');
NewString = ['/SysEnv_ARPkg/root_' TargetECU_Abb '_FlatMap'];
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SysEnv_ARPkg/root_FDC_FlatMap

h = find(contains(tmpCell,'<SOFTWARE-COMPOSITION-TREF DEST="COMPOSITION-SW-COMPONENT-TYPE">'));
OldString = extractBetween(tmpCell(h),'>','<');
NewString = ['/Comp_' TargetECU_Abb '_ARPkg/Comp_' TargetECU_Abb '_main'];
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main

Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];

%% Modify flat map
% Get template part
Raw_start = find(contains(Template_arxml,'<FLAT-MAP>'));
Raw_end = find(contains(Template_arxml,'</FLAT-MAP>'));
tmpCell = Template_arxml(Raw_start:Raw_end);

Raw_start = find(contains(Target_arxml,'<FLAT-MAP>'));
Raw_end = find(contains(Target_arxml,'</FLAT-MAP>'));

h = find(contains(tmpCell,'<SHORT-NAME>FlatMapName</SHORT-NAME>'));
OldString = extractBetween(tmpCell(h),'>','<');
NewString = ['root_' TargetECU_Abb '_FlatMap'];
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>root_FDC_FlatMap</SHORT-NAME>

h = find(contains(tmpCell,'<SHORT-NAME>FlatInstanceName</SHORT-NAME>'));
OldString = extractBetween(tmpCell(h),'>','<');
NewString = ['FlatIns_' TargetECU_Abb];
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>FlatIns_FDC</SHORT-NAME>

h = find(contains(tmpCell,'<CONTEXT-ELEMENT-REF DEST="ROOT-SW-COMPOSITION-PROTOTYPE">'),1,'first');
OldString = extractBetween(tmpCell(h),'>','<');
NewString = ['/SysEnv_ARPkg/System_' TargetECU_Abb '/root_' TargetECU_Abb];
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SysEnv_ARPkg/System_FDC/root_FDC

h = find(contains(tmpCell,'<CONTEXT-ELEMENT-REF DEST="ROOT-SW-COMPOSITION-PROTOTYPE">'),1,'last');
OldString = extractBetween(tmpCell(h),'>','<');
NewString = ['/SysEnv_ARPkg/System_' TargetECU_Abb '/root_' TargetECU_Abb];
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SysEnv_ARPkg/System_FDC/root_FDC

h = find(contains(tmpCell,'<TARGET-REF DEST="SW-COMPONENT-PROTOTYPE">'),1,'first');
OldString = extractBetween(tmpCell(h),'>','<');
NewString = ['/Comp_' TargetECU_Abb '_ARPkg/Comp_' TargetECU_Abb '_main/SWC_' TargetECU_Abb];
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_FDC

h = find(contains(tmpCell,'<TARGET-REF DEST="SW-COMPONENT-PROTOTYPE">'),1,'last');
OldString = extractBetween(tmpCell(h),'>','<');
NewString = ['/Comp_' TargetECU_Abb '_ARPkg/Comp_' TargetECU_Abb '_main/SWC_' TargetECU_Abb];
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_FDC

Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];

%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen('System.arxml','w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);
end