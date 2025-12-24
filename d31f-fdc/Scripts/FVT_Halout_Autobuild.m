function FVT_Halout_Autobuild()
%% Initial settings
ref_car_model = {'d31f-fdc'};
car_model = ref_car_model{1};

arch_Path = pwd;
if ~contains(arch_Path, 'arch'), error('current folder is not under arch'), end
project_path = extractBefore(arch_Path,'\software');
library_path = [project_path '/library'];
Scripts_path = [project_path '/Scripts'];

addpath(library_path);
addpath(Scripts_path)
addpath([project_path '/documents/FVT_API']);
addpath(arch_Path);

%% Select Project
Autosar_flg = boolean(1);
% q = questdlg({'Check the following conditions:','1. Run project_start?',...
%     '2. Current folder arch?','3. Outp and SCP finished?','4. MessageLink finished?'},...
%     'Initial check','Yes','No','Yes');
% if ~contains(q, 'Yes')
%     return
% end
% arch_Path = pwd;
% if ~contains(arch_Path, 'arch'), error('current folder is not under arch'), end
% project_path = extractBefore(arch_Path,'\software');

ECU_list = {'FUSION','ZONE_DR','ZONE_FR'};
q = listdlg('PromptString','Select target ECU:','ListString', ECU_list, ...
    'Name', 'Select target ECU', ...
    'ListSize', [250 150],'SelectionMode','single');

if isempty(q), error('No ECU selected'), end
TargetNode = ECU_list(q);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUS list is real CAN channel in BSP. It depends on hardware layout and
% vehicle side cable.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(TargetNode,'FUSION')
    channel_list = {'CAN1','CAN2','CAN3','CAN4','CAN5','CAN6'};
    busList =      {'1','2','3','4','6','7'};
elseif strcmp(TargetNode,'ZONE_DR')
    channel_list = {'CAN_Dr1','CAN4','LIN_Dr1','LIN_Dr2','LIN_Dr3','LIN_Dr4'};
    busList =      {'1','0','0','1','2','3'};
elseif strcmp(TargetNode,'ZONE_FR')
    channel_list = {'CAN_Fr1','CAN4','LIN_Fr1','LIN_Fr2'};
    busList =      {'1','0','0','1'};
else
    error('Undefined target ECU');
end

q = questdlg(append('Check the following settings-->  ',string(channel_list), ' = BSP channel ', string(busList)), ...
    'Channel check', ...
    'Yes','No','Yes');
if ~contains(q,'Yes'), return, end

q = listdlg('PromptString','Select one or multiple channel to create:', ...
    'ListString', channel_list,'Name', 'Select CAN Channel', ...
    'ListSize', [250 150], 'SelectionMode', 'mutiple');

NUN_CHANNEL = length(q);
DD_halout = cell(1,8);

cd([arch_Path '\outp']);
DD_OUTP = readcell('DD_OUTP.xlsx','Sheet','Signals');
cd([arch_Path '\app']);
%Check scp exist(pt-v06 no signal routing)
if exist('scp','file')
    SCP_flg = boolean(1);
    cd([arch_Path '\app\scp']);
    DD_SCP = readcell('DD_SCP.xlsx','Sheet','Signals');
else
    DD_SCP = 'no_scp';
    SCP_flg = boolean(0);
end
cd(arch_Path);
%% RoutingTable
%Loading excel
% path = [project_path '\documents\MessageMap\'];
% filenames = dir(path);
% filenames = string({filenames.name});
% RoutingTableName = char(filenames(contains(filenames,['RoutingTable_' char(TargetNode)])));
% password = filenames(contains(filenames,'to@'));
% password = extractBefore(password,'.txt');
% 
% xlsAPP = actxserver('excel.application');
% xlsAPP.Visible = 1;
% xlsWB = xlsAPP.Workbooks;
% xlsFile = xlsWB.Open([path RoutingTableName],[],false,[],password);
% exlSheet0 = xlsFile.Sheets.Item('RoutingTable');
% da_range = exlSheet0.UsedRange;
% raw_data = da_range.value;
% xlsFile.Close(false);
% xlsAPP.Quit;

%% Read SWC_FDC.arxml for output port order
addpath([project_path '/documents/ARXML_output']);
fileID = fopen('SWC_FDC.arxml');
Target_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Target_arxml{1,1}),1);
for i = 1:length(Target_arxml{1,1})
    tmpCell{i,1} = Target_arxml{1,1}{i,1};
end
Target_arxml = tmpCell;
fclose(fileID);
cd(project_path);

% <DATA-RECEIVE-POINT-BY-ARGUMENTS>
Raw_start = find(contains(Target_arxml(:,1),'<DATA-RECEIVE-POINT-BY-ARGUMENTS>'),1,"last");
% Raw_end = find(contains(Target_arxml(:,1),'</DATA-RECEIVE-POINT-BY-ARGUMENTS>'),1,"last");

% <DATA-RECEIVE-POINT-BY-ARGUMENTS>
h = find(contains(Target_arxml(:,1),'<DATA-SEND-POINTS>'));
idx = find(h>Raw_start,1,"first");
Raw_start = h(idx);
h = find(contains(Target_arxml(:,1),'</DATA-SEND-POINTS>'));
idx = find(h>Raw_start,1,"first");
Raw_end = h(idx);

% P_CANx_FD_xxx_CANx_SG_FD_xxx_write
% PORT-PROTOTYPE-REF
h = find(contains(Target_arxml(Raw_start:Raw_end,1),'<PORT-PROTOTYPE-REF'));
tmpCell1 = extractBetween(Target_arxml(Raw_start+h-1,1),'SWC_FDC_type/','</PORT-PROTOTYPE-REF>');

% CANx_SG_XXX 
h = find(contains(Target_arxml(Raw_start:Raw_end,1),'<SHORT-NAME>'));
tmpCell2 = extractBetween(Target_arxml(Raw_start+h-1,1),'<SHORT-NAME>dsp','</SHORT-NAME>');

% IRV_CANx_SG_FD_xxx_write
% <WRITTEN-LOCAL-VARIABLES>
h = find(contains(Target_arxml(:,1),'<WRITTEN-LOCAL-VARIABLES>'));
idx = find(h>Raw_start,1,"first");
Raw_start = h(idx);
h = find(contains(Target_arxml(:,1),'</WRITTEN-LOCAL-VARIABLES>'));
idx = find(h>Raw_start,1,"first");
Raw_end = h(idx);

% IRV_CANx_SG_FD_xxx_write 
h = find(contains(Target_arxml(Raw_start:Raw_end,1),'<SHORT-NAME>'));
tmpCell3 = extractBetween(Target_arxml(Raw_start+h-1,1),'<SHORT-NAME>','</SHORT-NAME>');

% Create CAN message output array
% Filter No need to output in Halout
CAN_Msg_Output_array = strings(length(tmpCell1)+length(tmpCell3),1);
CAN_Msg_Output_array(1:length(tmpCell1)) = string(tmpCell1) + string(tmpCell2) + '_write';
CAN_Msg_Output_array(length(tmpCell1)+1:end) = string(tmpCell3) + '_write';
for i = 1:length(CAN_Msg_Output_array)
    while i <= length(CAN_Msg_Output_array) && ...
        ~startsWith(CAN_Msg_Output_array(i),'P_CAN')... 
        && ~startsWith(CAN_Msg_Output_array(i),'IRV_ms')...
		&& ~startsWith(CAN_Msg_Output_array(i),'IRV_E2E_CAN')
        
        CAN_Msg_Output_array(i) = [];
    end 

    if i > length(CAN_Msg_Output_array)
        break;
    end
end

CAN_Msg_Output_array = cellstr(CAN_Msg_Output_array);

%% Data filter
% [data_m , ~] = size(raw_data);
% Numb_restore = 0;
% Frame_routing_array = cell(0);
% Autosar_Frame_routing_array  = cell(0);
% raw_data(cellfun(@(x) all(ismissing(x)), raw_data)) = {'Invalid'};
% raw_data(end+1,:) = {'Invalid'};
% for i = 1:data_m
%     SignalName = raw_data(i,1);
%     Rx_MessageName = raw_data(i,2);
%     Tx_MessageName = raw_data(i,5);
%     if ~Autosar_flg
%         if ~strcmp(Rx_MessageName,'Invalid')
%             % Here is use for save parameter from raw_data to Frame_routing_array  
%             cmp_flg = strcmp(Rx_MessageName,"Message Name");
%             Array_space = isspace(string(Rx_MessageName));
%             Numb_space = sum(Array_space);
% 
%             if (cmp_flg == 1)
%                 CAN_chn = extractAfter(raw_data(i-1,1),'source:');
%                 CAN_chn_res = char(erase(CAN_chn,'_'));
%                 
%                 CAN_chn = extractAfter(raw_data(i-1,4),'target:');
%                 CAN_chn_out = char(erase(CAN_chn,'_'));
%             end
%     
%             if strcmp(SignalName,'Invalid') && (Numb_space==0) && ~contains(Rx_MessageName,'Diag') && ~contains(Rx_MessageName,'CCP') && ~contains(Rx_MessageName,'XCP')
%                Numb_restore = Numb_restore + 1;
%                Frame_routing_array(Numb_restore,1) = cellstr(CAN_chn_res);
%                Frame_routing_array(Numb_restore,2) = Rx_MessageName;
%                Frame_routing_array(Numb_restore,3) = Rx_MessageName;
%                Frame_routing_array(Numb_restore,4) = cellstr(CAN_chn_out);
%                Frame_routing_array(Numb_restore,5) = raw_data(i,4);
%                Frame_routing_array(Numb_restore,6) = Tx_MessageName;
%                Frame_routing_array(Numb_restore,7) = raw_data(i,10);
%             end
%         end
%     elseif Autosar_flg
%         if ~strcmp(Rx_MessageName,'Invalid')
%             % Here is use for save parameter from raw_data to Frame_routing_array  
%             cmp_flg = strcmp(Rx_MessageName,"Message Name");
%             Array_space = isspace(string(Rx_MessageName));
%             Numb_space = sum(Array_space);
% 
%             if (cmp_flg == 1)
%                 CAN_chn = extractAfter(raw_data(i-1,1),'source:');
%                 CAN_chn_res = char(erase(CAN_chn,'_'));
%                 
%                 CAN_chn = extractAfter(raw_data(i-1,4),'target:');
%                 CAN_chn_out = char(erase(CAN_chn,'_'));
%             end
% 
%             if strcmp(SignalName,'Invalid') && (Numb_space==0) && ~contains(Rx_MessageName,'Diag') && ~contains(Rx_MessageName,'CCP') && ~contains(Rx_MessageName,'XCP')
%                 Numb_restore = Numb_restore + 1;
%                 Autosar_Frame_routing_array(Numb_restore,1) = cellstr(CAN_chn_out);
%                 Autosar_Frame_routing_array(Numb_restore,2) = raw_data(i,5);
%             end
%         end
%     end
% end

%% Create new model and all subsystems
new_model = ['HALOUT_temp_' datestr(now,30)];
load_system FVT_lib;
new_system(new_model);
open_system(new_model);
set_param(new_model,'LibraryLinkDisplay','all');
set_param(new_model,'SimUserSources', 'FVT_API.c');
set_param(new_model,'SimCustomHeaderCode', '#include "FVT_API.h"');
set_param(new_model,'CustomHeaderCode', '#include "FVT_API.h"');
set_param(new_model,'CustomSource', 'FVT_API.c');
original_x = 0;
original_y = 0;

% Filter Autosar

if Autosar_flg
    hDict = Simulink.data.dictionary.open('APPTypes.sldd');
    hDesignData = hDict.getSection('Global');
    childNamesList = hDesignData.evalin('who');
    Autosar_output_msg_all = cell(length(childNamesList),1);
    for n = 1:numel(childNamesList)
        hEntry = hDesignData.getEntry(childNamesList{n});
        assignin('base', hEntry.Name, hEntry.getValue);
    end
    for j = 1:length(childNamesList)
        if any(strcmp(extractBetween(CAN_Msg_Output_array,'SG_','_write'),extractAfter(childNamesList(j),'SG_')))
            Autosar_output_msg_all(j,1) = childNamesList(j); % DBC index
        end
    end

    for j = length(Autosar_output_msg_all(:,1)):-1:1
        if cellfun(@isempty,Autosar_output_msg_all(j,1))
            Autosar_output_msg_all(j,:) = [];
        end
    end
end

