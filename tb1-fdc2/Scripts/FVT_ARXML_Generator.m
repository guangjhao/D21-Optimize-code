function FVT_ARXML_Generator()
%% path settings
project_path = pwd;
addpath(project_path);
addpath([project_path '/Scripts']);
addpath([project_path '/documents/Templates']);
addpath([project_path '/documents/MessageLink']);

%% Project settings
Channel_list = {'CAN1','CAN2','CAN3','CAN4','CAN5','CAN7'};
Channel_list_LIN = {};
LDFSet = {};
% Channel_list = {'CAN6'};
TargetECU = 'FUSION';

%% Read MessageLink
cd([project_path '/documents/MessageLink']);
[MsgLinkFileName, ~] = uigetfile({'*.xlsx;'}, 'Select MessageLinkOut file');

%% Read Routing table
cd([project_path '/documents/MessageMap_AUTOSAR_WorkAround']);
[RoutingTableName, path] = uigetfile({'*.xlsx;'}, 'Select routing table');
passwordFile = 'password.txt';
if isfile(passwordFile)
    password = strtrim(fileread(passwordFile));
else
    filenames = dir;
    filenames = string({filenames.name});
    password = filenames(contains(filenames,'to@'));
    password = extractBefore(password,'.txt');
end

xlsAPP = actxserver('excel.application');
xlsAPP.Visible = 1;
xlsWB = xlsAPP.Workbooks;
xlsFile = xlsWB.Open([path RoutingTableName],[],false,[],password);
exlSheet1 = xlsFile.Sheets.Item('RoutingTable');
dat_range = exlSheet1.UsedRange;
RoutingTable = dat_range.value;

% RoutingTable = readcell(RoutingTableName,'Sheet','RoutingTable');
RoutingTable(cellfun(@(x) all(ismissing(x)), RoutingTable)) = {'Invalid'};
RoutingTable(end+1,:) = {'Invalid'};

%% Read DBCs
cd(project_path)
for i = 1:length(Channel_list)
    Channel = char(Channel_list(i));
    cd([project_path '/documents/MessageMap_AUTOSAR_WorkAround'])
    [FileName, Filepath] = uigetfile({'*.dbc;'}, ['Select DBC file for ' Channel]);
    cd(Filepath)
    DBC = canDatabase(FileName);
    cd(project_path)
    DBCSet(i) = DBC;
end

%% Read DIDList
cd([project_path '/documents']);
[FVT_DIDListFileName, ~] = uigetfile({'*.xlsx;'}, 'Select FVT_DIDList file');

%% Generate CANx
for i = 1:length(Channel_list)
    cd(project_path)
    DBC = DBCSet(i);
    Channel = char(Channel_list(i));
    Gen_CANSettings(DBC,Channel,MsgLinkFileName,TargetECU,RoutingTable)
end

%% Generate PDU group
cd(project_path)
Gen_PDUGroup(Channel_list,MsgLinkFileName,TargetECU,DBCSet,Channel_list_LIN,LDFSet)

%% Generate ECU instance
cd(project_path)
Gen_ECUInstance(Channel_list,MsgLinkFileName,TargetECU,DBCSet,Channel_list_LIN,LDFSet)

%% Generate CANInterface
cd(project_path)
Gen_CANInterface(Channel_list,Channel_list_LIN)

%% Generate Composition
cd(project_path)
Gen_Composition(Channel_list,MsgLinkFileName,TargetECU,Channel_list_LIN,RoutingTable)

%% Generate SWC (include runnable)
cd(project_path)
Gen_SWC(Channel_list,MsgLinkFileName,TargetECU,DBCSet,RoutingTable);

cd([project_path '/Scripts']);
FVT_SWC_Runnable_CAN

%% Generate SWC_CGW
cd(project_path)
Gen_SWC_CGW(Channel_list,RoutingTable,Channel_list_LIN,MsgLinkFileName);

%% Generate System
cd(project_path)
Gen_System(Channel_list,MsgLinkFileName,TargetECU,DBCSet,Channel_list_LIN,LDFSet,RoutingTable)

%% Generate Signal Gateway
cd(project_path)
Gen_Gateway(Channel_list,TargetECU,RoutingTable,Channel_list_LIN,RoutingTableName);

%% Generate ComSetting
cd(project_path)
Gen_ComSettings(Channel_list,Channel_list_LIN,LDFSet,DBCSet,TargetECU);

%% Modify SWC_CGW model
cd(project_path)
Gen_CGW_Model(TargetECU,RoutingTable,Channel_list,Channel_list_LIN);

%%  Generate com_timeout_handle.c.h
cd(project_path)
Gen_com_timeout_handle

%% Generate DID
cd(project_path)
Gen_DID(FVT_DIDListFileName);

end