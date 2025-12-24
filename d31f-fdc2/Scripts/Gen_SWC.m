function Gen_SWC(Channel_list,MsgLinkFileName,TargetECU,DBCSet,RoutingTable)
project_path = pwd;
ScriptVersion = '2024.05.15';
addpath([project_path '/Scripts']);

%% Read messageLink
cd([project_path '/../common/documents']);
MessageLink_Rx = readcell(MsgLinkFileName,'Sheet','InputSignal');
MessageLink_Tx = readcell(MsgLinkFileName,'Sheet','OutputSignal');

%% Get Tx signal routing messages
tmpCell = {};
cnt = 0;
for n = 1:length(Channel_list)
    Channel = char(Channel_list(n));

    if strcmp(Channel,'CANDr1')
        Raw_start = find(contains(RoutingTable(:,4),'distributed messages, target:CAN_Dr1')) + 2;
    else
        Raw_start = find(contains(RoutingTable(:,4),['distributed messages, target:' Channel])) + 2;
    end

    for i = 1:length(Raw_start)
        Raw_end = Raw_start(i) + find(contains(RoutingTable(Raw_start(i):end,4),'distributed messages, target'),1,'first') - 2;
        if isempty(Raw_end); Raw_end = length(RoutingTable(:,1));end

        for k = Raw_start(i):Raw_end
            if ~strcmp(RoutingTable(k,4),'Invalid')
                cnt = cnt + 1;
                tmpCell(cnt,1) = cellstr([Channel '_' char(RoutingTable(k,5))]);
            else
                continue
            end
        end
    end
end
tmpCell = categories(categorical(tmpCell));
tmpCell(contains(tmpCell,'Invalid')) = [];
Tx_MsgSignalGW = tmpCell;

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
% get FVT_HALIN & FVT_HALOUT ORIGINAL
cd([project_path '/documents/ARXML_output'])
fileID = fopen('FVT_HALIN.arxml');
HALIN_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(HALIN_arxml{1,1}),1);
for i = 1:length(HALIN_arxml{1,1})
    tmpCell{i,1} = HALIN_arxml{1,1}{i,1};
end
HALIN_arxml = tmpCell;
fclose(fileID);
cd(project_path);

cd([project_path '/documents/ARXML_output'])
fileID = fopen('FVT_HALOUT.arxml');
HALOUT_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(HALOUT_arxml{1,1}),1);
for i = 1:length(HALOUT_arxml{1,1})
    tmpCell{i,1} = HALOUT_arxml{1,1}{i,1};
end
HALOUT_arxml = tmpCell;
fclose(fileID);
cd(project_path);

% modify script version
h = contains(HALIN_arxml(:,1),'<SD GID="ScriptVersion">');
tmpCell = HALIN_arxml(h);
OldString = extractBetween(tmpCell,'>','<');
HALIN_arxml(h) = strrep(tmpCell,OldString,ScriptVersion); % <SD GID="ScriptVersion">0.0.1</SD>

h = contains(HALOUT_arxml(:,1),'<SD GID="ScriptVersion">');
tmpCell = HALOUT_arxml(h);
OldString = extractBetween(tmpCell,'>','<');
HALOUT_arxml(h) = strrep(tmpCell,OldString,ScriptVersion); % <SD GID="ScriptVersion">0.0.1</SD>

% modify MessageLink version
h = contains(HALIN_arxml(:,1),'<SD GID="InputFile">');
tmpCell = HALIN_arxml(h);
OldString = char(extractBetween(tmpCell,'>','<'));
NewString = MsgLinkFileName;
HALIN_arxml(h) = strrep(tmpCell,OldString,NewString); % <SD GID="InputFile">CAN_MessageLinkOut</SD>

h = contains(HALOUT_arxml(:,1),'<SD GID="InputFile">');
tmpCell = HALOUT_arxml(h);
OldString = char(extractBetween(tmpCell,'>','<'));
NewString = MsgLinkFileName;
HALOUT_arxml(h) = strrep(tmpCell,OldString,NewString); % <SD GID="InputFile">CAN_MessageLinkOut</SD>

%% Modify FVT_HALIN
% Remove all R_CANxxxxx
R_CAN_Raw_start = find(contains(HALIN_arxml,'<SHORT-NAME>R_CAN'));
R_CAN_Raw_end = find(contains(HALIN_arxml,'</R-PORT-PROTOTYPE>'));