% create subsystems for different channel
for i = 1:NUN_CHANNEL
    Channel = char(channel_list(q(i)));
    Channel = erase(Channel, '_');
    BlockName = Channel;
    block_x = original_x + 800*(i-1);
    block_y = original_y + 300;
    block_w = block_x + 250;
    block_h = block_y + 400;
    srcT = 'simulink/Ports & Subsystems/Triggered Subsystem';
    dstT = [new_model '/' BlockName];
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'ContentPreviewEnabled','off','BackgroundColor','LightBlue');

    % wroking inside channel model
    TargetModel = [new_model '/' Channel];
    block_x = original_x;
    block_y = original_y;
    block_w = block_x + 30;
    block_h = block_y + 30;
    set_param([TargetModel '/Trigger'],'TriggerType','function-call');
    set_param([TargetModel '/Trigger'],'position',[block_x,block_y,block_w,block_h]);

    block_x = original_x;
    block_y = original_y+400;
    block_w = block_x + 30;
    block_h = block_y + 13;
    set_param([TargetModel '/In1'],'position',[block_x,block_y,block_w,block_h]);
    set_param([TargetModel '/In1'],'UseBusObject','on')
    set_param([TargetModel '/In1'],'BusObject','BOUTP_outputs','Name','BOUTP_outputs');
    delete_line(TargetModel, 'BOUTP_outputs/1','Out1/1');
    delete_block([TargetModel '/Out1']);

    sourceport = get_param([TargetModel '/BOUTP_outputs'],'PortHandles');
    targetpos = get_param(sourceport.Outport(1),'Position');
    BlockName = 'Goto';
    block_x = targetpos(1) + 100;
    block_y = targetpos(2) - 20;
    block_w = block_x + 220;
    block_h = block_y + 40;
    srcT = 'simulink/Signal Routing/Goto';
    dstT = [TargetModel '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'Gototag', 'BOUTP_outputs','ShowName', 'off');
    targetport = get_param(h,'PortHandles');
    add_line(TargetModel, sourceport.Outport(1), targetport.Inport(1));

    BlockName = 'BSCP_outputs';
    block_x = targetpos(1)-35;
    block_y = targetpos(2)+50;
    block_w = block_x + 30;
    block_h = block_y + 13;
    srcT = 'simulink/Sources/In1';
    dstT = [TargetModel '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    if SCP_flg
        set_param(h,'UseBusObject','on','BusObject','BSCP_outputs','Name','BSCP_outputs');        
    end   

    sourceport = get_param(h,'PortHandles');
    targetpos = get_param(sourceport.Outport(1),'Position');
    BlockName = 'Goto';
    block_x = targetpos(1) + 100;
    block_y = targetpos(2)-20;
    block_w = block_x + 220;
    block_h = block_y + 40;
    srcT = 'simulink/Signal Routing/Goto';
    dstT = [TargetModel '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'Gototag', 'BSCP_outputs','ShowName', 'off');
    targetport = get_param(h,'PortHandles');
    add_line(TargetModel, sourceport.Outport(1), targetport.Inport(1));

    % Frame routing inport
%     if exist('Frame_routing_array','var') && ~isempty(Frame_routing_array) && any(contains(string(Frame_routing_array(:,1)),Channel))
% 
%         % Detect frame routing on each can
%         Frame_routing_array_can = strcmp(Frame_routing_array(:,4),string(Channel));
%         Frame_routing_can = find(Frame_routing_array_can==1);
%         Numb_Restore_array_can = length(Frame_routing_can);
% 
%         if ~isempty(Frame_routing_can)
%             Restore_can = cell(Numb_Restore_array_can,1);
%             for g = 1:Numb_Restore_array_can
%                 Restore_can(g,1) = Frame_routing_array((Frame_routing_can(g)),1);
%             end            
%             Restore_can = sort(union(Restore_can,Restore_can));
%         end
% 
%         targetpos = get_param([TargetModel '/BSCP_outputs'],'position');
% 
%         for g = 1:length(Restore_can)
%             BlockName = ['HAL_' char(Restore_can(g)) '_outputs'];
%             block_x = targetpos(1);
%             block_y = targetpos(2)+55;
%             block_w = block_x + 30;
%             block_h = block_y + 13;
%             srcT = 'simulink/Sources/In1';
%             dstT = [TargetModel '/' BlockName];
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
% 
%             sourceport = get_param(h,'PortHandles');
%             targetpos = get_param(sourceport.Outport(1),'Position');
%             BlockName = 'Goto';
%             block_x = targetpos(1) + 100;
%             block_y = targetpos(2)-20;
%             block_w = block_x + 220;
%             block_h = block_y + 40;
%             srcT = 'simulink/Signal Routing/Goto';
%             dstT = [TargetModel '/' BlockName];
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'Gototag', ['HAL_' char(Restore_can(g)) '_outputs'],'ShowName', 'off');
%             targetport = get_param(h,'PortHandles');
%             add_line(TargetModel, sourceport.Outport(1), targetport.Inport(1));
%             targetpos = get_param([TargetModel '/HAL_' char(Restore_can(g)) '_outputs'],'Position');
%         end
%     end
end

%% Read MessageLink
path = [project_path '\documents\'];
filenames = dir(path);
filenames = string({filenames.name});
MessageLinkOutName = char(filenames(contains(filenames,'MessageLinkOut')));
xlsAPP = actxserver('excel.application');
xlsAPP.Visible = 1;
xlsWB = xlsAPP.Workbooks;
path = [project_path '\documents\'];
xlsFile = xlsWB.Open([path MessageLinkOutName],[],false,[]);
exlSheet2 = xlsFile.Sheets.Item('OutputSignal');
data2_range = exlSheet2.UsedRange;
OutputSignal = data2_range.value;
OutputSignal(cellfun(@(x) all(ismissing(x)), OutputSignal)) = {'Invalid'};
OutputSignal(end+1,:) = {'Invalid'};
xlsFile.Close(false);
xlsAPP.Quit;

%% Detcet Output signal without Tx CAN Message in MessageLiknOut
for k = 2:length(OutputSignal(2:end-1,1))
    h = find(strcmp(string(OutputSignal(1,:)),string(channel_list(1))));
    h1 = find(strcmp(string(OutputSignal(1,:)),string(channel_list(end))));
    if sum(strcmp(string(OutputSignal(k,h:h1)),'Invalid')) == length(channel_list)
       errorsignal = char(OutputSignal(k,1));
       warning([errorsignal ' is not defined on the DBC file.']); 
    end
end

for n = 1:NUN_CHANNEL  
    path = [project_path '\documents\'];
    filenames = dir(path);
    filenames = string({filenames.name});
    MessageLinkOutName = char(filenames(contains(filenames,'MessageLinkOut')));
    xlsAPP = actxserver('excel.application');
    xlsAPP.Visible = 1;
    xlsWB = xlsAPP.Workbooks;
    path = [project_path '\documents\'];
    xlsFile = xlsWB.Open([path MessageLinkOutName],[],false,[]);
    exlSheet1 = xlsFile.Sheets.Item(char(channel_list(q(n))));
    exlSheet2 = xlsFile.Sheets.Item('OutputSignal');
    data1_range = exlSheet1.UsedRange;
    data2_range = exlSheet2.UsedRange;
    MessageLink = data1_range.value;
    OutputSignal = data2_range.value;
    xlsFile.Close(false);
    xlsAPP.Quit;
    cd(arch_Path);

    %% Read CAN dbc or LIN excel
    cd(arch_Path);
    Channel = char(channel_list(q(n)));
    busID = char(busList(q(n)));
    if contains(Channel,'CAN')
        IsLINMessage = boolean(0);
        path = [project_path '\documents\MessageMap\'];
        filenames = dir(path);
        filenames = string({filenames.name});
        FileName = string(filenames(contains(filenames,Channel)));
        FileName = char(FileName(contains(FileName,'.dbc')));
        DBC= canDatabase([path FileName]);
    else
        Filepath = [project_path '\documents\MessageMap\'];
        filenames = dir(Filepath);
        filenames = string({filenames.name});
        FileName = string(filenames(contains(filenames,Channel)));
        FileName = char(FileName(contains(FileName,'.xlsx')));
        DBC = LinDatabase(Filepath,FileName,Channel,password);
        IsLINMessage = boolean(1);
    end
    Channel = erase(Channel, '_');

    %% Cannel Outport
    if Autosar_flg
        XX = contains(Autosar_output_msg_all,Channel);
        Autosar_output_msg_CAN = Autosar_output_msg_all(XX);
    end

    %% Detect frame routing message on each can
    %
%     if (exist('Frame_routing_array','var') && ~isempty(Frame_routing_array))
%         Detect_Frame_routing_array_can = strcmp(Frame_routing_array(:,4),string(Channel));
%         Detect_Frame_routing_can = find(Detect_Frame_routing_array_can==1);
%         Numb_Restore_array_can = length(Detect_Frame_routing_can);
%         if ~isempty(Detect_Frame_routing_can)
% 
%             Restore_array_can = cell(Numb_Restore_array_can,2);
% 
%             for g = 1:Numb_Restore_array_can
%                 Restore_array_can(g,1) = Frame_routing_array((Detect_Frame_routing_can(g)),1);
%                 Restore_array_can(g,2) = Frame_routing_array((Detect_Frame_routing_can(g)),2);
%                 Restore_array_can(g,3) = Frame_routing_array((Detect_Frame_routing_can(g)),6);
%             end
%         end
%     end

    %% Detect frame routing message on each can for Autosar
    %
%     if (exist('Autosar_Frame_routing_array','var') && ~isempty(Autosar_Frame_routing_array)) && Autosar_flg
%         Detect_Autosar_Frame_routing_array = strcmp(Autosar_Frame_routing_array(:,1),string(Channel));
%         Detect_Autosar_Frame_routing_can = find(Detect_Autosar_Frame_routing_array==1);
%         Numb_Autosar_Frame_array_can = length(Detect_Autosar_Frame_routing_can);
% 
%         if ~isempty(Detect_Autosar_Frame_routing_can)
% 
%             Autosar_Frame_routing_can = cell(Numb_Autosar_Frame_array_can,2);
% 
%             for g = 1:Numb_Autosar_Frame_array_can
%                 Autosar_Frame_routing_can(g,1) = Autosar_Frame_routing_array((Detect_Autosar_Frame_routing_can(g)),1);
%                 Autosar_Frame_routing_can(g,2) = Autosar_Frame_routing_array((Detect_Autosar_Frame_routing_can(g)),2);
%             end
%         end
%     end

    %% Judge Tx Messages
    TxMsgTable = cell(length(DBC.Messages),10);
    MsgCnt = 0;
    SignalCnt = 0;

    for j = 1:length(DBC.Messages)
        if ~contains(DBC.MessageInfo(j).Name,'CCP')...
                && ~contains(DBC.MessageInfo(j).Name,'XCP')...
                && contains(DBC.MessageInfo(j).TxNodes,TargetNode)...
                && ~contains(DBC.MessageInfo(j).Name,'Diag')...
                && ~contains(DBC.MessageInfo(j).Name,'NMm')...
                && ~isempty(DBC.MessageInfo(j).Signals)...
                && any(strcmp(extractAfter(Autosar_output_msg_CAN,'SG_'),DBC.MessageInfo(j).Name))
                %&& ~contains(DBC.MessageInfo(j).Name,'GW')...


            TxMsgTable(j,1) = num2cell(j); % DBC index
            TxMsgTable(j,2) = num2cell(DBC.MessageInfo(j).ID); % Message ID in dec
            TxMsgTable(j,3) = num2cell(DBC.MessageInfo(j).Length); % Data length
            TxMsgTable(j,4) = cellstr(DBC.MessageInfo(j).Name); % Message name
            TxMsgTable(j,5) = cellstr(erase(DBC.MessageInfo(j).Name,'_')); % Message name for DD

            if IsLINMessage
                TxMsgTable(j,2) = num2cell(DBC.MessageInfo(j).PID); % LIN message use PID
                TxMsgTable(j,6) = cellstr('Schedule'); % Message Tx method
                TxMsgTable(j,7) = cellstr(DBC.MessageInfo(j).MsgCycleTime); % LIN message cycle time
                TxMsgTable(j,8) = cellstr(DBC.MessageInfo(j).Delay); % LIN message delay time
                TxMsgTable(j,9) = cellstr('NONE');
            else
                TxMsgTable(j,6) = cellstr(DBC.MessageInfo(j).AttributeInfo(strcmp(DBC.MessageInfo(j).Attributes(:,1),'GenMsgSendType')).Value); % Message Tx method
                TxMsgTable(j,7) = num2cell(DBC.MessageInfo(j).AttributeInfo(strcmp(DBC.MessageInfo(j).Attributes(:,1),'GenMsgCycleTime')).Value);
                TxMsgTable(j,8) = cellstr('0');
                TxMsgTable(j,9) = cellstr(DBC.MessageInfo(j).ProtocolMode); % Judge CAN FD Message
                TxMsgTable(j,10) = cellstr(DBC.MessageInfo(j).AttributeInfo(strcmp(DBC.MessageInfo(j).Attributes(:,1),'DataID')).Value);
            end
            MsgCnt = MsgCnt + 1;
            SignalCnt = SignalCnt + length(DBC.MessageInfo(j).Signals);
        end
    end

    for j = length(TxMsgTable(:,1)):-1:1
        if cellfun(@isempty,TxMsgTable(j,1))
            TxMsgTable(j,:) = [];
        end
    end

    TxMsgTable = [{'DBCidx','ID/PID(dec)','DLC','MsgName','MsgName_DD','MsgTxMethod','MsgCycleTime','LIN Delay time','IDFormat','DataID'};TxMsgTable];
    DD_cell = cell(MsgCnt+10,8);
    DD_cell(1,1) = {['KHAL_' Channel 'TxReq_flg']}; % HAL signal name
    DD_cell(1,2) = {'internal'}; % Direction
    DD_cell(1,3) = {'boolean'}; % data type
    DD_cell(1,4) = {'0'}; % Minimum
    DD_cell(1,5) = {'1'}; % Maximun
    DD_cell(1,6) = {'flg'}; % Unit
    DD_cell(1,7) = {'N/A'}; % Enum Table
    DD_cell(1,8) = {'1'}; % Default during Running

    %% add Message Model
    for i = 2: MsgCnt+1
        TargetModel = [new_model '/' Channel];

        % read Tx message infos
        MsgName = char(TxMsgTable(i,strcmp(TxMsgTable(1,:),'MsgName')));
        MsgName_DD = char(TxMsgTable(i,strcmp(TxMsgTable(1,:),'MsgName_DD')));
        MsgTxMethod = char(TxMsgTable(i,strcmp(TxMsgTable(1,:),'MsgTxMethod')));
        ID = cell2mat(TxMsgTable(i,strcmp(TxMsgTable(1,:),'ID/PID(dec)')));
        MsgID_hex = ['0x' char(dec2hex(ID))];
        DLC = string(TxMsgTable(i,strcmp(TxMsgTable(1,:),'DLC')));
        IDFormat = char(TxMsgTable(i,strcmp(TxMsgTable(1,:),'IDFormat')));

        SignalName_raw = DBC.MessageInfo(cell2mat(TxMsgTable(i,strcmp(TxMsgTable(1,:),'DBCidx')))).Signals;
        if IsLINMessage
            MsgCycleTime = string(TxMsgTable(i,strcmp(TxMsgTable(1,:),'MsgCycleTime')));
            FirstDelay = string(TxMsgTable(i,strcmp(TxMsgTable(1,:),'LIN Delay time')));
        elseif contains(MsgName,'NMm_')
            MsgCycleTime = string(700);      % NMm cycle = 700
        else
            MsgCycleTime = string(TxMsgTable(i,strcmp(TxMsgTable(1,:),'MsgCycleTime')));
        end

        Num_Signal = length(SignalName_raw);
        DD_Index_Msg = find(cellfun(@isempty,DD_cell(1:end,1)));
        DD_cell(DD_Index_Msg(1),1) = {['KHAL_' Channel MsgName_DD 'TxReq_flg']}; % HAL signal name
        DD_cell(DD_Index_Msg(1),2) = {'internal'}; % Direction
        DD_cell(DD_Index_Msg(1),3) = {'boolean'}; % data type
        DD_cell(DD_Index_Msg(1),4) = {'0'}; % Minimum
        DD_cell(DD_Index_Msg(1),5) = {'1'}; % Maximun
        DD_cell(DD_Index_Msg(1),6) = {'flg'}; % Unit
        DD_cell(DD_Index_Msg(1),7) = {'N/A'}; % Enum Table
        DD_cell(DD_Index_Msg(1),8) = {'1'}; % Default during Running

        if strcmp(Channel,'CAN2') && strcmp(MsgName_DD,'FDOTA1')
            DD_cell(DD_Index_Msg(1),8) = {'0'}; % Default during Running
        end

        %% Detcet message match frame rougting
        % 
%         if exist('Detect_Frame_routing_can','var') && ~isempty(Detect_Frame_routing_can)
% 
%             frame_routing = strcmp(string(Restore_array_can(:,3)),string(MsgName));
%             Detect_frame_routing = find(frame_routing == 1);
% 
%             if exist('Detect_frame_routing','var') && ~isempty(Detect_frame_routing)
%                 RxMsgName = char(Restore_array_can(Detect_frame_routing(1),2));
%                 RxMsgName = erase(RxMsgName, '_');
% 
%                 if (length(Detect_frame_routing)>=3)
%                     error('GG');
%                 end
%             end
%         end

        %% FD VCU transmit Checksum & Rolling counter CAN & Message
        CRC_flg = boolean(0);
        CRC_E2E_flg = boolean(0);
        
        if Autosar_flg && any(contains(CAN_Msg_Output_array(:,1),['E2E_' Channel '_SG_' MsgName]))
            CRC_E2E_flg = boolean(1);
        end

        if (strcmp(string(Channel),'CAN1') && (strcmp(string(MsgName),'FD1_VCU2') || strcmp(string(MsgName),'FD1_VCU3') || strcmp(string(MsgName),'VMC_FCM1')))...
           || (strcmp(string(Channel),'CAN1') && (strcmp(string(MsgName),'FD1_APS3')))...
           || (strcmp(string(Channel),'CAN3') && (strcmp(string(MsgName),'FD3_VCU2')))...
           || (strcmp(string(Channel),'CAN3') && (strcmp(string(MsgName),'FD3_VCU2_toNIDEC')))...
           || (strcmp(string(Channel),'CAN4') && strcmp(string(MsgName),'FD4_CE100_0'))...
           || (strcmp(string(Channel),'CAN6') && strcmp(string(MsgName),'FD6_VCU2'))...
           || (strcmp(string(Channel),'CAN6') && strcmp(string(MsgName),'FD6_APS3'))...

            CRC_flg = boolean(1);
            
            CS_array = { 'CAN1' , 'FD1_VCU2' , 'CS_VCU2_CAN1' ;...
                        'CAN1' , 'FD1_VCU3' , 'CS_VCU3_CAN1' ;...
                        'CAN1' , 'FD1_APS3' , 'APS3_checksum' ;...
                        'CAN1' , 'VMC_FCM1' , 'VMC_FCM1_Checksum' ;...
                        'CAN3' , 'FD3_VCU2' , 'CS_VCU2_CAN1' ;...
                        'CAN3' , 'FD3_VCU2_toNIDEC' , 'CS_VCU2_CAN1_toNidec' ;...
                        'CAN4' , 'FD4_CE100_0' , 'CS_VCU1_CAN4' ;...
                        'CAN6' , 'FD6_VCU2' , 'CS_VCU2_CAN6' ;...
                        'CAN6' , 'FD6_APS3' , 'APS3_checksum'};
            
            RC_array = { 'CAN1' , 'FD1_VCU2' , 'RC_VCU2_CAN1' ;...
                        'CAN1' , 'FD1_VCU3' , 'RC_VCU3_CAN1' ;...
                        'CAN1' , 'FD1_APS3' , 'APS3_LifeCount' ;...
                        'CAN1' , 'VMC_FCM1' , 'VMC_FCM1_LifeCount' ;...
                        'CAN3' , 'FD3_VCU2' , 'RC_VCU2_CAN1' ;...
                        'CAN3' , 'FD3_VCU2_toNIDEC' , 'RC_VCU2_CAN1_toNidec' ;...
                        'CAN4' , 'FD4_CE100_0' , 'RC_VCU1_CAN4' ;...
                        'CAN6' , 'FD6_VCU2' , 'RC_VCU2_CAN6' ;...
                        'CAN6' , 'FD6_APS3' , 'APS3_LifeCount'};
            
            % Get Message E2E DataID
            DataID = char(TxMsgTable(i,strcmp(TxMsgTable(1,:),'DataID')));
            if ~isempty(DataID)
                DataID1 = DataID(5:6);
                DataID2 = DataID(3:4);
            end
            % Create calibration for E2E trigger
            DD_Index_Msg = find(cellfun(@isempty,DD_cell(1:end,1)));
            DD_cell(DD_Index_Msg(1),1) = {['KHAL_' Channel erase(MsgName,'_') 'E2E_flg']}; % HAL signal name
            DD_cell(DD_Index_Msg(1),2) = {'internal'}; % Direction
            DD_cell(DD_Index_Msg(1),3) = {'boolean'}; % data type
            DD_cell(DD_Index_Msg(1),4) = {'0'}; % Minimum
            DD_cell(DD_Index_Msg(1),5) = {'1'}; % Maximun
            DD_cell(DD_Index_Msg(1),6) = {'flg'}; % Unit
            DD_cell(DD_Index_Msg(1),7) = {'N/A'}; % Enum Table
            DD_cell(DD_Index_Msg(1),8) = {'1'}; % for E2E enable
            if (strcmp(string(Channel),'CAN3') && (strcmp(string(MsgName),'FD3_VCU2_toNIDEC')))
                DD_cell(DD_Index_Msg(1),8) = {'0'}; % for E2E disable
            end
        end
        
        %% add Msg triggered subsystem
        BlockName = [MsgName '_' MsgID_hex];
        i = i-1;
        if (1<=i) && (i<=5)
            block_x = original_x;
            block_y = original_y + 600 + i*400;
        elseif (6<=i) && (i<=10)
            block_x = original_x + 1000;
            block_y = original_y + 600 + (i-5)*400;
        elseif (11<=i) && (i<=15)
            block_x = original_x + 2000;
            block_y = original_y + 600 + (i-10)*400;
        elseif (16<=i) && (i<=20)
            block_x = original_x + 3000;
            block_y = original_y + 600 + (i-15)*400;
        elseif (21<=i) && (i<=25)
            block_x = original_x + 4000;
            block_y = original_y + 600 + (i-20)*400;
        elseif (26<=i) && (i<=30)
            block_x = original_x + 5000;
            block_y = original_y + 600 + (i-25)*400;
        elseif (31<=i) && (i<=35)
            block_x = original_x + 6000;
            block_y = original_y + 600 + (i-30)*400;
        elseif (36<=i) && (i<=40)
            block_x = original_x + 7000;
            block_y = original_y + 600 + (i-35)*400;
        else
            block_x = original_x + 8000;
            block_y = original_y + 600 + (i-40)*400;
        end
        i = i+1;
        block_w = block_x + 250;
        block_h = block_y + 200;
        if CRC_flg
            srcT = 'simulink/Ports & Subsystems/Triggered Subsystem';
        else
            srcT = 'simulink/Ports & Subsystems/Subsystem';
        end
        dstT = [TargetModel '/' BlockName];
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'ContentPreviewEnabled','off','BackgroundColor','Gray');

        %% set up Msg block

        if ~exist('Detect_frame_routing','var') || isempty(Detect_frame_routing)
            MsgModel = [TargetModel '/' BlockName];
            block_x = original_x;
            block_y = original_y;
            block_w = block_x + 30;
            block_h = block_y + 30;
            if CRC_flg
                set_param([MsgModel '/Trigger'],'TriggerType','function-call')
                set_param([MsgModel '/Trigger'],'position',[block_x,block_y,block_w,block_h]);
            end
            block_x = original_x;
            block_y = original_y+100;
            block_w = block_x + 30;
            block_h = block_y + 13;
            set_param([MsgModel '/In1'],'position',[block_x,block_y,block_w,block_h]);
            if SCP_flg
                set_param([MsgModel '/In1'],'UseBusObject','on','BusObject','BSCP_outputs');
            end
            set_param([MsgModel '/In1'],'Name','BSCP_outputs');
            delete_line(MsgModel, 'BSCP_outputs/1','Out1/1');
            delete_block([MsgModel '/Out1']);

            sourceport = get_param([MsgModel '/BSCP_outputs'],'PortHandles');
            targetpos = get_param(sourceport.Outport(1),'Position');
            BlockName = 'Goto';
            block_x = targetpos(1) + 100;
            block_y = targetpos(2)-20;
            block_w = block_x + 220;
            block_h = block_y + 40;
            srcT = 'simulink/Signal Routing/Goto';
            dstT = [MsgModel '/' BlockName];
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h,'Gototag', 'BSCP_outputs','ShowName', 'off');
            targetport = get_param(h,'PortHandles');
            add_line(MsgModel, sourceport.Outport(1),targetport.Inport(1));

            BlockName = 'BOUTP_outputs';
            block_x = original_x;
            block_y = original_y+150;
            block_w = block_x + 30;
            block_h = block_y + 13;
            srcT = 'simulink/Sources/In1';
            dstT = [MsgModel '/' BlockName];
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h,'UseBusObject','on','BusObject','BOUTP_outputs','Name','BOUTP_outputs');

            sourceport = get_param([MsgModel '/BOUTP_outputs'],'PortHandles');
            targetpos = get_param(sourceport.Outport(1),'Position');
            BlockName = 'Goto';
            block_x = targetpos(1) + 100;
            block_y = targetpos(2)-20;
            block_w = block_x + 220;
            block_h = block_y + 40;
            srcT = 'simulink/Signal Routing/Goto';
            dstT = [MsgModel '/' BlockName];
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h,'Gototag', 'BOUTP_outputs','ShowName', 'off');
            targetport = get_param(h,'PortHandles');
            add_line(MsgModel, sourceport.Outport(1),targetport.Inport(1));

            targetport = get_param(MsgModel,'PortHandles');
            targetpos = get_param(targetport.Inport(1),'Position');
            BlockName = 'From';
            block_x = targetpos(1) - 300;
            block_y = targetpos(2) - 20;
            block_w = block_x + 220;
            block_h = block_y + 40;
            srcT = 'simulink/Signal Routing/From';
            dstT = [TargetModel '/' BlockName];
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h,'Gototag', 'BSCP_outputs','ShowName', 'off');
            sourceport = get_param(h,'PortHandles');
            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on')

            targetpos = get_param(targetport.Inport(2),'Position');
            BlockName = 'From';
            block_x = targetpos(1) - 300;
            block_y = targetpos(2) - 20;
            block_w = block_x + 220;
            block_h = block_y + 40;
            srcT = 'simulink/Signal Routing/From';
            dstT = [TargetModel '/' BlockName];
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h,'Gototag', 'BOUTP_outputs','ShowName', 'off');
            sourceport = get_param(h,'PortHandles');
            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(2),'autorouting','on')

       %  elseif exist('Detect_frame_routing','var') && ~isempty(Detect_frame_routing)
%             RxCAN = char(Restore_array_can(Detect_frame_routing(1),1));
%             MsgModel = [TargetModel '/' BlockName];
%             block_x = original_x;
%             block_y = original_y;
%             block_w = block_x + 30;
%             block_h = block_y + 30;
%             set_param([MsgModel '/Trigger'],'TriggerType','function-call')
%             set_param([MsgModel '/Trigger'],'position',[block_x,block_y,block_w,block_h]);
%             block_x = original_x;
%             block_y = original_y + 100;
%             block_w = block_x + 30;
%             block_h = block_y + 13;
%             set_param([MsgModel '/In1'],'position',[block_x,block_y,block_w,block_h]);
%             set_param([MsgModel '/In1'],'Name',['HAL_' RxCAN '_outputs']);
%             delete_line(MsgModel, ['HAL_' RxCAN '_outputs/1'],'Out1/1');
%             delete_block([MsgModel '/Out1']);
% 
%             sourceport = get_param([MsgModel '/HAL_' RxCAN '_outputs'],'PortHandles');
%             targetpos = get_param(sourceport.Outport(1),'Position');
%             BlockName = 'Goto';
%             block_x = targetpos(1) + 100;
%             block_y = targetpos(2)-20;
%             block_w = block_x + 220;
%             block_h = block_y + 40;
%             srcT = 'simulink/Signal Routing/Goto';
%             dstT = [MsgModel '/' BlockName];
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'Gototag', ['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%             targetport = get_param(h,'PortHandles');
%             add_line(MsgModel, sourceport.Outport(1),targetport.Inport(1));
% 
%             if (length(Detect_frame_routing)>1)
%                 RxCAN = char(Restore_array_can(Detect_frame_routing(2),1));
%                 % For frame routing input
%                 BlockName = ['HAL_' RxCAN '_outputs'];
%                 block_x = original_x;
%                 block_y = original_y+150;
%                 block_w = block_x + 30;
%                 block_h = block_y + 13;
%                 srcT = 'simulink/Sources/In1';
%                 dstT = [MsgModel '/' BlockName];
%                 h = add_block(srcT,dstT,'MakeNameUnique','on');
%                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                 set_param(h,'Name',['HAL_' RxCAN '_outputs']);
% 
%                 % For frame routing goto
%                 sourceport = get_param([MsgModel '/HAL_' RxCAN '_outputs'],'PortHandles');
%                 targetpos = get_param(sourceport.Outport(1),'Position');
%                 BlockName = 'Goto';
%                 block_x = targetpos(1) + 100;
%                 block_y = targetpos(2)-20;
%                 block_w = block_x + 220;
%                 block_h = block_y + 40;
%                 srcT = 'simulink/Signal Routing/Goto';
%                 dstT = [MsgModel '/' BlockName];
%                 h = add_block(srcT,dstT,'MakeNameUnique','on');
%                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                 set_param(h,'Gototag', ['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%                 targetport = get_param(h,'PortHandles');
%                 add_line(MsgModel, sourceport.Outport(1),targetport.Inport(1));
%             end
% 
%             RxCAN = char(Restore_array_can(Detect_frame_routing(1),1));
%             targetport = get_param(MsgModel,'PortHandles');
%             targetpos = get_param(targetport.Inport(1),'Position');
%             BlockName = 'From';
%             block_x = targetpos(1) - 300;
%             block_y = targetpos(2) - 20;
%             block_w = block_x + 220;
%             block_h = block_y + 40;
%             srcT = 'simulink/Signal Routing/From';
%             dstT = [TargetModel '/' BlockName];
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'Gototag', ['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%             sourceport = get_param(h,'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on')
% 
%             if (length(Detect_frame_routing)>1)
%                 RxCAN = char(Restore_array_can(Detect_frame_routing(2),1));
%                 targetport = get_param(MsgModel,'PortHandles');
%                 targetpos = get_param(targetport.Inport(2),'Position');
%                 BlockName = 'From';
%                 block_x = targetpos(1) - 300;
%                 block_y = targetpos(2) - 20;
%                 block_w = block_x + 220;
%                 block_h = block_y + 40;
%                 srcT = 'simulink/Signal Routing/From';
%                 dstT = [TargetModel '/' BlockName];
%                 h = add_block(srcT,dstT,'MakeNameUnique','on');
%                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                 set_param(h,'Gototag', ['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%                 sourceport = get_param(h,'PortHandles');
%                 add_line(TargetModel,sourceport.Outport(1),targetport.Inport(2),'autorouting','on')
%             end
        end

        %%  Add message Tx controller
        if ~Autosar_flg || CRC_flg || CRC_E2E_flg
            targetport = get_param(MsgModel,'PortHandles');
            if CRC_E2E_flg
                targetpos = get_param(MsgModel,'Position');
                block_x = targetpos(1) - 275;
                block_y = targetpos(2) - 150;
            else
                targetpos = get_param(targetport.Trigger(1),'Position');
                block_x = targetpos(1) - 400;
                block_y = targetpos(2) - 150;
            end
            BlockName = [MsgName '_Tx'];
            block_w = block_x + 200;
            block_h = block_y + 100;
            if IsLINMessage
                srcT = 'FVT_lib/hal/LIN_Scheduler';
            elseif ~contains(MsgName,'NMm_') && (contains(MsgTxMethod,'Event') || (exist('Detect_frame_routing','var') && ~isempty(Detect_frame_routing)))
                srcT = 'FVT_lib/hal/MsgTxController_Event';
            elseif (contains(MsgTxMethod,'CE') || contains(MsgName,'NMm_'))
                srcT = 'FVT_lib/hal/MsgTxController_CE';
            else
                srcT = 'FVT_lib/hal/MsgTxController';
            end
            dstT = [TargetModel '/' BlockName];
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h, 'LinkStatus', 'inactive','ShowName','off');
            if IsLINMessage
                set_param(h, 'MaskValues', {MsgCycleTime,FirstDelay});
            elseif (exist('Detect_frame_routing','var') && ~isempty(Detect_frame_routing))

            elseif contains(MsgTxMethod,'CE')|| contains(MsgTxMethod,'Cycle') || contains(MsgName,'NMm_')
                set_param(h, 'MaskValues', {MsgCycleTime});
            end
            sourceport = get_param(h,'PortHandles');
            % E2E Tx output set
            if CRC_E2E_flg
                targetpos = get_param(sourceport.Outport(1),'Position');
                BlockName = ['E2E_' Channel '_SG_' MsgName '_Trigger'];
                block_x = targetpos(1) + 425;
                block_y = targetpos(2) - 7;    
                block_w = block_x + 30;
                block_h = block_y + 13;
                srcT = 'simulink/Sinks/Out1';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT);  
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                targetport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on');
                % CAN4 FD_VCU1
                if CRC_flg              
                   targetport = get_param(MsgModel,'PortHandles'); 
                   add_line(TargetModel,sourceport.Outport(1),targetport.Trigger(1),'autorouting','on');
                end
            else
                add_line(TargetModel,sourceport.Outport(1),targetport.Trigger(1),'autorouting','on'); 
            end

            if  (strcmp(MsgTxMethod,'CE') || strcmp(MsgTxMethod,'Cycle') || strcmp(MsgTxMethod,'Event')) && ~contains(MsgName,'NMm_')
                targetport = sourceport;
                targetpos = get_param(targetport.Inport(1),'Position');
                BlockName = 'Constant';
                block_x = targetpos(1) - 300;
                block_y = targetpos(2) - 20;
                block_w = block_x + 220;
                block_h = block_y + 40;
                srcT = 'simulink/Commonly Used Blocks/Constant';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Value',['KHAL_' Channel MsgName_DD 'TxReq_flg'],'ShowName', 'off');
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on');

                % set up TxControllerModel only for NMm message

            elseif contains(MsgName,'NMm_')
                targetport = sourceport;
                targetpos = get_param(targetport.Inport(1),'Position');
                BlockName = 'Bus selector';
                block_x = targetpos(1) - 40;
                block_y = targetpos(2) - 10;
                block_w = block_x + 5 ;
                block_h = block_y + 40;
                srcT = 'simulink/Signal Routing/Bus Selector';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h],'outputsignals','VOUTP_NMmTxReq_flg','ShowName', 'off'); %TBD
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(2),'autorouting','on');

                targetport = sourceport;
                targetpos = get_param(targetport.Inport(1),'Position');
                BlockName = 'From';
                block_x = targetpos(1) - 255;
                block_y = targetpos(2) - 20;
                block_w = block_x + 220;
                block_h = block_y + 40;
                srcT = 'simulink/Signal Routing/From';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Gototag','BOUTP_outputs','ShowName', 'off');
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on');
                % inside controller model
                TargetModel = [new_model '/' Channel '/' MsgName '_Tx'];
                delete_block([TargetModel  '/Signals1']);
                sourceport = get_param([TargetModel '/Signals'],'PortHandles');
                targetpos = get_param(sourceport.Outport(1),'Position');
                BlockName = 'Goto';
                block_x = targetpos(1) + 100;
                block_y = targetpos(2)-20;
                block_w = block_x + 200;
                block_h = block_y + 40;
                srcT = 'simulink/Signal Routing/Goto';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Gototag','VOUTP_NMmTxReq_flg','ShowName', 'off');
                set_param([TargetModel '/Signals'],'Name','VOUTP_NMmTxReq_flg');
                targetport = get_param(h,'PortHandles');
                add_line(TargetModel, sourceport.Outport(1),targetport.Inport(1));

                targetpos = get_param(sourceport.Outport(1),'Position');
                BlockName = 'Goto';
                block_x = targetpos(1) +100;
                block_y = targetpos(2) + 200;
                block_w = block_x + 200;
                block_h = block_y + 40;
                srcT = 'simulink/Signal Routing/Goto';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Gototag', 'EventReq_flg','ShowName', 'off');

                targetport = get_param(h,'PortHandles');
                targetpos = get_param(targetport.Inport(1),'Position');
                BlockName='detect_Increase';
                srcT = 'simulink/Logic and Bit Operations/Detect Increase';
                dstT = [TargetModel '/' BlockName];
                block_x = targetpos(1) - 200;
                block_y = targetpos(2) - 15;
                block_w = block_x + 70;
                block_h = block_y + 30;
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h],'ShowName', 'off');
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));

                targetpos = get_param(h,'Position');
                targetport = get_param(h,'PortHandles');
                BlockName = 'From';
                block_x = targetpos(1) - 300;
                block_y = targetpos(2) - 5;
                block_w = block_x + 220;
                block_h = block_y + 40;
                srcT = 'simulink/Signal Routing/From';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Gototag','VOUTP_NMmTxReq_flg','ShowName', 'off');
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
            end

            % set up Tx_Controller Model only for CE message
            if  (~Autosar_flg || CRC_flg || CRC_E2E_flg) && strcmp(MsgTxMethod,'CE') && (~exist('Detect_frame_routing','var') || isempty(Detect_frame_routing))
                targetpos = get_param(targetport.Inport(2),'Position');
                BlockName = 'From';
                block_x = targetpos(1) - 300;
                block_y = targetpos(2) - 20;
                block_w = block_x + 220;
                block_h = block_y + 40;
                srcT = 'simulink/Signal Routing/From';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Gototag', 'BSCP_outputs','ShowName', 'off');
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(2),'autorouting','on')

                targetpos = get_param(targetport.Inport(3),'Position');
                BlockName = 'From';
                block_x = targetpos(1) - 300;
                block_y = targetpos(2) - 20;
                block_w = block_x + 220;
                block_h = block_y + 40;
                srcT = 'simulink/Signal Routing/From';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Gototag', 'BOUTP_outputs','ShowName', 'off');
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(3),'autorouting','on')

                % inside controller model
                TargetModel = [new_model '/' Channel '/' MsgName '_Tx'];
                sourceport = get_param([TargetModel '/Signals'],'PortHandles');
                targetpos = get_param(sourceport.Outport(1),'Position');
                BlockName = 'Goto';
                block_x = targetpos(1) + 100;
                block_y = targetpos(2)-20;
                block_w = block_x + 220;
                block_h = block_y + 40;
                srcT = 'simulink/Signal Routing/Goto';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Gototag', 'BSCP_outputs','ShowName', 'off');
                if SCP_flg
                set_param([TargetModel '/Signals'],'UseBusObject','on','BusObject','BSCP_outputs','Name','BSCP_outputs');
                else
                set_param([TargetModel '/Signals'],'Name','BSCP_outputs');
                end
                targetport = get_param(h,'PortHandles');
                add_line(TargetModel, sourceport.Outport(1),targetport.Inport(1));

                sourceport = get_param([TargetModel '/Signals1'],'PortHandles');
                targetpos = get_param(sourceport.Outport(1),'Position');
                BlockName = 'Goto';
                block_x = targetpos(1) + 100;
                block_y = targetpos(2)-20;
                block_w = block_x + 220;
                block_h = block_y + 40;
                srcT = 'simulink/Signal Routing/Goto';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Gototag', 'BOUTP_outputs','ShowName', 'off');
                set_param([TargetModel '/Signals1'],'UseBusObject','on','BusObject','BOUTP_outputs','Name','BOUTP_outputs');
                targetport = get_param(h,'PortHandles');
                add_line(TargetModel, sourceport.Outport(1),targetport.Inport(1));

                BlockName = 'OR';
                block_x = targetpos(1);
                block_y = targetpos(2)+50;
                block_w = block_x + 50;
                block_h = block_y + 50*Num_Signal;
                srcT = 'simulink/Commonly Used Blocks/Logical Operator';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Inputs', num2str(Num_Signal));
                set_param(h,'Operator','OR');
                sourceport = get_param(h,'PortHandles');

                targetpos = get_param(sourceport.Outport(1),'Position');
                BlockName = 'Goto';
                block_x = targetpos(1) +100;
                block_y = targetpos(2) - 20;
                block_w = block_x + 220;
                block_h = block_y + 40;
                srcT = 'simulink/Signal Routing/Goto';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Gototag', 'EventReq_flg','ShowName', 'off');
                targetport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));

                %set up Tx_Controller Model only for frame routing message and event
            % elseif (exist('Detect_frame_routing','var') && ~isempty(Detect_frame_routing)) %&& (strcmp(MsgTxMethod,'CE') ||  strcmp(MsgTxMethod,'Event'))
