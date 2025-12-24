function Gen_ECUInstance(Channel_list,MsgLinkFileName,TargetECU,DBCSet,Channel_list_LIN,LDFSet)
project_path = pwd;
ScriptVersion = '2024.06.03';

%% Get informations from source arxml

Fcnt = 0;
FPortCell = {};
Pcnt = 0;
PDUPortCell = {};
Scnt = 0;
SPortCell = {};

% Get CAN related info
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

    % Get all frame ports
    for k = 1:length(Source_arxml)
        if contains(Source_arxml(k),[TargetECU '/Conn' Channel '/FP_' Channel])
            Fcnt = Fcnt + 1;
            FPortCell(Fcnt,1) = extractBetween(Source_arxml(k),['/Conn' Channel '/'],'</FRAME-PORT-REF>');
        elseif contains(Source_arxml(k),[TargetECU '/Conn' Channel '/PP_' Channel])
            Pcnt = Pcnt + 1;
            PDUPortCell(Pcnt,1) = extractBetween(Source_arxml(k),['/Conn' Channel '/'],'</I-PDU-PORT-REF>');
        elseif contains(Source_arxml(k),[TargetECU '/Conn' Channel '/SP_' Channel])
            Scnt = Scnt + 1;
            SPortCell(Scnt,1) = extractBetween(Source_arxml(k),['/Conn' Channel '/'],'</I-SIGNAL-PORT-REF>');
        end
    end
    fclose(fileID);
    cd(project_path);
end

% Get LIN related info
for i = 1:length(Channel_list_LIN)
    Channel = char(Channel_list_LIN(i));
    cd([project_path '/documents/ARXML_output'])
    fileID = fopen([Channel '.arxml']);
    Source_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
    tmpCell = cell(length(Source_arxml{1,1}),1);
    for j = 1:length(Source_arxml{1,1})
        tmpCell{j,1} = Source_arxml{1,1}{j,1};
    end
    Source_arxml = tmpCell;

    % Get all frame ports
    for k = 1:length(Source_arxml)
        if contains(Source_arxml(k),[TargetECU '/Conn' Channel '/FP_' Channel])
            Fcnt = Fcnt + 1;
            FPortCell(Fcnt,1) = extractBetween(Source_arxml(k),['/Conn' Channel '/'],'</FRAME-PORT-REF>');
        elseif contains(Source_arxml(k),[TargetECU '/Conn' Channel '/PP_' Channel])
            Pcnt = Pcnt + 1;
            PDUPortCell(Pcnt,1) = extractBetween(Source_arxml(k),['/Conn' Channel '/'],'</I-PDU-PORT-REF>');
        elseif contains(Source_arxml(k),[TargetECU '/Conn' Channel '/SP_' Channel])
            Scnt = Scnt + 1;
            SPortCell(Scnt,1) = extractBetween(Source_arxml(k),['/Conn' Channel '/'],'</I-SIGNAL-PORT-REF>');
        end
    end
    fclose(fileID);
    cd(project_path);
end

%% Get PDU groups
cd([project_path '/documents/ARXML_output'])
fileID = fopen('PDUGroup.arxml');
Source_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Source_arxml{1,1}),1);
for j = 1:length(Source_arxml{1,1})
    tmpCell{j,1} = Source_arxml{1,1}{j,1};
end
Source_arxml = tmpCell;

cnt = 0;
PDUGroupCell = {};
for i = 1:length(Source_arxml)

    if strcmp(char(extractBetween(Source_arxml(i),'<','>')),'I-SIGNAL-I-PDU-GROUP')
        cnt = cnt + 1;
        PDUGroupCell(cnt,1) = extractBetween(Source_arxml(i+1),'>','<'); % ZONE_FR_LINFr1_Tx
    end
end