for i = 1:length(R_CAN_Raw_start)
    ECUC_start = R_CAN_Raw_start(i)-1;
    ECUC_end = min(R_CAN_Raw_end(R_CAN_Raw_end>R_CAN_Raw_start(i)));
    HALIN_arxml(ECUC_start:ECUC_end) = {'xxx'};
end

xxx_array = strcmp(HALIN_arxml(:,1),'xxx');
HALIN_arxml(xxx_array,:) = [];

% R-Ports
Raw_start = find(contains(HALIN_arxml,'<R-PORT-PROTOTYPE>'),1,'first');
Raw_end = find(contains(HALIN_arxml,'</R-PORT-PROTOTYPE>'),1,'first');
Template = HALIN_arxml(Raw_start:Raw_end);

for k = 1:length(Rx_Messages)
    tmpCell = Template; % initialize tmpCell
    Channel = char(extractBefore(Rx_Messages(k),'_'));
    MsgName = char(extractAfter(Rx_Messages(k),'_'));

    h = contains(tmpCell(:,1),'<SHORT-NAME>R');
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
    Raw_start = find(contains(HALIN_arxml,'</R-PORT-PROTOTYPE>'),1,'last');
    Raw_end = Raw_start + 1;
    HALIN_arxml = [HALIN_arxml(1:Raw_start);tmpCell(1:end);HALIN_arxml(Raw_end:end)];
end

cd([project_path '/documents/ARXML_output'])
fileID = fopen( 'FVT_HALIN.arxml','w');
for i = 1:length(HALIN_arxml(:,1))
    fprintf(fileID,'%s\n',char(HALIN_arxml(i,1)));
end
fclose(fileID);

% Update Halin Impl
path = [project_path '\software\sw_development\arch\hal'];
hal_dir = char(path);
pro_hal_dir = dir(hal_dir);
pro_hal_dir = struct2table(pro_hal_dir);
pro_hal_dir = table2cell(pro_hal_dir);
num_pro_hal_dir = length(pro_hal_dir(:,1));
ref_module = {''};
k=0;
for i = 1:num_pro_hal_dir
    str = pro_hal_dir(i,1);
    isdir = cell2mat(pro_hal_dir(i,5));
    if isdir && contains(str,'can')
        k =k+1;
        ref_module(k,1) = str;
    end 
end 