% 
%                 RxCAN = char(Restore_array_can(Detect_frame_routing(1),1));
%                 targetpos = get_param(targetport.Inport(2),'Position');
%                 BlockName = 'From';
%                 block_x = targetpos(1) - 300;
%                 block_y = targetpos(2) - 20;
%                 block_w = block_x + 220;
%                 block_h = block_y + 40;
%                 srcT = 'simulink/Signal Routing/From';
%                 dstT = [TargetModel '/' BlockName];
%                 h = add_block(srcT,dstT,'MakeNameUnique','on');
%                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                 set_param(h,'Gototag',['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%                 sourceport = get_param(h,'PortHandles');
%                 add_line(TargetModel,sourceport.Outport(1),targetport.Inport(2),'autorouting','on')
% 
%                 if (length(Detect_frame_routing)>1)
%                     RxCAN = char(Restore_array_can(Detect_frame_routing(2),1));
%                     targetpos = get_param(targetport.Inport(3),'Position');
%                     BlockName = 'From';
%                     block_x = targetpos(1) - 300;
%                     block_y = targetpos(2) - 20;
%                     block_w = block_x + 220;
%                     block_h = block_y + 40;
%                     srcT = 'simulink/Signal Routing/From';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'Gototag', ['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(3),'autorouting','on')
% 
% 
%                     % inside controller model
%                     TargetModel = [new_model '/' Channel '/' MsgName '_Tx'];
%                     RxCAN = char(Restore_array_can(Detect_frame_routing(1),1));
%                     sourceport = get_param([TargetModel '/Signals'],'PortHandles');
%                     targetpos = get_param(sourceport.Outport(1),'Position');
%                     BlockName = 'Goto';
%                     block_x = targetpos(1) + 100;
%                     block_y = targetpos(2)-20;
%                     block_w = block_x + 220;
%                     block_h = block_y + 40;
%                     srcT = 'simulink/Signal Routing/Goto';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'Gototag', ['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%                     set_param([TargetModel '/Signals'],'Name',['HAL_' RxCAN '_outputs']);
%                     targetport = get_param(h,'PortHandles');
%                     add_line(TargetModel, sourceport.Outport(1),targetport.Inport(1));
% 
%                     RxCAN = char(Restore_array_can(Detect_frame_routing(2),1));
%                     sourceport = get_param([TargetModel '/Signals1'],'PortHandles');
%                     targetpos = get_param(sourceport.Outport(1),'Position');
%                     BlockName = 'Goto';
%                     block_x = targetpos(1) + 100;
%                     block_y = targetpos(2)-20;
%                     block_w = block_x + 220;
%                     block_h = block_y + 40;
%                     srcT = 'simulink/Signal Routing/Goto';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'Gototag', ['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%                     set_param([TargetModel '/Signals1'],'Name',['HAL_' RxCAN '_outputs']);
%                     targetport = get_param(h,'PortHandles');
%                     add_line(TargetModel, sourceport.Outport(1),targetport.Inport(1));
% 
%                     % Add bus selector and from for frame routing
% 
%                     targetpos = get_param(h,'Position');
%                     BlockName = 'Goto';
%                     block_x = targetpos(1);
%                     block_y = targetpos(2) +90;
%                     block_w = block_x + 220;
%                     block_h = block_y + 40;
%                     srcT = 'simulink/Signal Routing/Goto';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'Gototag', 'EventReq_flg','ShowName', 'off');
% 
%                     targetport = get_param(h,'PortHandles');
%                     targetpos = get_param(targetport.Inport(1),'Position');
%                     BlockName = 'OR';
%                     block_x = targetpos(1)-100;
%                     block_y = targetpos(2)-50;
%                     block_w = block_x + 50;
%                     block_h = block_y + 50*length(Detect_frame_routing);
%                     srcT = 'simulink/Commonly Used Blocks/Logical Operator';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'Inputs', '2');
%                     set_param(h,'Operator','OR');
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel, sourceport.Outport(1),targetport.Inport(1));
% 
%                     targetport = get_param([TargetModel '/OR'],'PortHandles');
%                     targetpos = get_param(targetport.Inport(1),'Position');
%                     BlockName='detect_change';
%                     srcT = 'simulink/Logic and Bit Operations/Detect Change';
%                     dstT = [TargetModel '/' BlockName];
%                     block_x = targetpos(1) - 200;
%                     block_y = targetpos(2) - 15;
%                     block_w = block_x + 70;
%                     block_h = block_y + 30;
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h],'ShowName', 'off');
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
%                     targetport = get_param([TargetModel '/OR'],'PortHandles');
%                     targetpos = get_param(targetport.Inport(2),'Position');
%                     BlockName='detect_change1';
%                     srcT = 'simulink/Logic and Bit Operations/Detect Change';
%                     dstT = [TargetModel '/' BlockName];
%                     block_x = targetpos(1) - 200;
%                     block_y = targetpos(2) - 15;
%                     block_w = block_x + 70;
%                     block_h = block_y + 30;
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h],'ShowName', 'off');
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(2));
% 
%                     RxCAN = char(Restore_array_can(Detect_frame_routing(1),1));
%                     targetport = get_param([TargetModel '/detect_change'],'PortHandles');
%                     targetpos = get_param(targetport.Inport(1),'Position');
%                     BlockName = 'Bus_Selector';
%                     block_x = targetpos(1) -180;
%                     block_y = targetpos(2) -15;
%                     block_w = block_x + 10;
%                     block_h = block_y + 30;
%                     srcT = 'simulink/Signal Routing/Bus Selector';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT);
%                     set_param(h,'outputsignals',['VHAL_' RxCAN RxMsgName '_cnt'],'ShowName', 'off');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
%                     targetpos = get_param(h,'Position');
%                     targetport = get_param(h,'PortHandles');
%                     BlockName = 'From';
%                     block_x = targetpos(1) - 300;
%                     block_y = targetpos(2) - 5;
%                     block_w = block_x + 220;
%                     block_h = block_y + 40;
%                     srcT = 'simulink/Signal Routing/From';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'Gototag',['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1))
% 
%                     RxCAN = char(Restore_array_can(Detect_frame_routing(2),1));
%                     targetport = get_param([TargetModel '/detect_change1'],'PortHandles');
%                     targetpos = get_param(targetport.Inport(1),'Position');
%                     BlockName = 'Bus_Selector1';
%                     block_x = targetpos(1) -180;
%                     block_y = targetpos(2) -15;
%                     block_w = block_x + 10;
%                     block_h = block_y + 30;
%                     srcT = 'simulink/Signal Routing/Bus Selector';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT);
%                     set_param(h,'outputsignals',['VHAL_' RxCAN RxMsgName '_cnt'],'ShowName', 'off');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
% 
%                     targetpos = get_param(h,'Position');
%                     targetport = get_param(h,'PortHandles');
%                     BlockName = 'From';
%                     block_x = targetpos(1) - 300;
%                     block_y = targetpos(2) - 5;
%                     block_w = block_x + 220;
%                     block_h = block_y + 40;
%                     srcT = 'simulink/Signal Routing/From';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'Gototag',['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
% 
%                 else
%                     targetpos = get_param(targetport.Inport(3),'Position');
%                     BlockName = 'From';
%                     block_x = targetpos(1) - 300;
%                     block_y = targetpos(2) - 20;
%                     block_w = block_x + 220;
%                     block_h = block_y + 40;
%                     srcT = 'simulink/Signal Routing/From';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'Gototag', 'BOUTP_outputs','ShowName', 'off');
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(3),'autorouting','on')
% 
% 
%                     % inside controller model
%                     TargetModel = [new_model '/' Channel '/' MsgName '_Tx'];
%                     RxCAN = char(Restore_array_can(Detect_frame_routing(1),1));
%                     sourceport = get_param([TargetModel '/Signals'],'PortHandles');
%                     targetpos = get_param(sourceport.Outport(1),'Position');
%                     BlockName = 'Goto';
%                     block_x = targetpos(1) + 100;
%                     block_y = targetpos(2)-20;
%                     block_w = block_x + 220;
%                     block_h = block_y + 40;
%                     srcT = 'simulink/Signal Routing/Goto';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'Gototag', ['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%                     set_param([TargetModel '/Signals'],'Name',['HAL_' RxCAN '_outputs']);
%                     targetport = get_param(h,'PortHandles');
%                     add_line(TargetModel, sourceport.Outport(1),targetport.Inport(1));
% 
%                     sourceport = get_param([TargetModel '/Signals1'],'PortHandles');
%                     targetpos = get_param(sourceport.Outport(1),'Position');
%                     BlockName = 'Goto';
%                     block_x = targetpos(1) + 100;
%                     block_y = targetpos(2)-20;
%                     block_w = block_x + 220;
%                     block_h = block_y + 40;
%                     srcT = 'simulink/Signal Routing/Goto';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'Gototag', 'BOUTP_outputs','ShowName', 'off');
%                     set_param([TargetModel '/Signals1'],'UseBusObject','on','BusObject','BOUTP_outputs','Name','BOUTP_outputs');
%                     targetport = get_param(h,'PortHandles');
%                     add_line(TargetModel, sourceport.Outport(1),targetport.Inport(1));
% 
%                     % Add bus selector and from for frame routing
% 
%                     targetpos = get_param(h,'Position');
%                     BlockName = 'Goto';
%                     block_x = targetpos(1);
%                     block_y = targetpos(2) +70;
%                     block_w = block_x + 220;
%                     block_h = block_y + 40;
%                     srcT = 'simulink/Signal Routing/Goto';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'Gototag', 'EventReq_flg','ShowName', 'off');
% 
%                     targetport = get_param(h,'PortHandles');
%                     targetpos = get_param(h,'Position');
%                     BlockName='detect_change';
%                     srcT = 'simulink/Logic and Bit Operations/Detect Change';
%                     dstT = [TargetModel '/' BlockName];
%                     block_x = targetpos(1) - 120;
%                     block_y = targetpos(2) + 5;
%                     block_w = block_x + 70;
%                     block_h = block_y + 30;
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h],'ShowName', 'off');
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
% 
%                     targetport = get_param(h,'PortHandles');
%                     targetpos = get_param(targetport.Inport(1),'Position');
%                     BlockName = 'Bus_Selector';
%                     block_x = targetpos(1) -180;
%                     block_y = targetpos(2) -15;
%                     block_w = block_x + 10;
%                     block_h = block_y + 30;
%                     srcT = 'simulink/Signal Routing/Bus Selector';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT);
%                     set_param(h,'outputsignals',['VHAL_' RxCAN RxMsgName '_cnt'],'ShowName', 'off');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
% 
%                     targetpos = get_param(h,'Position');
%                     targetport = get_param(h,'PortHandles');
%                     BlockName = 'From';
%                     block_x = targetpos(1) - 300;
%                     block_y = targetpos(2) - 5;
%                     block_w = block_x + 220;
%                     block_h = block_y + 40;
%                     srcT = 'simulink/Signal Routing/From';
%                     dstT = [TargetModel '/' BlockName];
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'Gototag',['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1))
%                 end
% 
%             elseif (~exist('Detect_frame_routing','var') || isempty(Detect_frame_routing)) && strcmp(MsgTxMethod,'Event') && ~contains(MsgName,'NMm_')
% 
%                 targetpos = get_param(targetport.Inport(2),'Position');
%                 BlockName = 'Ground';
%                 block_x = targetpos(1) - 60;
%                 block_y = targetpos(2) - 15;
%                 block_w = block_x + 30;
%                 block_h = block_y + 30;
%                 srcT = 'simulink/Commonly Used Blocks/Ground';
%                 dstT = [TargetModel '/' BlockName];
%                 h = add_block(srcT,dstT,'MakeNameUnique','on');
%                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                 sourceport = get_param(h,'PortHandles');
%                 add_line(TargetModel,sourceport.Outport(1),targetport.Inport(2),'autorouting','on')
%                 add_line(TargetModel,sourceport.Outport(1),targetport.Inport(3),'autorouting','on')
% 
%                 % inside controller model
%                 TargetModel = [new_model '/' Channel '/' MsgName '_Tx'];
%                 sourceport = get_param([TargetModel '/Signals'],'PortHandles');
%                 targetpos = get_param(sourceport.Outport(1),'Position');
%                 BlockName = 'Goto';
%                 block_x = targetpos(1) + 100;
%                 block_y = targetpos(2)-20;
%                 block_w = block_x + 200;
%                 block_h = block_y + 40;
%                 srcT = 'simulink/Signal Routing/Goto';
%                 dstT = [TargetModel '/' BlockName];
%                 h = add_block(srcT,dstT,'MakeNameUnique','on');
%                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                 set_param(h,'Gototag', 'EventReq_flg','ShowName', 'off');
%                 set_param([TargetModel '/Signals'],'Name','EventReq_flg');
%                 targetport = get_param(h,'PortHandles');
%                 add_line(TargetModel, sourceport.Outport(1),targetport.Inport(1));
% 
%                 sourceport = get_param([TargetModel '/Signals1'],'PortHandles');
%                 targetpos = get_param(sourceport.Outport(1),'Position');
%                 BlockName = 'Terminator';
%                 block_x = targetpos(1) + 50;
%                 block_y = targetpos(2) -20;
%                 block_w = block_x + 25;
%                 block_h = block_y + 35;
%                 srcT = 'simulink/Commonly Used Blocks/Terminator';
%                 dstT = [TargetModel '/' BlockName];
%                 h = add_block(srcT,dstT,'MakeNameUnique','on');
%                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                 targetport = get_param(h,'PortHandles');
%                 add_line(TargetModel, sourceport.Outport(1),targetport.Inport(1));

            end
        end
        %% Add transmitter in Msg block
        TargetModel = MsgModel;
        BlockName = MsgName;
        block_x = original_x+1500;
        block_y = original_y+500;
        block_w = block_x + 250;
        block_h = block_y + 50*str2double(DLC);
        if IsLINMessage
            srcT = 'FVT_lib/hal/LINTransmit';
            buf = 3; % Tx data port number
            TransmitSet = {busID,MsgID_hex,DLC};
        elseif strcmp(IDFormat,'CAN FD')
            IsCANFD = '1';
            srcT = 'FVT_lib/hal/CANTransmit';
            buf = 4; % Tx data port number
            TransmitSet = {busID,MsgID_hex,DLC,IsCANFD};
        else
            IsCANFD = '0';
            srcT = 'FVT_lib/hal/CANTransmit';
            buf = 4; % Tx data port number
            TransmitSet = {busID,MsgID_hex,DLC,IsCANFD};
        end

        if ~Autosar_flg
            dstT = [TargetModel '/' BlockName];
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h, 'LinkStatus', 'inactive','MaskValues',TransmitSet);
            Obj = get_param([TargetModel '/' BlockName '/C Caller'],'FunctionPortSpecification');
            Obj.InputArguments(buf).Size = DLC;
        end
        
        if exist('Detect_frame_routing','var') && ~isempty(Detect_frame_routing) && (length(Detect_frame_routing)==1)
        %   RxCAN = char(Restore_array_can(Detect_frame_routing(1),1));