fclose(fileID);
cd(project_path);

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
for i = 1:length(PDUGroupCell)
    PDUGroupName = char(PDUGroupCell(i));

    h = find(contains(Target_arxml,'<ASSOCIATED-COM-I-PDU-GROUP-REF DEST="I-SIGNAL-I-PDU-GROUP">'),1,'first');
    tmpCell = Target_arxml(h);
    OldString = char(extractBetween(tmpCell,'>','<'));
    NewString = ['/PduGroups/' PDUGroupName];
    tmpCell = strrep(tmpCell,OldString,NewString); % /PduGroups/FUSION_CAN3_Tx

    if i == 1 % to replase original part
        Target_arxml(h) = tmpCell;

    else % to add new part
        Raw_start = find(contains(Target_arxml,'<ASSOCIATED-COM-I-PDU-GROUP-REF DEST="I-SIGNAL-I-PDU-GROUP">'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell;Target_arxml(Raw_end:end)];
    end
end

%% Modify COMM-CONTROLLERS part

% COMM-CONTROLLER for CAN
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

% COMM-CONTROLLER for LIN
Raw_start = find(contains(Target_arxml,'<LIN-MASTER>'),1,'first');
Raw_end = find(contains(Target_arxml,'</LIN-MASTER>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:length(Channel_list_LIN)
    Channel = char(Channel_list_LIN(i));
    LDF = LDFSet{i};

    tmpCell = Template;
    h = contains(tmpCell,'<SHORT-NAME>LINChannelName</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = Channel;
    tmpCell = strrep(tmpCell,OldString,NewString); % <SHORT-NAME>LINDr1</SHORT-NAME>

    for k = 1:length(LDF.SlaveNodes)

        Raw_start = find(contains(tmpCell,'<LIN-SLAVE-CONFIG>'),1,'first');
        Raw_end = find(contains(tmpCell,'</LIN-SLAVE-CONFIG>'),1,'first');
        tmpCell2 = tmpCell(Raw_start:Raw_end);

        h = contains(tmpCell2,'<CONFIGURED-NAD>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = char(LDF.SlaveNodes(k).Configured_NAD);
        tmpCell2 = strrep(tmpCell2,OldString,NewString);% <CONFIGURED-NAD>2</CONFIGURED-NAD>

        h = contains(tmpCell2,'<FUNCTION-ID>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = char(LDF.SlaveNodes(k).Function_ID);
        tmpCell2 = strrep(tmpCell2,OldString,NewString); % <FUNCTION-ID>0</FUNCTION-ID>

        h = contains(tmpCell2,'<SHORT-NAME>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = char(LDF.SlaveNodes(k).Name);
        tmpCell2 = strrep(tmpCell2,OldString,NewString); % <SHORT-NAME>SlaveNodeName</SHORT-NAME>

        h = contains(tmpCell2,'<SUPPLIER-ID>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = char(LDF.SlaveNodes(k).Supplier_ID);
        tmpCell2 = strrep(tmpCell2,OldString,NewString); % <SUPPLIER-ID>0</SUPPLIER-ID>

        h = contains(tmpCell2,'<VARIANT-ID>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = char(LDF.SlaveNodes(k).Variant_ID);
        tmpCell2 = strrep(tmpCell2,OldString,NewString); % <VARIANT-ID>0</VARIANT-ID>

        if k == 1 % to replace original part
            Raw_start = find(contains(tmpCell,'<LIN-SLAVE-CONFIG>'),1,'first');
            Raw_end = find(contains(tmpCell,'</LIN-SLAVE-CONFIG>'),1,'first');
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];

        else % to add new part
            Raw_start = find(contains(tmpCell,'</LIN-SLAVE-CONFIG>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    if i == 1 % to replace original part
        Raw_start = find(contains(Target_arxml,'<LIN-MASTER>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</LIN-MASTER>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];

    else % to add new part
        Raw_start = find(contains(Target_arxml,'</LIN-MASTER>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

%% Modify CAN CONNECTORS part
Raw_start = find(contains(Target_arxml,'<CAN-COMMUNICATION-CONNECTOR>'),1,'first');
Raw_end = find(contains(Target_arxml,'</CAN-COMMUNICATION-CONNECTOR>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

Raw_start = find(contains(Template,'<I-PDU-PORT>'),1,'first');
Raw_end = find(contains(Template,'</I-PDU-PORT>'),1,'first');
Template_PDUPort = Template(Raw_start:Raw_end);

Raw_start = find(contains(Template,'<FRAME-PORT>'),1,'first');
Raw_end = find(contains(Template,'</FRAME-PORT>'),1,'first');
Template_FPort = Template(Raw_start:Raw_end);

Raw_start = find(contains(Template,'<I-SIGNAL-PORT>'),1,'first');
Raw_end = find(contains(Template,'</I-SIGNAL-PORT>'),1,'first');
Template_SPort = Template(Raw_start:Raw_end);

FirstChannel = boolean(1);

for i = 1:length(Channel_list)
    Channel = char(Channel_list(i));
    tmpCell = Template; % initialize tmpCell

    h = contains(tmpCell,'<SHORT-NAME>CANCommunicationConnector</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['Conn' Channel];
    tmpCell = strrep(tmpCell,OldString,NewString); % <SHORT-NAME>CAN1</SHORT-NAME>

    h = contains(tmpCell,'<COMM-CONTROLLER-REF DEST="CAN-COMMUNICATION-CONTROLLER">');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['/ECU/' TargetECU '/' Channel];
    tmpCell = strrep(tmpCell,OldString,NewString); % /ECU/FUSION/CAN1

    % Add PDU port part
    FirstInd = boolean(1);
    for k = 1:length(PDUPortCell)
        if ~strcmp(Channel,extractBetween(char(PDUPortCell(k)),'PP_','_'))
            continue
        end

        tmpCell2 = Template_PDUPort;

        h = contains(tmpCell2,'<SHORT-NAME>PDUPort</SHORT-NAME>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = char(PDUPortCell(k));
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>PP_CAN1_ABM1_IN</SHORT-NAME>

        if endsWith(char(PDUPortCell(k)),'_IN')
            Direction = 'IN';
        else
            Direction = 'OUT';
        end

        h = find(contains(tmpCell2,'<COMMUNICATION-DIRECTION>'));
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = Direction;
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>

        if FirstInd
            Raw_start = find(contains(tmpCell,'<I-PDU-PORT>'),1,'first');
            Raw_end = find(contains(tmpCell,'</I-PDU-PORT>'),1,'first');
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
            FirstInd = boolean(0);
        else
            Raw_start = find(contains(tmpCell,'</I-PDU-PORT>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    % Add Frame port part
    FirstInd = boolean(1);
    for k = 1:length(FPortCell)
        if ~strcmp(Channel,extractBetween(char(FPortCell(k)),'FP_','_'))
            continue
        end

        tmpCell2 = Template_FPort;

        h = contains(tmpCell2,'<SHORT-NAME>FramePort</SHORT-NAME>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = char(FPortCell(k));
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>PP_CAN1_ABM1_IN</SHORT-NAME>

        if endsWith(char(FPortCell(k)),'_IN')
            Direction = 'IN';
        else
            Direction = 'OUT';
        end

        h = find(contains(tmpCell2,'<COMMUNICATION-DIRECTION>'));
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = Direction;
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>

        if FirstInd
            Raw_start = find(contains(tmpCell,'<FRAME-PORT>'),1,'first');
            Raw_end = find(contains(tmpCell,'</FRAME-PORT>'),1,'first');
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
            FirstInd = boolean(0);
        else
            Raw_start = find(contains(tmpCell,'</FRAME-PORT>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    % Add signal port part
    FirstInd = boolean(1);
    for k = 1:length(SPortCell)
        if ~strcmp(Channel,extractBetween(char(SPortCell(k)),'SP_','_'))
            continue
        end

        tmpCell2 = Template_SPort;

        h = contains(tmpCell2,'<SHORT-NAME>SignalPort</SHORT-NAME>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = char(SPortCell(k));
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>PP_CAN1_ABM1_IN</SHORT-NAME>

        if endsWith(char(SPortCell(k)),'_IN')
            Direction = 'IN';
        else
            Direction = 'OUT';
        end

        h = find(contains(tmpCell2,'<COMMUNICATION-DIRECTION>'));
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = Direction;
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>

        if FirstInd
            Raw_start = find(contains(tmpCell,'<I-SIGNAL-PORT>'),1,'first');
            Raw_end = find(contains(tmpCell,'</I-SIGNAL-PORT>'),1,'first');
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
            FirstInd = boolean(0);
        else
            Raw_start = find(contains(tmpCell,'</I-SIGNAL-PORT>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    if FirstChannel % to replace original part
        Raw_start = find(contains(Target_arxml,'<CAN-COMMUNICATION-CONNECTOR>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</CAN-COMMUNICATION-CONNECTOR>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
        FirstChannel = boolean(0);
    else
        Raw_start = find(contains(Target_arxml,'</CAN-COMMUNICATION-CONNECTOR>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end    
end

%% Modify LIN CONNECTORS part
Raw_start = find(contains(Target_arxml,'<LIN-COMMUNICATION-CONNECTOR>'),1,'first');
Raw_end = find(contains(Target_arxml,'</LIN-COMMUNICATION-CONNECTOR>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

Raw_start = find(contains(Template,'<I-PDU-PORT>'),1,'first');
Raw_end = find(contains(Template,'</I-PDU-PORT>'),1,'first');
Template_PDUPort = Template(Raw_start:Raw_end);

Raw_start = find(contains(Template,'<FRAME-PORT>'),1,'first');
Raw_end = find(contains(Template,'</FRAME-PORT>'),1,'first');
Template_FPort = Template(Raw_start:Raw_end);

Raw_start = find(contains(Template,'<I-SIGNAL-PORT>'),1,'first');
Raw_end = find(contains(Template,'</I-SIGNAL-PORT>'),1,'first');
Template_SPort = Template(Raw_start:Raw_end);

FirstChannel = boolean(1);
for i = 1:length(Channel_list_LIN)
    Channel = char(Channel_list_LIN(i));
    tmpCell = Template;

    h = contains(tmpCell,'<SHORT-NAME>LINCommunicationConnector</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['Conn' Channel];
    tmpCell = strrep(tmpCell,OldString,NewString); % <SHORT-NAME>ConnLINDr1</SHORT-NAME>

    h = contains(tmpCell,'<COMM-CONTROLLER-REF DEST="LIN-MASTER">');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['/ECU/' TargetECU '/' Channel];
    tmpCell = strrep(tmpCell,OldString,NewString); % /ECU/ZONE_DR/LINDr1

    % Add PDU port part
    FirstInd = boolean(1);
    for k = 1:length(PDUPortCell)
        if ~strcmp(Channel,extractBetween(char(PDUPortCell(k)),'PP_','_'))
            continue
        end

        tmpCell2 = Template_PDUPort;

        h = contains(tmpCell2,'<SHORT-NAME>PDUPort</SHORT-NAME>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = char(PDUPortCell(k));
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>PP_CAN1_ABM1_IN</SHORT-NAME>

        if endsWith(char(PDUPortCell(k)),'_IN')
            Direction = 'IN';
        else
            Direction = 'OUT';
        end

        h = find(contains(tmpCell2,'<COMMUNICATION-DIRECTION>'));
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = Direction;
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>

        if FirstInd
            Raw_start = find(contains(tmpCell,'<I-PDU-PORT>'),1,'first');
            Raw_end = find(contains(tmpCell,'</I-PDU-PORT>'),1,'first');
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
            FirstInd = boolean(0);
        else
            Raw_start = find(contains(tmpCell,'</I-PDU-PORT>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    % Add Frame port part
    FirstInd = boolean(1);
    for k = 1:length(FPortCell)
        if ~strcmp(Channel,extractBetween(char(FPortCell(k)),'FP_','_'))
            continue
        end

        tmpCell2 = Template_FPort;

        h = contains(tmpCell2,'<SHORT-NAME>FramePort</SHORT-NAME>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = char(FPortCell(k));
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>PP_CAN1_ABM1_IN</SHORT-NAME>

        if endsWith(char(FPortCell(k)),'_IN')
            Direction = 'IN';
        else
            Direction = 'OUT';
        end

        h = find(contains(tmpCell2,'<COMMUNICATION-DIRECTION>'));
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = Direction;
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>

        if FirstInd
            Raw_start = find(contains(tmpCell,'<FRAME-PORT>'),1,'first');
            Raw_end = find(contains(tmpCell,'</FRAME-PORT>'),1,'first');
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
            FirstInd = boolean(0);
        else
            Raw_start = find(contains(tmpCell,'</FRAME-PORT>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    % Add signal port part
    FirstInd = boolean(1);
    for k = 1:length(SPortCell)
        if ~strcmp(Channel,extractBetween(char(SPortCell(k)),'SP_','_'))
            continue
        end

        tmpCell2 = Template_SPort;

        h = contains(tmpCell2,'<SHORT-NAME>SignalPort</SHORT-NAME>');
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = char(SPortCell(k));
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>PP_CAN1_ABM1_IN</SHORT-NAME>

        if endsWith(char(SPortCell(k)),'_IN')
            Direction = 'IN';
        else
            Direction = 'OUT';
        end

        h = find(contains(tmpCell2,'<COMMUNICATION-DIRECTION>'));
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = Direction;
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>

        if FirstInd
            Raw_start = find(contains(tmpCell,'<I-SIGNAL-PORT>'),1,'first');
            Raw_end = find(contains(tmpCell,'</I-SIGNAL-PORT>'),1,'first');
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
            FirstInd = boolean(0);
        else
            Raw_start = find(contains(tmpCell,'</I-SIGNAL-PORT>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    if FirstChannel % to replace original part
        Raw_start = find(contains(Target_arxml,'<LIN-COMMUNICATION-CONNECTOR>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</LIN-COMMUNICATION-CONNECTOR>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
        FirstChannel = boolean(0);
    else
        Raw_start = find(contains(Target_arxml,'</LIN-COMMUNICATION-CONNECTOR>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

%% Delete LIN description
if isempty(Channel_list_LIN)
Raw_start = find(contains(Target_arxml,'<LIN-COMMUNICATION-CONNECTOR>'));
Raw_end = find(contains(Target_arxml,'</LIN-COMMUNICATION-CONNECTOR>'));
Target_arxml(Raw_start:Raw_end) = [];

Raw_start = find(contains(Target_arxml,'<LIN-MASTER>'));
Raw_end = find(contains(Target_arxml,'</LIN-MASTER>'));
Target_arxml(Raw_start:Raw_end) = [];
end

%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen( 'ECUInstance.arxml','w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);


end