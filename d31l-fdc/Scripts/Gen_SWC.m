function Gen_SWC(Channel_list,MsgLinkFileName,TargetECU,DBCSet)
project_path = pwd;
ScriptVersion = '2024.05.15';

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

TargetECU = 'FDC';

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
% get SWC_FDC_ORIGINAL
cd([project_path '/documents/ARXML_output'])
fileID = fopen('SWC_FDC.arxml');
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
h = contains(Target_arxml(:,1),'<SD GID="InputFile">');
tmpCell = Target_arxml(h);
OldString = char(extractBetween(tmpCell,'>','<'));
NewString = MsgLinkFileName;
Target_arxml(h) = strrep(tmpCell,OldString,NewString); % <SD GID="InputFile">CAN_MessageLinkOut</SD>

%% Modify ports

% Remove all P_CANxxxxx
P_CAN_Raw_start = find(contains(Target_arxml,'<SHORT-NAME>P_CAN'),1,'first');
P_CAN_Raw_end = find(contains(Target_arxml,'<SHORT-NAME>P_CAN'),1,'last');
Target_arxml(P_CAN_Raw_start-1:P_CAN_Raw_end+2) = [];

% P-Ports
Raw_start = find(contains(Target_arxml,'<P-PORT-PROTOTYPE>'),1,'first');
Raw_end = find(contains(Target_arxml,'</P-PORT-PROTOTYPE>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for k = 1:length(Tx_Messages)
    tmpCell = Template; % initialize tmpCell
    Channel = char(extractBefore(Tx_Messages(k),'_'));
    MsgName = char(extractAfter(Tx_Messages(k),'_'));

    % Ignore OTA ports
    if contains(MsgName,'_OTA1')
        continue
    end

    h = contains(tmpCell(:,1),'<SHORT-NAME>P_AppModeReq</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['P_' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>P_CAN1_FD_APS1</SHORT-NAME>

    h = contains(tmpCell(:,1),'<PROVIDED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['/CANInterface_ARPkg/IF_' Channel '_SG_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_FD_APS1


    % Write P-PORTS into target arxml
    Raw_start = find(contains(Target_arxml,'</P-PORT-PROTOTYPE>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];

end


% Remove all R_CANxxxxx
R_CAN_Raw_start = find(contains(Target_arxml,'<SHORT-NAME>R_CAN'),1,'first');
R_CAN_Raw_end = find(contains(Target_arxml,'<SHORT-NAME>R_CAN'),1,'last');
Target_arxml(R_CAN_Raw_start-1:R_CAN_Raw_end+2) = [];


% R-Ports
Raw_start = find(contains(Target_arxml,'<R-PORT-PROTOTYPE>'),1,'first');
Raw_end = find(contains(Target_arxml,'</R-PORT-PROTOTYPE>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for k = 1:length(Rx_Messages)
    tmpCell = Template; % initialize tmpCell
    Channel = char(extractBefore(Rx_Messages(k),'_'));
    MsgName = char(extractAfter(Rx_Messages(k),'_'));

    h = contains(tmpCell(:,1),'<SHORT-NAME>R_E2E_CAN3_VCU1</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['R_' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>R_CAN1_FCM3</SHORT-NAME>

    h = contains(tmpCell(:,1),'<REQUIRED-INTERFACE-TREF DEST="CLIENT-SERVER-INTERFACE">');
    OldString = char(extractBetween(tmpCell(h),'REQUIRED-INTERFACE-TREF DEST="','">'));
    NewString = 'SENDER-RECEIVER-INTERFACE';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <REQUIRED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['/CANInterface_ARPkg/IF_' Channel '_SG_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_FCM3


    % Write R-PORTS into target arxml
    Raw_start = find(contains(Target_arxml,'</R-PORT-PROTOTYPE>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end

%% Modify IRV
% Remove all IRV_msxxxxx
Raw_start = find(contains(Target_arxml,'<EXPLICIT-INTER-RUNNABLE-VARIABLES>'));
Raw_end = find(contains(Target_arxml,'</EXPLICIT-INTER-RUNNABLE-VARIABLES>'));
IRV_CAN_Raw_start = Raw_start-1 + find(contains(Target_arxml(Raw_start:Raw_end),'<SHORT-NAME>IRV_ms'),1,'first');
IRV_CAN_Raw_end = Raw_start-1 + find(contains(Target_arxml(Raw_start:Raw_end),'<SHORT-NAME>IRV_ms'),1,'last');
Target_arxml(IRV_CAN_Raw_start-1:IRV_CAN_Raw_end+2) = [];

%% Modify run_SWC_FDC_Tx RUNNABLE-ENTITY
Runnable_numb = sum(contains(Target_arxml,'<SHORT-NAME>run_SWC_FDC_Tx'));
Runnable_idx = find(contains(Target_arxml,'<SHORT-NAME>run_SWC_FDC_Tx'));

% Modify each Runnable except run_SWC_FDC_RxTx_5ms
for i = 1:Runnable_numb
    Runnable_start = Runnable_idx(i)-1;
    h = find(contains(Target_arxml,'</RUNNABLE-ENTITY>'));
    Runnable_end = min(h(h > Runnable_start));
    
    % Modify VARIABLE-ACCESS in <DATA-SEND-POINTS>
    h  = Runnable_start + find(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>dsp_CAN'))-2;
    Var_numb = sum(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>dsp_CAN'));

    for j = 1:Var_numb
        % VARIABLE-ACCESS
        VarAcess_raw_start = h(j);
        h1 = find(contains(Target_arxml,'</VARIABLE-ACCESS>'));
        VarAcess_raw_end = min(h1(h1 > VarAcess_raw_start));
        Target_arxml(VarAcess_raw_start:VarAcess_raw_end) = {'xxx'};
    end
    
    % Data send point delete if no any dsp_xxx
    Data_send_point_check = any(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>dsp_'));
    if ~Data_send_point_check
        Data_send_point_raw_start = Runnable_start + find(contains(Target_arxml(Runnable_start:Runnable_end),'<DATA-SEND-POINTS>')) -1;
        Data_send_point_raw_end = Runnable_start + find(contains(Target_arxml(Runnable_start:Runnable_end),'</DATA-SEND-POINTS>'))-1;
        Target_arxml(Data_send_point_raw_start:Data_send_point_raw_end) = {'xxx'};
    end

    % Modify VARIABLE-ACCESS in <READ-LOCAL-VARIABLES>
    h  = Runnable_start + find(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>IRV_ms'))-2;
    Var_numb = sum(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>IRV_ms'));

    for j = 1:Var_numb
        % VARIABLE-ACCESS
        VarAcess_raw_start = h(j);
        h1 = find(contains(Target_arxml,'</VARIABLE-ACCESS>'));
        VarAcess_raw_end = min(h1(h1 > VarAcess_raw_start));
        Target_arxml(VarAcess_raw_start:VarAcess_raw_end) = {'xxx'};
    end
    
    % Runnable delete if no any IRV & Delete Timing event 
    Runnable_check = any(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>IRV_'));
    if ~Runnable_check
        DeleteRunnable_ms = (extractBetween(Target_arxml(Runnable_start+1),'Tx_','</SHORT-NAME>'));
        idx = find(contains(Target_arxml(:,1),'<SHORT-NAME>TE_' + string(DeleteRunnable_ms)));
        TimingEvent_raw_start = idx-1;

        h2 = find(contains(Target_arxml(:,1),'</TIMING-EVENT>'));
        TimingEvent_raw_end = min(h2(h2 > TimingEvent_raw_start));

        Target_arxml(Runnable_start:Runnable_end) = {'xxx'};
        Target_arxml(TimingEvent_raw_start:TimingEvent_raw_end) = {'xxx'};
    end
end

%% Modify run_SWC_FDC_RxTx_5ms
Runnable_start = find(contains(Target_arxml,'<SHORT-NAME>run_SWC_FDC_RxTx_5ms'))-1;
h = find(contains(Target_arxml(:,1),'</RUNNABLE-ENTITY>'));
Runnable_end = min(h(h > Runnable_start));

% Delete dsp_CANxxx in <DATA-SEND-POINTS>
h  = Runnable_start + find(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>dsp_CAN'))-2;
Var_numb = sum(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>dsp_CAN'));

for j = 1:Var_numb
    % VARIABLE-ACCESS
    VarAcess_raw_start = h(j);
    h1 = find(contains(Target_arxml,'</VARIABLE-ACCESS>'));
    VarAcess_raw_end = min(h1(h1 > VarAcess_raw_start));
    Target_arxml(VarAcess_raw_start:VarAcess_raw_end) = {'xxx'};
end

% Delete drparg_CANxxx in <DATA-RECEIVE-POINT-BY-ARGUMENTS>
h  = Runnable_start + find(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>drparg_CAN'))-2;
Var_numb = sum(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>drparg_CAN'));

for j = 1:Var_numb
    % VARIABLE-ACCESS
    VarAcess_raw_start = h(j);
    h1 = find(contains(Target_arxml,'</VARIABLE-ACCESS>'));
    VarAcess_raw_end = min(h1(h1 > VarAcess_raw_start));
    Target_arxml(VarAcess_raw_start:VarAcess_raw_end) = {'xxx'};
end

% Modify VARIABLE-ACCESS in <WRITTEN-LOCAL-VARIABLES>
h  = Runnable_start + find(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>IRV_ms'))-2;
    Var_numb = sum(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>IRV_ms'));
  
for j = 1:Var_numb
    % VARIABLE-ACCESS
    VarAcess_raw_start = h(j);
    h1 = find(contains(Target_arxml,'</VARIABLE-ACCESS>'));
    VarAcess_raw_end = min(h1(h1 > VarAcess_raw_start));
    Target_arxml(VarAcess_raw_start:VarAcess_raw_end) = {'xxx'};
end

% Delete <DATA-RECEIVE-POINT-BY-ARGUMENTS>
% Data send point delete if no any dsp_xxx
Data_send_point_check = any(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>dsp_'));
if ~Data_send_point_check
    Data_send_point_raw_start = Runnable_start + find(contains(Target_arxml(Runnable_start:Runnable_end),'<DATA-SEND-POINTS>')) -1;
    Data_send_point_raw_end = Runnable_start + find(contains(Target_arxml(Runnable_start:Runnable_end),'</DATA-SEND-POINTS>'))-1;
    Target_arxml(Data_send_point_raw_start:Data_send_point_raw_end) = {'xxx'};
end

% Delete <DATA-RECEIVE-POINT-BY-ARGUMENTS>
% Data Receive point by argument delete if no any drparg_xxx
Data_Receive_point_check = any(contains(Target_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>drparg_CAN'));
if ~Data_Receive_point_check
    Data_Receive_point_raw_start = Runnable_start + find(contains(Target_arxml(Runnable_start:Runnable_end),'<DATA-RECEIVE-POINT-BY-ARGUMENTS>')) -1;
    Data_Receive_point_raw_end = Runnable_start + find(contains(Target_arxml(Runnable_start:Runnable_end),'</DATA-RECEIVE-POINT-BY-ARGUMENTS>'))-1;
    Target_arxml(Data_Receive_point_raw_start:Data_Receive_point_raw_end) = {'xxx'};
end

%% Delete XXX
xxx_array = strcmp(Target_arxml(:,1),'xxx');
Target_arxml(xxx_array,:) = [];

%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen( 'SWC_FDC_ORIGINAL.arxml','w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);

end