%             targetport = get_param(h,'PortHandles');
%             targetpos = get_param(targetport.Inport(1),'Position');
%             BlockName='bus_selector';
%             srcT = 'simulink/Signal Routing/Bus Selector';
%             dstT = [TargetModel '/' BlockName];
%             block_x = targetpos(1) - 250;
%             block_y = targetpos(2) - 20;
%             block_w = block_x + 10;
%             block_h = block_y + 30;
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'outputsignals',['VHAL_' RxCAN RxMsgName '_raw'],'ShowName', 'off');
%             sourceport = get_param(h,'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%             targetport = sourceport;
% 
%             targetpos = get_param(targetport.Inport(1),'Position');
%             BlockName = 'From';
%             block_x = targetpos(1) - 300;
%             block_y = targetpos(2) - 20;
%             block_w = block_x + 220;
%             block_h = block_y + 40;
%             srcT = 'simulink/Signal Routing/From';
%             dstT = [TargetModel '/' BlockName];
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'Gototag', ['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%             sourceport = get_param(h,'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));

        elseif exist('Detect_frame_routing','var') && ~isempty(Detect_frame_routing) && (length(Detect_frame_routing)>1)
        %   RxCAN = char(Restore_array_can(Detect_frame_routing(1),1));
%             targetport = get_param(h,'PortHandles');
%             targetpos = get_param(targetport.Inport(1),'Position');
%             BlockName = 'Switch';
%             block_x = targetpos(1)-100;
%             block_y = targetpos(2)-70;
%             block_w = block_x + 50;
%             block_h = block_y + 70*length(Detect_frame_routing);
%             srcT = 'simulink/Commonly Used Blocks/Switch';
%             dstT = [TargetModel '/' BlockName];
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'Criteria','u2 ~= 0');
%             sourceport = get_param(h,'PortHandles');
%             add_line(TargetModel, sourceport.Outport(1),targetport.Inport(1));
% 
%             targetport = get_param(h,'PortHandles');
%             targetpos = get_param(targetport.Inport(1),'Position');
%             BlockName='bus_selector';
%             srcT = 'simulink/Signal Routing/Bus Selector';
%             dstT = [TargetModel '/' BlockName];
%             block_x = targetpos(1) - 250;
%             block_y = targetpos(2) - 20;
%             block_w = block_x + 10;
%             block_h = block_y + 30;
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'outputsignals',['VHAL_' RxCAN RxMsgName '_raw'],'ShowName', 'off');
%             sourceport = get_param(h,'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%             targetport = sourceport;
% 
%             targetpos = get_param(targetport.Inport(1),'Position');
%             BlockName = 'From';
%             block_x = targetpos(1) - 300;
%             block_y = targetpos(2) - 20;
%             block_w = block_x + 220;
%             block_h = block_y + 40;
%             srcT = 'simulink/Signal Routing/From';
%             dstT = [TargetModel '/' BlockName];
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'Gototag', ['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%             sourceport = get_param(h,'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
%             targetport = get_param([TargetModel '/Switch'],'PortHandles');
%             targetpos = get_param(targetport.Inport(2),'Position');
% 
%             BlockName='detect_change';
%             srcT = 'simulink/Logic and Bit Operations/Detect Change';
%             dstT = [TargetModel '/' BlockName];
%             block_x = targetpos(1) - 120;
%             block_y = targetpos(2) - 15;
%             block_w = block_x + 70;
%             block_h = block_y + 30;
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h],'ShowName', 'off');
%             sourceport = get_param(h,'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(2));
% 
%             targetport = sourceport;
%             BlockName='bus_selector';
%             srcT = 'simulink/Signal Routing/Bus Selector';
%             dstT = [TargetModel '/' BlockName];
%             block_x = targetpos(1) - 250;
%             block_y = targetpos(2) - 20;
%             block_w = block_x + 10;
%             block_h = block_y + 30;
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'outputsignals',['VHAL_' RxCAN RxMsgName '_cnt'],'ShowName', 'off');
%             sourceport = get_param(h,'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
%             targetport = sourceport;
%             targetpos = get_param(sourceport.Inport(1),'Position');
%             BlockName = 'From';
%             block_x = targetpos(1) - 300;
%             block_y = targetpos(2) - 20;
%             block_w = block_x + 220;
%             block_h = block_y + 40;
%             srcT = 'simulink/Signal Routing/From';
%             dstT = [TargetModel '/' BlockName];
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'Gototag', ['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%             sourceport = get_param(h,'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
% 
%             RxCAN = char(Restore_array_can(Detect_frame_routing(2),1));
%             targetport = get_param([TargetModel '/Switch'],'PortHandles');
%             targetpos = get_param(targetport.Inport(3),'Position');
%             BlockName='bus_selector1';
%             srcT = 'simulink/Signal Routing/Bus Selector';
%             dstT = [TargetModel '/' BlockName];
%             block_x = targetpos(1) - 250;
%             block_y = targetpos(2) - 20;
%             block_w = block_x + 10;
%             block_h = block_y + 30;
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'outputsignals',['VHAL_' RxCAN RxMsgName '_raw'],'ShowName', 'off');
%             sourceport = get_param(h,'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(3));
%             targetport = sourceport;
% 
%             targetpos = get_param(targetport.Inport(1),'Position');
%             BlockName = 'From1';
%             block_x = targetpos(1) - 300;
%             block_y = targetpos(2) - 20;
%             block_w = block_x + 220;
%             block_h = block_y + 40;
%             srcT = 'simulink/Signal Routing/From';
%             dstT = [TargetModel '/' BlockName];
%             h = add_block(srcT,dstT,'MakeNameUnique','on');
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'Gototag', ['HAL_' RxCAN '_outputs'],'ShowName', 'off');
%             sourceport = get_param(h,'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));

        elseif (~exist('Detect_frame_routing','var') || isempty(Detect_frame_routing)) && ~Autosar_flg
        %   targetport = get_param(h,'PortHandles');
%             targetpos = get_param(targetport.Inport(1),'Position');
%             BlockName = 'Mux';
%             block_x = targetpos(1) - 100;
%             block_y = targetpos(2)- 35*str2double(DLC);
%             block_w = block_x + 20;
%             block_h = block_y + 70*str2double(DLC);
%             srcT = 'simulink/Commonly Used Blocks/Mux';
%             dstT = [TargetModel '/' BlockName];
%             h = add_block(srcT,dstT);
%             set_param(h,'Inputs',DLC);
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             sourceport = get_param(h,'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
%             targetport = sourceport;
%             for k = 1:str2double(DLC)
%                 targetpos = get_param(targetport.Inport(k),'Position');
%                 BlockName = 'From';
%                 block_x = targetpos(1) - 300;
%                 block_y = targetpos(2) - 20;
%                 block_w = block_x + 220;
%                 block_h = block_y + 40;
%                 srcT = 'simulink/Signal Routing/From';
%                 dstT = [TargetModel '/' BlockName];
%                 h = add_block(srcT,dstT,'MakeNameUnique','on');
%                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                 set_param(h,'Gototag', ['Byte_' num2str(k-1)],'ShowName', 'off');
%                 sourceport = get_param(h,'PortHandles');
%                 add_line(TargetModel,sourceport.Outport(1),targetport.Inport(k))
%             end

        elseif Autosar_flg
            % get signal raw from DT
            DT_cell = Simulink.Bus.objectToCell({['DT_' Channel '_SG_' MsgName]});
                DT_Msg_signal = cell(length(DT_cell{1, 1}{1, 7}),1);
            for p = 1:length(DT_cell{1, 1}{1, 7})
                DT_Msg_signal(p,1) = {(DT_cell{1, 1}{1, 7}{p, 1}{1, 1})};
            end

            Autosar_output_msg = char(Autosar_output_msg_CAN(strcmp(extractAfter(Autosar_output_msg_CAN,'SG_'),MsgName)));
            BlockName = 'bus_creator';
            block_x = original_x + 1400;
            block_y = original_y + 770;
            block_w = block_x + 20;
            block_h = block_y + 100*length(DT_Msg_signal);
            srcT = 'simulink/Signal Routing/Bus Creator';
            dstT = [TargetModel '/' BlockName];
            h = add_block(srcT,dstT);
            set_param(h,'Inputs',string(length(DT_Msg_signal)));
            set_param(h,'position',[block_x,block_y,block_w,block_h]);

            if ~isempty(Autosar_output_msg)
                set_param(h,'OutDataTypeStr',['Bus: ' Autosar_output_msg]);
                set_param(h,'NonVirtualBus','on');
            end
            sourceport = get_param(h,'PortHandles');
            targetport = sourceport;
            for k = 1:length(DT_Msg_signal)
                targetpos = get_param(targetport.Inport(k),'Position');
                BlockName = 'From';
                block_x = targetpos(1) - 600;
                block_y = targetpos(2) - 20;
                block_w = block_x + 220;
                block_h = block_y + 40;
                srcT = 'simulink/Signal Routing/From';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');

                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Gototag', char(DT_Msg_signal(k)),'ShowName', 'off');
                sourceport = get_param(h,'PortHandles');
                g = add_line(TargetModel,sourceport.Outport(1),targetport.Inport(k));
                set_param(g,'name',char(DT_Msg_signal(k)));
                % Check Tx signal mapping to sldd info
%                 DT_Msg_signal = evalin('base',['DT_' Channel '_SG_' MsgName '.Elements(' char(string(k)) ').Name']);
%                 if ~strcmp(DT_Msg_signal,[Channel '_' char(SignalName_raw(k))]) 
%                     msg = ['Error: ' Channel ' ' MsgName '  Output Signal: ' char(SignalName_raw(k)) ' No link successful, checkout DT_' Channel '_SG_' MsgName];
%                     error(msg);
%                 end
            end

            targetport = get_param([TargetModel '/bus_creator'],'PortHandles');
            targetpos = get_param(targetport.Outport(1),'Position');

            if  Autosar_flg && any(contains(Autosar_output_msg_CAN,MsgName))
                BlockName = MsgName;
                block_x = targetpos(1) + 100;
                block_y = targetpos(2) - 5;    
                block_w = block_x + 30;
                block_h = block_y + 13;
                srcT = 'simulink/Sinks/Out1';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT);  
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,targetport.Outport(1),sourceport.Inport(1));             
            elseif  Autosar_flg
                BlockName = 'Terminator';
                block_x = targetpos(1) + 100;
                block_y = targetpos(2) - 20;
                block_w = block_x + 25;
                block_h = block_y + 35;
                srcT = 'simulink/Commonly Used Blocks/Terminator';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');     
                set_param(h,'position',[block_x,block_y,block_w,block_h])
                set_param(h,'ShowName', 'off');
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,targetport.Outport(1),sourceport.Inport(1));
            end
        end   

        %% For CRC process

        if CRC_flg
            for j = 1:length(CS_array(1:end,1))
                if strcmp(CS_array(j,1),string(Channel)) && strcmp(CS_array(j,2),string(MsgName))
                   CS_SignalName = CS_array(j,3); 
                end
                if strcmp(RC_array(j,1),string(Channel)) && strcmp(RC_array(j,2),string(MsgName))
                   RC_SignalName = RC_array(j,3); 
                end
            end
        end
    
        %%%%%%%%%%%%%%%%%%%%%%% create message pack table %%%%%%%%%%%%%%%%%%%%%%%%%
        % For each signal, analyze signal mask and position for each byte.
        % Signal components for each byte are generated.
        % For a byte you can find what signal should do in this byte.
        % Example: Signal A in byte0 is [0,3,2] means A first do right shift 0
        % then use mask (2^3-1) do bit wise AND, then left shift 2.
        % If byte0 contains signal A,B,C..., then do bit wise OR for every handled
        % signals.

        if (~exist('Detect_frame_routing','var') || isempty(Detect_frame_routing))

            MsgPackTable = cell(Num_Signal,str2double(DLC)+1);
            for k = 1:Num_Signal
                MsgPackTable(k,1) = SignalName_raw(k);
                Startbit = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(k).StartBit;
                SignalSize = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(k).SignalSize;
                SignalResolution = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(k).Factor;
                SignalOffset = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(k).Offset;

                if SignalSize == 1
                    NUM_BYTE = 1;
                else
                    RightShiftCnt = rem(Startbit,8);
                    remainlength = SignalSize-(8-RightShiftCnt);
                    if remainlength > 0
                        NUM_BYTE = ceil(remainlength/8)+1;
                    else
                        NUM_BYTE = 1;
                    end
                end

                for m = 1:NUM_BYTE
                    if m == 1
                        TargetByte = floor(Startbit/8);
                        RightShiftCnt = 0;
                        LeftShiftCnt = rem(Startbit,8);
                        remainlength = SignalSize - (8-LeftShiftCnt);
                        if remainlength <= 0
                            NUM_MASK = SignalSize;
                        else
                            NUM_MASK = 8-LeftShiftCnt;
                        end
                        MsgPackTable(k,TargetByte+2) = {[SignalSize,SignalResolution,SignalOffset,RightShiftCnt,NUM_MASK,LeftShiftCnt]};

                    elseif remainlength > 0
                        if IsLINMessage
                            TargetByte = TargetByte + 1;
                        else
                            TargetByte = TargetByte - 1;
                        end
                        RightShiftCnt = SignalSize - remainlength;
                        LeftShiftCnt = 0;
                        if remainlength >= 8
                            NUM_MASK = 8;
                        else
                            NUM_MASK = rem(remainlength,8);
                        end
                        MsgPackTable(k,TargetByte+2) = {[SignalSize,SignalResolution,SignalOffset,RightShiftCnt,NUM_MASK,LeftShiftCnt]};
                        remainlength = remainlength - NUM_MASK;
                    else
                        break
                    end
                end
            end

            if ~Autosar_flg
            %  %% Create separated byte models