for i = 1:length(ref_module)
    upper_str = upper(ref_module(i));
    file = char(strcat('DD_',upper_str));
    HAL_CAN_path = strcat([path '\' char(ref_module(i)) '\']);
    data = readtable([HAL_CAN_path file],'sheet','Signals','PreserveVariableNames',true);
    [data_m,~] = size(data);
    data_cell = table2cell(data);
    k =0;
    restore_data = {};
    for j = 1:data_m
        str = data_cell(j,1);
        str_dir = data_cell(j,2);
        if contains(str_dir, 'output')
            k = k+1; 
            restore_data(k,1) = str;
            restore_data(k,2) = str_dir;
            restore_data(k,3) = data_cell(j,3);
            restore_data(k,4) = data_cell(j,4);            
            restore_data(k,5) = data_cell(j,5);
            restore_data(k,6) = data_cell(j,6);
            restore_data(k,7) = cellstr(upper_str);
        end
    end
    Module = char(extractAfter(file,'DD_'));
    Build_SWC_APP(Module,restore_data,project_path)
end
disp('FVT_HALIN.arxml Done');

%% Modify FVT_HALOUT
% Remove all P_CANxxxxx
P_CAN_Raw_start = find(contains(HALOUT_arxml,'<SHORT-NAME>P_CAN'),1,'first');
P_CAN_Raw_end = find(contains(HALOUT_arxml,'<SHORT-NAME>P_CAN'),1,'last');
HALOUT_arxml(P_CAN_Raw_start-1:P_CAN_Raw_end+2) = [];

% P-Ports
Raw_start = find(contains(HALOUT_arxml,'<P-PORT-PROTOTYPE>'),1,'first');
Raw_end = find(contains(HALOUT_arxml,'</P-PORT-PROTOTYPE>'),1,'first');
Template = HALOUT_arxml(Raw_start:Raw_end);

for k = 1:length(Tx_Messages)
    tmpCell = Template; % initialize tmpCell
    Channel = char(extractBefore(Tx_Messages(k),'_'));
    MsgName = char(extractAfter(Tx_Messages(k),'_'));

    % Ignore OTA ports
    if endsWith(MsgName,'_OTA1') || endsWith(MsgName,'_CONN1') 
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
    Raw_start = find(contains(HALOUT_arxml,'</P-PORT-PROTOTYPE>'),1,'last');
    Raw_end = Raw_start + 1;
    HALOUT_arxml = [HALOUT_arxml(1:Raw_start);tmpCell(1:end);HALOUT_arxml(Raw_end:end)];
end

%% Modify IRV
% Remove all IRV_msxxxxx
Raw_start = find(contains(HALOUT_arxml,'<EXPLICIT-INTER-RUNNABLE-VARIABLES>'));
Raw_end = find(contains(HALOUT_arxml,'</EXPLICIT-INTER-RUNNABLE-VARIABLES>'));
IRV_CAN_Raw_start = Raw_start-1 + find(contains(HALOUT_arxml(Raw_start:Raw_end),'<SHORT-NAME>IRV_ms'),1,'first');
IRV_CAN_Raw_end = Raw_start-1 + find(contains(HALOUT_arxml(Raw_start:Raw_end),'<SHORT-NAME>IRV_ms'),1,'last');
HALOUT_arxml(IRV_CAN_Raw_start-1:IRV_CAN_Raw_end+2) = [];

%% Modify run_SWC_FDC_Tx RUNNABLE-ENTITY
Runnable_numb = sum(contains(HALOUT_arxml,'<SHORT-NAME>run_SWC_HALOUT_Tx'));
Runnable_idx = find(contains(HALOUT_arxml,'<SHORT-NAME>run_SWC_HALOUT_Tx'));

% Modify each Runnable except run_SWC_FDC_RxTx_5ms
for i = 1:Runnable_numb
    Runnable_start = Runnable_idx(i)-1;
    h = find(contains(HALOUT_arxml,'</RUNNABLE-ENTITY>'));
    Runnable_end = min(h(h > Runnable_start));
    
    % Modify VARIABLE-ACCESS in <DATA-SEND-POINTS>
    h  = Runnable_start + find(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>dsp_CAN'))-2;
    Var_numb = sum(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>dsp_CAN'));
    
    if Var_numb >= 1
        for j = 1:Var_numb
            % VARIABLE-ACCESS
            VarAcess_raw_start = h(j);
            h1 = find(contains(HALOUT_arxml,'</VARIABLE-ACCESS>'));
            VarAcess_raw_end = min(h1(h1 > VarAcess_raw_start));
            HALOUT_arxml(VarAcess_raw_start:VarAcess_raw_end) = {'xxx'};
        end
    end
    % Data send point delete if no any dsp_xxx
    Data_send_point_check = any(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>dsp_'));
    if ~Data_send_point_check
        Data_send_point_raw_start = Runnable_start + find(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<DATA-SEND-POINTS>')) -1;
        Data_send_point_raw_end = Runnable_start + find(contains(HALOUT_arxml(Runnable_start:Runnable_end),'</DATA-SEND-POINTS>'))-1;
        HALOUT_arxml(Data_send_point_raw_start:Data_send_point_raw_end) = {'xxx'};
    end

    % Modify VARIABLE-ACCESS in <READ-LOCAL-VARIABLES>
    h  = Runnable_start + find(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>IRV_ms'))-2;
    Var_numb = sum(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>IRV_ms'));
    if Var_numb >= 1
        for j = 1:Var_numb
            % VARIABLE-ACCESS
            VarAcess_raw_start = h(j);
            h1 = find(contains(HALOUT_arxml,'</VARIABLE-ACCESS>'));
            VarAcess_raw_end = min(h1(h1 > VarAcess_raw_start));
            HALOUT_arxml(VarAcess_raw_start:VarAcess_raw_end) = {'xxx'};
        end
    end
    % Runnable delete if no any IRV & Delete Timing event 
    Runnable_check = any(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>IRV_'));
    if ~Runnable_check
        DeleteRunnable_ms = (extractBetween(HALOUT_arxml(Runnable_start+1),'Tx_','</SHORT-NAME>'));
        idx = find(contains(HALOUT_arxml(:,1),'<SHORT-NAME>TE_HALOUT_' + string(DeleteRunnable_ms)));
        TimingEvent_raw_start = idx-1;

        h2 = find(contains(HALOUT_arxml(:,1),'</TIMING-EVENT>'));
        TimingEvent_raw_end = min(h2(h2 > TimingEvent_raw_start));

        HALOUT_arxml(Runnable_start:Runnable_end) = {'xxx'};
        HALOUT_arxml(TimingEvent_raw_start:TimingEvent_raw_end) = {'xxx'};
    end
end

%% Modify run_SWC_FDC_RxTx_5ms
% Runnable_start = find(contains(HALOUT_arxml,'<SHORT-NAME>run_SWC_FDC_RxTx_5ms'))-1;
% h = find(contains(HALOUT_arxml(:,1),'</RUNNABLE-ENTITY>'));
% Runnable_end = min(h(h > Runnable_start));
% 
% % Delete dsp_CANxxx in <DATA-SEND-POINTS>
% h  = Runnable_start + find(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>dsp_CAN'))-2;
% Var_numb = sum(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>dsp_CAN'));
% 
% for j = 1:Var_numb
%     % VARIABLE-ACCESS
%     VarAcess_raw_start = h(j);
%     h1 = find(contains(HALOUT_arxml,'</VARIABLE-ACCESS>'));
%     VarAcess_raw_end = min(h1(h1 > VarAcess_raw_start));
%     HALOUT_arxml(VarAcess_raw_start:VarAcess_raw_end) = {'xxx'};
% end
% 
% % Delete drparg_CANxxx in <DATA-RECEIVE-POINT-BY-ARGUMENTS>
% h  = Runnable_start + find(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>drparg_CAN'))-2;
% Var_numb = sum(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>drparg_CAN'));
% 
% for j = 1:Var_numb
%     % VARIABLE-ACCESS
%     VarAcess_raw_start = h(j);
%     h1 = find(contains(HALOUT_arxml,'</VARIABLE-ACCESS>'));
%     VarAcess_raw_end = min(h1(h1 > VarAcess_raw_start));
%     HALOUT_arxml(VarAcess_raw_start:VarAcess_raw_end) = {'xxx'};
% end
% 
% % Modify VARIABLE-ACCESS in <WRITTEN-LOCAL-VARIABLES>
% h  = Runnable_start + find(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>IRV_ms'))-2;
%     Var_numb = sum(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>IRV_ms'));
%   
% for j = 1:Var_numb
%     % VARIABLE-ACCESS
%     VarAcess_raw_start = h(j);
%     h1 = find(contains(HALOUT_arxml,'</VARIABLE-ACCESS>'));
%     VarAcess_raw_end = min(h1(h1 > VarAcess_raw_start));
%     HALOUT_arxml(VarAcess_raw_start:VarAcess_raw_end) = {'xxx'};
% end
% 
% % Delete <DATA-RECEIVE-POINT-BY-ARGUMENTS>
% % Data send point delete if no any dsp_xxx
% Data_send_point_check = any(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>dsp_'));
% if ~Data_send_point_check
%     Data_send_point_raw_start = Runnable_start + find(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<DATA-SEND-POINTS>')) -1;
%     Data_send_point_raw_end = Runnable_start + find(contains(HALOUT_arxml(Runnable_start:Runnable_end),'</DATA-SEND-POINTS>'))-1;
%     HALOUT_arxml(Data_send_point_raw_start:Data_send_point_raw_end) = {'xxx'};
% end
% 
% % Delete <DATA-RECEIVE-POINT-BY-ARGUMENTS>
% % Data Receive point by argument delete if no any drparg_xxx
% Data_Receive_point_check = any(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<SHORT-NAME>drparg_'));
% if ~Data_Receive_point_check
%     Data_Receive_point_raw_start = Runnable_start + find(contains(HALOUT_arxml(Runnable_start:Runnable_end),'<DATA-RECEIVE-POINT-BY-ARGUMENTS>')) -1;
%     Data_Receive_point_raw_end = Runnable_start + find(contains(HALOUT_arxml(Runnable_start:Runnable_end),'</DATA-RECEIVE-POINT-BY-ARGUMENTS>'))-1;
%     HALOUT_arxml(Data_Receive_point_raw_start:Data_Receive_point_raw_end) = {'xxx'};
% end

%% Delete XXX
xxx_array = strcmp(HALOUT_arxml(:,1),'xxx');
HALOUT_arxml(xxx_array,:) = [];

%% Output HALOUT_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen( 'FVT_HALOUT_ORIGINAL.arxml','w');
for i = 1:length(HALOUT_arxml(:,1))
    fprintf(fileID,'%s\n',char(HALOUT_arxml(i,1)));
end
fclose(fileID);

end

function Build_SWC_APP(Module,Arry_outputs,project_path)
%% Get FVT_APP arxml
cd([project_path '/documents/ARXML_output'])
if contains(Module,'HAL_CAN')
    ARXML_Name = 'HALIN';
elseif contains(Module,'INP_')
    ARXML_Name = 'INP';
elseif contains(Module,'HAL_')
    ARXML_Name = 'HALIN_CDD';
elseif strcmp(Module,'OUTP') || strcmp(Module,'HALOUT')
    ARXML_Name = Module;
else
    ARXML_Name = 'APP';
end
fileID = fopen(['FVT_' ARXML_Name '.arxml']);
FVTAPP_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(FVTAPP_arxml{1,1}),1);
for i = 1:length(FVTAPP_arxml{1,1})
    tmpCell{i,1} = FVTAPP_arxml{1,1}{i,1};
end
FVTAPP_arxml = tmpCell;
fclose(fileID);
cd(project_path);

%% Modify <IMPLEMENTATION-DATA-TYPE-ELEMENT>
h = find(contains(FVTAPP_arxml(:,1),['<SHORT-NAME>DT_B' Module  '_outputs</SHORT-NAME>']));
ECUC_start_array = find(contains(FVTAPP_arxml(:,1),'<IMPLEMENTATION-DATA-TYPE-ELEMENT>'));
ECUC_end_array = find(contains(FVTAPP_arxml(:,1),'</IMPLEMENTATION-DATA-TYPE-ELEMENT>'));

ECUC_start = min(ECUC_start_array(ECUC_start_array>h));
ECUC_end = min(ECUC_end_array(ECUC_end_array>h));

% 
for i = 1:length(Arry_outputs(:,1))
    tmpCell = FVTAPP_arxml(ECUC_start:ECUC_end);
    SignalName = Arry_outputs(i,1);
    DataType = Arry_outputs(i,3);
    Arrayflg = boolean(0);

    if strcmp(DataType,'single')
        DataType = cellstr('float32');
    elseif strcmp(DataType,'int16')
        DataType = cellstr('sint16'); 
    elseif strcmp(DataType,'Array16')
        DataType = cellstr('u8_Array16_type');
        Arrayflg = boolean(1);
    elseif strcmp(DataType,'Array8')
        DataType = cellstr('u8_Array8_type');
        Arrayflg = boolean(1);
    end

    % Signal Name
    h = find(contains(tmpCell,'<SHORT-NAME>V'));
    OldString = extractBetween(tmpCell(h),'<SHORT-NAME>','</SHORT-NAME>');
    NewString = SignalName;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % DataType
    h = find(contains(tmpCell,'<IMPLEMENTATION-DATA-TYPE-REF DEST="'));
    if ~Arrayflg
        OldString = extractBetween(tmpCell(h),'/ImplementationDataTypes/','</IMPLEMENTATION-DATA-TYPE-REF>');
        NewString = DataType;
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    else
        OldString = extractBetween(tmpCell(h),'DEST="IMPLEMENTATION-DATA-TYPE">','</IMPLEMENTATION-DATA-TYPE-REF>');
        NewString = ['/Impl_Type_' ARXML_Name '_ARPkg/' char(DataType)];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    end
    if i == 1
        tmpCell2 = tmpCell;
    else 
        tmpCell2 = [tmpCell2;tmpCell];
    end
end

% Replace original CanIfInitHohCfg(CanIfHrhCfg & CanIfHthCfg) part
h = find(contains(FVTAPP_arxml(:,1),['<SHORT-NAME>DT_B' Module  '_outputs</SHORT-NAME>']));
ECUC_start_array = find(contains(FVTAPP_arxml(:,1),'<SUB-ELEMENTS>'));
ECUC_end_array = find(contains(FVTAPP_arxml(:,1),'</SUB-ELEMENTS>'));

ECUC_start = min(ECUC_start_array(ECUC_start_array>h));
ECUC_end = min(ECUC_end_array(ECUC_end_array>h));

FVTAPP_arxml = [FVTAPP_arxml(1:ECUC_start);tmpCell2;FVTAPP_arxml(ECUC_end:end)];

%% Output FVT_APP_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen(['FVT_' ARXML_Name '.arxml'],'w');
for i = 1:length(FVTAPP_arxml(:,1))
    fprintf(fileID,'%s\n',char(FVTAPP_arxml(i,1)));
end
fclose(fileID);
end