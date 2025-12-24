function FVT_ARXML_Generator()
%% path settings
project_path = pwd;
addpath(project_path);
addpath([project_path '/Scripts']);
addpath([project_path '/documents/Templates']);
addpath([project_path '/documents/MessageLink']);

%% Project settings
Channel_list = {'CAN1','CAN2','CAN3','CAN4','CAN5'};
% Channel_list = {'CAN3'};
TargetECU = 'FUSION';

%% Read MessageLink
cd([project_path '/documents/MessageLink']);
files = dir('CAN_MessageLinkOut_*.xlsx');
MsgLinkFileName = files.name;

%% Read Routing table
cd([project_path '/documents/MessageMap_AUTOSAR_WorkAround']);
files = dir('*RoutingTable*.xlsx');
RoutingTableName = files.name;
path = [files.folder '\'];
% [RoutingTableName, path] = uigetfile({'*.xlsx;'}, 'Select routing table');
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

% Close EXCEL
xlsWB.Close();
xlsAPP.Quit();
delete(xlsAPP);
clear xlsWB;
clear xlsAPP;

%% Read DBCs
cd(project_path)
for i = 1:length(Channel_list)
    Channel = char(Channel_list(i));
    cd([project_path '/documents/MessageMap_AUTOSAR_WorkAround'])
    CANNum = sprintf('*CAN%d*.dbc', i);
    files = dir(CANNum);
    FileName = files.name;
    Filepath = [files.folder '\'];
%     [FileName, Filepath] = uigetfile({'*.dbc;'}, ['Select DBC file for ' Channel]);
    cd(Filepath)
    DBC = canDatabase(FileName);
    cd(project_path)
    DBCSet(i) = DBC;
    DBC_Files(i) = string(FileName);
end

%% Read DIDList
cd([project_path '/documents']);
FVT_DIDListFileName = 'FVT_DIDList.xlsx';
% [FVT_DIDListFileName, ~] = uigetfile({'*.xlsx;'}, 'Select FVT_DIDList file');

%% Generate CANx
for i = 1:length(Channel_list)
    cd(project_path)
    DBC = DBCSet(i);
    Channel = char(Channel_list(i));
    Gen_CANSettings(DBC,Channel,MsgLinkFileName,TargetECU,RoutingTable)
end

%% Generate ECU instance
cd(project_path)
Gen_ECUInstance(Channel_list,MsgLinkFileName,TargetECU,DBCSet)

%% Generate PDU group
cd(project_path)
Gen_PDUGroup(Channel_list,MsgLinkFileName,TargetECU,DBCSet)

%% Generate CANInterface
cd(project_path)
Gen_CANInterface(Channel_list,MsgLinkFileName)

%% Generate Composition
cd(project_path)
Gen_Composition(Channel_list,MsgLinkFileName,RoutingTable,DBCSet);

%% Generate SWC (including Runnable)
cd(project_path)
Gen_SWC(Channel_list,MsgLinkFileName,TargetECU,DBCSet);

cd([project_path '/Scripts']);
FVT_SWC_Runnable_CAN

%% Generate System
cd(project_path)
Gen_System(Channel_list,MsgLinkFileName,TargetECU,DBCSet);

%% Generate DID
cd(project_path)
Gen_DID(FVT_DIDListFileName);

%% Modify_CAN3_ARXML
cd([project_path '/Scripts'])
Modify_CAN3_ARXML(project_path)

%% Display document version
disp('<strong>- Document version -</strong>');
disp('<strong>MessageLink : </strong>');
disp(MsgLinkFileName)
disp('<strong>RoutingTable : </strong>');
disp(RoutingTableName)
disp('<strong>CAN Message Map : </strong>');
DBC_Files = erase(DBC_Files,'"');
for i= 1:length(Channel_list)
    disp(DBC_Files(i))
end

end