%                 for k = 1:str2double(DLC)
%                     TargetModel = MsgModel;
%                     if k == 1
%                         lastblk_pos_y = 500;
%                     else
%                         lastblk_pos = get_param([TargetModel '/Byte_' num2str(k-2)],'Position');
%                         lastblk_pos_y = lastblk_pos(4)+ 80;
%                     end
% 
%                     idx = find(~cellfun(@isempty,MsgPackTable(:,k+1)));
% 
%                     if isempty(idx) % byte unused
% 
%                         BlockName = ['Byte_' num2str(k-1)];
%                         block_x = original_x;
%                         block_y = lastblk_pos_y + 5;
%                         block_w = block_x + 250;
%                         block_h = block_y + 40;
%                         srcT = 'simulink/Commonly Used Blocks/Constant';
%                         dstT = [TargetModel '/' BlockName];
%                         h = add_block(srcT,dstT);
%                         set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                         set_param(h,'Value','ZERO_INT','ShowName', 'on')
%                         sourceport = get_param(h,'PortHandles');
%                         targetpos = get_param(sourceport.Outport(1),'Position');
% 
%                         BlockName = 'Goto';
%                         block_x = targetpos(1) +100;
%                         block_y = targetpos(2) - 20;
%                         block_w = block_x + 220;
%                         block_h = block_y + 40;
%                         srcT = 'simulink/Signal Routing/Goto';
%                         dstT = [TargetModel '/' BlockName];
%                         h = add_block(srcT,dstT,'MakeNameUnique','on');
%                         set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                         set_param(h,'Gototag', ['Byte_' num2str(k-1)],'ShowName', 'off');
%                         targetport = get_param(h,'PortHandles');
%                         add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%                     else
%                         BlockName = ['Byte_' num2str(k-1)];
%                         block_x = original_x;
%                         block_y = lastblk_pos_y + 5;
%                         block_w = block_x + 250;
%                         block_h = block_y + 60*length(idx);
%                         srcT = 'simulink/Ports & Subsystems/Subsystem';
%                         dstT = [TargetModel '/' BlockName];
%                         h = add_block(srcT,dstT);
%                         set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                         set_param(h,'ContentPreviewEnabled','off','BackgroundColor','Gray');
%                         delete_line([TargetModel '/' BlockName], 'In1/1','Out1/1');
%                         delete_block([TargetModel '/' BlockName  '/In1']);
%                         set_param([TargetModel '/' BlockName  '/Out1'],'Name',['Byte_' num2str(k-1)]);
% 
%                         sourceport = get_param([TargetModel '/' BlockName],'PortHandles');
%                         targetpos = get_param(sourceport.Outport(1),'Position');
%                         BlockName = 'Goto';
%                         block_x = targetpos(1) +100;
%                         block_y = targetpos(2) - 20;
%                         block_w = block_x + 220;
%                         block_h = block_y + 40;
%                         srcT = 'simulink/Signal Routing/Goto';
%                         dstT = [TargetModel '/' BlockName];
%                         h = add_block(srcT,dstT,'MakeNameUnique','on');
%                         set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                         set_param(h,'Gototag', ['Byte_' num2str(k-1)],'ShowName', 'off');
%                         targetport = get_param(h,'PortHandles');
%                         add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
%                         %% pack signals into byte model
%                         TargetModel = [TargetModel '/Byte_' num2str(k-1)];
%                         targetport = get_param([TargetModel '/Byte_' num2str(k-1)],'PortHandles');
%                         targetpos = get_param(targetport.Inport(1),'Position');
%                         BlockName = 'BitwiseOR';
%                         block_x = targetpos(1) - 150;
%                         block_y = targetpos(2) - 40*length(idx);
%                         block_w = block_x + 70;
%                         block_h = block_y + 80*length(idx);
%                         srcT = 'simulink/Logic and Bit Operations/Bitwise Operator';
%                         dstT = [TargetModel '/' BlockName];
%                         h = add_block(srcT,dstT);
%                         set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                         set_param(h,'UseBitMask','off');
%                         set_param(h,'logicop','OR');
%                         set_param(h,'NumInputPorts',num2str(length(idx)));
%                         sourceport = get_param(h,'PortHandles');
%                         add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
% 
%                         for m = 1:length(idx)
%                             packinfo = MsgPackTable{idx(m),k+1};
%                             if packinfo(1) <= 8; SignalDataType = 'uint8'; end
%                             if (8 < packinfo(1)) && (packinfo(1) <= 16); SignalDataType = 'uint16'; end
%                             if (16 < packinfo(1)) && (packinfo(1) <= 32); SignalDataType = 'uint32'; end
%                             if (32 < packinfo(1)) && (packinfo(1) <= 64); SignalDataType = 'uint64'; end
% 
%                             targetport = get_param([TargetModel '/BitwiseOR'],'PortHandles');
%                             targetpos = get_param(targetport.Inport(m),'Position');
% 
%                             BlockName = 'UnitConverter';
%                             srcT = 'simulink/Signal Attributes/Data Type Conversion';
%                             dstT = [TargetModel '/' BlockName];
%                             block_x = targetpos(1) - 150;
%                             block_y = targetpos(2) - 20;
%                             block_w = block_x + 100;
%                             block_h = block_y + 40;
%                             h = add_block(srcT,dstT,'MakeNameUnique','on');
%                             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                             set_param(h,'OutDataTypeStr', 'uint8','ShowName', 'off');
%                             set_param(h,'RndMeth', 'Round');
%                             sourceport = get_param(h,'PortHandles');
%                             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(m));
%                             if ~ Autosar_flg
%                                 targetport = sourceport;
%                                 targetpos = get_param(targetport.Inport(1),'Position');
%                                 BlockName = 'SignalPack';
%                                 block_x = targetpos(1) -350;
%                                 block_y = targetpos(2) - 20;
%                                 block_w = block_x + 250;
%                                 block_h = block_y + 40;
%                                 srcT = 'FVT_lib/hal/SignalPack';
%                                 dstT = [TargetModel '/' BlockName];
%                                 h = add_block(srcT,dstT,'MakeNameUnique','on');
%                                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                                 set_param(h, 'MaskValues', {num2str(packinfo(4)),['2^' num2str(packinfo(5)) '-1'],num2str(packinfo(6))});
%                                 sourceport = get_param(h,'PortHandles');
%                                 add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
%                                 targetport = sourceport;
%                                 targetpos = get_param(targetport.Inport(1),'Position');
%                                 BlockName = 'UnitConverter';
%                                 srcT = 'simulink/Signal Attributes/Data Type Conversion';
%                                 dstT = [TargetModel '/' BlockName];
%                                 block_x = targetpos(1) - 150;
%                                 block_y = targetpos(2) - 20;
%                                 block_w = block_x + 100;
%                                 block_h = block_y + 40;
%                                 h = add_block(srcT,dstT,'MakeNameUnique','on');
%                                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                                 set_param(h,'OutDataTypeStr', SignalDataType,'ShowName', 'off');
%                                 set_param(h,'RndMeth', 'Round');
%                                 sourceport = get_param(h,'PortHandles');
%                                 add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%                             end
% 
%                             targetport = sourceport;
%                             targetpos = get_param(targetport.Inport(1),'Position');
% 
%                             if packinfo(3) ==0 && packinfo(2) == 1
%                                 BlockName = char(MsgPackTable(idx(m),1));
%                                 block_x = targetpos(1) - 150;
%                                 block_y = targetpos(2) - 5;
%                                 block_w = block_x + 30;
%                                 block_h = block_y + 13;
%                                 srcT = 'simulink/Sources/In1';
%                                 dstT = [TargetModel '/' BlockName];
%                                 h = add_block(srcT,dstT);
%                                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                                 sourceport = get_param(h,'PortHandles');
%                                 add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%                             else
%                                 BlockName = 'convert_out';
%                                 block_x = targetpos(1) - 200;
%                                 block_y = targetpos(2) - 25;
%                                 block_w = block_x + 100;
%                                 block_h = block_y + 50;
%                                 srcT = 'FVT_lib/hal/convert_out';
%                                 dstT = [TargetModel '/' BlockName];
%                                 h = add_block(srcT,dstT,'MakeNameUnique','on');
%                                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                                 set_param(h, 'MaskValues', {num2str(packinfo(2)),num2str(packinfo(3))});
%                                 sourceport = get_param(h,'PortHandles');
%                                 add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
% 
%                                 targetport = sourceport;
%                                 targetpos = get_param(targetport.Inport(1),'Position');
% 
%                                 BlockName = char(MsgPackTable(idx(m),1));
%                                 block_x = targetpos(1) - 150;
%                                 block_y = targetpos(2) - 5;
%                                 block_w = block_x + 30;
%                                 block_h = block_y + 13;
%                                 srcT = 'simulink/Sources/In1';
%                                 dstT = [TargetModel '/' BlockName];
%                                 h = add_block(srcT,dstT);
%                                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                                 sourceport = get_param(h,'PortHandles');
%                                 add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%                             end
%                         end
%                     end
%                 end

            elseif Autosar_flg
                cnt = 0;
                for p = 1:length(SignalName_raw)                    
                    SignalSize = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(p).SignalSize;
                    SignalResolution = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(p).Factor;
                    SignalOffset = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(p).Offset;
                    
                    % Filter signal not in DT
                    if ~any(strcmp(extractAfter(string(DT_Msg_signal),[Channel '_']),SignalName_raw(p)))
                        continue
                    end
                    cnt = cnt + 1;
                    TargetModel = MsgModel;
                    BlockName = 'Goto';
                    block_x = original_x;
                    block_y = 800 + 100*(cnt-1);
                    block_w = block_x + 220;
                    block_h = block_y + 40;
                    srcT = 'simulink/Signal Routing/Goto';
                    dstT = [TargetModel '/' BlockName];
                    h = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    set_param(h,'Gototag', [Channel '_' char(SignalName_raw(p))],'ShowName', 'off');
                                        
                    targetport = get_param(h,'PortHandles');
                    targetpos = get_param(targetport.Inport(1),'Position');
                    BlockName = erase(char(SignalName_raw(p)),'_');
                    block_x = targetpos(1) - 500;
                    block_y = targetpos(2) - 30;
                    block_w = block_x + 250;
                    block_h = block_y + 60;
                    srcT = 'simulink/Ports & Subsystems/Subsystem';
                    dstT = [TargetModel '/' BlockName];    
                    h = add_block(srcT,dstT);     
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    set_param(h,'ContentPreviewEnabled','off','BackgroundColor','Gray');
                    delete_line([TargetModel '/' BlockName], 'In1/1','Out1/1');
                    delete_block([TargetModel '/' BlockName  '/In1']);
                    set_param([TargetModel '/' BlockName  '/Out1'],'Name', [Channel '_' char(SignalName_raw(p))]);
                    sourceport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));

                    if SignalSize <= 8; SignalDataType = 'uint8'; end
                    if (8 < SignalSize) && (SignalSize <= 16); SignalDataType = 'uint16'; end
                    if (16 < SignalSize) && (SignalSize <= 32); SignalDataType = 'uint32'; end
                    if (32 < SignalSize) && (SignalSize <= 64); SignalDataType = 'uint64'; end

                    TargetModel = [TargetModel '/' erase(char(SignalName_raw(p)),'_')];
                    targetport = get_param([TargetModel '/' Channel '_' char(SignalName_raw(p))],'PortHandles');
                    targetpos = get_param(targetport.Inport(1),'Position');
                    BlockName = 'Data Type Conversion';
                    srcT = 'simulink/Signal Attributes/Data Type Conversion';
                    dstT = [TargetModel '/' BlockName];
                    block_x = targetpos(1) - 170;
                    block_y = targetpos(2) - 20;
                    block_w = block_x + 100;
                    block_h = block_y + 40;
                    h = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    set_param(h,'OutDataTypeStr', SignalDataType,'ShowName', 'off');
                    set_param(h,'RndMeth', 'Round');
                    sourceport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));

                    targetport = sourceport;
                    targetpos = get_param(targetport.Inport(1),'Position');

                    if SignalResolution == 1 && SignalOffset ==0
                        BlockName = erase(char(SignalName_raw(p)),'_');
                        block_x = targetpos(1) - 150;
                        block_y = targetpos(2) - 5;
                        block_w = block_x + 30;
                        block_h = block_y + 13;
                        srcT = 'simulink/Sources/In1';
                        dstT = [TargetModel '/' BlockName];    
                        h = add_block(srcT,dstT);
                        set_param(h,'position',[block_x,block_y,block_w,block_h]);
                        sourceport = get_param(h,'PortHandles');
                        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                    else
                        BlockName = 'convert_out';
                        block_x = targetpos(1) - 180;
                        block_y = targetpos(2) - 25;
                        block_w = block_x + 100;
                        block_h = block_y + 50;
                        srcT = 'FVT_lib/hal/convert_out';
                        dstT = [TargetModel '/' BlockName];
                        h = add_block(srcT,dstT,'MakeNameUnique','on');
                        set_param(h,'position',[block_x,block_y,block_w,block_h],'ShowName', 'off');
                        set_param(h, 'MaskValues', {num2str(SignalResolution),num2str(SignalOffset)});
                        sourceport = get_param(h,'PortHandles');
                        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));

                        targetport = sourceport;
                        targetpos = get_param(targetport.Inport(1),'Position');
                        BlockName = erase(char(SignalName_raw(p)),'_');
                        block_x = targetpos(1) - 150;
                        block_y = targetpos(2) - 5;
                        block_w = block_x + 30;
                        block_h = block_y + 13;
                        srcT = 'simulink/Sources/In1';
                        dstT = [TargetModel '/' BlockName];    
                        h = add_block(srcT,dstT);
                        set_param(h,'position',[block_x,block_y,block_w,block_h]);
                        sourceport = get_param(h,'PortHandles');
                        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                    end 
                end

                %% Add signal package for CRC           
                if CRC_flg
                 %  MsgPackTable = cell(Num_Signal,str2double(DLC)+1);
