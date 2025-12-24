function Gen_System(Channel_list,MsgLinkFileName,TargetECU,DBCSet,Channel_list_LIN,LDFSet,RoutingTable)
project_path = pwd;
ScriptVersion = '2024.06.13';

%% Define target ECU name
if strcmp(TargetECU,'FUSION'); TargetECU_Abb = 'FDC'; end
if strcmp(TargetECU,'ZONE_DR'); TargetECU_Abb = 'ZONE_DR'; end
if strcmp(TargetECU,'ZONE_FR'); TargetECU_Abb = 'ZONE_FR'; end

%% Get all CAN PDUs from source arxml

Fcnt = 0;
FrameCell = {};
Icnt = 0;
IPDUCell = {};
Ncnt = 0;
NPDUCell = {};
DCMcnt = 0;
DCMIPDUCell = {};
SGcnt = 0;
SGCell = {};
Scnt = 0;
SignalCell = {};
Nmcnt = 0;
NmPDUCell = {};
DTcnt = 0;
DTCell = {};
Channel_list_all = union(Channel_list,Channel_list_LIN);

for i = 1:length(Channel_list_all)
    Channel = char(Channel_list_all(i));
    cd([project_path '/documents/ARXML_output'])
    fileID = fopen([Channel '.arxml']);
    Source_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
    tmpCell = cell(length(Source_arxml{1,1}),1);
    for j = 1:length(Source_arxml{1,1})
        tmpCell{j,1} = Source_arxml{1,1}{j,1};
    end
    Source_arxml = tmpCell;

    for k = 1:length(Source_arxml)
        if strcmp(strip(char(Source_arxml(k)),'left'),'<CAN-FRAME>') ||...
                strcmp(strip(char(Source_arxml(k)),'left'),'<LIN-UNCONDITIONAL-FRAME>')
            Fcnt = Fcnt + 1;
            FrameCell(Fcnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
        elseif strcmp(strip(char(Source_arxml(k)),'left'),'<I-SIGNAL-I-PDU>')
            Icnt = Icnt + 1;
            IPDUCell(Icnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
        elseif strcmp(strip(char(Source_arxml(k)),'left'),'<N-PDU>')
            Ncnt = Ncnt + 1;
            NPDUCell(Ncnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
        elseif strcmp(strip(char(Source_arxml(k)),'left'),'<DCM-I-PDU>')
            DCMcnt = DCMcnt + 1;
            DCMIPDUCell(DCMcnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
        elseif strcmp(strip(char(Source_arxml(k)),'left'),'<I-SIGNAL-GROUP>')
            SGcnt = SGcnt + 1;
            SGCell(SGcnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
        elseif strcmp(strip(char(Source_arxml(k)),'left'),'<I-SIGNAL>')
            Scnt = Scnt + 1;
            SignalCell(Scnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
        elseif strcmp(strip(char(Source_arxml(k)),'left'),'<NM-PDU>')
            Nmcnt = Nmcnt + 1;
            NmPDUCell(Nmcnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
        elseif contains(Source_arxml(k),['<SHORT-NAME>DT_' Channel '_'])
            DTName = char(extractBetween(Source_arxml(k),'>','<'));
            Raw_start = k;
            Raw_end = k + find(contains(Source_arxml(k:end),'</IMPLEMENTATION-DATA-TYPE>'),1,"first") -1;
            tmpCell = Source_arxml(Raw_start:Raw_end);

            idx = find(contains(tmpCell,'<IMPLEMENTATION-DATA-TYPE-ELEMENT>'));
            for n = 1:length(idx)
                DTcnt = DTcnt + 1;
                ElementName = char(extractBetween(tmpCell(idx(n)+1),'>','<'));
                DTCell(DTcnt,1) = cellstr(DTName);
                DTCell(DTcnt,2) = cellstr(ElementName);
            end
        else
            continue
        end
    end
    fclose(fileID);
    cd(project_path);
end

FrameCell = categories(categorical(FrameCell));
IPDUCell = categories(categorical(IPDUCell));
NPDUCell = categories(categorical(NPDUCell));

%% Get R and P ports for each SWC
% For main SWC
cnt = 0;
Port_SWC = {};

cd([project_path '/documents/ARXML_output'])
fileID = fopen('SWC_FDC.arxml');
Source_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Source_arxml{1,1}),1);
for j = 1:length(Source_arxml{1,1})
    tmpCell{j,1} = Source_arxml{1,1}{j,1};
end

% Remove Admin data
Source_arxml = tmpCell;
if any(find(contains(Source_arxml,'<ADMIN-DATA>')))
    h = find(contains(Source_arxml,'<ADMIN-DATA>'));
    for i = 1:length(h)
        Raw_start = find(contains(Source_arxml,'<ADMIN-DATA>'),1,'first');
        Raw_end = find(contains(Source_arxml,'</ADMIN-DATA>'),1,'first');
        Source_arxml(Raw_start:Raw_end) = [];
    end
end


for k = 1:length(Source_arxml)
    if (strcmp(strip(char(Source_arxml(k)),'left'),'<R-PORT-PROTOTYPE>') ||...
            strcmp(strip(char(Source_arxml(k)),'left'),'<P-PORT-PROTOTYPE>')) && contains(Source_arxml(k+2),'CANInterface_ARPkg')
        cnt = cnt + 1;
        Port_SWC(cnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
        Port_SWC(cnt,2) = cellstr([char(extractBetween(Source_arxml(k+2),'>' ,'<')) '/' char(extractBetween(Source_arxml(k+2),'/IF_' ,'<'))]);
        Port_SWC(cnt,3) = cellstr(['/' char(extractBetween(Source_arxml(k+2),'IF_' ,'_')) '/SignalGroup/' char(extractBetween(Source_arxml(k+2),'/IF_' ,'<'))]);
    end
end

% For SWC_CGW
cnt = 0;
Port_SWC_CGW = {};

cd([project_path '/documents/ARXML_output'])
fileID = fopen('SWC_CGW.arxml');
Source_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Source_arxml{1,1}),1);
for j = 1:length(Source_arxml{1,1})
    tmpCell{j,1} = Source_arxml{1,1}{j,1};
end
Source_arxml = tmpCell;
for k = 1:length(Source_arxml)
    if (strcmp(strip(char(Source_arxml(k)),'left'),'<R-PORT-PROTOTYPE>') ||...
            strcmp(strip(char(Source_arxml(k)),'left'),'<P-PORT-PROTOTYPE>')) && contains(Source_arxml(k+2),'CANInterface_ARPkg')
        cnt = cnt + 1;
        Port_SWC_CGW(cnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
        Port_SWC_CGW(cnt,2) = cellstr([char(extractBetween(Source_arxml(k+2),'>' ,'<')) '/' char(extractBetween(Source_arxml(k+2),'/IF_' ,'<'))]);
        Port_SWC_CGW(cnt,3) = cellstr(['/' char(extractBetween(Source_arxml(k+2),'IF_' ,'_')) '/SignalGroup/' char(extractBetween(Source_arxml(k+2),'/IF_' ,'<'))]);
    end
end


%% Get all LIN signals from source arxml

Scnt = 0;
S_SignalCell_LIN = {};
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

    for k = 1:length(Source_arxml)
        if contains(Source_arxml(k),'<IMPLEMENTATION-DATA-TYPE-ELEMENT>')
            Scnt = Scnt + 1;
            S_SignalCell_LIN(Scnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
        else
            continue
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

%% Modify ECU instance Fibex elements

h = contains(Target_arxml(:,1),'<FIBEX-ELEMENT-REF DEST="ECU-INSTANCE">');
OldString = char(extractBetween(Target_arxml(h),'>','<'));
NewString = ['/ECU/' TargetECU];
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString); % /ECU/FUSION

%% Add gateway fibex element
% Return <FIBEX-ELEMENT-REF-CONDITIONAL>
Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL'),1,'first') + 1;
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENTS>'),1,'first') - 1;
Target_arxml(Raw_start:Raw_end) = [];

Raw_start = find(contains(Target_arxml,'<FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);
tmpCell = Template; % initialize tmpCell

h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
OldString = extractBetween(tmpCell(h),'"','"');
NewString = 'GATEWAY';
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="GATEWAY"

OldString = extractBetween(tmpCell(h),'>','<');
NewString = ['/Gateway/Gateway_' TargetECU];
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Gateway/Gateway_ZONE_DR

Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
Raw_end = Raw_start + 1;
Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];

%% Add NM fibex element
for i = 1:length(Channel_list)
Channel = char(Channel_list(i));
if strcmp(Channel,'CAN1') || strcmp(Channel,'CAN7')
    continue
end
Raw_start = find(contains(Target_arxml,'<FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);
tmpCell = Template; % initialize tmpCell

h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
OldString = extractBetween(tmpCell(h),'"','"');
NewString = 'NM-CONFIG';
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="NM-CONFIG"

OldString = extractBetween(tmpCell(h),'>','<');
NewString = ['/NmConfig_' Channel '/NmConfig_' Channel];
tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /NmConfig_CAN4/NmConfig_CAN4

Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
Raw_end = Raw_start + 1;
Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end

%% Add NmPDUCell element
Raw_start = find(contains(Target_arxml,'<FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:length(NmPDUCell)
    tmpCell = Template; % initialize tmpCell
    Channel = extractBefore(char(NmPDUCell(i)),'_');
    NmName = char(NmPDUCell(i));
    
    % CAN-FRAME
    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'CAN-FRAME';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="I-SIGNAL-I-PDU-GROUP"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/Frame/' NmName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /PduGroups/ZONE_DR_CAN4_Tx

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    
    % NM-PDU
    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'NM-PDU';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="I-SIGNAL-I-PDU-GROUP"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/PDU/' NmName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /PduGroups/ZONE_DR_CAN4_Tx

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end

%% Add PDU group fibex element
Raw_start = find(contains(Target_arxml,'<FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:length(PDUGroupCell)
    tmpCell = Template; % initialize tmpCell
    PDUGroupName = char(PDUGroupCell(i));

    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'I-SIGNAL-I-PDU-GROUP';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="I-SIGNAL-I-PDU-GROUP"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/PduGroups/' PDUGroupName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /PduGroups/ZONE_DR_CAN4_Tx

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end

%% Add cluster fibex element
Raw_start = find(contains(Target_arxml,'<FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:length(Channel_list_all)
    tmpCell = Template; % initialize tmpCell
    Channel = char(Channel_list_all(i));
    if contains(Channel,'CAN')
        CLUSTER = 'CAN-CLUSTER';
    elseif contains(Channel,'LIN')
        CLUSTER = 'LIN-CLUSTER';
    end

    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = CLUSTER;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="CAN-CLUSTER"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/Cluster/' Channel];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/Cluster/CAN1

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end

%% Add CAN/LIN frame fibex element
Raw_start = find(contains(Target_arxml,'<FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:length(FrameCell)
    tmpCell = Template; % initialize tmpCell
    if strcmp(char(FrameCell(i)),'MasterReq') || strcmp(char(FrameCell(i)),'SlaveResp')
        continue
    end

    Channel = extractBefore(char(FrameCell(i)),'_');

    if startsWith(char(FrameCell(i)),'CAN')
        FRAME = 'CAN-FRAME';
    elseif startsWith(char(FrameCell(i)),'LIN')
        FRAME = 'LIN-UNCONDITIONAL-FRAME';
    end

    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = FRAME;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="CAN-FRAME"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/Frame/' char(FrameCell(i))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANDr1/Frame/CANDr1_zGW_ESC1

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end

% Add MasterReq and SlaveResp
for i = 1:length(Channel_list_LIN)
    tmpCell = Template; % initialize tmpCell
    Channel = char(Channel_list_LIN(i));

    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'LIN-UNCONDITIONAL-FRAME';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="CAN-FRAME"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/Frame/MasterReq'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/Frame/SlaveResp'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end

%% Add CAN/LIN I-PDU fibex element
Raw_start = find(contains(Target_arxml,'<FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:length(IPDUCell)
    tmpCell = Template; % initialize tmpCell
    Channel = extractBefore(char(IPDUCell(i)),'_');

    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'I-SIGNAL-I-PDU';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="I-SIGNAL-I-PDU"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/PDU/' char(IPDUCell(i))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANDr1/Frame/CANDr1_zGW_ESC1

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end

%% Add CAN/LIN N-PDU fibex element
Raw_start = find(contains(Target_arxml,'<FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:length(NPDUCell)
    tmpCell = Template; % initialize tmpCell
    if strcmp(char(NPDUCell(i)),'MasterReq') || strcmp(char(NPDUCell(i)),'SlaveResp')
        continue
    end
    Channel = extractBefore(char(NPDUCell(i)),'_');

    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'N-PDU';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="N-PDU"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/PDU/' char(NPDUCell(i))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANDr1/Frame/CANDr1_zGW_ESC1

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end

% Add MasterReq and SlaveResp
for i = 1:length(Channel_list_LIN)
    tmpCell = Template; % initialize tmpCell
    Channel = char(Channel_list_LIN(i));

    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'N-PDU';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="CAN-FRAME"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/PDU/MasterReq'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/PDU/SlaveResp'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end

%% Add CAN DCM-I-PDU fibex element
Raw_start = find(contains(Target_arxml,'<FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:length(DCMIPDUCell)
    tmpCell = Template; % initialize tmpCell
    Channel = extractBefore(char(DCMIPDUCell(i)),'_');

    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'DCM-I-PDU';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="DCM-I-PDU"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/PDU/' char(DCMIPDUCell(i))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANDr1/Frame/CANDr1_zGW_ESC1

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end

%% Add I-SIGNAL-GROUP fibex element
Raw_start = find(contains(Target_arxml,'<FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:length(SGCell)
    tmpCell = Template; % initialize tmpCell
    Channel = extractBefore(char(SGCell(i)),'_');

    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'I-SIGNAL-GROUP';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="DCM-I-PDU"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/ISignalGroup/' char(SGCell(i))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANDr1/Frame/CANDr1_zGW_ESC1

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end

%% Add I-SIGNAL fibex element
Raw_start = find(contains(Target_arxml,'<FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Raw_end = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:length(SignalCell)
    tmpCell = Template; % initialize tmpCell
    Channel = extractBefore(char(SignalCell(i)),'_');

    h = find(contains(tmpCell,'<FIBEX-ELEMENT-REF DEST='));
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = 'I-SIGNAL';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % DEST="DCM-I-PDU"

    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' Channel '/ISignal/' char(SignalCell(i))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANDr1/Frame/CANDr1_zGW_ESC1

    Raw_start = find(contains(Target_arxml,'</FIBEX-ELEMENT-REF-CONDITIONAL>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end

%% Modify SWC system mapping
% SWC will not change everytime, maintain SWC mppings in template.

%% Modify Signal mapping for main SWC
% Return SignalMappings
Raw_start = find(contains(Target_arxml,'</SYSTEM-MAPPING>'),1,'first') + 2;
Raw_end = find(contains(Target_arxml,'</SYSTEM-MAPPING>'),1,'last') - 1;
Target_arxml(Raw_start:Raw_end) = [];

Raw_start = find(contains(Template_arxml,'<SYSTEM-MAPPING>'),1,'last');
Raw_end = find(contains(Template_arxml,'</SYSTEM-MAPPING>'),1,'last');
Template = Template_arxml(Raw_start:Raw_end);
FirstMessage = boolean(1);

for i = 1:length(Port_SWC(:,1))
    if strcmp(char(Port_SWC(i,1)),'R_HALINCDD') || strcmp(char(Port_SWC(i,1)),'R_HALOUTCDD')
        continue;
    end

    tmpCell = Template; % initialize tmpCell

    if startsWith(char(Port_SWC(i,1)),'R_')
        Direction = 'IN';
        Porttype = 'R-PORT-PROTOTYPE';
    elseif startsWith(char(Port_SWC(i,1)),'P_')
        Direction = 'OUT';
        Porttype = 'P-PORT-PROTOTYPE';
    end


    h = find(contains(tmpCell,'<SHORT-NAME>SignalMappings</SHORT-NAME>'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['MAP_' char(Port_SWC(i,1))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>MAP_R_CAN4_FCM1</SHORT-NAME>

    h = find(contains(tmpCell,'<COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = Direction;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>

    h = find(contains(tmpCell,'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/Comp_' TargetECU_Abb '_ARPkg/Comp_' TargetECU_Abb '_main/SWC_' TargetECU_Abb];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_FDC

    h = find(contains(tmpCell,'<CONTEXT-COMPOSITION-REF DEST="ROOT-SW-COMPOSITION-PROTOTYPE">'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/SysEnv_ARPkg/System_' TargetECU_Abb '/root_' TargetECU_Abb];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SysEnv_ARPkg/System_FDC/root_FDC

    h = find(contains(tmpCell,'<CONTEXT-PORT-REF DEST="P-PORT-PROTOTYPE">'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/SWC_' TargetECU_Abb '_ARPkg/SWC_' TargetECU_Abb '_type/' char(Port_SWC(i,1))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_FDC_ARPkg/SWC_FDC_type/P_CAN1_FD_BCM1

    h = find(contains(tmpCell,'<CONTEXT-PORT-REF DEST="P-PORT-PROTOTYPE">'),1,'first');
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = Porttype;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <CONTEXT-PORT-REF DEST="R-PORT-PROTOTYPE">

    h = find(contains(tmpCell,'<TARGET-DATA-PROTOTYPE-REF DEST="VARIABLE-DATA-PROTOTYPE">'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = char(Port_SWC(i,2));
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /HALInterface_ARPkg/IF_CAN1_SG_FD_BCM1/CAN1_SG_FD_BCM1

    h = find(contains(tmpCell,'<SIGNAL-GROUP-REF DEST="SYSTEM-SIGNAL-GROUP">'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = char(Port_SWC(i,3));
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/SignalGroup/CAN1_SG_FD_BCM1

    idx_DTCell = find(strcmp(extractAfter(DTCell(:,1),'DT_'),char(extractAfter(Port_SWC(i,3),'SignalGroup/'))));
    FirstSignal = boolean(1);
    for m = 1:length(idx_DTCell)
        Raw_start = find(contains(Template,'<SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'first');
        Raw_end = find(contains(Template,'</SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'first');
        tmpCell2 = Template(Raw_start:Raw_end); % initialize tmpCell2

        h = find(contains(tmpCell2,'<IMPLEMENTATION-RECORD-ELEMENT-REF DEST="IMPLEMENTATION-DATA-TYPE-ELEMENT">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' char(extractBefore(DTCell(idx_DTCell(m),2),'_')) '/ImplementationDataTypes/' char(DTCell(idx_DTCell(m),1)) '/' char(DTCell(idx_DTCell(m),2))];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/ImplementationDataTypes/DT_CAN1_SG_FD_BCM1/CAN1_AllDoorSW

        h = find(contains(tmpCell2,'<SYSTEM-SIGNAL-REF DEST="SYSTEM-SIGNAL">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' char(extractBefore(DTCell(idx_DTCell(m),2),'_')) '/Signal/' char(DTCell(idx_DTCell(m),2))];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/Signal/CAN1_AllDoorSW

        if FirstSignal % to replace original part
            Raw_start = find(contains(Template,'<SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'first');
            Raw_end = find(contains(Template,'</SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'first');
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
            FirstSignal = boolean(0);
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

%% Modify Signal mapping for SWC_CGW
% Template reused
FirstMessage = boolean(1);

for i = 1:length(Port_SWC_CGW(:,1))
    if strcmp(char(Port_SWC_CGW(i,1)),'R_HALINCDD') || strcmp(char(Port_SWC_CGW(i,1)),'R_HALOUTCDD')...
            || strcmp(char(Port_SWC_CGW(i,1)),'R_ExtTrig_CGW')
        continue;
    end

    tmpCell = Template; % initialize tmpCell

    if startsWith(char(Port_SWC_CGW(i,1)),'R_')
        Direction = 'IN';
        Porttype = 'R-PORT-PROTOTYPE';
    elseif startsWith(char(Port_SWC_CGW(i,1)),'P_')
        Direction = 'OUT';
        Porttype = 'P-PORT-PROTOTYPE';
    end

    h = find(contains(tmpCell,'<SHORT-NAME>SignalMappings</SHORT-NAME>'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['MAP_CGW_' char(Port_SWC_CGW(i,1))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>MAP_R_CAN4_FCM1</SHORT-NAME>

    h = find(contains(tmpCell,'<COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = Direction;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <COMMUNICATION-DIRECTION>OUT</COMMUNICATION-DIRECTION>

    h = find(contains(tmpCell,'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/Comp_' TargetECU_Abb '_ARPkg/Comp_' TargetECU_Abb '_main/SWC_CGW'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_FDC

    h = find(contains(tmpCell,'<CONTEXT-COMPOSITION-REF DEST="ROOT-SW-COMPOSITION-PROTOTYPE">'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/SysEnv_ARPkg/System_' TargetECU_Abb '/root_' TargetECU_Abb];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SysEnv_ARPkg/System_FDC/root_FDC

    h = find(contains(tmpCell,'<CONTEXT-PORT-REF DEST="P-PORT-PROTOTYPE">'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/SWC_CGW_ARPkg/SWC_CGW_type/' char(Port_SWC_CGW(i,1))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_FDC_ARPkg/SWC_FDC_type/P_CAN1_FD_BCM1

    h = find(contains(tmpCell,'<CONTEXT-PORT-REF DEST="P-PORT-PROTOTYPE">'),1,'first');
    OldString = extractBetween(tmpCell(h),'"','"');
    NewString = Porttype;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <CONTEXT-PORT-REF DEST="R-PORT-PROTOTYPE">

    h = find(contains(tmpCell,'<TARGET-DATA-PROTOTYPE-REF DEST="VARIABLE-DATA-PROTOTYPE">'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = char(Port_SWC_CGW(i,2));
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /HALInterface_ARPkg/IF_CAN1_SG_FD_BCM1/CAN1_SG_FD_BCM1

    h = find(contains(tmpCell,'<SIGNAL-GROUP-REF DEST="SYSTEM-SIGNAL-GROUP">'),1,'first');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = char(Port_SWC_CGW(i,3));
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/SignalGroup/CAN1_SG_FD_BCM1

    idx_DTCell = find(contains(DTCell(:,1),char(extractAfter(Port_SWC_CGW(i,3),'SignalGroup/'))));
    FirstSignal = boolean(1);
    for m = 1:length(idx_DTCell)
        Raw_start = find(contains(Template,'<SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'first');
        Raw_end = find(contains(Template,'</SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'first');
        tmpCell2 = Template(Raw_start:Raw_end); % initialize tmpCell2

        h = find(contains(tmpCell2,'<IMPLEMENTATION-RECORD-ELEMENT-REF DEST="IMPLEMENTATION-DATA-TYPE-ELEMENT">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' char(extractBefore(DTCell(idx_DTCell(m),2),'_')) '/ImplementationDataTypes/' char(DTCell(idx_DTCell(m),1)) '/' char(DTCell(idx_DTCell(m),2))];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/ImplementationDataTypes/DT_CAN1_SG_FD_BCM1/CAN1_AllDoorSW

        h = find(contains(tmpCell2,'<SYSTEM-SIGNAL-REF DEST="SYSTEM-SIGNAL">'));
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' char(extractBefore(DTCell(idx_DTCell(m),2),'_')) '/Signal/' char(DTCell(idx_DTCell(m),2))];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/Signal/CAN1_AllDoorSW

        if FirstSignal % to replace original part
            Raw_start = find(contains(Template,'<SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'first');
            Raw_end = find(contains(Template,'</SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'first');
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
            FirstSignal = boolean(0);
        else % too add new part
            Raw_start = find(contains(Template,'</SENDER-REC-RECORD-ELEMENT-MAPPING>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    if FirstMessage % to replace original part
        Raw_start = find(contains(Target_arxml,'</SYSTEM-MAPPING>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
        FirstMessage = boolean(0);
    else % too add new part
        Raw_start = find(contains(Target_arxml,'</SYSTEM-MAPPING>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end
%% Modify root software composition
% Will not change everytime, maintain mppings in template.

%% Modify flat map
% Will not change everytime, maintain mppings in template.

%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen('System.arxml','w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);
end