%                      for k = 1:Num_Signal
%                         MsgPackTable(k,1) = SignalName_raw(k);
%                         Startbit = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(k).StartBit;
%                         SignalSize = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(k).SignalSize;
%                         SignalResolution = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(k).Factor;
%                         SignalOffset = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(k).Offset;
%                         
%                         if SignalSize == 1
%                             NUM_BYTE = 1;
%                         else 
%                             RightShiftCnt = rem(Startbit,8);
%                             remainlength = SignalSize-(8-RightShiftCnt);
%                             if remainlength > 0
%                                 NUM_BYTE = ceil(remainlength/8)+1;
%                             else
%                                 NUM_BYTE = 1;
%                             end
%                         end
%             
%                         for m = 1:NUM_BYTE
%                             if m == 1
%                                 TargetByte = floor(Startbit/8);
%                                 RightShiftCnt = 0;
%                                 LeftShiftCnt = rem(Startbit,8);
%                                 remainlength = SignalSize - (8-LeftShiftCnt);
%                                 if remainlength <= 0
%                                     NUM_MASK = SignalSize;
%                                 else
%                                     NUM_MASK = 8-LeftShiftCnt;
%                                 end
%                                 MsgPackTable(k,TargetByte+2) = {[SignalSize,SignalResolution,SignalOffset,RightShiftCnt,NUM_MASK,LeftShiftCnt]};
%                                 
%                             elseif remainlength > 0
%                                 if IsLINMessage
%                                     TargetByte = TargetByte + 1;
%                                 else
%                                     TargetByte = TargetByte - 1;
%                                 end
%                                 RightShiftCnt = SignalSize - remainlength;
%                                 LeftShiftCnt = 0;
%                                 if remainlength >= 8
%                                     NUM_MASK = 8;
%                                 else
%                                     NUM_MASK = rem(remainlength,8);
%                                 end
%                                 MsgPackTable(k,TargetByte+2) = {[SignalSize,SignalResolution,SignalOffset,RightShiftCnt,NUM_MASK,LeftShiftCnt]};
%                                 remainlength = remainlength - NUM_MASK;
%                             else
%                                 break
%                             end
%                         end
%                      end
        
                    % Create separated byte models
                    empty_byte = [];
                    for k = 1:str2double(DLC)
                    TargetModel = MsgModel;
                        if k == 1
                            lastblk_pos_y = 800;
                        else
                            lastblk_pos = get_param([TargetModel '/Byte_' num2str(k-2)],'Position');
                            lastblk_pos_y = lastblk_pos(4)+ 80;
                        end
        
                        idx = find(~cellfun(@isempty,MsgPackTable(:,k+1)));    
                        if isempty(idx) % byte unused
                            if strcmp(MsgName,'FD4_CE100_0')
                                empty_byte(end+1) = k-1;
                            end
                            BlockName = ['Byte_' num2str(k-1)];
                            block_x = original_x - 3000;
                            block_y = lastblk_pos_y + 5;
                            block_w = block_x + 250;
                            block_h = block_y + 40;
                            srcT = 'simulink/Commonly Used Blocks/Constant';
                            dstT = [TargetModel '/' BlockName];
                            h = add_block(srcT,dstT);
                            set_param(h,'position',[block_x,block_y,block_w,block_h]);
                            set_param(h,'Value','ZERO_INT','ShowName', 'on')
                            sourceport = get_param(h,'PortHandles');
                            targetpos = get_param(sourceport.Outport(1),'Position');
            
                            BlockName = 'Goto';
                            block_x = targetpos(1) +100;
                            block_y = targetpos(2) - 20;
                            block_w = block_x + 220;
                            block_h = block_y + 40;
                            srcT = 'simulink/Signal Routing/Goto';
                            dstT = [TargetModel '/' BlockName];
                            h = add_block(srcT,dstT,'MakeNameUnique','on');
                            set_param(h,'position',[block_x,block_y,block_w,block_h]);
                            set_param(h,'Gototag', ['Byte_' num2str(k-1)],'ShowName', 'off');
                            targetport = get_param(h,'PortHandles');
                            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                        else
                            empty_byte = [];
                            BlockName = ['Byte_' num2str(k-1)];
                            block_x = original_x - 3000;
                            block_y = lastblk_pos_y + 5;
                            block_w = block_x + 250;
                            block_h = block_y + 60*length(idx);
                            srcT = 'simulink/Ports & Subsystems/Subsystem';
                            dstT = [TargetModel '/' BlockName];    
                            h = add_block(srcT,dstT);     
                            set_param(h,'position',[block_x,block_y,block_w,block_h]);
                            set_param(h,'ContentPreviewEnabled','off','BackgroundColor','Gray');
                            delete_line([TargetModel '/' BlockName], 'In1/1','Out1/1');
                            delete_block([TargetModel '/' BlockName  '/In1']);
                            set_param([TargetModel '/' BlockName  '/Out1'],'Name',['Byte_' num2str(k-1)]);
        
                            if  CRC_flg && strcmp(CS_SignalName,string(MsgPackTable(idx(1),1)))
                                sourceport = get_param([TargetModel '/' BlockName],'PortHandles');
                                targetpos = get_param(sourceport.Outport(1),'Position');
                                BlockName = 'Terminator';
                                block_x = targetpos(1) + 50;
                                block_y = targetpos(2) -20;
                                block_w = block_x + 25;
                                block_h = block_y + 35;
                                srcT = 'simulink/Commonly Used Blocks/Terminator';
                                dstT = [TargetModel '/' BlockName];    
                                h = add_block(srcT,dstT,'MakeNameUnique','on');  
                                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                                targetport = get_param(h,'PortHandles');
                                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                            else
                                sourceport = get_param([TargetModel '/' BlockName],'PortHandles');
                                targetpos = get_param(sourceport.Outport(1),'Position');
                                BlockName = 'Goto';
                                block_x = targetpos(1) +100;
                                block_y = targetpos(2) - 20;
                                block_w = block_x + 220;
                                block_h = block_y + 40;
                                srcT = 'simulink/Signal Routing/Goto';
                                dstT = [TargetModel '/' BlockName];
                                h = add_block(srcT,dstT,'MakeNameUnique','on');
                                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                                set_param(h,'Gototag', ['Byte_' num2str(k-1)],'ShowName', 'off');
                                targetport = get_param(h,'PortHandles');
                                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                            end
        
                            % pack signals into byte model for CRC8
                            TargetModel = [TargetModel '/Byte_' num2str(k-1)];
                            targetport = get_param([TargetModel '/Byte_' num2str(k-1)],'PortHandles');
                            targetpos = get_param(targetport.Inport(1),'Position');
                            BlockName = 'BitwiseOR';
                            block_x = targetpos(1) - 150;
                            block_y = targetpos(2) - 40*length(idx);
                            block_w = block_x + 70;
                            block_h = block_y + 80*length(idx);
                            srcT = 'simulink/Logic and Bit Operations/Bitwise Operator';
                            dstT = [TargetModel '/' BlockName];    
                            h = add_block(srcT,dstT);     
                            set_param(h,'position',[block_x,block_y,block_w,block_h]);
                            set_param(h,'UseBitMask','off');
                            set_param(h,'logicop','OR');
                            set_param(h,'NumInputPorts',num2str(length(idx)));
                            sourceport = get_param(h,'PortHandles');
                            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
        
                                        
                            for m = 1:length(idx)
                                packinfo = MsgPackTable{idx(m),k+1};
                                if packinfo(1) <= 8; SignalDataType = 'uint8'; end
                                if (8 < packinfo(1)) && (packinfo(1) <= 16); SignalDataType = 'uint16'; end
                                if (16 < packinfo(1)) && (packinfo(1) <= 32); SignalDataType = 'uint32'; end
                                if (32 < packinfo(1)) && (packinfo(1) <= 64); SignalDataType = 'uint64'; end
                                
                                targetport = get_param([TargetModel '/BitwiseOR'],'PortHandles');
                                targetpos = get_param(targetport.Inport(m),'Position');
            
                                BlockName = 'UnitConverter';
                                srcT = 'simulink/Signal Attributes/Data Type Conversion';
                                dstT = [TargetModel '/' BlockName];
                                block_x = targetpos(1) - 150;
                                block_y = targetpos(2) - 20;
                                block_w = block_x + 100;
                                block_h = block_y + 40;
                                h = add_block(srcT,dstT,'MakeNameUnique','on');     
                                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                                set_param(h,'OutDataTypeStr', 'uint8','ShowName', 'off');
                                set_param(h,'RndMeth', 'Round');
                                sourceport = get_param(h,'PortHandles');
                                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(m));
            
                                targetport = sourceport;
                                targetpos = get_param(targetport.Inport(1),'Position');
                                BlockName = 'SignalPack';
                                block_x = targetpos(1) -350;
                                block_y = targetpos(2) - 20;
                                block_w = block_x + 250;
                                block_h = block_y + 40;
                                srcT = 'FVT_lib/hal/SignalPack';
                                dstT = [TargetModel '/' BlockName];
                                h = add_block(srcT,dstT,'MakeNameUnique','on');
                                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                                set_param(h, 'MaskValues', {num2str(packinfo(4)),['2^' num2str(packinfo(5)) '-1'],num2str(packinfo(6))});
                                sourceport = get_param(h,'PortHandles');
                                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                                
                                targetport = sourceport;
                                targetpos = get_param(targetport.Inport(1),'Position');
                                BlockName = 'UnitConverter';
                                srcT = 'simulink/Signal Attributes/Data Type Conversion';
                                dstT = [TargetModel '/' BlockName];
                                block_x = targetpos(1) - 150;
                                block_y = targetpos(2) - 20;
                                block_w = block_x + 100;
                                block_h = block_y + 40;
                                h = add_block(srcT,dstT,'MakeNameUnique','on');     
                                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                                set_param(h,'OutDataTypeStr', SignalDataType,'ShowName', 'off');
                                set_param(h,'RndMeth', 'Round');
                                sourceport = get_param(h,'PortHandles');
                                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                              
                                targetport = sourceport;
                                targetpos = get_param(targetport.Inport(1),'Position');
            
                                if packinfo(3) ==0 && packinfo(2) == 1
                                    BlockName = char(MsgPackTable(idx(m),1));
                                    block_x = targetpos(1) - 150;
                                    block_y = targetpos(2) - 5;
                                    block_w = block_x + 30;
                                    block_h = block_y + 13;
                                    srcT = 'simulink/Sources/In1';
                                    dstT = [TargetModel '/' BlockName];    
                                    h = add_block(srcT,dstT);
                                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                                    sourceport = get_param(h,'PortHandles');
                                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                                else
                                    BlockName = 'convert_out';
                                    block_x = targetpos(1) - 200;
                                    block_y = targetpos(2) - 25;
                                    block_w = block_x + 100;
                                    block_h = block_y + 50;
                                    srcT = 'FVT_lib/hal/convert_out';
                                    dstT = [TargetModel '/' BlockName];    
                                    h = add_block(srcT,dstT,'MakeNameUnique','on');     
                                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                                    set_param(h, 'MaskValues', {num2str(packinfo(2)),num2str(packinfo(3))});
                                    sourceport = get_param(h,'PortHandles');
                                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
            
                                    targetport = sourceport;
                                    targetpos = get_param(targetport.Inport(1),'Position');
            
                                    BlockName = char(MsgPackTable(idx(m),1));
                                    block_x = targetpos(1) - 150;
                                    block_y = targetpos(2) - 5;
                                    block_w = block_x + 30;
                                    block_h = block_y + 13;
                                    srcT = 'simulink/Sources/In1';
                                    dstT = [TargetModel '/' BlockName];    
                                    h = add_block(srcT,dstT);
                                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                                    sourceport = get_param(h,'PortHandles');
                                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                                end         
                             end 
                        end                
                    end

                    % Add CRC mux 
                    BlockName = 'Mux2';
                    TargetModel = MsgModel; 
                    block_x = original_x - 2000;
                    block_y = 800;
                    block_w = block_x + 20 ;
                    block_h = block_y + 70*ceil(str2double(DLC)-1-length(empty_byte));
                    srcT = 'simulink/Commonly Used Blocks/Mux';
                    dstT = [TargetModel '/' BlockName];
                    h = add_block(srcT,dstT,'MakeNameUnique','off');     
                    set_param(h,'Inputs',num2str(ceil((str2double(DLC)-1-length(empty_byte)))));
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    sourceport = get_param(h,'PortHandles');
       
                    BlockName = 'CRC8_IfAction_Tx'; 
                    targetport = get_param([TargetModel '/Mux2'],'PortHandles');  
                    targetpos = get_param(targetport.Outport(1),'Position');
                    srcT = 'FVT_lib/hal/CRC8_IfAction_Tx';
                    dstT = [TargetModel '/' BlockName]; 
                    block_x = targetpos(1) + 300;
                    block_y = targetpos(2) - 175;
                    block_w = block_x + 200;
                    block_h = block_y + 200;
                    h = add_block(srcT,dstT,'MakeNameUnique','on');  
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    set_param(h, 'LinkStatus', 'inactive');
                    targetport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(4));
                    
                    % Add E2E Tx Enable
                    targetpos = get_param(targetport.Inport(1),'Position');
                    BlockName = 'Constant';
                    block_x = targetpos(1) - 265;
                    block_y = targetpos(2) - 20;
                    block_w = block_x + 220;
                    block_h = block_y + 40;
                    srcT = 'simulink/Commonly Used Blocks/Constant';
                    dstT = [TargetModel '/' BlockName];
                    h = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    set_param(h,'Value',['KHAL_' Channel erase(MsgName,'_') 'E2E_flg'],'ShowName', 'off');
                    sourceport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on');
                    
                    % Add Data ID 1
                    targetpos = get_param(targetport.Inport(2),'Position');
                    BlockName = 'Constant';
                    block_x = targetpos(1) - 265;
                    block_y = targetpos(2) - 20;
                    block_w = block_x + 220;
                    block_h = block_y + 40;
                    srcT = 'simulink/Commonly Used Blocks/Constant';
                    dstT = [TargetModel '/' BlockName];
                    h = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    set_param(h,'Value',['0x' DataID1],'ShowName', 'off');
                    sourceport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(2),'autorouting','on');
                    
                    % Add Data ID 2
                    targetpos = get_param(targetport.Inport(3),'Position');
                    BlockName = 'Constant';
                    block_x = targetpos(1) - 265;
                    block_y = targetpos(2) - 20;
                    block_w = block_x + 220;
                    block_h = block_y + 40;
                    srcT = 'simulink/Commonly Used Blocks/Constant';
                    dstT = [TargetModel '/' BlockName];
                    h = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    set_param(h,'Value',['0x' DataID2],'ShowName', 'off');
                    sourceport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(3),'autorouting','on');

                    BlockName = 'Goto'; 
                    sourceport = targetport;
                    targetpos = get_param(sourceport.Outport(1),'Position');
                    srcT = 'simulink/Signal Routing/Goto';
                    dstT = [TargetModel '/' BlockName]; 
                    block_x = targetpos(1) + 100;
                    block_y = targetpos(2) - 20;
                    block_w = block_x + 220;
                    block_h = block_y + 40;
                    h = add_block(srcT,dstT,'MakeNameUnique','on');  
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    set_param(h,'GotoTag',char(CS_SignalName),'ShowName','off');
                    targetport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                    
                    % Add Message link for CRC package 
                    for k = 1:str2double(DLC)
                        TargetModel = MsgModel;
                        buf = get_param([TargetModel '/Byte_' num2str(k-1)],'Handle');
                        buf = find_system(buf,'SearchDepth', 1, 'BlockType', 'Inport');
                        if isempty(buf)
                           if CRC_flg && isempty(intersect(empty_byte,k-1))                    
                               targetport = get_param([TargetModel '/Mux2'],'PortHandles'); 
                               h = get_param([TargetModel '/Mux2'],'LineHandles');
                               Linksatus = find(h.Inport ==-1);
                               targetpos = get_param(targetport.Inport(Linksatus(1)),'Position');
                               BlockName = 'From';
                               block_x = targetpos(1) - 300;
                               block_y = targetpos(2) - 20;
                               block_w = block_x + 220;
                               block_h = block_y + 40;
                               srcT = 'simulink/Signal Routing/From';
                               dstT = [TargetModel '/' BlockName];    
                               h = add_block(srcT,dstT,'MakeNameUnique','on');     
                               set_param(h,'position',[block_x,block_y,block_w,block_h]);
                               set_param(h,'GotoTag',['Byte_' num2str(k-1)],'ShowName','off');    
                               sourceport = get_param(h,'PortHandles');
                               add_line(TargetModel,sourceport.Outport(1),targetport.Inport(Linksatus(1)));
                           end
                        continue; 
                        end
                        
                        for m = 1:length(buf)
                            SignalName_raw = get_param(buf(m), 'Name');
                            idx = strcmp(MessageLink(:,1),SignalName_raw);
                            IsSCPSignal = boolean(0);
            
                            if isempty(find(idx, 1)) || isempty(MessageLink{idx,2})
                                SCPSignal = ['VSCP_' Channel char(erase(MsgName, '_')) char(erase(SignalName_raw, '_')) '_'];
                                idx = find(contains(DD_SCP(:,1),SCPSignal));
                                if isempty(idx)
                                    OUTPSignal = '';                       
                                else
                                    IsSCPSignal = boolean(1);
                                    OUTPSignal = char(DD_SCP(idx,1));      
                                end
                            else
                                idx = contains(DD_OUTP(:,7),MessageLink(idx,2));
                                OUTPSignal = char(DD_OUTP(idx,1));
                                OutputSignal_idy = strcmp(OutputSignal(:,1),SignalName_raw);
                                OutputSignal_idx = strcmp(OutputSignal(1,:), Channel);
                                if ~any(idx) ||...
                                    ~strcmp(OutputSignal(OutputSignal_idy,OutputSignal_idx),MsgName)
                                    WaningModel = [TargetModel '/Byte_' num2str(k-1)];
                                    msg = [SignalName_raw char(9) 'No link successful, checkout MessageLinkOut' char(9)...
                                        '<a href="matlab:Simulink.SimulationData.BlockPath.hilite_block (''' WaningModel ''')">' WaningModel '</a>'];
                                    warning(msg);
                                end
                            end
                            
                           % Add CRC8 function and from 

                            if CRC_flg && m==1 && ~strcmp(CS_SignalName,SignalName_raw)
                               targetport = get_param([TargetModel '/Mux2'],'PortHandles'); 
                               h = get_param([TargetModel '/Mux2'],'LineHandles');
                               Linksatus = find(h.Inport ==-1);
                               targetpos = get_param(targetport.Inport(Linksatus(1)),'Position');
                               BlockName = 'From';
                               block_x = targetpos(1) - 300;
                               block_y = targetpos(2) - 20;
                               block_w = block_x + 220;
                               block_h = block_y + 40;
                               srcT = 'simulink/Signal Routing/From';
                               dstT = [TargetModel '/' BlockName];    
                               h = add_block(srcT,dstT,'MakeNameUnique','on');     
                               set_param(h,'position',[block_x,block_y,block_w,block_h]);
                               set_param(h,'GotoTag',['Byte_' num2str(k-1)],'ShowName','off');    
                               sourceport = get_param(h,'PortHandles');
                               add_line(TargetModel,sourceport.Outport(1),targetport.Inport(Linksatus(1)));
                            end
            
                            targetport = get_param([TargetModel '/Byte_' num2str(k-1)],'Porthandles');
                            targetpos = get_param(targetport.Inport(m),'Position');
            
                            if CRC_flg && strcmp(RC_SignalName,SignalName_raw)
                                BlockName = 'RollingCounter_IfAction';
                                block_x = targetpos(1) - 200;
                                block_y = targetpos(2) - 20;
                                block_w = block_x + 120;
                                block_h = block_y + 40;
                                srcT = 'FVT_lib/hal/RollingCounter_IfAction';
                                dstT = [TargetModel '/' BlockName];
                                h = add_block(srcT,dstT,'MakeNameUnique','on');
                                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                                sourceport = get_param(h,'PortHandles');
                                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(m));
            
                                % add E2E Enable for Rolling counter
                                targetport = sourceport;
                                targetpos = get_param(targetport.Inport(1),'Position');
                                BlockName = 'Constant';
                                block_x = targetpos(1) - 300;
                                block_y = targetpos(2) - 20;
                                block_w = block_x + 220;
                                block_h = block_y + 40;
                                srcT = 'simulink/Commonly Used Blocks/Constant';
                                dstT = [TargetModel '/' BlockName];
                                h = add_block(srcT,dstT,'MakeNameUnique','on');
                                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                                set_param(h,'Value',['KHAL_' Channel erase(MsgName,'_') 'E2E_flg'],'ShowName', 'off');
                                sourceport = get_param(h,'PortHandles');
                                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on');
                                continue;                 
                            elseif isempty(OUTPSignal)
                                BlockName = 'Ground';
                                block_x = targetpos(1) - 100;
                                block_y = targetpos(2) - 15;
                                block_w = block_x + 30;
                                block_h = block_y + 30;
                                srcT = 'simulink/Commonly Used Blocks/Ground';
                                dstT = [TargetModel '/' BlockName];
                                h = add_block(srcT,dstT,'MakeNameUnique','on');     
                                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                                set_param(h,'ShowName', 'off');
                                sourceport = get_param(h,'PortHandles');
                                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(m));
                                continue;
                            end
              
                            BlockName='bus_selector';
                            block_x = targetpos(1) - 200;
                            block_y = targetpos(2) - 20;
                            block_w = block_x + 10;
                            block_h = block_y + 30;
                            srcT = 'simulink/Signal Routing/Bus Selector';
                            dstT = [TargetModel '/' BlockName];
                            h = add_block(srcT,dstT,'MakeNameUnique','on');
                            set_param(h,'position',[block_x,block_y,block_w,block_h]);
                            set_param(h,'outputsignals',OUTPSignal,'ShowName', 'off');
                            sourceport = get_param(h,'PortHandles');
                            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(m));
            
                            targetport = sourceport;
                            targetpos = get_param(targetport.Inport(1),'Position');
            
                            BlockName = 'From';
                            block_x = targetpos(1) - 300;
                            block_y = targetpos(2) - 20;
                            block_w = block_x + 220;
                            block_h = block_y + 40;
                            srcT = 'simulink/Signal Routing/From';
                            dstT = [TargetModel '/' BlockName];
                            h = add_block(srcT,dstT,'MakeNameUnique','on');
                            set_param(h,'position',[block_x,block_y,block_w,block_h]);
                            if IsSCPSignal
                                set_param(h,'Gototag', 'BSCP_outputs','ShowName', 'off');
                            else
                                set_param(h,'Gototag', 'BOUTP_outputs','ShowName', 'off');
                            end
                            sourceport = get_param(h,'PortHandles');
                            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                        end
                    end    
                end
            end

            %% link signal from messagelink file
            if ~Autosar_flg
            %   for k = 1:str2double(DLC)
%                     TargetModel = MsgModel;
%                     buf = get_param([TargetModel '/Byte_' num2str(k-1)],'Handle');
%                     buf = find_system(buf,'SearchDepth', 1, 'BlockType', 'Inport');
%                     if isempty(buf); continue; end
% 
%                     for m = 1:length(buf)
%                         SignalName_raw = get_param(buf(m), 'Name');
%                         idx = strcmp(MessageLink(:,1),SignalName_raw);
%                         IsSCPSignal = boolean(0);
% 
%                         if isempty(find(idx, 1)) || isempty(MessageLink{idx,2})
%                             SCPSignal = ['VSCP_' Channel char(erase(MsgName, '_')) char(erase(SignalName_raw, '_')) '_'];
%                             idx = find(contains(DD_SCP(:,1),SCPSignal));
%                             if isempty(idx)
%                                 OUTPSignal = '';
%                             else
%                                 IsSCPSignal = boolean(1);
%                                 OUTPSignal = char(DD_SCP(idx,1));
%                             end
%                         else
%                             % Detect each APP On CAN signal and MessageLinkOut
%                             idx = contains(DD_OUTP(:,7),MessageLink(idx,2));
%                             OUTPSignal = char(DD_OUTP(idx,1));
%                             OutputSignal_idy = strcmp(OutputSignal(:,1),SignalName_raw);
%                             OutputSignal_idx = strcmp(OutputSignal(1,:), Channel);
%                             if ~any(idx) ||...
%                                 ~strcmp(OutputSignal(OutputSignal_idy,OutputSignal_idx),MsgName)
%                                 WaningModel = [TargetModel '/Byte_' num2str(k-1)];
%                                 msg = [SignalName_raw char(9) 'No link successful, checkout MessageLinkOut' char(9)...
%                                     '<a href="matlab:Simulink.SimulationData.BlockPath.hilite_block (''' WaningModel ''')">' WaningModel '</a>'];
%                                 warning(msg);
%                             end
%                         end
% 
%                         targetport = get_param([TargetModel '/Byte_' num2str(k-1)],'Porthandles');
%                         targetpos = get_param(targetport.Inport(m),'Position');
% 
%                         if  CRC_flg && any(contains(RC_SignalName,SignalName_raw))
%                             BlockName = 'RollingCounter';
%                             block_x = targetpos(1) - 200;
%                             block_y = targetpos(2) - 20;
%                             block_w = block_x + 100;
%                             block_h = block_y + 40;
%                             srcT = 'FVT_lib/hal/RollingCounter';
%                             dstT = [TargetModel '/' BlockName];
%                             h = add_block(srcT,dstT,'MakeNameUnique','on');
%                             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                             sourceport = get_param(h,'PortHandles');
%                             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(m));
%                             continue;                 
%                         elseif isempty(OUTPSignal)
%                             BlockName = 'Ground';
%                             block_x = targetpos(1) - 100;
%                             block_y = targetpos(2) - 15;
%                             block_w = block_x + 30;
%                             block_h = block_y + 30;
%                             srcT = 'simulink/Commonly Used Blocks/Ground';
%                             dstT = [TargetModel '/' BlockName];
%                             h = add_block(srcT,dstT,'MakeNameUnique','on');     
%                             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                             set_param(h,'ShowName', 'off');
%                             sourceport = get_param(h,'PortHandles');
%                             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(m));
%                            if ~startsWith(char(SignalName_raw),'NM_')
%                              % WaningModel = [TargetModel '/Byte_' num2str(k-1)];
%                              % msg = [char(SignalName_raw) char(9) 'link Ground '];
%                              % disp([ msg char(9) '<a href="matlab:Simulink.SimulationData.BlockPath.hilite_block (''' WaningModel ''')">' WaningModel '</a>']);
%                             end
%                             continue;
%                         end
% 
%                         BlockName='bus_selector';
%                         block_x = targetpos(1) - 200;
%                         block_y = targetpos(2) - 20;
%                         block_w = block_x + 10;
%                         block_h = block_y + 30;
%                         srcT = 'simulink/Signal Routing/Bus Selector';
%                         dstT = [TargetModel '/' BlockName];
%                         h = add_block(srcT,dstT,'MakeNameUnique','on');
%                         set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                         set_param(h,'outputsignals',OUTPSignal,'ShowName', 'off');
%                         sourceport = get_param(h,'PortHandles');
%                         add_line(TargetModel,sourceport.Outport(1),targetport.Inport(m));
% 
%                         targetport = sourceport;
%                         targetpos = get_param(targetport.Inport(1),'Position');
% 
%                         BlockName = 'From';
%                         block_x = targetpos(1) - 300;
%                         block_y = targetpos(2) - 20;
%                         block_w = block_x + 220;
%                         block_h = block_y + 40;
%                         srcT = 'simulink/Signal Routing/From';
%                         dstT = [TargetModel '/' BlockName];
%                         h = add_block(srcT,dstT,'MakeNameUnique','on');
%                         set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                         if IsSCPSignal
%                             set_param(h,'Gototag', 'BSCP_outputs','ShowName', 'off');
%                         else
%                             set_param(h,'Gototag', 'BOUTP_outputs','ShowName', 'off');
%                         end
%                         sourceport = get_param(h,'PortHandles');
%                         add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%                     end
%                 end
            else % Autosar messagelink
                SignalName_raw = DBC.MessageInfo(cell2mat(TxMsgTable(i,strcmp(TxMsgTable(1,:),'DBCidx')))).Signals;
                for k = 1:length(SignalName_raw)

                    % Filter signal not in DT
                    if ~any(strcmp(extractAfter(string(DT_Msg_signal),[Channel '_']),SignalName_raw(k)))
                        continue
                    end

                    TargetModel = MsgModel;
                    buf = get_param([TargetModel '/' erase(char(SignalName_raw(k)),'_')],'Handle');
                    buf = 1;
                    if isempty(buf); continue; end

                    ChecK_SignalName_raw = char(SignalName_raw(k));
                    idx = strcmp(MessageLink(:,1),ChecK_SignalName_raw);
                    IsSCPSignal = boolean(0);

                    if isempty(find(idx, 1)) || isempty(MessageLink{idx,2}) || strcmp(MessageLink{idx,2},'SCP')
                        SCPSignal = ['VSCP_' Channel char(erase(MsgName, '_')) char(erase(SignalName_raw(k), '_')) '_'];
                        idx = find(contains(DD_SCP(:,1),SCPSignal));
                        if isempty(idx)
                            OUTPSignal = '';
                        else
                            IsSCPSignal = boolean(1);
                            OUTPSignal = char(DD_SCP(idx,1));
                        end
                    else
                        idx = contains(DD_OUTP(:,7),MessageLink(idx,2));
                        OUTPSignal = char(DD_OUTP(idx,1));
                        OutputSignal_idy = strcmp(OutputSignal(:,1),ChecK_SignalName_raw);
                        OutputSignal_idx = strcmp(OutputSignal(1,:), Channel);
                        if ~any(idx) ||...
                            ~strcmp(OutputSignal(OutputSignal_idy,OutputSignal_idx),MsgName)
                            WaningModel = [TargetModel '/'  erase(char(SignalName_raw(k)),'_')];
                            msg = [ChecK_SignalName_raw char(9) 'No link successful, checkout MessageLinkOut' char(9)...
                            '<a href="matlab:Simulink.SimulationData.BlockPath.hilite_block (''' WaningModel ''')">' WaningModel '</a>'];
                            warning(msg);
                        end
                    end

                    targetport = get_param([TargetModel '/'  erase(char(SignalName_raw(k)),'_')],'Porthandles');
                    targetpos = get_param(targetport.Inport(1),'Position');

                    if  CRC_flg && strcmp(CS_SignalName,ChecK_SignalName_raw) % add CRC8 library if need
                        BlockName = 'From';
                        block_x = targetpos(1) - 505;
                        block_y = targetpos(2) - 20;
                        block_w = block_x + 220;
                        block_h = block_y + 40;
                        srcT = 'simulink/Signal Routing/From';
                        dstT = [TargetModel '/' BlockName];
                        h = add_block(srcT,dstT,'MakeNameUnique','on');     
                        set_param(h,'position',[block_x,block_y,block_w,block_h])
                        set_param(h,'Gototag',char(CS_SignalName),'ShowName', 'off');
                        sourceport = get_param(h,'PortHandles');
                        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                        continue;
                    elseif CRC_flg && strcmp(RC_SignalName,ChecK_SignalName_raw) % add Rollingcounter library if need
                        BlockName = 'RollingCounter_IfAction';
                        block_x = targetpos(1) - 200;
                        block_y = targetpos(2) - 20;
                        block_w = block_x + 120;
                        block_h = block_y + 40;
                        srcT = 'FVT_lib/hal/RollingCounter_IfAction';
                        dstT = [TargetModel '/' BlockName];
                        h = add_block(srcT,dstT,'MakeNameUnique','on');
                        set_param(h,'position',[block_x,block_y,block_w,block_h]);
                        sourceport = get_param(h,'PortHandles');
                        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on');

                        % add E2E Enable for Rolling counter
                        targetport = sourceport;
                        targetpos = get_param(targetport.Inport(1),'Position');
                        BlockName = 'Constant';
                        block_x = targetpos(1) - 300;
                        block_y = targetpos(2) - 20;
                        block_w = block_x + 220;
                        block_h = block_y + 40;
                        srcT = 'simulink/Commonly Used Blocks/Constant';
                        dstT = [TargetModel '/' BlockName];
                        h = add_block(srcT,dstT,'MakeNameUnique','on');
                        set_param(h,'position',[block_x,block_y,block_w,block_h]);
                        set_param(h,'Value',['KHAL_' Channel erase(MsgName,'_') 'E2E_flg'],'ShowName', 'off');
                        sourceport = get_param(h,'PortHandles');
                        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on');
                        continue;
                    elseif isempty(OUTPSignal)
                        BlockName = 'Ground';
                        block_x = targetpos(1) - 100;
                        block_y = targetpos(2) - 15;
                        block_w = block_x + 30;
                        block_h = block_y + 30;
                        srcT = 'simulink/Commonly Used Blocks/Ground';
                        dstT = [TargetModel '/' BlockName];
                        h = add_block(srcT,dstT,'MakeNameUnique','on');     
                        set_param(h,'position',[block_x,block_y,block_w,block_h])
                        set_param(h,'ShowName', 'off');
                        sourceport = get_param(h,'PortHandles');
                        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                        disp(char(SignalName_raw(k)))
                        continue;
                    end

                    BlockName='bus_selector';
                    block_x = targetpos(1) - 200;
                    block_y = targetpos(2) - 20;
                    block_w = block_x + 10;
                    block_h = block_y + 30;
                    srcT = 'simulink/Signal Routing/Bus Selector';
                    dstT = [TargetModel '/' BlockName];
                    h = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    set_param(h,'outputsignals',OUTPSignal,'ShowName', 'off');
                    sourceport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));

                    targetport = sourceport;
                    targetpos = get_param(targetport.Inport(1),'Position');

                    BlockName = 'From';
                    block_x = targetpos(1) - 300;
                    block_y = targetpos(2) - 20;
                    block_w = block_x + 220;
                    block_h = block_y + 40;
                    srcT = 'simulink/Signal Routing/From';
                    dstT = [TargetModel '/' BlockName];
                    h = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    if IsSCPSignal
                        set_param(h,'Gototag', 'BSCP_outputs','ShowName', 'off');
                    else
                        set_param(h,'Gototag', 'BOUTP_outputs','ShowName', 'off');
                    end
                    sourceport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                end
            end
        end

       %% Add signals for CE message

        if (contains(MsgTxMethod,'CE') && (~(exist('Detect_frame_routing','var')) || isempty(Detect_frame_routing))) && (~Autosar_flg || CRC_flg || CRC_E2E_flg)
            TargetModel = [new_model '/' Channel '/' MsgName '_Tx'];

            for k = 1:length(MsgPackTable(:,1))
                SigSendType = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(k).Attributes(:,1),'GenSigSendType')).Value;
                Signal_event_flg = strcmp(string(SigSendType),'OnChange');
                SignalName_raw = char(MsgPackTable(k,1));
                idx = strcmp(MessageLink(:,1),SignalName_raw);
                IsSCPSignal = boolean(0);
                % For On change signal warning(float)
                SignalResolution = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(k).Factor;
                SignalOffset = DBC.MessageInfo(cell2mat(TxMsgTable(i,1))).SignalInfo(k).Offset;

                if isempty(find(idx, 1)) || isempty(MessageLink{idx,2})
                    SCPSignal = ['VSCP_' Channel char(erase(MsgName, '_')) char(erase(SignalName_raw, '_')) '_'];
                    idx = find(contains(DD_SCP(:,1),SCPSignal));
                    if isempty(idx)
                        OUTPSignal = '';
                    else
                        IsSCPSignal = boolean(1);
                        OUTPSignal = char(DD_SCP(idx,1));
                        OUTPSignal_Datatype = char(DD_SCP(idx,strcmp(DD_SCP(1,:),'Data type')));
                    end
                else
                    idx = contains(DD_OUTP(:,7),MessageLink(idx,2));
                    OUTPSignal = char(DD_OUTP(idx,1));
                    OUTPSignal_Datatype = char(DD_OUTP(idx,strcmp(DD_OUTP(1,:),'Data type')));
                end

                if isempty(OUTPSignal) || ~Signal_event_flg
                    BlockName = 'Ground';
                    targetport = get_param([TargetModel '/OR'],'PortHandles');
                    targetpos = get_param(targetport.Inport(k),'Position');
                    srcT = 'simulink/Commonly Used Blocks/Ground';
                    dstT = [TargetModel '/' BlockName];
                    block_x = targetpos(1) - 100;
                    block_y = targetpos(2)-15;
                    block_w = block_x + 30;
                    block_h = block_y + 30;
                    h = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(h,'position',[block_x,block_y,block_w,block_h])
                    set_param(h,'ShowName', 'off');
                    sourceport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(k));
                    continue;
                end

                targetport = get_param([TargetModel '/OR'],'PortHandles');
                targetpos = get_param(targetport.Inport(k),'Position');
                BlockName='detect_change';
                srcT = 'simulink/Logic and Bit Operations/Detect Change';
                dstT = [TargetModel '/' BlockName];
                block_x = targetpos(1) - 120;
                block_y = targetpos(2) - 15;
                block_w = block_x + 70;
                block_h = block_y + 30;
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h],'ShowName', 'off');
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(k));
                targetport = sourceport;

                % For On change signal warning(float)
                if strcmp(OUTPSignal_Datatype,'single')
                    BlockName = 'Data Type Conversion';
                    srcT = 'simulink/Signal Attributes/Data Type Conversion';
                    dstT = [TargetModel '/' BlockName];
                    block_x = targetpos(1) - 260;
                    block_y = targetpos(2) - 20;
                    block_w = block_x + 100;
                    block_h = block_y + 40;
                    h = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    set_param(h,'OutDataTypeStr', 'uint8','ShowName', 'off');
                    sourceport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                    targetport = sourceport;

                    BlockName = 'convert_out';
                    block_x = targetpos(1) - 420;
                    block_y = targetpos(2) - 25;
                    block_w = block_x + 100;
                    block_h = block_y + 50;
                    srcT = 'FVT_lib/hal/convert_out';
                    dstT = [TargetModel '/' BlockName];
                    h = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(h,'position',[block_x,block_y,block_w,block_h],'ShowName', 'off');
                    set_param(h, 'MaskValues', {num2str(SignalResolution),num2str(SignalOffset)});
                    sourceport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                    targetport = sourceport;
                end
                
                BlockName='bus_selector';
                srcT = 'simulink/Signal Routing/Bus Selector';
                dstT = [TargetModel '/' BlockName];
                block_x = targetpos(1) - 600;
                block_y = targetpos(2) - 20;
                block_w = block_x + 10;
                block_h = block_y + 30;
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'outputsignals',OUTPSignal,'ShowName', 'off');
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                targetport = sourceport;

                targetpos = get_param(targetport.Inport(1),'Position');
                BlockName = 'From';
                block_x = targetpos(1) - 300;
                block_y = targetpos(2) - 20;
                block_w = block_x + 220;
                block_h = block_y + 40;
                srcT = 'simulink/Signal Routing/From';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                if Signal_event_flg
                    if IsSCPSignal
                        set_param(h,'Gototag', 'BSCP_outputs','ShowName', 'off');
                    else
                        set_param(h,'Gototag', 'BOUTP_outputs','ShowName', 'off');
                    end
                end
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
            end
        end
        
        if Autosar_flg  && any(contains(Autosar_output_msg_CAN,MsgName))
            TargetModel = MsgModel;
            Autosar_output_msg = char(Autosar_output_msg_CAN(strcmp(extractAfter(Autosar_output_msg_CAN,'SG_'),MsgName)));
            targetport = get_param(TargetModel ,'PortHandles');
            targetpos = get_param(targetport.Outport(1),'Position');
            TargetModel = [new_model '/' Channel];
            srcT = 'simulink/Sinks/Out1';
            dstT = [TargetModel '/' Autosar_output_msg];
            block_x = targetpos(1) + 100;
            block_y = targetpos(2) -5;
            block_w = block_x + 30;
            block_h = block_y + 13;
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            sourceport = get_param(h,'PortHandles');
            set_param(h,'position',[block_x,block_y,block_w,block_h],'UseBusObject','on','BusObject',Autosar_output_msg);
            add_line(TargetModel, targetport.Outport(1), sourceport.Inport(1));
        end
    end
    
    for j = length(DD_cell(:,1)):-1:1
        if cellfun(@isempty,DD_cell(j,1))
        DD_cell(j,:) = [];
        end
    end
    disp([Channel 'done!']);
    DD_halout = [DD_halout;DD_cell];
end

% Set output port number
for g = 1:length(CAN_Msg_Output_array)
    Targetport_name = char(CAN_Msg_Output_array(g));

    for n = 1:NUN_CHANNEL
        Channel = char(channel_list(q(n)));
        Channel = erase(Channel, '_');
        targetport = get_param([new_model '/' Channel],'PortHandles');
        h = get_param([new_model '/' Channel],'LineHandles');
        Linksatus = find(h.Outport ==-1);
     
        for i = 1:length(Linksatus)
            targetpos = get_param(targetport.Outport(Linksatus(i)),'Position');
            h = get_param([new_model '/' Channel],'Handle');
            h = find_system(h,'SearchDepth', 1, 'BlockType', 'Outport');
            Ouputport_Name = get_param(h(Linksatus(i)),'Name');
            if contains(Targetport_name,erase(Ouputport_Name,'DT_'))
                BlockName = Targetport_name;
                srcT = 'simulink/Sinks/Out1';
                dstT = [new_model '/' BlockName];
                block_x = targetpos(1) +100;
                block_y = targetpos(2) -5;
                block_w = block_x + 30;
                block_h = block_y + 13;
                h = add_block(srcT,dstT);
                set_param(h,'position',[block_x,block_y,block_w,block_h],'UseBusObject','on','BusObject',Ouputport_Name,'Port',num2str(g));
                sourceport = get_param(h,'PortHandles');
                add_line(new_model,targetport.Outport(Linksatus(i)),sourceport.Inport(1));
                break
            end
        end
        if strcmp(BlockName,Targetport_name), break, end
    end
end

% % For else outport
% Channel = char(channel_list(q(end)));
% ElseOutport_array = {'VOUTP_NetworkReq_flg','VOUTP_SysPowerMode_enum','VOUTP_NvWriteReqRisingEdge_flg','VOUTP_FdcSlpReqRisingEdge_flg','VOUTP_FdcSlpTime_sec','VOUTP_IVIRST_flg'};
% BusSelector_array = 'VOUTP_NetworkReq_flg,VOUTP_SysPowerMode_enum,VOUTP_NvWriteReqRisingEdge_flg,VOUTP_FdcSlpReqRisingEdge_flg,VOUTP_FdcSlpTime_sec,VOUTP_IVIRST_flg';
% targetpos = get_param([new_model '/' Channel],'Position');
% BlockName = 'Bus_Selector';
% block_x = targetpos(1) + 120;
% block_y = targetpos(2) + 500;
% block_w = block_x + 10;
% block_h = block_y + 40*length(ElseOutport_array);
% srcT = 'simulink/Signal Routing/Bus Selector';
% dstT = [new_model '/' BlockName];
% h = add_block(srcT,dstT);
% set_param(h,'outputsignals',BusSelector_array,'ShowName', 'off');
% set_param(h,'position',[block_x,block_y,block_w,block_h]);
% sourceport = get_param(h,'PortHandles');
% 
% for i =1:length(ElseOutport_array)
%     targetpos = get_param(sourceport.Outport(i),'Position');
%     BlockName = char(ElseOutport_array(i));
%     srcT = 'simulink/Sinks/Out1';
%     dstT = [new_model '/' BlockName];
%     block_x = targetpos(1) + 220;
%     block_y = targetpos(2) -5;
%     block_w = block_x + 30;
%     block_h = block_y + 13;
%     hh = add_block(srcT,dstT);
%     set_param(hh,'position',[block_x,block_y,block_w,block_h],'ShowName', 'on');
%     targetport = get_param(hh,'PortHandles');
%     add_line(new_model, sourceport.Outport(i), targetport.Inport(1));
% end
% 
% targetport = get_param(h,'PortHandles');
% targetpos = get_param(targetport.Inport(1),'Position');
% BlockName = 'From';
% block_x = targetpos(1) - 300;
% block_y = targetpos(2) - 20;
% block_w = block_x + 220;
% block_h = block_y + 40;
% srcT = 'simulink/Signal Routing/From';
% dstT = [new_model '/' BlockName];
% h = add_block(srcT,dstT,'MakeNameUnique','on');
% set_param(h,'position',[block_x,block_y,block_w,block_h]);
% set_param(h,'Gototag', 'BOUTP_outputs','ShowName', 'off');
% sourceport = get_param(h,'PortHandles');
% add_line(new_model, sourceport.Outport(1), targetport.Inport(1));


% Set output port number for E2E Tx trigger
for n = 1:NUN_CHANNEL
    Channel = char(channel_list(q(n)));
    Channel = erase(Channel, '_');
    targetport = get_param([new_model '/' Channel],'PortHandles');
    h = get_param([new_model '/' Channel],'LineHandles');
    Linksatus = find(h.Outport ==-1);
 
    for i = 1:length(Linksatus)
        targetpos = get_param(targetport.Outport(Linksatus(i)),'Position');
        h = get_param([new_model '/' Channel],'Handle');
        h = find_system(h,'SearchDepth', 1, 'BlockType', 'Outport');
        Ouputport_Name = get_param(h(Linksatus(i)),'Name');   
        if startsWith(Ouputport_Name,'E2E') && contains(Ouputport_Name,'Trigger')
            % Set E2E trigger output port at the end of the order
            BlockName = Ouputport_Name;
            srcT = 'simulink/Sinks/Out1';
            dstT = [new_model '/' BlockName];
            block_x = targetpos(1) +100;
            block_y = targetpos(2) -5;
            block_w = block_x + 30;
            block_h = block_y + 13;
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h]);  
        end
        sourceport = get_param(h,'PortHandles');
        add_line(new_model,targetport.Outport(Linksatus(i)),sourceport.Inport(1));
    end

    for i = 1:length(targetport.Inport)
        targetpos = get_param(targetport.Inport(i),'Position');
        g = get_param([new_model '/' Channel],'Handle');
        g = find_system(g,'SearchDepth', 1, 'BlockType', 'Inport');
        BlockName = get_param(g(i), 'Name');
        srcT = 'simulink/Signal Routing/From';
        dstT = [new_model '/' BlockName];
        block_x = targetpos(1) - 300;
        block_y = targetpos(2)-20;
        block_w = block_x + 220;
        block_h = block_y + 40;
        g = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(g,'position',[block_x,block_y,block_w,block_h]);
        set_param(g,'Gototag',BlockName,'ShowName', 'off'); 
        sourceport = get_param(g,'PortHandles');
        add_line(new_model, sourceport.Outport(1), targetport.Inport(i));
    end
end

%% Create SYS Variable signal 
DD_halout(end+1,:) = {'KHAL_CounterMAXE2E_enum'    'internal'    'uint8'   '0'    '14'  'N/A'  'flg' '14'};
DD_halout(end+1,:) = {'KHAL_CounterMAX_enum'       'internal'    'uint8'   '0'    '15'  'N/A'  'flg' '15'};
disp('Writing DD file...');
DD_halout(1,:) = [];
DD_path = [arch_Path '\hal\halout'];
cd(DD_path);
DD_Sigtable = cell2table(cell(1,6));
DD_Sigtable.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units'};
DD_Caltable = cell2table(DD_halout);
DD_Caltable.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units' 'Enum Table' 'Default during Running'};
File_name = ['DD_HALOUT_',char(date),'.xlsx'];
writetable(DD_Sigtable,File_name,'Sheet',1);
writetable(DD_Caltable,File_name,'Sheet',2);

File_pos = strcat(DD_path,'\',File_name);
xlsApp = actxserver('Excel.Application');
ewb = xlsApp.Workbooks.Open(File_pos);
ewb.Worksheets.Item(1).name = 'Signals';
ewb.Worksheets.Item(1).Range('A1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('B1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('C1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('D1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('E1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('F1').Interior.ColorIndex = 4;

ewb.Worksheets.Item(2).name = 'Calibrations';
ewb.Worksheets.Item(2).Range('A1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('B1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('C1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('D1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('E1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('F1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('G1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('H1').Interior.ColorIndex = 4;
ewb.Save();
ewb.Close(true);

disp('Write DD finish, running FVT_export_businfo_modified');

DD_file = 'DD_HALOUT.xlsx';
DD_path = [arch_Path '\hal\halout'];
delete DD_HALOUT.xlsx;
movefile(File_name,DD_file);

signal_table = readtable(DD_file,'sheet','Signals','PreserveVariableNames',true);
calibration_table = readtable(DD_file,'sheet','Calibrations','PreserveVariableNames',true);
verctrl = 'FVT_export_businfo_v3.0 2022-09-06';
buildbus(DD_file,DD_path,signal_table,calibration_table,verctrl);

cd(arch_Path);
disp('halout Done!')
end

function buildbus(FileName,PathName,signal_table,calibration_table,verctrl)
%% Get sheets name & number
cd (PathName);
[~,sheets] = xlsfinfo(FileName);
numSheets = length(sheets);
%% Get module name
module_name = extractAfter(FileName,"_");
module_name = extractBefore(module_name,".");
%% Get sig & cal size
[num_signal, ~] = size(signal_table);
[num_calibration, ~] = size(calibration_table);
%% Get cal array/table name & number
if contains(module_name,'_')
    m_str = ['M' extractBefore(module_name,'_')];
    a_str = ['A' extractBefore(module_name,'_') '_'];
    A_str = ['A' extractBefore(module_name,'_')];
else
    m_str = ['M' module_name];
    a_str = ['A' module_name '_'];
    A_str = ['A' module_name];
end
k = 0; l = 0;
calarry = cell(numSheets, 1);
caltable = cell(numSheets, 1);
for i = 1: numSheets
    Sheets_Names = sheets(i);
    sheet_name = string(Sheets_Names);
    chk = extractBefore(sheet_name,"_");
    ychk = extractAfter(sheet_name,"_");
    ychk = extractAfter(ychk,"_");
    ychk = extractBefore(ychk,"_");
    if (chk==m_str)&&(ychk=='Y')
        l = l+1;
        calarry(l,1) = cellstr(sheet_name) ;
    elseif (chk==m_str)
        k = k+1;
        caltable(k,1) = cellstr(sheet_name) ;
    end
end
num_caltable = k ; num_calarry = l ;
%% Get signal internal/output data & number
num_sig_internal = 0;
num_sig_outputs = 0;
internal_arry = cell(num_signal, 5);
output_arry = cell(num_signal, 5);
for i = 1:num_signal
    str = table2cell(signal_table(i,1));
    str = char(str);
    str_dir = table2cell(signal_table(i,2));
    str_dir = char(str_dir);
    type = table2cell(signal_table(i,3));
    type = char(type);
    unit = extractAfter(str,"_");
    unit = extractAfter(unit,"_");

    min = table2cell(signal_table(i,4));
    max = table2cell(signal_table(i,5));

    internal_flg = strcmp(str_dir,'internal');
    outputs_flg = strcmp(str_dir,'output');

    if (isempty(type)==0)&&(internal_flg==1)
        num_sig_internal = num_sig_internal +1;
        internal_arry(num_sig_internal,1) = cellstr(str);
        internal_arry(num_sig_internal,2) = cellstr(type);
        internal_arry(num_sig_internal,3) = cellstr(unit);
        internal_arry(num_sig_internal,4) = (min);
        internal_arry(num_sig_internal,5) = (max);
    elseif (isempty(type)==0)&&(outputs_flg==1)
        num_sig_outputs = num_sig_outputs +1;
        output_arry(num_sig_outputs,1) = cellstr(str);
        output_arry(num_sig_outputs,2) = cellstr(type);
        output_arry(num_sig_outputs,3) = cellstr(unit);
        output_arry(num_sig_outputs,4) = (min);
        output_arry(num_sig_outputs,5) = (max);
    end
end
%% build XXX_cal.m
cal_file = strcat(lower(module_name),"_cal.m");
fullFileName = char(cal_file) ;
fileID = fopen(fullFileName, 'w');
%% disp('Loading $Id: pmm_cal.m 198 2013-08-29 09:10:12Z haitec $')
%tile1 = 'disp(''Loading $Id:';
%tile2 = 'foxtron $'')';
datetime.setDefaultFormats('default','yyyy-MM-dd HH:mm:ss');

fprintf(fileID,'%%===========$Update Time :  %s $=========\n',datetime);
fprintf(fileID,'disp(''Loading $Id: %s  %s    foxtron $      %s'')',cal_file,datetime,verctrl);
fprintf(fileID,'\n');
fprintf(fileID,'\n');
%tot_sig = '';
str_firstcali = (string(table2cell(calibration_table(1,1))));
%% Judge have cali data or not
if (num_calibration~=0)&&(str_firstcali ~="0")
    %% Write KXXX cal data
    for i = 1:num_calibration
        str = table2cell(calibration_table(i,1));
        str_tablechk = extractBefore(str,"_");
        if (str_tablechk~=string(A_str))&&(str_tablechk~=string(m_str))
            str = char(str);
            defval = string(table2cell(calibration_table(i,8)));
            if (ismissing(defval)==1)
                defval = '0';
            end
            sig = strcat("a2l_cal(","'",str,"',","     ", defval,")",";");
            fprintf(fileID,'%s \n',char(sig));
        end
    end
    %% write caltable(XYZ) cal data
    for i = 1:num_caltable
        str_var = char(caltable(i,1));
        %    if ~contains(str_var,'_Z_'), continue, end

        str_var_chk = extractAfter(str_var,"_");
        str_var_chk = extractBefore(str_var_chk,"_");
        str_var_x = strcat(a_str,str_var_chk,"_X");
        str_var_y = strcat(a_str,str_var_chk,"_Y");

        table_var = readtable([PathName FileName],'sheet', str_var);

        arry_var = table2cell(table_var(:,1));
        var_y = arry_var(any(cellfun(@(x)any(~isnan(x)),arry_var),2),1);
        arry_var = table2cell(table_var(1,:));
        arry_var = transpose(arry_var);
        var_x = arry_var(any(cellfun(@(x)any(~isnan(x)),arry_var),2),1);
        num_x = length(var_x);
        num_y = length(var_y);
        var_z = table_var(2:num_y+1,2:num_x+1);
        var_z = table2cell(var_z);

        al2_x = strjoin(string(cell2mat((var_x)')));
        al2_y = strjoin(string(cell2mat((var_y)')));
        join_z = join(string(cell2mat(var_z)));
        al2_z = '';
        for j = 1:num_y
            al2_z = strcat(al2_z,";",join_z(j));
        end
        al2_z = extractAfter(al2_z,";");

        sig_z = strcat("a2l_cal(","'",str_var,"',","     ", "[", al2_z,"]",")",";");

        for j = 1:num_calibration
            str_mod = table2cell(calibration_table(j,1));
            str_mod = char(str_mod);
            chk_flg = strncmp(str_var_x, str_mod, length(char(str_var_x)));
            if (chk_flg==1)
                sig_x = strcat("a2l_cal(","'",str_mod,"',","     ","[", al2_x,"]",")",";");
                fprintf(fileID,[char(sig_x)  '\n']);
            end
        end

        for j = 1:num_calibration
            str_mod = table2cell(calibration_table(j,1));
            str_mod = char(str_mod);
            chk_flg = strncmp(str_var_y, str_mod, length(char(str_var_x)));
            if (chk_flg==1)
                sig_y = strcat("a2l_cal(","'",str_mod,"',","     ","[", al2_y,"]",")",";");
                fprintf(fileID,[char(sig_y)  '\n']);
            end
        end

        fprintf(fileID,[char(sig_z) '\n']);
    end
    %%  write calarray(XY) cal data
    for i = 1:num_calarry
        str_var = char(calarry(i,1));
        str_var_chk = extractAfter(str_var,"_");
        str_var_chk = extractBefore(str_var_chk,"_");
        str_var_x = strcat(a_str,str_var_chk,"_X");

        table_var = readtable([PathName FileName],'sheet', str_var);

        var_x = table2cell(table_var(1,2:end));
        var_y = table2cell(table_var(2,2:end));
        %num_x = length(var_x);
        %num_y = length(var_y);

        al2_x = strjoin(string(cell2mat((var_x)')));
        al2_y = strjoin(string(cell2mat((var_y)')));


        sig_z = strcat("a2l_cal(","'",str_var,"',","     ", "[", al2_y,"]",")",";");
        for j = 1:num_calibration
            str_mod = table2cell(calibration_table(j,1));
            str_mod = char(str_mod);
            chk_flg = strncmp(str_var_x, str_mod, length(char(str_var_x)));
            if (chk_flg==1)
                sig_x = strcat("a2l_cal(","'",str_mod,"',","     ","[", al2_x,"]",")",";");
                fprintf(fileID,[char(sig_x) '\n']);
            end
        end
        fprintf(fileID,[char(sig_z)  '\n']);

    end
end
%% Close the file.
fclose(fileID);
% Open the file in the editor.
% save(fullFileName);


%% build XXX_outputs.m
outputsfile = strcat("B",module_name,"_outputs.m");
output_filename =char(outputsfile);
outputs = strcat("B",module_name,"_outputs");
%couputs = char(outputs);
spe_couputs = strcat("'",outputs,"'");
fileID = fopen(output_filename, 'w');
datetime.setDefaultFormats('default','yyyy-MM-dd HH:mm:ss');
second = strcat("function ",outputs,"(varargin)");
%second = strcat("function cellInfo = ",outputs,"(varargin)");
datetime.setDefaultFormats('default','yyyy-MM-dd HH:mm:ss');

fprintf(fileID,[char(second) '\n']);
fprintf(fileID,'%%===========$Update Time :  %s $=========\n',datetime);
fprintf(fileID,'disp(''Loading $Id: %s  %s    foxtron $ %s'')\n',outputsfile,datetime,verctrl);

%tile = ['%%===========$Update Time : ' date '$========='];
fprintf(fileID,'%%===========$Update Time :  %s $=========\n',datetime);
fprintf(fileID,['%% BXXX_outputs returns a cell array containing bus object information' '\n'...
    '%% Optional Input: ''false'' will suppress a call to Simulink.Bus.cellToObject' '\n'...
    '%% when the m-file is executed.' '\n'...
    '%% The order of bus element attributes is as follows:' '\n'...
    '%% ElementName, Dimensions, DataType, SampleTime, Complexity, SamplingMode' '\n'...
    '\n'...
    'suppressObject = false;' '\n'...
    'if nargin == 1 && islogical(varargin{1}) && varargin{1} == false' '\n'...
    'suppressObject = true;' '\n'...
    'elseif nargin > 1' '\n'...
    'error(''Invalid input argument(s) encountered'');' '\n'...
    'end' '\n'...
    '\n'...
    'cellInfo = { ... ' '\n'...
    '           {... ' '\n'...
    '    '     char(spe_couputs) ',...'  '\n'...
    '       '''', ...'  '\n'...
    '       sprintf(''''), { ... ' '\n'...
    ]);
for i = 1:num_sig_outputs
    str = output_arry(i,1) ;
    str = string(str);
    type = output_arry(i,2) ;
    type = string(type);
    sens = strcat("{","'", str ,"' ", " ,1, ", " '", type ,"' ", " ,-1" , ", 'real'", " ,'Sample'};...");
    fprintf(fileID,[
        '         '  char(sens) '\n'...
        ]);
end

fprintf(fileID,[ '      } ... ' '\n'...
    '    } ...' '\n'...
    '  }''; ' '\n'...
    'if ~suppressObject'  '\n'...
    '    %% Create bus objects in the MATLAB base workspace' '\n'...
    '    Simulink.Bus.cellToObject(cellInfo)' '\n'...
    'end' '\n'...
    'end' '\n'...
    ]);


% Close the file.
fclose(fileID);
% Open the file in the editor.
% save(output_filename);


%% build xxx_var.m

varfile = strcat(lower(module_name),"_var.m");
varfile =char(varfile);
fileID = fopen(varfile, 'w');
datetime.setDefaultFormats('default','yyyy-MM-dd HH:mm:ss');

fprintf(fileID,'%%===========$Update Time :  %s $=========\n',datetime);
fprintf(fileID,'disp(''Loading $Id: %s  %s    foxtron $      %s'')',varfile,datetime,verctrl);
fprintf(fileID,['\n'...
    '%%%% Calibration Name, Units, Min, Max, Data Type, Comment' '\n'...
    ]);
str_firstcali = (string(table2cell(calibration_table(1,1))));
if (num_calibration~=0)&&(str_firstcali ~="0")
    for i = 1:num_calibration
        str = table2cell(calibration_table(i,1));
        str = string(str);
        unit = table2cell(calibration_table(i,6));
        unit = string(unit);
        type = table2cell(calibration_table(i,3));
        type = string(type);
        max = table2cell(calibration_table(i,5));
        max = string(max);
        min = table2cell(calibration_table(i,4));
        min = string(min);

        sens = strcat("a2l_par('", str, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
        fprintf(fileID,[ char(sens)  '\n'...
            ]);
    end


    fprintf(fileID,['\n'...
        '%%%% Monitored Signals'  '\n'...
        '%% Internal Signals %%' '\n'...
        ]);
end
if (num_sig_internal~=0)
    for i = 1:num_sig_internal
        str = string(internal_arry(i,1));
        unit = string(internal_arry(i,3));
        type = string(internal_arry(i,2));
        max = string(internal_arry(i,5));
        min = string(internal_arry(i,4));
        sens = strcat("a2l_mon('", str, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
        fprintf(fileID,[ char(sens)  '\n'...
            ]);
    end
end


fprintf(fileID,['\n'...
    '%%%% Outputs Signals'  '\n'...
    '%% Outputs Signals %%' '\n'...
    ]);
if (num_sig_outputs~=0)
    for i = 1:num_sig_outputs
        str = string(output_arry(i,1));
        unit = string(output_arry(i,3));
        type = string(output_arry(i,2));
        max = string(output_arry(i,5));
        min = string(output_arry(i,4));
        sens = strcat("a2l_mon('", str, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
        fprintf(fileID,[ char(sens)  '\n'...
            ]);
    end
end

% Close the file.
fclose(fileID);
% Open the file in the editor.
% save(varfile);
end

function database = LinDatabase(Filepath,FileName,Linchannel,password)
%% read excel file
xlsAPP = actxserver('excel.application');
xlsAPP.Visible = 1;
xlsWB = xlsAPP.Workbooks;
xlsFile = xlsWB.Open([Filepath FileName],[],false,[],password);
exlSheet1 = xlsFile.Sheets.Item(Linchannel);
dat_range = exlSheet1.UsedRange;
raw_data = dat_range.value;
exlSheet1 = xlsFile.Sheets.Item('Schedule');
dat_range = exlSheet1.UsedRange;
raw_data_schedule = dat_range.value;
Buf = find(strcmp(raw_data_schedule(:,1),'Slot ID'));
raw_data_schedule(1:Buf,:) = [];
data_schedule(:,1) = string(raw_data_schedule(:,2));
data_schedule(:,2) = string(raw_data_schedule(:,3));% ID(dec), delay time
xlsFile.Close(false);
xlsAPP.Quit;
%% create LIN DBC
raw_data{1,1} = [];
database = struct;
MsgIndex = find(cell2mat(cellfun(@(x)any(~isnan(x)),raw_data(:,1),'UniformOutput',false)));
MsgCnt = length(MsgIndex);
for i = 1:MsgCnt
    database.Messages(i,1) = raw_data(MsgIndex(i),1);
    database.MessageInfo(i).Name = char(raw_data(MsgIndex(i),1));
    database.MessageInfo(i).ID = hex2dec(char(raw_data(MsgIndex(i),2)));
    database.MessageInfo(i).PID = hex2dec(char(raw_data(MsgIndex(i),3)));
    database.MessageInfo(i).Length = raw_data(MsgIndex(i),6);
    database.MessageInfo(i).TxNodes = raw_data(1,strcmp(raw_data(MsgIndex(i),:),'Tx'));

    ScheduleIdx = find(strcmp(data_schedule(:,1),char(raw_data(MsgIndex(i),2))));
    if ScheduleIdx == 1
        database.MessageInfo(i).Delay = '0';
    else
        database.MessageInfo(i).Delay = num2str(sum(str2double(data_schedule(1:ScheduleIdx(1)-1,2))));
    end
    database.MessageInfo(i).MsgCycleTime = num2str(sum(str2double(data_schedule(1:end,2)))/length(ScheduleIdx));

    if i ~= MsgCnt
        Signallength = MsgIndex(i+1)-MsgIndex(i)-2;
        database.MessageInfo(i).Signals = raw_data(MsgIndex(i)+1:MsgIndex(i)+Signallength,7);
        for k = 1:Signallength
            database.MessageInfo(i).SignalInfo(k).Name = char(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Name')));

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Bit Length (Bit)')));
            % From ET_V09 CAN team changed LIN messagemap column name
            if isempty(Buf); Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Length (Bit)'))); end

            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).SignalSize = Buf; else; database.MessageInfo(i).SignalInfo(k).SignalSize = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Start Bit')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).StartBit = Buf; else; database.MessageInfo(i).SignalInfo(k).StartBit = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Resolution')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Factor = Buf; else; database.MessageInfo(i).SignalInfo(k).Factor = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Offset')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Offset = Buf; else; database.MessageInfo(i).SignalInfo(k).Offset = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Min. Value (phys)')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Minimum = Buf; else; database.MessageInfo(i).SignalInfo(k).Minimum = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Max. Value (phys)')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Maximum = Buf; else; database.MessageInfo(i).SignalInfo(k).Maximum = str2double(Buf); end

            Buf = raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Unit'));
            if ismissing(string(Buf)); database.MessageInfo(i).SignalInfo(k).Units = ""; else; database.MessageInfo(i).SignalInfo(k).Units = char(Buf); end

        end

    else
        Signallength = length(raw_data(:,1)) - MsgIndex(i);
        database.MessageInfo(i).Signals = raw_data(MsgIndex(i)+1:end,7);
        for k = 1:Signallength
            database.MessageInfo(i).SignalInfo(k).Name = char(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Name')));

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Bit Length (Bit)')));
            % From ET_V09 CAN team changed LIN messagemap column name
            if isempty(Buf); Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Length (Bit)'))); end

            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).SignalSize = Buf; else; database.MessageInfo(i).SignalInfo(k).SignalSize = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Start Bit')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).StartBit = Buf; else; database.MessageInfo(i).SignalInfo(k).StartBit = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Resolution')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Factor = Buf; else; database.MessageInfo(i).SignalInfo(k).Factor = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Offset')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Offset = Buf; else; database.MessageInfo(i).SignalInfo(k).Offset = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Min. Value (phys)')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Minimum = Buf; else; database.MessageInfo(i).SignalInfo(k).Minimum = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Max. Value (phys)')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Maximum = Buf; else; database.MessageInfo(i).SignalInfo(k).Maximum = str2double(Buf); end

            Buf = raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Unit'));
            if ismissing(string(Buf)); database.MessageInfo(i).SignalInfo(k).Units = ""; else; database.MessageInfo(i).SignalInfo(k).Units = char(Buf); end
        end
    end
end

end