function FVT_HalIn_Autobuild()
%% Initial settings
ref_car_model = {'d31x-fdc'};
car_model = ref_car_model{1};

AllMessagesRequiringRcCsCheck = {'FCM2', 'FCM4', 'ABM1', 'BMS1', 'BMS6', 'CCU1', 'CCU2', 'Shifter', ...
                                 'MCU_N_R1', 'MCU_N_F1', 'ESC1', 'ESC5', 'ESC7', 'EPS1', 'EPB1'};
EscMessagesRequiringRcCsCheck = {'ESC1', 'ESC5', 'ESC7'};
AllMessagesWithoutEscRequiringRcCsCheck = setdiff(AllMessagesRequiringRcCsCheck, EscMessagesRequiringRcCsCheck);

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
    NUM_CAN_CHANNEL = '6';
    NUM_LIN_CHANNEL = '0';
elseif strcmp(TargetNode,'ZONE_DR')
    channel_list = {'CAN_Dr1','CAN4','LIN_Dr1','LIN_Dr2','LIN_Dr3','LIN_Dr4'};
    busList =      {'1','0','0','1','2','3'};
    NUM_CAN_CHANNEL = '2';
    NUM_LIN_CHANNEL = '4';
elseif strcmp(TargetNode,'ZONE_FR')
    channel_list = {'CAN_Fr1','CAN4','LIN_Fr1','LIN_Fr2'};
    busList =      {'1','0','0','1'};
    NUM_CAN_CHANNEL = '2';
    NUM_LIN_CHANNEL = '2';
else
    error('Undefined target ECU');
end

q = questdlg(append('Check the following settings-->  ',string(channel_list), ' = BSP channel ', string(busList)), ...
	'Channel check', ...
	'Yes','No','Yes');
if ~contains(q,'Yes'), return, end
        
q = listdlg('PromptString','Select one or multiple channel to create:','ListString', channel_list, ...
            'Name', 'Select CAN Channel', ...
			'ListSize', [250 150], ...
            'SelectionMode', 'mutiple' ...
            );
NUN_CHANNEL = length(q);
%% Autosar
Autosar_flg = boolean(1);
%% RoutingTable
%
% Loading excel    
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
%% Data filter
%
% [data_m , ~] = size(raw_data);
% Numb_restore = 0;
% Frame_routing_array = cell(0);
% raw_data(cellfun(@(x) all(ismissing(x)), raw_data)) = {'Invalid'};
% raw_data(end+1,:) = {'Invalid'};
% if ~Autosar_flg
%     for i = 1:data_m
%         SignalName = raw_data(i,1);
%         Rx_MessageName = raw_data(i,2);
%         Tx_MessageName = raw_data(i,5);
%     
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
%            if strcmp(SignalName,'Invalid') && (Numb_space==0) && ~contains(Rx_MessageName,'Diag') && ~contains(Rx_MessageName,'CCP') && ~contains(Rx_MessageName,'XCP')
%                Numb_restore = Numb_restore + 1;
%                Frame_routing_array(Numb_restore,1) = cellstr(CAN_chn_res);
%                Frame_routing_array(Numb_restore,2) = Rx_MessageName;
%                Frame_routing_array(Numb_restore,3) = Tx_MessageName;
%                Frame_routing_array(Numb_restore,4) = cellstr(CAN_chn_out);
%            end
%         end
%     end
% end
%% Creat new model and all subsystems
new_model = ['HAL_IN_temp_' datestr(now,30)];
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

% Create set filter subsystem
BlockName = 'SetFilter';
block_x = original_x;
block_y = original_y;
block_w = block_x + 180;
block_h = block_y + 85;
srcT = 'simulink/Ports & Subsystems/Triggered Subsystem';
dstT = [new_model '/' BlockName];    
h = add_block(srcT,dstT);     
set_param(h,'position',[block_x,block_y,block_w,block_h]);
set_param(h,'ContentPreviewEnabled','off','BackgroundColor','LightBlue');
set_param([new_model '/' BlockName '/Trigger'],'TriggerType','function-call');
delete_line([new_model '/' BlockName],'In1/1','Out1/1');
delete_block([new_model '/' BlockName '/In1']);
delete_block([new_model '/' BlockName '/Out1']);
    
% create subsystems for different channel
for i = 1:NUN_CHANNEL
    Channel = char(channel_list(q(i)));
    Channel = erase(Channel, '_');
    BlockName = Channel;
    block_x = original_x + 600*(i-1);
    block_y = original_y + 300;
    block_w = block_x + 250;
    block_h = block_y + 400;
    srcT = 'built-in/SubSystem';
    dstT = [new_model '/' BlockName];    
    h = add_block(srcT,dstT);     
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'ContentPreviewEnabled','off','BackgroundColor','LightBlue');

    BlockName = ['HAL_' Channel '_outputs']; 
    srcT = 'simulink/Sinks/Out1';
    dstT = [new_model '/' Channel '/' BlockName]; 
    block_x = original_x + 100;
    block_y = original_y;
    block_w = block_x + 30;
    block_h = block_y + 13;
    h = add_block(srcT,dstT);  
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    
    % Frame routing raw output
    %
%     BlockName = ['HAL_' Channel 'outputs_raw']; 
%     srcT = 'simulink/Sinks/Out1';
%     dstT = [new_model '/' Channel '/' BlockName]; 
%     block_x = original_x + 100;
%     block_y = original_y + 100;
%     block_w = block_x + 30;
%     block_h = block_y + 13;
%     h = add_block(srcT,dstT);  
%     set_param(h,'position',[block_x,block_y,block_w,block_h]);
          
end

%% Read MessageLink
path = [project_path '\documents\'];
filenames = dir(path);
filenames = string({filenames.name});
MessageLinkOutName = char(filenames(contains(filenames,'MessageLinkOut')));
xlsAPP = actxserver('excel.application');
xlsAPP.Visible = 1;
xlsWB = xlsAPP.Workbooks;
xlsFile = xlsWB.Open([path MessageLinkOutName],[],false,[]);
exlSheet1 = xlsFile.Sheets.Item('InputSignal');
dat_range = exlSheet1.UsedRange;
MessageLink = dat_range.value;
xlsFile.Close(false);
xlsAPP.Quit;
cd(arch_Path);

% Filter Autosar
if Autosar_flg
    hDict = Simulink.data.dictionary.open('APPTypes.sldd');
    hDesignData = hDict.getSection('Global');
    childNamesList = hDesignData.evalin('who');
    Autosar_input_msg = cell(length(childNamesList),1);
    for j = 1:length(childNamesList)
        idx = find(contains(MessageLink(2:end,3),extractAfter(childNamesList(j),'SG_')));
        if startsWith(childNamesList(j),'DT_') && ...
            any(idx) && any(strcmp(MessageLink(idx+1,2),extractBetween(childNamesList(j),'DT_','_')))
            Autosar_input_msg(j,1) = childNamesList(j); % DBC index
        end
    end

    for j = length(Autosar_input_msg(:,1)):-1:1
        if cellfun(@isempty,Autosar_input_msg(j,1))
            Autosar_input_msg(j,:) = [];
        end
    end
    Autosar_input_msg = sort(Autosar_input_msg);
end

%% Working for seperate channel
for i = 1:NUN_CHANNEL
    
    % read DBC or LIN message map
    cd(arch_Path);
    Channel = char(channel_list(q(i)));
    busID = char(busList(q(i)));
    % num_routing = 0;
 
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
    %% Detect frame routing message on each can
    % 
%     if exist('Frame_routing_array','var') && ~isempty(Frame_routing_array)
%         Detect_Frame_routing_array_can = strcmp(Frame_routing_array(:,1),string(Channel));
%         Detect_Frame_routing_can = find(Detect_Frame_routing_array_can==1);
%         Numb_Restore_array_can = length(Detect_Frame_routing_can);
%             
%         if ~isempty(Detect_Frame_routing_can)            
%             Restore_array_can = cell(Numb_Restore_array_can,2);           
%             for g = 1:Numb_Restore_array_can            
%                 Restore_array_can(g,1) = Frame_routing_array((Detect_Frame_routing_can(g)),1);
%                 Restore_array_can(g,2) = Frame_routing_array((Detect_Frame_routing_can(g)),2);            
%             end    
%         end   
%     end
    %% Delete frame routing outport for no frame routing on CAN
    % 
%     if ~exist('Frame_routing_array','var') || isempty(Frame_routing_array) || ~exist('Detect_Frame_routing_can','var') || isempty(Detect_Frame_routing_can)      
%             delete_block([new_model '/' Channel '/' ['HAL_' Channel 'outputs_raw']]);    
%     end
    %% Detect APP siganl for each CAN   
    Numb_restore = 0;

    if find(ismissing(string(MessageLink)))
        msg = 'Error: Input Signal not match between Messagelink and DBC, checkout signal name is correct';
        error(msg);
    end

    MessageLink(:,2) = erase(MessageLink(:,2),'_');
    Detect_APP_signal_array_can = strcmp(MessageLink(:,2),Channel);
    Detect_APP_signal_can = find(Detect_APP_signal_array_can == 1);
    Numb_array = length(Detect_APP_signal_can);
    
    % Creat APP siganl table for each CAN
    if ~isempty(Detect_APP_signal_can)
        APP_CANSignal = cell(Numb_array,3);
        for p = 1:Numb_array    
               Numb_restore = Numb_restore + 1;
               APP_CANSignal(Numb_restore,1) = cellstr(Channel);
               APP_CANSignal(Numb_restore,2) = MessageLink((Detect_APP_signal_can(p,1)),1);
               APP_CANSignal(Numb_restore,3) = MessageLink((Detect_APP_signal_can(p,1)),3);
        end
    end

    %% generate RxMsgTable and define CAN filter
    RxMsgTable = cell(length(DBC.Messages),8);
    filter = '[';
    MsgCnt = 0;
    SignalCnt = 0;

    for j = 1:length(DBC.Messages)
        if ~contains(DBC.MessageInfo(j).Name,'CCP')...
                && ~contains(DBC.MessageInfo(j).Name,'XCP')...
                && ~contains(DBC.MessageInfo(j).Name,'Diag')...
                && (any(strcmp(APP_CANSignal(:,3),DBC.MessageInfo(j).Name)))...
                && (~startsWith(DBC.MessageInfo(j).Name,'NMm_')|| ~startsWith(DBC.MessageInfo(j).Name,'XNMm_'))...
                && ~contains(DBC.MessageInfo(j).TxNodes,TargetNode)... 
                && ~isempty(DBC.MessageInfo(j).Signals)    
              % && ~contains(DBC.MessageInfo(j).Name,'NMm')...

            RxMsgTable(j,1) = num2cell(j); % DBC index
            RxMsgTable(j,2) = num2cell(DBC.MessageInfo(j).ID); % Message ID in dec
            RxMsgTable(j,3) = num2cell(DBC.MessageInfo(j).Length); % Data length
            RxMsgTable(j,4) = cellstr(DBC.MessageInfo(j).Name); % Message name
            RxMsgTable(j,5) = cellstr(erase(DBC.MessageInfo(j).Name,'_')); % Message name for DD
            RxMsgTable(j,6) = cellstr(DBC.MessageInfo(j).TxNodes); % Message Tx node
            if IsLINMessage
                RxMsgTable(j,2) = num2cell(DBC.MessageInfo(j).PID); % LIN message use PID
                RxMsgTable(j,7) = cellstr(DBC.MessageInfo(j).MsgCycleTime); % LIN message cycle time
                RxMsgTable(j,8) = cellstr(DBC.MessageInfo(j).Delay); % LIN message delay time
                filter = [filter ' 0x' num2str(dec2hex(DBC.MessageInfo(j).PID))];
            else
                RxMsgTable(j,7) = num2cell(DBC.MessageInfo(j).AttributeInfo(strcmp(DBC.MessageInfo(j).Attributes(:,1),'GenMsgCycleTime')).Value);
                RxMsgTable(j,8) = cellstr('0');
                filter = [filter ' 0x' num2str(dec2hex(DBC.MessageInfo(j).ID))];
            end
            MsgCnt = MsgCnt + 1;
            
            SignalCnt = SignalCnt + length(DBC.MessageInfo(j).Signals);
        end   
    end
    filter = [filter ']'];

    for j = length(RxMsgTable(:,1)):-1:1
        if cellfun(@isempty,RxMsgTable(j,1))
            RxMsgTable(j,:) = [];
        end
    end
    RxMsgTable = [{'DBCidx','ID/PID(dec)','DLC','MsgName','MsgName_DD','TxNode','MsgCycleTime','LIN Delay time'};RxMsgTable]; 
    
    DD_cell = cell(MsgCnt + Numb_array + 20,16);
    DD_cell2 = cell(2*MsgCnt + Numb_array, 8);

    %% rework FVT_API.h
    cd([project_path '\documents\FVT_API']);
    fileID = fopen('FVT_API.h');
    FVT_API = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
    tmpCell = cell(length(FVT_API{1,1}),1);
    for j = 1:length(FVT_API{1,1})
        tmpCell{j,1} = FVT_API{1,1}{j,1};
    end
    FVT_API = tmpCell;
    fclose(fileID);

    idx = contains(FVT_API(:,1),'NUM_CAN_CHANNEL');
    FVT_API{idx} = ['#define NUM_CAN_CHANNEL ' num2str(NUM_CAN_CHANNEL)];

    idx = contains(FVT_API(:,1),'NUM_LIN_CHANNEL');
    FVT_API{idx} = ['#define NUM_LIN_CHANNEL ' num2str(NUM_LIN_CHANNEL)];

    if IsLINMessage
        idx = contains(FVT_API(:,1),['NUM_LIN_CH' busID '_RX_MSG']);
        FVT_API{idx} = ['#define NUM_LIN_CH' busID '_RX_MSG ' num2str(MsgCnt)];
    else
        idx = contains(FVT_API(:,1),['NUM_CAN_CH' busID '_RX_MSG']);
        FVT_API{idx} = ['#define NUM_CAN_CH' busID '_RX_MSG ' num2str(MsgCnt)];
    end

    delete FVT_API.h
    fileID = fopen('NewAPI.h','w');
    for j = 1:length(FVT_API(:,1))
        fprintf(fileID,'%s\n',char(FVT_API(j,1)));
    end
    fclose(fileID);
    
    movefile('NewAPI.h','FVT_API.h');
    cd (arch_Path);
  
    %% Add SetFilter
    TargetModel = [new_model '/SetFilter'];

    % C caller settings
    BlockName = Channel;
    srcT = 'simulink/User-Defined Functions/C Caller';
    dstT = [TargetModel '/' BlockName];
    block_x = original_x;
    block_y = original_y + i*250;
    block_w = block_x + 300;
    block_h = block_y + 200;
    h = add_block(srcT,dstT);  
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    if IsLINMessage
        set_param(h,'FunctionName','LINSetFilter');
    else
        set_param(h,'FunctionName','CANSetFilter');
    end
    Obj = get_param(h,'FunctionPortSpecification');
    Obj.InputArguments(3).Size = num2str(MsgCnt);
    Obj.InputArguments(3).Scope = 'Input';
    CCallerport = get_param(h,'PortHandles');
    
    % BUS ID settings
    BlockName = 'UnitConverter';
    srcT = 'simulink/Signal Attributes/Data Type Conversion';
    dstT = [TargetModel '/' BlockName];
    targetpos = get_param(CCallerport.Inport(1),'Position');
    block_x = targetpos(1) - 150;
    block_y = targetpos(2) - 15;
    block_w = block_x + 70;
    block_h = block_y + 30;
    h = add_block(srcT,dstT,'MakeNameUnique','on');     
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'OutDataTypeStr', 'uint8','ShowName', 'off');
    sourceport = get_param(h,'PortHandles');
    add_line(TargetModel,sourceport.Outport(1),CCallerport.Inport(1));
    targetport = sourceport.Inport(1);
    targetpos = get_param(targetport,'Position');

    BlockName = 'Constant';
    srcT = 'simulink/Sources/Constant';
    dstT = [TargetModel '/' BlockName];
    block_x = targetpos(1) - 150;
    block_y = targetpos(2) - 15;
    block_w = block_x + 70;
    block_h = block_y + 30;
    h = add_block(srcT,dstT,'MakeNameUnique','on');     
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'value',busID,'ShowName', 'off');
    sourceport = get_param(h,'PortHandles');
    add_line(TargetModel,sourceport.Outport(1),targetport);
    
    % Num_Msg settings
    BlockName = 'UnitConverter';
    srcT = 'simulink/Signal Attributes/Data Type Conversion';
    dstT = [TargetModel '/' BlockName];
    targetpos = get_param(CCallerport.Inport(2),'Position');
    block_x = targetpos(1) - 150;
    block_y = targetpos(2) - 15;
    block_w = block_x + 70;
    block_h = block_y + 30;
    h = add_block(srcT,dstT,'MakeNameUnique','on');     
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'OutDataTypeStr', 'uint8','ShowName', 'off');
    sourceport = get_param(h,'PortHandles');
    add_line(TargetModel,sourceport.Outport(1),CCallerport.Inport(2));
    targetport = sourceport.Inport(1);
    targetpos = get_param(targetport,'Position');

    BlockName = 'Constant';
    srcT = 'simulink/Sources/Constant';
    dstT = [TargetModel '/' BlockName];
    block_x = targetpos(1) - 150;
    block_y = targetpos(2) - 15;
    block_w = block_x + 70;
    block_h = block_y + 30;
    h = add_block(srcT,dstT,'MakeNameUnique','on');     
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'value',num2str(MsgCnt),'ShowName', 'off');
    sourceport = get_param(h,'PortHandles');
    add_line(TargetModel,sourceport.Outport(1),targetport);

    % Filter settings
    BlockName = 'UnitConverter';
    srcT = 'simulink/Signal Attributes/Data Type Conversion';
    dstT = [TargetModel '/' BlockName];
    targetpos = get_param(CCallerport.Inport(3),'Position');
    block_x = targetpos(1) - 150;
    block_y = targetpos(2) - 15;
    block_w = block_x + 70;
    block_h = block_y + 30;
    h = add_block(srcT,dstT,'MakeNameUnique','on');     
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    if IsLINMessage
        set_param(h,'OutDataTypeStr', 'uint8','ShowName', 'off');
    else
        set_param(h,'OutDataTypeStr', 'uint16','ShowName', 'off');
    end
    sourceport = get_param(h,'PortHandles');
    add_line(TargetModel,sourceport.Outport(1),CCallerport.Inport(3));
    targetport = sourceport.Inport(1);
    targetpos = get_param(targetport,'Position');

    BlockName = 'Constant';
    srcT = 'simulink/Sources/Constant';
    dstT = [TargetModel '/' BlockName];
    block_x = targetpos(1) - 150;
    block_y = targetpos(2) - 15;
    block_w = block_x + 70;
    block_h = block_y + 30;
    h = add_block(srcT,dstT,'MakeNameUnique','on');     
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'value',filter,'ShowName', 'off');
    sourceport = get_param(h,'PortHandles');
    add_line(TargetModel,sourceport.Outport(1),targetport);

    %% Autosar inport in Can
    if Autosar_flg
        XX = find(contains(Autosar_input_msg,Channel));
        Autosar_input_msg_CAN_num = length(XX);
        Autosar_input_msg_CAN = cell(0);
        % Inside channel block
        for k = 1:Autosar_input_msg_CAN_num
            Autosar_input_msg_CAN(k) = Autosar_input_msg(XX(k));
            TargetModel = [new_model '/' Channel];
            BlockName = char(Autosar_input_msg_CAN(k)); 
            srcT = 'simulink/Sources/In1';
            dstT = [TargetModel '/' BlockName];
            block_x = original_x -1000;
            block_y = original_y + 50*k;    
            block_w = block_x + 30;
            block_h = block_y + 13;
            h = add_block(srcT,dstT);  
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            targetport = get_param(h,'PortHandles');
            
            sourceport = targetport; 
            targetpos = get_param(sourceport.Outport(1),'Position');
            BlockName = 'Goto';
            block_x = targetpos(1) + 100;
            block_y = targetpos(2)-20;
            block_w = block_x + 250;
            block_h = block_y + 35;
            srcT = 'simulink/Signal Routing/Goto';
            dstT = [TargetModel '/' BlockName];    
            h = add_block(srcT,dstT,'MakeNameUnique','on');     
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h,'GotoTag',char(Autosar_input_msg_CAN(k)),'ShowName','off');
            targetport = get_param(h,'PortHandles');
            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
        end
        
        % Outside channel block       
        targetport = get_param([new_model '/' Channel],'PortHandles');
        for k = 1:length(targetport.Inport)
            targetpos = get_param(targetport.Inport(k),'Position');
            BlockName = char(Autosar_input_msg_CAN(k)); 
            srcT = 'simulink/Sources/In1';
            dstT = [new_model '/' BlockName]; 
            block_x = targetpos(1) -100;
            block_y = targetpos(2) -5;
            block_w = block_x + 30;
            block_h = block_y + 13;
            h = add_block(srcT,dstT);  
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            sourceport = get_param(h,'PortHandles');
            add_line(new_model,sourceport.Outport(1),targetport.Inport(k));
        end
        sourceport = targetport;
        targetpos = get_param(sourceport.Outport(1),'Position');
        BlockName = ['BHAL_' Channel '_outputs']; 
        srcT = 'simulink/Sinks/Out1';
        dstT = [new_model '/' BlockName]; 
        block_x = targetpos(1) +100;
        block_y = targetpos(2) -5;
        block_w = block_x + 30;
        block_h = block_y + 13;
        h = add_block(srcT,dstT);  
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'UseBusObject','on','BusObject',BlockName);
        targetport = get_param(h,'PortHandles');
        add_line(new_model,sourceport.Outport(1),targetport.Inport(1));
    end
    %% Generate channel model
    
    for j = 2: MsgCnt+1
        TargetModel = [new_model '/' Channel];
        % get last block position
        if j == 2
             lastblk_pos_y = 0;
        else
            dstT = [TargetModel '/' MsgName];
            lastblk_pos = get_param(dstT,'position');
            lastblk_pos_y = lastblk_pos(4);
        end
        % read Rx message infos
        MsgName = char(RxMsgTable(j,strcmp(RxMsgTable(1,:),'MsgName')));
        MsgName_DD = char(RxMsgTable(j,strcmp(RxMsgTable(1,:),'MsgName_DD')));
        TxNode = char(RxMsgTable(j,strcmp(RxMsgTable(1,:),'TxNode')));
        ID = cell2mat(RxMsgTable(j,strcmp(RxMsgTable(1,:),'ID/PID(dec)')));
        MsgID_hex = ['0x' char(dec2hex(ID))];
        DLC = string(RxMsgTable(j,strcmp(RxMsgTable(1,:),'DLC')));
 
        %% Detcet message match APP signals
        if ~isempty(Detect_APP_signal_can)
        Msg_check = strcmp((string(APP_CANSignal(:,3))),string(MsgName));
        Detect_AppMsg = find(Msg_check == 1);
        Numb_Msg_Matchsignal = length(Detect_AppMsg);

            if ~isempty(Detect_AppMsg)
            Signal_match_array = zeros((Numb_Msg_Matchsignal),1);
    
            % Detcet each match signal in DBC table row positon       
               for kkk = 1:length(Detect_AppMsg)            
                Match_Signal = string(APP_CANSignal((Detect_AppMsg(kkk)),2));   
                Signal_match = strcmp(DBC.MessageInfo(cell2mat(RxMsgTable(j,strcmp(RxMsgTable(1,:),'DBCidx')))).Signals,(Match_Signal)');
                Signal_match_array_pos = find(Signal_match == 1);

                if isempty(Signal_match_array_pos)
                msg = ['Error: Input Signal: ' char(Match_Signal) ' not match between Messagelink and DBC, checkout signal name is correct'];
                error(msg);
                end

                   if ~isempty(Signal_match_array_pos)
                      Signal_match_array(kkk,1) = Signal_match_array_pos;  
                   end  
               end    
    
                % Creat SignalName_raw for APP singal
                Signal_match_array = sort(Signal_match_array);
                SignalName_app = cell(length(Signal_match_array),1);  

                for bbb = 1:length(Signal_match_array)
                    Index_signal = find(cellfun(@isempty,SignalName_app(1:end,1)));
                    SignalName_app(Index_signal(1),1) = DBC.MessageInfo(cell2mat(RxMsgTable(j,strcmp(RxMsgTable(1,:),'DBCidx')))).Signals(Signal_match_array(bbb),1);
                end
            end        
        end

        %% Detcet message match frame rougting       
        % 
%         if exist('Detect_Frame_routing_can','var') && ~isempty(Detect_Frame_routing_can)
%             frame_routing = strcmp(string(Restore_array_can(:,2)),string(MsgName));
%             Detect_frame_routing = find(frame_routing == 1);
%         end
     %%
        if IsLINMessage
            MsgCycleTime = string(RxMsgTable(j,strcmp(RxMsgTable(1,:),'MsgCycleTime')));
            FirstDelay = string(RxMsgTable(j,strcmp(RxMsgTable(1,:),'LIN Delay time')));
            TimeoutSet = {'3'};
        elseif contains(MsgName,'NMm')
            TimeoutSet = {num2str(1), num2str(700)};   
        else
            MsgCycleTime = string(RxMsgTable(j,strcmp(RxMsgTable(1,:),'MsgCycleTime')));
            TimeoutSet = {num2str(2.5), num2str(MsgCycleTime)};
        end

        % Generate message model
                   
        BlockName = MsgName;
        block_x = original_x + 50;
        block_y = original_y + 80 + lastblk_pos_y;
        block_w = block_x + 250;
        
        if exist('Detect_AppMsg','var') && ~isempty(Detect_AppMsg) && ~isempty(Detect_APP_signal_can)

            if exist('Detect_frame_routing','var') && ~isempty(Detect_frame_routing)
            block_h = block_y + (length(SignalName_app)+2)*70;
            else
            block_h = block_y + length(SignalName_app)*70;    
            end
        else
        block_h = block_y + 50;    
        end

        srcT = 'built-in/SubSystem';
        dstT = [TargetModel '/' BlockName];    
        h = add_block(srcT,dstT);     
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'ContentPreviewEnabled','off','BackgroundColor','Gray');

        % Add LIN scheduler
        if IsLINMessage
            TargetModel = [new_model '/' Channel '/' MsgName];
            BlockName = 'Trigger';
            srcT = 'simulink/Ports & Subsystems/Trigger';
            dstT = [TargetModel '/' BlockName];
            h = add_block(srcT,dstT);
            set_param(h,'TriggerType','function-call');

            TargetModel = [new_model '/' Channel];
            targetport = get_param([TargetModel '/' MsgName],'PortHandles');
            targetpos = get_param(targetport.Trigger(1),'Position');
            BlockName = 'LIN_Scheduler';
            block_x = targetpos(1) - 300;
            block_y = targetpos(2) - 70;
            block_w = block_x + 150;
            block_h = block_y + 50;
            srcT = 'FVT_lib/hal/LIN_Scheduler';
            dstT = [TargetModel '/' BlockName];    
            h = add_block(srcT,dstT,'MakeNameUnique','on');     
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h, 'MaskValues', {MsgCycleTime,FirstDelay});
            sourceport = get_param(h,'PortHandles');
            add_line(TargetModel,sourceport.Outport(1),targetport.Trigger(1),'autorouting','on');
        end

        % *************** Set up message receiver*************************%
        if ~Autosar_flg
            TargetModel = [new_model '/' Channel '/' MsgName];
            ReceiveSet = {busID,MsgID_hex,DLC};
            BlockName = MsgName;
            block_x = original_x;
            block_y = original_y;
            block_w = block_x + 250;
            block_h = block_y + 50*str2double(DLC);
            if IsLINMessage
                srcT = 'FVT_lib/hal/LINReceiver';
            else
                srcT = 'FVT_lib/hal/CANReceiver';
            end
            dstT = [TargetModel '/' BlockName];    
            h = add_block(srcT,dstT);     
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h, 'LinkStatus', 'inactive','MaskValues',ReceiveSet);
    
            % setup blocks inside Receiver
            TargetModel = [new_model '/' Channel '/' MsgName '/' MsgName];
            sourceport = get_param([TargetModel '/Demux'],'PortHandles');
    
            if IsLINMessage
                for k = 1:8
                    if k <= str2double(DLC)
                        targetpos = get_param(sourceport.Outport(k),'Position');
                        BlockName = ['Byte_' num2str(k-1)];
                        block_x = targetpos(1) + 150;
                        block_y = targetpos(2)-5;
                        block_w = block_x + 30;
                        block_h = block_y + 13;
                        srcT = 'simulink/Sinks/Out1';
                        dstT = [TargetModel '/' BlockName];    
                        h = add_block(srcT,dstT);     
                        set_param(h,'position',[block_x,block_y,block_w,block_h]);
                        targetport = get_param(h,'PortHandles');
                        add_line(TargetModel,sourceport.Outport(k),targetport.Inport(1));
                    else
                        targetpos = get_param(sourceport.Outport(k),'Position');
                        BlockName = 'Terminator';
                        block_x = targetpos(1) + 50;
                        block_y = targetpos(2) - 20;
                        block_w = block_x + 25;
                        block_h = block_y + 35;
                        srcT = 'simulink/Commonly Used Blocks/Terminator';
                        dstT = [TargetModel '/' BlockName];
                        h = add_block(srcT,dstT,'MakeNameUnique','on');
                        set_param(h,'position',[block_x,block_y,block_w,block_h]);
                        targetport = get_param(h,'PortHandles');
                        add_line(TargetModel,sourceport.Outport(k),targetport.Inport(1));
                    end
                end
            else
                targetpos = get_param(sourceport.Outport(1),'Position');
                BlockName = 'Mux';
                block_x = targetpos(1) + 50;
                block_y = targetpos(2)-15;
                block_w = block_x + 20;
                block_h = block_y + 30*ceil(str2double(DLC)/4);
                srcT = 'simulink/Commonly Used Blocks/Mux';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT);
                set_param(h,'Inputs',num2str(ceil((str2double(DLC)/4))));
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                targetport = get_param(h,'PortHandles');
    
                for k = 1:16
                    if k <= ceil(str2double(DLC)/4)
                        add_line(TargetModel,sourceport.Outport(k),targetport.Inport(k));
                    else
                        targetpos = get_param(sourceport.Outport(k),'Position');
                        BlockName = 'Terminator';
                        block_x = targetpos(1) + 50;
                        block_y = targetpos(2) - 20;
                        block_w = block_x + 25;
                        block_h = block_y + 35;
                        srcT = 'simulink/Commonly Used Blocks/Terminator';
                        dstT = [TargetModel '/' BlockName];
                        h = add_block(srcT,dstT,'MakeNameUnique','on');
                        set_param(h,'position',[block_x,block_y,block_w,block_h]);
                        targetport = get_param(h,'PortHandles');
                        add_line(TargetModel,sourceport.Outport(k),targetport.Inport(1));
                    end
                end
    
                sourceport = get_param([TargetModel '/Mux'],'PortHandles');
                targetpos = get_param(sourceport.Outport(1),'Position');
                BlockName = 'Demux';
                block_x = targetpos(1) + 100;
                block_y = targetpos(2)-15;
                block_w = block_x + 20;
                block_h = block_y + 30*str2double(DLC);
                srcT = 'simulink/Commonly Used Blocks/Demux';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'Outputs',num2str(str2double(DLC)));
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                targetport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on');
                sourceport = get_param(h,'PortHandles');
    
                for k = 1:str2double(DLC)
                    targetpos = get_param(sourceport.Outport(k),'Position');
                    BlockName = ['Byte_' num2str(k-1)];
                    block_x = targetpos(1) + 150;
                    block_y = targetpos(2)-5;
                    block_w = block_x + 30;
                    block_h = block_y + 13;
                    srcT = 'simulink/Sinks/Out1';
                    dstT = [TargetModel '/' BlockName];    
                    h = add_block(srcT,dstT);     
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    targetport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(k),targetport.Inport(1));
                end
            end
        elseif contains(MsgName,'NMm')
            TargetModel = [new_model '/' Channel '/' MsgName];
            BlockName = MsgName;
            block_x = original_x;
            block_y = original_y;
            block_w = block_x + 30;
            block_h = block_y + 30;
            srcT = 'simulink/Commonly Used Blocks/Ground';
            dstT = [TargetModel '/' BlockName];
            h = add_block(srcT,dstT,'MakeNameUnique','on');     
            set_param(h,'position',[block_x,block_y,block_w,block_h])
            set_param(h,'ShowName', 'off');
        end

        %************** Setup message invalid and byte goto***************%
        % write DD file
        if IsLINMessage
            MsgTimeoutflg = ['VHAL_LINMsgInvalid' MsgName_DD '_flg'];
        % elseif strcmp(Channel,'CAN6')
        %   MsgTimeoutflg = ['VHAL_CAN6CANMsgInvalid' MsgName_DD '_flg'];
        else
            MsgTimeoutflg = ['VHAL_CANMsgInvalid' MsgName_DD '_flg'];
        end
        MsgTimeoutflgUnit = 'flg';
        MsgTimeoutflgDataType = 'boolean';             
        DD_Index_Msg = find(cellfun(@isempty,DD_cell(1:end,1)));
        DD_cell(DD_Index_Msg(1),1) = {MsgTimeoutflg}; % HAL signal name
        DD_cell(DD_Index_Msg(1),2) = {'output'}; % Direction
        DD_cell(DD_Index_Msg(1),3) = {MsgTimeoutflgDataType}; % data type
        DD_cell(DD_Index_Msg(1),4) = {'0'}; % Minimum
        DD_cell(DD_Index_Msg(1),5) = {'1'}; % Maximun
        DD_cell(DD_Index_Msg(1),6) = {MsgTimeoutflgUnit}; % Unit
        DD_cell(DD_Index_Msg(1),7) = {'N/A'}; % Enum table
        DD_cell(DD_Index_Msg(1),8) = {'N/A'}; % Default before and during POWER-UP
        DD_cell(DD_Index_Msg(1),9) = {'N/A'}; % DDefault before and during POWER-DOWN
        DD_cell(DD_Index_Msg(1),10) = {'N/A'}; % Description
        DD_cell(DD_Index_Msg(1),11) = {TxNode}; % CAN transmitter
        DD_cell(DD_Index_Msg(1),12) = {MsgName}; % Message
        if IsLINMessage
            DD_cell(DD_Index_Msg(1),13) = {'LIN'}; % Data source
        else
            DD_cell(DD_Index_Msg(1),13) = {'CAN'};
        end
        

        %%%%%%%%%%%%%%%%% Setup Checksum & Rollingcount %%%%%%%%%%%%%%%%%%%

        % write DD file
        if contains(MsgName, AllMessagesRequiringRcCsCheck)
              
            MsgCSErrflg = ['VHAL_' MsgName_DD 'CSErr_flg'];
            MsgCSErrflgUnit = 'flg';
            MsgCSErrflgDataType = 'boolean';
            DD_Index_Msg = find(cellfun(@isempty, DD_cell(1:end, 1)));
            DD_cell(DD_Index_Msg(1), 1) = {MsgCSErrflg}; % HAL signal name
            DD_cell(DD_Index_Msg(1), 2) = {'output'}; % Direction
            DD_cell(DD_Index_Msg(1), 3) = {MsgCSErrflgDataType}; % data type
            DD_cell(DD_Index_Msg(1), 4) = {'0'}; % Minimum
            DD_cell(DD_Index_Msg(1), 5) = {'1'}; % Maximun
            DD_cell(DD_Index_Msg(1), 6) = {MsgCSErrflgUnit}; % Unit
            DD_cell(DD_Index_Msg(1), 7) = {'N/A'}; % Enum table
            DD_cell(DD_Index_Msg(1), 8) = {'N/A'}; % Default before and during POWER-UP
            DD_cell(DD_Index_Msg(1), 9) = {'N/A'}; % DDefault before and during POWER-DOWN
            DD_cell(DD_Index_Msg(1), 10) = {'N/A'}; % Description
            DD_cell(DD_Index_Msg(1), 11) = {TxNode}; % CAN transmitter
            DD_cell(DD_Index_Msg(1), 12) = {MsgName}; % Message
            DD_cell(DD_Index_Msg(1), 13) = {'CAN'};

            if true % ~contains(MsgName, {'FCM4'})
                MsgRCErrflg = ['VHAL_' MsgName_DD 'RCErr_flg'];
                MsgRCErrflgUnit = 'flg';
                MsgRCErrflgDataType = 'boolean';
                DD_Index_Msg = find(cellfun(@isempty, DD_cell(1:end, 1)));
                DD_cell(DD_Index_Msg(1), 1) = {MsgRCErrflg}; % HAL signal name
                DD_cell(DD_Index_Msg(1), 2) = {'output'}; % Direction
                DD_cell(DD_Index_Msg(1), 3) = {MsgRCErrflgDataType}; % data type
                DD_cell(DD_Index_Msg(1), 4) = {'0'}; % Minimum
                DD_cell(DD_Index_Msg(1), 5) = {'1'}; % Maximun
                DD_cell(DD_Index_Msg(1), 6) = {MsgRCErrflgUnit}; % Unit
                DD_cell(DD_Index_Msg(1), 7) = {'N/A'}; % Enum table
                DD_cell(DD_Index_Msg(1), 8) = {'N/A'}; % Default before and during POWER-UP
                DD_cell(DD_Index_Msg(1), 9) = {'N/A'}; % DDefault before and during POWER-DOWN
                DD_cell(DD_Index_Msg(1), 10) = {'N/A'}; % Description
                DD_cell(DD_Index_Msg(1), 11) = {TxNode}; % CAN transmitter
                DD_cell(DD_Index_Msg(1), 12) = {MsgName}; % Message
                DD_cell(DD_Index_Msg(1), 13) = {'CAN'};
            end
        end

        %% Add detect change for nm message
        if ~contains(MsgName,'NMm') && ~Autosar_flg
            TargetModel = [new_model '/' Channel '/' MsgName];
            sourceport = get_param([new_model '/' Channel '/' MsgName '/' MsgName],'PortHandles');
            targetpos = get_param(sourceport.Outport(1),'Position');
            BlockName = 'MsgTimeoutJudge';
            block_x = targetpos(1) + 120;
            block_y = targetpos(2) - 15;
            block_w = block_x + 200;
            block_h = block_y + 30;
                if IsLINMessage
                    srcT = 'FVT_lib/hal/MsgTimeoutJudge_LIN';
                else
                    srcT = 'FVT_lib/hal/MsgTimeoutJudge_CAN';
                end
            dstT = [TargetModel '/' BlockName];
            h = add_block(srcT,dstT);     
            set_param(h,'position',[block_x,block_y,block_w,block_h])
            set_param(h,'MaskValues', TimeoutSet,'ShowName','on');
            targetport = get_param(h,'PortHandles');
            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
        
        elseif contains(MsgName,'NMm')        
            TargetModel = [new_model '/' Channel '/' MsgName];
            sourceport = get_param([new_model '/' Channel '/' MsgName '/' MsgName],'PortHandles');
            targetpos = get_param(sourceport.Outport(1),'Position');
            BlockName = 'Detect Change';
            block_x = targetpos(1) + 120;
            block_y = targetpos(2) - 15;
            block_w = block_x + 100;
            block_h = block_y + 30;
            srcT = 'simulink/Logic and Bit Operations/Detect Change';
            dstT = [TargetModel '/' BlockName];
            h = add_block(srcT,dstT);     
            set_param(h,'position',[block_x,block_y,block_w,block_h])
            targetport = get_param(h,'PortHandles');
            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));

        end
        
        if ~Autosar_flg      
            for k = 1:str2double(DLC)
                targetpos = get_param(sourceport.Outport(k+1),'Position');
                BlockName = ['Byte_' num2str(k-1)];
                block_x = targetpos(1) + 100;
                block_y = targetpos(2)-20;
                block_w = block_x + 250;
                block_h = block_y + 35;
                srcT = 'simulink/Signal Routing/Goto';
                dstT = [TargetModel '/' BlockName];    
                h = add_block(srcT,dstT);     
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'GotoTag',BlockName,'ShowName','off');
                targetport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(k+1),targetport.Inport(1));
            end
        end        
        
        if ~contains(MsgName,'NMm') && ~Autosar_flg 
            sourceport = get_param([new_model '/' Channel '/' MsgName '/' MsgName],'PortHandles');  
            targetpos = get_param(sourceport.Outport(1),'Position');
            BlockName = MsgTimeoutflg;
            block_x = targetpos(1) + 300;
            block_y = targetpos(2)-5;
            block_w = block_x + 30;
            block_h = block_y + 13;
            srcT = 'simulink/Sinks/Out1';
            dstT = [TargetModel '/' BlockName];
            h = add_block(srcT,dstT);     
            set_param(h,'position',[block_x,block_y,block_w,block_h],'Port', '1');
            targetport = get_param(h,'PortHandles');         
            h = add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
            set_param(h,'name', MsgTimeoutflg);
        elseif contains(MsgName,'NMm')
            sourceport = get_param([new_model '/' Channel '/' MsgName '/Detect Change'],'PortHandles');
            targetpos = get_param(sourceport.Outport(1),'Position');
            BlockName = MsgTimeoutflg;
            block_x = targetpos(1) + 300;
            block_y = targetpos(2)-5;
            block_w = block_x + 30;
            block_h = block_y + 13;
            srcT = 'simulink/Sinks/Out1';
            dstT = [TargetModel '/' BlockName];
            h = add_block(srcT,dstT);     
            set_param(h,'position',[block_x,block_y,block_w,block_h],'Port', '1');         
        end               

        %************************** Unpack signals ***********************%
        if exist('Detect_AppMsg','var') && ~isempty(Detect_AppMsg) && ~isempty(Detect_APP_signal_can)

           % Add input from Autosar 
           if Autosar_flg 
               XXX = contains(Autosar_input_msg_CAN,MsgName);
               Autosar_msg = Autosar_input_msg_CAN(XXX);
               TargetModel = [new_model '/' Channel '/' MsgName];
               BlockName = char(Autosar_msg); 
               srcT = 'simulink/Sources/In1';
               dstT = [TargetModel '/' BlockName]; 
               block_x = original_x -10;
               block_y = original_y + 200;
               block_w = block_x + 30;
               block_h = block_y + 13;
               h = add_block(srcT,dstT);  
               set_param(h,'position',[block_x,block_y,block_w,block_h]);
    
               targetport = get_param(h,'Porthandles');
               targetpos = get_param(targetport.Outport(1),'Position');
               sourceport = targetport;
               BlockName = 'Goto';
               block_x = targetpos(1)+200 ;
               block_y = targetpos(2)-20;
               block_w = block_x + 250;
               block_h = block_y + 35;
               srcT = 'simulink/Signal Routing/Goto';
               dstT = [TargetModel '/' BlockName];    
               h = add_block(srcT,dstT,'MakeNameUnique','on');     
               set_param(h,'position',[block_x,block_y,block_w,block_h]);
               set_param(h,'GotoTag',char(Autosar_msg),'ShowName','off');
               targetport = get_param(h,'PortHandles');
               add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
    
               TargetModel = [new_model '/' Channel '/' MsgName];
               targetport = get_param(TargetModel,'Porthandles');
               targetpos = get_param(targetport.Inport(1),'Position');
               sourceport = targetport;
               BlockName = 'From';
               block_x = targetpos(1)- 300;
               block_y = targetpos(2)-15;
               block_w = block_x + 250;
               block_h = block_y + 35;
               srcT = 'simulink/Signal Routing/From';
               dstT = [new_model '/' Channel '/' BlockName];    
               h = add_block(srcT,dstT,'MakeNameUnique','on');     
               set_param(h,'position',[block_x,block_y,block_w,block_h]);
               set_param(h,'GotoTag',char(Autosar_msg),'ShowName','off');
               targetport = get_param(h,'PortHandles');
               add_line([new_model '/' Channel],targetport.Outport(1),sourceport.Inport(1));
               TargetModel = [new_model '/' Channel '/' MsgName];
           end
           
            if contains(MsgName,'NMm') || ~Autosar_flg
                sourceport = get_param([TargetModel '/' MsgTimeoutflg],'PortHandles');
                targetpos = get_param(sourceport.Inport(1),'Position');  
            elseif Autosar_flg
                targetpos = get_param([TargetModel '/Goto'],'Position');
            end
            

            %%%%%%%%%%%%%%%%%% DDM (ESC & Others) %%%%%%%%%%%%%%%%%%

            if contains(MsgName, AllMessagesRequiringRcCsCheck) 
              
                
                % Array storing signals position
                PackArray = strings(str2double(DLC),8); 

                % DBC info of the message
                NumberOfSignals = length(DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).Signals);
                DataID = char(cellstr(DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).AttributeInfo(strcmp(DBC.MessageInfo(j).Attributes(:, 1), 'DataID')).Value));
                msg_time_ms = string(DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).AttributeInfo(strcmp(DBC.MessageInfo(j).Attributes(:, 1), 'GenMsgCycleTime')).Value);
                

                BlockName = 'From';
                block_x = targetpos(1) - 500 ;
                PortsSpace = 50;
                block_y = targetpos(2) + 200 + NumberOfSignals/2*PortsSpace;
                block_w = block_x + 250;
                block_h = block_y + 35;
                srcT = 'simulink/Signal Routing/From';
                dstT = [TargetModel '/' BlockName];    
                from = add_block(srcT,dstT,'MakeNameUnique','on');     
                set_param(from,'position',[block_x,block_y,block_w,block_h]);
                set_param(from,'GotoTag',char(Autosar_msg),'ShowName','off');
                fromport = get_param(from,'PortHandles');
                fromportpos = get_param(fromport.Outport(1),'Position');

                % Bus Selector of all signals on CAN message
                BlockName ='bus_selector';
                srcT = 'simulink/Signal Routing/Bus Selector';
                dstT = [TargetModel '/' BlockName];
                block_x = fromportpos(1) + 150 ;
                block_y = fromportpos(2) - NumberOfSignals/2*PortsSpace;
                block_w = block_x + 10;
                block_h = block_y + NumberOfSignals*PortsSpace;
                signalNames = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).Signals;
                for l = 1:NumberOfSignals
                    signalNames(l) = strcat(Channel,'_',signalNames(l));
                end
                busselector = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(busselector,'position',[block_x,block_y,block_w,block_h]);
                set_param(busselector,'OutputSignals',string(join(signalNames,",")),'ShowName', 'off');
                busselectorport = get_param(busselector,'PortHandles');
                busselectorpos = get_param(busselector, 'PortConnectivity');
                add_line(TargetModel,fromport.Outport(1),busselectorport.Inport(1),'autorouting','smart');
                

                % Process the known datas for repacking the original message 
                fromportpos(2) = fromportpos(2) + NumberOfSignals/2*PortsSpace + 200;
                for m = 1:NumberOfSignals
                    
                    % Goto of all signals on CAN message
                    block_x = busselectorpos(m+1).Position(1) + 150;
                    block_y = busselectorpos(m+1).Position(2) - 20;
                    block_w = block_x + 220;
                    block_h = block_y + 35;
                    BlockName = 'Goto';
                    srcT = 'simulink/Signal Routing/Goto';
                    dstT = [TargetModel '/' BlockName];
                    goto = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(goto,'position',[block_x,block_y,block_w,block_h]);
                    set_param(goto,'Gototag',string(signalNames(m)),'ShowName', 'off');
                    gotoport = get_param(goto,'PortHandles');
                    add_line(TargetModel,busselectorport.Outport(m),gotoport.Inport,'autorouting','smart')
                
                    SignalSize = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(m).SignalSize;
                    Startbit = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(m).StartBit;
                    
                    EndByte = floor(Startbit / 8);
                    LeftShiftCnt = rem(Startbit, 8);

                    if SignalSize == 1
                        NUM_BYTE = 1;
                    else
                        remainlength = SignalSize - (8 - LeftShiftCnt);

                        if remainlength > 0
                            NUM_BYTE = ceil(remainlength / 8) + 1;
                        else
                            NUM_BYTE = 1;
                        end
                    end

                    % From of all signals on CAN message
                    block_x = targetpos(1) - 500;
                    block_y = fromportpos(2) + (NUM_BYTE)*PortsSpace;
                    block_w = block_x + 220;
                    block_h = block_y + 35;
                    BlockName = 'From';
                    srcT = 'simulink/Signal Routing/From';
                    dstT = [TargetModel '/' BlockName];
                    from = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(from,'position',[block_x,block_y,block_w,block_h]);
                    set_param(from,'Gototag',string(signalNames(m)),'ShowName', 'off');
                    fromport = get_param(from,'PortHandles');
                    fromportpos = get_param(fromport.Outport(1),'Position');

                    % Pack
                    if NUM_BYTE == 1
                        
                        BlockName = 'LeftShift';
                        block_x = fromportpos(1) + 50;
                        block_y = fromportpos(2) - 20;
                        block_w = block_x + 100;
                        block_h = block_y + 35;
                        srcT = 'simulink/Logic and Bit Operations/Shift Arithmetic';
                        dstT = [TargetModel '/' BlockName];
                        leftShift = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                        set_param(leftShift, 'position', [block_x, block_y, block_w, block_h]);
                        set_param(leftShift, 'BitShiftDirection', 'Left','ShowName', 'off');
                        set_param(leftShift, 'BitShiftNumber', num2str(LeftShiftCnt));
                        leftShiftport = get_param(leftShift, 'PortHandles');
                        leftShiftportpos = get_param(leftShiftport.Outport(1),'Position');
                        add_line(TargetModel, fromport.Outport(1), leftShiftport.Inport(1));

                        BlockName = 'BitwiseAND';
                        block_x = block_x + 200;
                        block_y = block_y;
                        block_w = block_x + 100;
                        block_h = block_y + 40;
                        srcT = 'simulink/Logic and Bit Operations/Bitwise Operator';
                        dstT = [TargetModel '/' BlockName];
                        bitwiseand = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                        set_param(bitwiseand, 'position', [block_x, block_y, block_w, block_h]);
                        set_param(bitwiseand, 'UseBitMask', 'on','ShowName', 'off');
                        set_param(bitwiseand, 'logicop', 'AND', 'BitMask', '0xFF');
                        bitwiseandport = get_param(bitwiseand, 'PortHandles');
                        add_line(TargetModel, leftShiftport.Outport(1), bitwiseandport.Inport);
                        
                        block_x = leftShiftportpos(1) + 250;
                        block_y = leftShiftportpos(2) - 20;
                        block_w = block_x + 220;
                        block_h = block_y + 35;
                        BlockName = 'Goto';
                        srcT = 'simulink/Signal Routing/Goto';
                        dstT = [TargetModel '/' BlockName];
                        goto = add_block(srcT,dstT,'MakeNameUnique','on');
                        set_param(goto,'position',[block_x,block_y,block_w,block_h]);
                        Bytepos = strcat('Byte_',num2str(EndByte),'_',string(signalNames(m)));
                        Arraypos = min(find(PackArray(EndByte+1,:) == ""));
                        PackArray(EndByte+1,Arraypos) = Bytepos;
                        set_param(goto,'Gototag',Bytepos,'ShowName', 'off');
                        gotoport = get_param(goto,'PortHandles');
                        add_line(TargetModel,bitwiseandport.Outport,gotoport.Inport,'autorouting','smart')

                        n = 1;

                    else
                    
                        for n = 1:NUM_BYTE
                            BlockName = 'RightShift';
                            block_x = fromportpos(1) + 50;
                            block_y = fromportpos(2) - 20 - PortsSpace*(NUM_BYTE - n);
                            block_w = block_x + 100;
                            block_h = block_y + 35;
                            srcT = 'simulink/Logic and Bit Operations/Shift Arithmetic';
                            dstT = [TargetModel '/' BlockName];
                            rightShift = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                            set_param(rightShift, 'position', [block_x, block_y, block_w, block_h]);
                            % set_param(rightShift, 'BitShiftDirection', 'Right','ShowName', 'off');
                            set_param(rightShift, 'BitShiftDirection', 'Bidirectional', 'ShowName', 'off');
                            RightShiftCnt = 8*(NUM_BYTE - n) - LeftShiftCnt;
                            set_param(rightShift, 'BitShiftNumber', num2str(RightShiftCnt));
                            rightShiftport = get_param(rightShift, 'PortHandles');
                            rightShiftportpos = get_param(rightShiftport.Outport(1),'Position');
                            add_line(TargetModel, fromport.Outport(1), rightShiftport.Inport(1),'autorouting','smart');
                        
                            BlockName = 'BitwiseAND';
                            block_x = block_x + 200;
                            block_y = block_y;
                            block_w = block_x + 100;
                            block_h = block_y + 40;
                            srcT = 'simulink/Logic and Bit Operations/Bitwise Operator';
                            dstT = [TargetModel '/' BlockName];
                            bitwiseand = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                            set_param(bitwiseand, 'position', [block_x, block_y, block_w, block_h]);
                            set_param(bitwiseand, 'UseBitMask', 'on','ShowName', 'off');
                            set_param(bitwiseand, 'logicop', 'AND', 'BitMask', '0xFF');
                            bitwiseandport = get_param(bitwiseand, 'PortHandles');
                            add_line(TargetModel, rightShiftport.Outport(1), bitwiseandport.Inport);
                            
                            block_x = rightShiftportpos(1) + 250;
                            block_y = rightShiftportpos(2) - 20;
                            block_w = block_x + 220;
                            block_h = block_y + 35;
                            BlockName = 'Goto';
                            srcT = 'simulink/Signal Routing/Goto';
                            dstT = [TargetModel '/' BlockName];
                            goto = add_block(srcT,dstT,'MakeNameUnique','on');
                            set_param(goto,'position',[block_x,block_y,block_w,block_h]);
                            Bytepos = strcat('Byte_',num2str(EndByte+n-NUM_BYTE),'_',string(signalNames(m)));
                            Arraypos = min(find(PackArray(EndByte+n-NUM_BYTE+1,:) == ""));
                            PackArray(EndByte+n-NUM_BYTE+1,Arraypos) = Bytepos;
                            set_param(goto,'Gototag',Bytepos,'ShowName', 'off');
                            gotoport = get_param(goto,'PortHandles');
                            add_line(TargetModel,bitwiseandport.Outport,gotoport.Inport,'autorouting','smart')
    
                        end

                        
                    end
                    
                
                end
                

                % Repack each byte of the message from the unpacked signals
                block_x0 = fromportpos(1) + 150;
                bitwiseorportpos(2) = fromportpos(2) + 350;
                constantportpos(2) = bitwiseorportpos(2);
                
                
                for ki = 1:str2double(DLC)
                    
                    
                    ByteNumberOfSignals = min(find(PackArray(ki,:) == "")) - 1;
                    if isempty(find(PackArray(ki,:) == ""))
                        ByteNumberOfSignals = 8;
                    end
                    
       
                    
                    if ByteNumberOfSignals > 0
                        
                        BlockName = 'BitwiseOR';
                        block_x = block_x0;
                        block_y = bitwiseorportpos(2) + 50;
                        block_w = block_x + 70;
                        block_h = block_y + PortsSpace * ByteNumberOfSignals;
                        srcT = 'simulink/Logic and Bit Operations/Bitwise Operator';
                        dstT = [TargetModel '/' BlockName];
                        bitwiseor = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                        set_param(bitwiseor, 'position', [block_x, block_y, block_w, block_h]);
                        set_param(bitwiseor, 'UseBitMask', 'off','ShowName', 'off');
                        set_param(bitwiseor, 'logicop', 'OR');
                        set_param(bitwiseor, 'NumInputPorts', num2str(ByteNumberOfSignals));
                        bitwiseorport = get_param(bitwiseor, 'PortHandles');
                        bitwiseorportpos = get_param(bitwiseorport.Inport(end),'Position');

                        for p = 1:ByteNumberOfSignals

                            portpos = get_param(bitwiseorport.Inport(p),'Position');
                            block_x = block_x0 - 200;
                            block_y = portpos(2) - 20;
                            block_w = block_x + 120;
                            block_h = block_y + 35;
                            BlockName = 'Data Type Conversion';
                            srcT = 'simulink/Signal Attributes/Data Type Conversion';
                            dstT = [TargetModel '/' BlockName];
                            convert = add_block(srcT,dstT,'MakeNameUnique','on');
                            set_param(convert,'position',[block_x,block_y,block_w,block_h],'OutDataTypeStr','uint8'); 
                            convertport = get_param(convert,'PortHandles');
                            add_line(TargetModel,convertport.Outport,bitwiseorport.Inport(p),'autorouting','smart')
    
                            portpos = get_param(convertport.Inport,'Position');
                            block_x = block_x0 - 500;
                            block_y = portpos(2) - 20;
                            block_w = block_x + 220;
                            block_h = block_y + 35;
                            BlockName = 'From';
                            srcT = 'simulink/Signal Routing/From';
                            dstT = [TargetModel '/' BlockName];
                            from = add_block(srcT,dstT,'MakeNameUnique','on');
                            set_param(from,'position',[block_x,block_y,block_w,block_h]);
                            set_param(from,'Gototag',string(PackArray(ki,p)),'ShowName', 'off');
                            fromport = get_param(from,'PortHandles');
                            fromportpos = get_param(fromport.Outport(1),'Position');
                            add_line(TargetModel,fromport.Outport,convertport.Inport,'autorouting','smart')
    
                        end
                        
                        portpos = get_param(bitwiseorport.Outport(1),'Position');
                        block_x = portpos(1) + 150;
                        block_y = portpos(2) - 20;
                        block_w = block_x + 220;
                        block_h = block_y + 35;
                        BlockName = 'Goto';
                        srcT = 'simulink/Signal Routing/Goto';
                        dstT = [TargetModel '/' BlockName];
                        goto = add_block(srcT,dstT,'MakeNameUnique','on');
                        set_param(goto,'position',[block_x,block_y,block_w,block_h]);
                        set_param(goto,'Gototag',strcat('Byte_',num2str(ki-1)),'ShowName', 'off');
                        gotoport = get_param(goto,'PortHandles');
                        add_line(TargetModel,bitwiseorport.Outport,gotoport.Inport,'autorouting','smart')
                    
                    else
                                               
                        block_x = block_x0 + 600;
                        block_y = constantportpos(2) + 100;
                        block_w = block_x + 70;
                        block_h = block_y + 40;
                        BlockName = 'constant';
                        srcT = 'simulink/Commonly Used Blocks/Constant';
                        dstT = [TargetModel '/' BlockName];
                        constant = add_block(srcT,dstT,'MakeNameUnique','on');
                        set_param(constant,'position',[block_x,block_y,block_w,block_h]);
                        set_param(constant,'Value','0x0','ShowName', 'off');
                        set_param(constant,'OutDataTypeStr', 'uint8');
                        constantport = get_param(constant,'PortHandles');
                        constantportpos = get_param(constantport.Outport(1),'Position');

                        block_x = constantportpos(1) + 150;
                        block_y = constantportpos(2) - 20;
                        block_w = block_x + 220;
                        block_h = block_y + 35;
                        BlockName = 'Goto';
                        srcT = 'simulink/Signal Routing/Goto';
                        dstT = [TargetModel '/' BlockName];
                        goto = add_block(srcT,dstT,'MakeNameUnique','on');
                        set_param(goto,'position',[block_x,block_y,block_w,block_h]);
                        set_param(goto,'Gototag',strcat('Byte_',num2str(ki-1)),'ShowName', 'off');
                        gotoport = get_param(goto,'PortHandles');
                        add_line(TargetModel,constantport.Outport,gotoport.Inport,'autorouting','smart')
                 
                    end


                end


                % Process CS
                if contains(MsgName, AllMessagesRequiringRcCsCheck) % CRC8 ckecksum
                   
                    BlockName = 'Mux';
                    block_x = block_x0;
                    block_y = bitwiseorportpos(2) + 45 * ceil(str2double(DLC));
                    block_w = block_x + 10;
                    block_h = block_y + 45 * ceil(str2double(DLC) - 1);
                    srcT = 'simulink/Commonly Used Blocks/Mux';
                    dstT = [TargetModel '/' BlockName];
                    mux = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(mux, 'Inputs', num2str(ceil((str2double(DLC))) - 1));
                    set_param(mux, 'position', [block_x, block_y, block_w, block_h]);
                    muxport = get_param(mux, 'PortHandles');
                    
                    % Exclude the Checksum byte
%                     for k = 1:length(Signal_match_array)
%                         Startbit = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).StartBit;
%                         SignalName = char(erase(DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Name, '_'));
%                         if contains(SignalName, {'CRC8', 'Checksum', 'ChckSum', 'CS', 'Chksum'}) && ~contains(SignalName, {'ACC'})
%                             EndByte = floor(Startbit / 8);
%                             csbytepos = 0;
%                         end 
%                     end                  
                    
                    csbytepos = 1;
                    
                    nocsbytelsit = setdiff(1:ceil(str2double(DLC)), csbytepos);
                    kkcnt = 1;

                    for kk = nocsbytelsit
                        portpos = get_param(muxport.Inport(kkcnt), 'Position');
                        BlockName = ['Byte_' num2str(kk - 1)];
                        block_x = portpos(1) - 300;
                        block_y = portpos(2) - 20;
                        block_w = block_x + 250;
                        block_h = block_y + 35;
                        srcT = 'simulink/Signal Routing/From';
                        dstT = [TargetModel '/' BlockName];
                        from = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                        set_param(from, 'position', [block_x, block_y, block_w, block_h]);
                        set_param(from, 'GotoTag', BlockName, 'ShowName', 'off');
                        fromport = get_param(from, 'PortHandles');
                        add_line(TargetModel, fromport.Outport(1), muxport.Inport(kkcnt));
                        kkcnt = kkcnt + 1;
                    end

                    BlockName = ['VHAL_' Channel MsgName_DD 'noCS_raw'];
                    muxportpos = get_param(muxport.Outport(1), 'Position');
                    srcT = 'simulink/Signal Routing/Goto';
                    dstT = [TargetModel '/' BlockName];
                    block_x = muxportpos(1) + 100;
                    block_y = muxportpos(2) - 10;
                    block_w = block_x + 250;
                    block_h = block_y + 20;
                    goto = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(goto, 'Gototag', BlockName, 'ShowName', 'off');
                    set_param(goto, 'position', [block_x, block_y, block_w, block_h]);
                    gotoport = get_param(goto, 'PortHandles');
                    add_line(TargetModel, muxport.Outport(1), gotoport.Inport(1));

                end
                
                                
                % write DD file for KHAL_E2E_flg
                DD_Index2 = find(cellfun(@isempty, DD_cell2(1:end, 1)));
                DD_cell2(DD_Index2(1), 1) = {['KHAL_' Channel MsgName_DD 'E2E_flg']}; % Signal name
                DD_cell2(DD_Index2(1), 2) = {'internal'}; % Direction
                DD_cell2(DD_Index2(1), 3) = {'boolean'}; % data type
                DD_cell2(DD_Index2(1), 4) = {'0'}; % Minimum
                DD_cell2(DD_Index2(1), 5) = {'1'}; % Maximun
                DD_cell2(DD_Index2(1), 6) = {'flg'}; % Unit
                DD_cell2(DD_Index2(1), 7) = {'N/A'}; % Enum table
                if contains(MsgName_DD, {'MCUNR1', 'MCUNF1'})
                    DD_cell2(DD_Index2(1), 8) = {'0'}; % Default during Running
                else
                    DD_cell2(DD_Index2(1), 8) = {'1'}; % Default during Running
                end



                % Check if the CS and RC are correct
                if contains(MsgName, AllMessagesRequiringRcCsCheck) 
              
                    BlockName = 'DDM_CS&RC_Comparison';
                    targetblockpos = get_param(gotoport.Inport(1), 'Position');
                    block_x = targetblockpos(1) - 100;
                    block_y = targetblockpos(2) + 200 + ceil(str2double(DLC)) * 45/2;
                    block_w = block_x + 250;
                    block_h = block_y + 350;
                    srcT = 'FVT_lib/hal/DDM_CS&RC_Comparison';
                    dstT = [TargetModel '/' BlockName];
                    hblock = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(hblock, 'position', [block_x, block_y, block_w, block_h]);
                    set_param(hblock, 'MsgCycleTime', msg_time_ms);
                    sourceblockport = get_param(hblock, 'PortHandles');
                    sourceblockport2 = sourceblockport;

                    BlockName = ['KHAL_' Channel MsgName_DD 'E2E_flg'];
                    targetblockpos = get_param(sourceblockport.Inport(1), 'Position');
                    srcT = 'simulink/Sources/Constant';
                    dstT = [TargetModel '/' BlockName];
                    block_x = targetblockpos(1) - 400;
                    block_y = targetblockpos(2) - 15;
                    block_w = block_x + 250;
                    block_h = block_y + 25;
                    hblock = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(hblock, 'value', BlockName, 'ShowName', 'off');
                    set_param(hblock, 'position', [block_x, block_y, block_w, block_h]);
                    targetblockport = get_param(hblock, 'PortHandles');
                    add_line(TargetModel, targetblockport.Outport(1), sourceblockport2.Inport(1), 'autorouting', 'on');
                    

                    if isempty(DataID)
                        DataID = '0x0000';
                    end

                    if length(DataID) < 6
                        for ii = 1:6 - length(DataID)
                            DataID = [DataID(1:2) '0' DataID(3:end)];
                        end
                    end

                    DataID_H = ['0x' DataID(3:4)];
                    DataID_L = ['0x' DataID(5:6)];

                    sourceblockport = get_param(hblock, 'PortHandles');
                    BlockName = DataID_L;
                    targetblockpos = get_param(sourceblockport.Outport(1), 'Position');
                    srcT = 'simulink/Sources/Constant';
                    dstT = [TargetModel '/' BlockName];
                    block_x = block_x;
                    block_y = targetblockpos(2) + 35;
                    block_w = block_x + 250;
                    block_h = block_y + 25;
                    hblock = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(hblock, 'value', BlockName, 'ShowName', 'off');
                    set_param(hblock, 'position', [block_x, block_y, block_w, block_h]);
                    targetblockport = get_param(hblock, 'PortHandles');
                    add_line(TargetModel, targetblockport.Outport(1), sourceblockport2.Inport(2), 'autorouting', 'on');

                    sourceblockport = get_param(hblock, 'PortHandles');
                    BlockName = DataID_H;
                    targetblockpos = get_param(sourceblockport.Outport(1), 'Position');
                    srcT = 'simulink/Sources/Constant';
                    dstT = [TargetModel '/' BlockName];
                    block_x = block_x;
                    block_y = targetblockpos(2) + 35;
                    block_w = block_x + 250;
                    block_h = block_y + 25;
                    hblock = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(hblock, 'value', BlockName, 'ShowName', 'off');
                    set_param(hblock, 'position', [block_x, block_y, block_w, block_h]);
                    targetblockport = get_param(hblock, 'PortHandles');
                    add_line(TargetModel, targetblockport.Outport(1), sourceblockport2.Inport(3), 'autorouting', 'on');

                    sourceblockport = get_param(hblock, 'PortHandles');
                    BlockName = ['VHAL_' Channel MsgName_DD 'noCS_raw'];
                    targetblockpos = get_param(sourceblockport.Outport(1), 'Position');
                    srcT = 'simulink/Signal Routing/From';
                    dstT = [TargetModel '/' BlockName];
                    block_x = block_x;
                    block_y = targetblockpos(2) + 35;
                    block_w = block_x + 250;
                    block_h = block_y + 25;
                    hblock = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(hblock, 'Gototag', BlockName, 'ShowName', 'off');
                    set_param(hblock, 'position', [block_x, block_y, block_w, block_h]);
                    targetblockport = get_param(hblock, 'PortHandles');
                    add_line(TargetModel, targetblockport.Outport(1), sourceblockport2.Inport(4), 'autorouting', 'on');

                    sourceblockport = get_param(hblock, 'PortHandles');
                    BlockName = ['Byte_' num2str(csbytepos - 1)];
                    targetblockpos = get_param(sourceblockport.Outport(1), 'Position');
                    block_x = block_x;
                    block_y = targetblockpos(2) + 35;
                    block_w = block_x + 250;
                    block_h = block_y + 25;
                    srcT = 'simulink/Signal Routing/From';
                    dstT = [TargetModel '/' BlockName];
                    hblock = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(hblock, 'position', [block_x, block_y, block_w, block_h]);
                    set_param(hblock, 'GotoTag', BlockName, 'ShowName', 'off');
                    targetblockport = get_param(hblock, 'PortHandles');
                    add_line(TargetModel, targetblockport.Outport(1), sourceblockport2.Inport(5), 'autorouting', 'on');

                    sourceblockport = get_param(hblock, 'PortHandles');
                    BlockName = 'Goto';
                    targetblockpos = get_param(sourceblockport.Outport(1), 'Position');
                    block_x = block_x;
                    block_y = targetblockpos(2) + 35;
                    block_w = block_x + 250;
                    block_h = block_y + 25;
                    srcT = 'simulink/Signal Routing/From';
                    dstT = [TargetModel '/' BlockName];
                    hblock = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(hblock, 'Gototag', 'RC_ECU', 'ShowName', 'off');
                    set_param(hblock, 'position', [block_x, block_y, block_w, block_h]);
                    targetblockport = get_param(hblock, 'PortHandles');
                    add_line(TargetModel, targetblockport.Outport(1), sourceblockport2.Inport(6), 'autorouting', 'on');

                    sourceblockport = get_param(hblock, 'PortHandles');
                    targetblockpos = get_param(sourceblockport.Outport(1), 'Position');
                    BlockName = 'MessageRollingCounter';
                    block_x = block_x;
                    block_y = targetblockpos(2) + 35;
                    block_w = block_x + 250;
                    block_h = block_y + 25;
                    srcT = 'FVT_lib/hal/MessageRollingCounter';
                    dstT = [TargetModel '/' BlockName];
                    hblock = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(hblock, 'position', [block_x, block_y, block_w, block_h], 'ShowName', 'off')
                    set_param(hblock, 'task_time_ms', '5', 'msg_time_ms', msg_time_ms);
                    targetblockport = get_param(hblock, 'PortHandles');
                    add_line(TargetModel, targetblockport.Outport(1), sourceblockport2.Inport(7), 'autorouting', 'on');

                    targetblockpos = get_param(sourceblockport2.Outport(1), 'Position');
                    BlockName = ['VHAL_' MsgName_DD 'CSErr_flg'];
                    block_x = targetblockpos(1) + 150;
                    block_y = targetblockpos(2) - 5;
                    block_w = block_x + 30;
                    block_h = block_y + 13;
                    srcT = 'simulink/Sinks/Out1';
                    dstT = [TargetModel '/' BlockName];
                    hblock = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(hblock, 'position', [block_x, block_y, block_w, block_h], 'Port', '1');
                    set_param(hblock, 'name', BlockName);
                    targetblockport = get_param(hblock, 'PortHandles');
                    add_line(TargetModel, sourceblockport2.Outport(1), targetblockport.Inport(1), 'autorouting', 'on');

                    targetblockpos = get_param(sourceblockport2.Outport(2), 'Position');
                    BlockName = ['VHAL_' MsgName_DD 'RCErr_flg'];
                    block_x = targetblockpos(1) + 150;
                    block_y = targetblockpos(2) - 5;
                    block_w = block_x + 30;
                    block_h = block_y + 13;
                    srcT = 'simulink/Sinks/Out1';
                    dstT = [TargetModel '/' BlockName];
                    hblock = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(hblock, 'position', [block_x, block_y, block_w, block_h], 'Port', '2');
                    set_param(hblock, 'name', BlockName);
                    targetblockport = get_param(hblock, 'PortHandles');
                    add_line(TargetModel, sourceblockport2.Outport(2), targetblockport.Inport(1), 'autorouting', 'on');

                end

            end

            

            for k  = 1:length(Signal_match_array)
                SignalSize = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).SignalSize;
                SignalMin = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Minimum;
                SignalMax = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Maximum;
                Startbit = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).StartBit;
                SignalUnit_raw = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Units;
                SignalUnit_modify = char(UnitChange(SignalUnit_raw));
                SignalName = char(erase(DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Name, '_'));
                Autosar_SignalName = char(DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Name);
                SignalResolution = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Factor;
                SignalOffset = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Offset;
                SignalConvert = {num2str(SignalResolution), num2str(SignalOffset)};
                     
                % define VHAL signal name and type   
                if SignalSize == 1
                    SignalUnit = 'flg';
                    SignalDataType = 'boolean';
                elseif contains(SignalName,'Diag')
                    SignalUnit = 'Diag';
                    SignalDataType = 'uint64';
                elseif isempty(SignalUnit_modify) && SignalOffset ==0 && SignalResolution == 1
                    SignalUnit = 'enum';
                    if SignalSize <= 8; SignalDataType = 'uint8'; end
                    if (8 < SignalSize) && (SignalSize <= 16); SignalDataType = 'uint16'; end
                    if (16 < SignalSize) && (SignalSize <= 32); SignalDataType = 'uint32'; end
                    if SignalSize > 32 ; SignalDataType = 'uint64'; end
                elseif isempty(SignalUnit_modify) && (SignalOffset ~=0 || SignalResolution ~= 1)
                    SignalUnit = 'cnt';
                    SignalDataType = 'single';
                else
                    SignalUnit = SignalUnit_modify;
                    SignalDataType = 'single';
                end
                
                % Modify signal maximum if out of range
                if startsWith(SignalDataType,'uint') && SignalMax > intmax(SignalDataType)
                    SignalMax = intmax(SignalDataType);
                    disp([SignalName char(9) 'maximum value has been modified']);
                end

                SignalName_HAL = ['VHAL_' SignalName '_' SignalUnit];
                % write DD file
                DD_Index = find(cellfun(@isempty,DD_cell(1:end,1)));
                DD_cell(DD_Index(1),1) = {SignalName_HAL}; % HAL signal name
                DD_cell(DD_Index(1),2) = {'output'}; % Direction
                DD_cell(DD_Index(1),3) = {SignalDataType}; % data type
                DD_cell(DD_Index(1),4) = {num2str(SignalMin)}; % Minimum
                DD_cell(DD_Index(1),5) = {num2str(SignalMax)}; % Maximun
                DD_cell(DD_Index(1),6) = {SignalUnit}; % Unit
                DD_cell(DD_Index(1),7) = {'N/A'}; % Enum table
                DD_cell(DD_Index(1),8) = {'N/A'}; % Default before and during POWER-UP
                DD_cell(DD_Index(1),9) = {'N/A'}; % DDefault before and during POWER-DOWN
                DD_cell(DD_Index(1),10) = {'N/A'}; % Description
                DD_cell(DD_Index(1),11) = {TxNode}; % CAN transmitter
                DD_cell(DD_Index(1),12) = {MsgName}; % Message
                DD_cell(DD_Index(1),13) = {'CAN'}; % Data source
    
                %*************** Signal unpack subsystem*******************************%
                if IsLINMessage
                    EndByte = floor((Startbit+SignalSize-1)/8);
                    RightShiftCnt = rem(Startbit,8);
                else
                    EndByte = floor(Startbit/8);
                    RightShiftCnt = rem(Startbit,8);
                end
                if SignalSize == 1
                    NUM_BYTE = 1;
                else
                    remainlength = SignalSize-(8-RightShiftCnt);
                    if remainlength > 0
                        NUM_BYTE = ceil(remainlength/8)+1;
                    else
                        NUM_BYTE = 1;
                    end
                end
    
                BlockName = SignalName;
                if k ==1
                    block_x = targetpos(1) + 1000;
                    block_y = targetpos(2);
                else
                    block_x = lastblk_pos(1);
                    block_y = lastblk_pos(4)+ 80;
                end
                block_w = block_x+250;
                block_h = block_y+NUM_BYTE*40;
                srcT = 'built-in/SubSystem';
                dstT = [TargetModel '/' BlockName];    
                h = add_block(srcT,dstT);     
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'ContentPreviewEnabled','off','BackgroundColor','Cyan');
                lastblk_pos = get_param(h,'position');
                
                % Modify signal unpack process for AUTOSAR 
                if ~Autosar_flg
                % 
%                     TargetModel = [TargetModel '/' SignalName];
%                     BlockName = 'BitwiseOR';
%                     block_x = original_x;
%                     block_y = original_y;
% 
%                     block_w = block_x + 70;
%                     block_h = block_y + 60*NUM_BYTE;
%                     srcT = 'simulink/Logic and Bit Operations/Bitwise Operator';
%                     dstT = [TargetModel '/' BlockName];    
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');     
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'UseBitMask','off');
%                     set_param(h,'logicop','OR');
%                     set_param(h,'NumInputPorts',num2str(NUM_BYTE));
%         
%                     sourceport = get_param(h,'PortHandles');
%                     targetpos = get_param(sourceport.Outport(1),'Position');
%                     BlockName = 'RightShift';
%                     block_x = targetpos(1) + 100;
%                     block_y = targetpos(2) - 25;
%                     block_w = block_x + 100;
%                     block_h = block_y + 50;
%                     srcT = 'simulink/Logic and Bit Operations/Shift Arithmetic';
%                     dstT = [TargetModel '/' BlockName];    
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');     
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'BitShiftDirection','Right');
%                     set_param(h,'BitShiftNumber',num2str(RightShiftCnt));
%                     targetport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%         
%                     sourceport = get_param(h,'PortHandles');
%                     targetpos = get_param(sourceport.Outport(1),'Position');
%                     BlockName = 'BitwiseAND';
%                     block_x = targetpos(1) + 300;
%                     block_y = targetpos(2) - 10;
%                     block_w = block_x + 100;
%                     block_h = block_y + 40;
%                     srcT = 'simulink/Logic and Bit Operations/Bitwise Operator';
%                     dstT = [TargetModel '/' BlockName];    
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');     
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'UseBitMask','off');
%                     set_param(h,'logicop','AND');
%                     set_param(h,'NumInputPorts','2');
%                     targetport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%         
%                     targetpos = get_param(targetport.Inport(2),'Position');
%                     BlockName = 'UnitConverter';
%                     srcT = 'simulink/Signal Attributes/Data Type Conversion';
%                     dstT = [TargetModel '/' BlockName];
%                     block_x = targetpos(1) - 100;
%                     block_y = targetpos(2) + 15;
%                     block_w = block_x + 70;
%                     block_h = block_y + 30;
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');     
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     if NUM_BYTE == 3
%                         set_param(h,'OutDataTypeStr', 'uint32','ShowName', 'off');
%                     elseif NUM_BYTE > 4
%                         set_param(h,'OutDataTypeStr', 'uint64','ShowName', 'off');
%                     else
%                         set_param(h,'OutDataTypeStr', ['uint' num2str(8*NUM_BYTE)],'ShowName', 'off');
%                     end
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(2),'autorouting','on');
%         
%                     targetpos = get_param(sourceport.Inport(1),'Position');
%                     targetport = sourceport;
%                     BlockName = 'Constant';
%                     srcT = 'simulink/Sources/Constant';
%                     dstT = [TargetModel '/' BlockName];
%                     block_x = targetpos(1) - 150;
%                     block_y = targetpos(2) - 15;
%                     block_w = block_x + 100;
%                     block_h = block_y + 30;
%                     h = add_block(srcT,dstT,'MakeNameUnique','on');     
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     set_param(h,'value',['(2^' num2str(SignalSize) '-1)']);
%                     sourceport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%         
%                     sourceport = get_param([TargetModel '/BitwiseAND'],'PortHandles');
%                     targetpos = get_param(sourceport.Outport(1),'Position');
%                     
%                     if SignalOffset ~=0 || SignalResolution ~= 1
%                         BlockName = 'convert_in';
%                         block_x = targetpos(1) + 100;
%                         block_y = targetpos(2) - 25;
%                         block_w = block_x + 100;
%                         block_h = block_y + 50;
%                         srcT = 'FVT_lib/hal/convert_in';
%                         dstT = [TargetModel '/' BlockName];    
%                         h = add_block(srcT,dstT,'MakeNameUnique','on');     
%                         set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                         set_param(h, 'MaskValues', SignalConvert);
%                         targetport = get_param(h,'PortHandles');
%                         add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%         
%                         sourceport = get_param(h,'PortHandles');
%                         targetpos = get_param(sourceport.Outport(1),'Position');
%                     end
%                     
%                     BlockName = SignalName_HAL;
%                     block_x = targetpos(1) + 350;
%                     block_y = targetpos(2)-5;
%                     block_w = block_x + 30;
%                     block_h = block_y + 13;
%                     srcT = 'simulink/Sinks/Out1';
%                     dstT = [TargetModel '/' BlockName];    
%                     h = add_block(srcT,dstT);     
%                     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                     targetport = get_param(h,'PortHandles');
%                     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%         
%                     for n = 1:NUM_BYTE
%                         targetport = get_param([TargetModel '/BitwiseOR'],'PortHandles');
%                         targetpos = get_param(targetport.Inport(n),'Position');
%                         BlockName = 'LeftShift';
%                         block_x = targetpos(1) - 200;
%                         block_y = targetpos(2) - 25;
%                         block_w = block_x + 100;
%                         block_h = block_y + 50;
%                         srcT = 'simulink/Logic and Bit Operations/Shift Arithmetic';
%                         dstT = [TargetModel '/' BlockName];    
%                         h = add_block(srcT,dstT,'MakeNameUnique','on');     
%                         set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                         set_param(h,'BitShiftDirection','Left');
%                         if IsLINMessage
%                             set_param(h,'BitShiftNumber',num2str(8*(n-1)));
%                         else
%                             set_param(h,'BitShiftNumber',num2str(8*(NUM_BYTE-n)));
%                         end
%                         sourceport = get_param(h,'PortHandles');
%                         add_line(TargetModel,sourceport.Outport(1),targetport.Inport(n));
%         
%                         targetpos = get_param(sourceport.Inport(1),'Position');
%                         targetport = sourceport;
%                         BlockName = 'UnitConverter';
%                         srcT = 'simulink/Signal Attributes/Data Type Conversion';
%                         dstT = [TargetModel '/' BlockName];
%                         block_x = targetpos(1) - 150;
%                         block_y = targetpos(2) - 15;
%                         block_w = block_x + 70;
%                         block_h = block_y + 30;
%                         h = add_block(srcT,dstT,'MakeNameUnique','on');     
%                         set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                         if NUM_BYTE == 3
%                             set_param(h,'OutDataTypeStr', 'uint32','ShowName', 'off');
%                         elseif NUM_BYTE > 4
%                             set_param(h,'OutDataTypeStr', 'uint64','ShowName', 'off');
%                         else
%                             set_param(h,'OutDataTypeStr', ['uint' num2str(8*NUM_BYTE)],'ShowName', 'off');
%                         end
%                         sourceport = get_param(h,'PortHandles');
%                         add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%         
%                         targetpos = get_param(sourceport.Inport(1),'Position');
%                         targetport = sourceport;
%                         BlockName = ['Byte_' num2str(EndByte-NUM_BYTE+n)];
%                         block_x = targetpos(1) - 100;
%                         block_y = targetpos(2)-5;
%                         block_w = block_x + 30;
%                         block_h = block_y + 13;
%                         srcT = 'simulink/Sources/In1';
%                         dstT = [TargetModel '/' BlockName];    
%                         h = add_block(srcT,dstT);     
%                         set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                         sourceport = get_param(h,'PortHandles');
%                         add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%                     end
                else
                    TargetModel = [TargetModel '/' SignalName];
                    BlockName = SignalName_HAL;
                    block_x = original_x;
                    block_y = original_y;
                    block_w = block_x + 30;
                    block_h = block_y + 13;
                    srcT = 'simulink/Sinks/Out1';
                    dstT = [TargetModel '/' BlockName];    
                    h = add_block(srcT,dstT);     
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    targetport = get_param(h,'PortHandles');
                    targetpos = get_param(targetport.Inport(1),'Position');
                   
                    if SignalOffset ~=0 || SignalResolution ~= 1
                        BlockName = 'convert_in';
                        block_x = targetpos(1) - 200;
                        block_y = targetpos(2) - 25;
                        block_w = block_x + 100;
                        block_h = block_y + 50;
                        srcT = 'FVT_lib/hal/convert_in';
                        dstT = [TargetModel '/' BlockName];    
                        h = add_block(srcT,dstT,'MakeNameUnique','on');     
                        set_param(h,'position',[block_x,block_y,block_w,block_h]);
                        set_param(h, 'MaskValues', SignalConvert);
                        sourceport = get_param(h,'PortHandles');
                        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                        targetport = get_param(h,'PortHandles');
                     end

                    BlockName = 'UnitConverter';
                    srcT = 'simulink/Signal Attributes/Data Type Conversion';
                    dstT = [TargetModel '/' BlockName];
                    block_x = targetpos(1) - 450;
                    block_y = targetpos(2) - 15;
                    block_w = block_x + 70;
                    block_h = block_y + 30;
                    h = add_block(srcT,dstT,'MakeNameUnique','on');     
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    if NUM_BYTE == 3
                        set_param(h,'OutDataTypeStr', 'uint32','ShowName', 'off');
                    elseif NUM_BYTE > 4
                        set_param(h,'OutDataTypeStr', 'uint64','ShowName', 'off');
                    else
                        set_param(h,'OutDataTypeStr', ['uint' num2str(8*NUM_BYTE)],'ShowName', 'off');
                    end
                    sourceport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
    
                    targetpos = get_param(sourceport.Inport(1),'Position');
                    targetport = sourceport;
                    BlockName = Autosar_SignalName;
                    block_x = targetpos(1) - 100;
                    block_y = targetpos(2)-5;
                    block_w = block_x + 30;
                    block_h = block_y + 13;
                    srcT = 'simulink/Sources/In1';
                    dstT = [TargetModel '/' BlockName];    
                    h = add_block(srcT,dstT);     
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    sourceport = get_param(h,'PortHandles');
                    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                end
    
                TargetModel = [new_model '/' Channel '/' MsgName];
                targetport = get_param([TargetModel '/' SignalName],'PortHandles');
                for n = 1:length(targetport.Inport)
                    TargetModel = [new_model '/' Channel '/' MsgName];
                    targetport = get_param([TargetModel '/' SignalName],'PortHandles');
                    % h = get_param([TargetModel '/' SignalName],'Handle');
                    % h = find_system(h,'SearchDepth', 1, 'BlockType', 'Inport');
                    targetpos = get_param(targetport.Inport(n),'Position');
                    BlockName = 'From';
                    block_x = targetpos(1) - 500;
                    block_y = targetpos(2)-20;
                    block_w = block_x + 250;
                    block_h = block_y + 35;
                    srcT = 'simulink/Signal Routing/From';
                    dstT = [TargetModel '/' BlockName];    
                    h = add_block(srcT,dstT,'MakeNameUnique','on');     
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);

                    if ~Autosar_flg
                        set_param(h,'GotoTag',BlockName,'ShowName','off');
                        sourceport = get_param(h,'PortHandles');
                        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(n));
                    else
                        set_param(h,'GotoTag',char(Autosar_msg),'ShowName','off');
                        targetport = get_param(h,'PortHandles');
                        targetpos = get_param(targetport.Outport(1),'Position');
                        BlockName='bus_selector';
                        block_x = targetpos(1) + 10;
                        block_y = targetpos(2) - 20;
                        block_w = block_x + 10;
                        block_h = block_y + 30;
                        srcT = 'simulink/Signal Routing/Bus Selector';
                        dstT = [TargetModel '/' BlockName];
                        h = add_block(srcT,dstT,'MakeNameUnique','on');
                        set_param(h,'position',[block_x,block_y,block_w,block_h]);
                        set_param(h,'outputsignals',[Channel '_' Autosar_SignalName],'ShowName', 'off');
                        sourceport = get_param(h,'PortHandles');
                        add_line(TargetModel,targetport.Outport(1),sourceport.Inport(1));
                        targetport = get_param([TargetModel '/' SignalName],'PortHandles');
                        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(n));
                    end
                end

                targetport = get_param([TargetModel '/' SignalName],'PortHandles');
                targetpos = get_param(targetport.Outport(1),'Position');
                sourceport = targetport;
                BlockName = SignalName_HAL;
                block_x = targetpos(1) + 100;
                block_y = targetpos(2)-5;
                block_w = block_x + 30;
                block_h = block_y + 13;
                srcT = 'simulink/Sinks/Out1';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT);     
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                targetport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1))


                % Add RC goto blocks
                if (contains(MsgName, EscMessagesRequiringRcCsCheck) && (contains(SignalName, 'RC') && contains(SignalName, MsgName) && ~contains(SignalName, 'CRC8'))) ...
                    || contains(SignalName, 'ShifterRC') ...
                    || (contains(MsgName, setdiff(AllMessagesWithoutEscRequiringRcCsCheck, {'Shifter'})) ...
                        && (contains(SignalName, 'RC') || contains(SignalName, 'LifeCount') || contains(SignalName, 'RolCnct') || contains(SignalName, 'RolCnt'))  && ~contains(SignalName, 'CRC8') && ~contains(SignalName, 'RCenter'))

                    
                    BlockName = 'Goto';
                    block_x = lastblk_pos(1) + 350;
                    block_y = lastblk_pos(2) - 30;
                    block_w = block_x + 250;
                    block_h = block_y + 20;
                    srcT = 'simulink/Signal Routing/Goto';
                    dstT = [TargetModel '/' BlockName];
                    goto = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(goto, 'Gototag', 'RC_ECU', 'ShowName', 'off');
                    set_param(goto, 'position', [block_x, block_y, block_w, block_h]);
                    gotoport = get_param(goto, 'PortHandles');
                    lastblkport = get_param([TargetModel '/' SignalName],'PortHandles');
                    add_line(TargetModel, lastblkport.Outport, gotoport.Inport, 'autorouting', 'smart')
       
                end
            
            end                   
        end
        %% For routing rollcount judge
        %
%         if  exist('Detect_frame_routing','var') && ~isempty(Detect_frame_routing) && ~isempty(Detect_Frame_routing_can)
%             
%             TargetModel = [new_model '/' Channel '/' MsgName];
%             sourceport = get_param([new_model '/' Channel '/' MsgName '/' MsgName],'PortHandles');
%             targetpos = get_param(sourceport.Outport(1),'Position');
%             BlockName = ['VHAL_' Channel MsgName_DD '_cnt'];
%             block_x = targetpos(1) + 270;
%             block_y = targetpos(2) -50;
%             block_w = block_x + 30;
%             block_h = block_y + 13;                    
%             srcT = 'simulink/Sinks/Out1';
%             dstT = [TargetModel '/' BlockName];
%             h = add_block(srcT,dstT);     
%             set_param(h,'position',[block_x,block_y,block_w,block_h])
%             targetport = get_param(h,'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on');
% 
%         end
%         %
        %% add mux for frame routing 
        %
%          if exist('Detect_frame_routing','var') && ~isempty(Detect_frame_routing) && ~isempty(Detect_Frame_routing_can)
% 
%             TargetModel = [new_model '/' Channel '/' MsgName];
%             targetport = get_param([TargetModel '/' MsgName],'Position');
%             BlockName = 'Mux';
%             block_x = targetport(1) + targetport(3) + 55;
%             block_y = targetport(2) + targetport(4) + 100;
%             block_w = block_x + 10 ;
%             block_h = block_y + 45*ceil(str2double(DLC));
%             srcT = 'simulink/Commonly Used Blocks/Mux';
%             dstT = [TargetModel '/' BlockName];
%             h = add_block(srcT,dstT);     
%             set_param(h,'Inputs',num2str(ceil((str2double(DLC)))));
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             sourceport = get_param(h,'PortHandles');
% 
%             for k = 1:str2double(DLC)
%                 targetpos = get_param(sourceport.Inport(k),'Position');
%                 BlockName = ['Byte_' num2str(k-1)];
%                 block_x = targetpos(1) - 300;
%                 block_y = targetpos(2) - 20;
%                 block_w = block_x + 250;
%                 block_h = block_y + 35;
%                 srcT = 'simulink/Signal Routing/From';
%                 dstT = [TargetModel '/' BlockName];    
%                 h = add_block(srcT,dstT,'MakeNameUnique','on');     
%                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                 set_param(h,'GotoTag',BlockName,'ShowName','off');
%                 targetport = get_param(h,'PortHandles');
%                 add_line(TargetModel,targetport.Outport(1),sourceport.Inport(k));
%             end
%             
%             
%             BlockName = ['VHAL_' Channel MsgName_DD '_raw']; 
%             targetpos = get_param(sourceport.Outport(1),'Position');
%             srcT = 'simulink/Sinks/Out1';
%             dstT = [TargetModel '/' BlockName]; 
%             block_x = targetpos(1) + 100;
%             block_y = targetpos(2) - 5;
%             block_w = block_x + 30;
%             block_h = block_y + 13;
%             h = add_block(srcT,dstT);  
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             targetport = get_param(h,'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%             num_routing = num_routing+1;
%          end
%                         
        %% For rollcount judge    
        %
%          if contains(MsgName,'NMm')
%             targetport = get_param([new_model '/' Channel '/' MsgName '/Detect Change'],'PortHandles');
%             targetpos = get_param(targetport.Outport(1),'Position');
%             BlockName = 'NOT';
%             block_x = targetpos(1)+150;
%             block_y = targetpos(2)-30;
%             block_w = block_x + 50;
%             block_h = block_y + 50;
%             srcT = 'simulink/Commonly Used Blocks/Logical Operator';
%             dstT = [TargetModel '/' BlockName];    
%             h = add_block(srcT,dstT,'MakeNameUnique','on');     
%             set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'Inputs', '1');
%             set_param(h,'Operator','NOT');
%             sourceport = get_param(h,'PortHandles');
%             add_line(TargetModel,targetport.Outport(1),sourceport.Inport(1));
% 
%             sourceport = get_param([new_model '/' Channel '/' MsgName '/NOT'],'PortHandles');
%             targetport = get_param([new_model '/' Channel '/' MsgName '/' MsgTimeoutflg],'PortHandles');
%             add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%         end      
    end
    % Delete empty DD_cell cell
        for j = length(DD_cell(:,1)):-1:1
            if cellfun(@isempty,DD_cell(j,1))
                DD_cell(j,:) = [];
            end
        end

    % Delete empty DD_cell2 cell
        for j = length(DD_cell2(:, 1)):-1:1

            if cellfun(@isempty, DD_cell2(j, 1))

                if j == 1
                    % write DD file
                    DD_cell2(1, 1:8) = {'0'};
                else
                    DD_cell2(j, :) = [];
                end

            end

        end    

    % add items top layer
    TargetModel = [new_model '/' Channel];
    BlockName ='bus_creator'; 
    srcT = 'simulink/Signal Routing/Bus Creator';
    dstT = [TargetModel '/' BlockName]; 
    block_x = original_x + 1800;
    block_y = original_y + 25;
    block_w = block_x + 20;
    block_h = block_y + 30*(length(DD_cell(1:end,1))); %bus length
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'inputs',num2str(length(DD_cell(1:end,1))), 'ShowName', 'off');
    sourceport = get_param(h,'PortHandles');
    targetpos = get_param(sourceport.Outport(1),'Position');

    BlockName = ['HAL_' Channel '_outputs'];
    dstT = [TargetModel '/' BlockName]; 
    block_x = targetpos(1) + 100;
    block_y = targetpos(2)-5;
    block_w = block_x + 30;
    block_h = block_y + 13;    
    set_param(dstT,'position',[block_x,block_y,block_w,block_h]);
    targetport = get_param(dstT,'PortHandles');
    add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));

    %% Add bus creator for message routing raw data    
    %
%     if exist('Detect_Frame_routing_can','var') && ~isempty(Detect_Frame_routing_can)
%     TargetModel = [new_model '/' Channel];
%     BlockName ='bus_creator_raw'; 
%     srcT = 'simulink/Signal Routing/Bus Creator';
%     dstT = [TargetModel '/' BlockName];
%     sourceport = get_param(h,'Position');
%     block_x = sourceport(1);
%     block_y = sourceport(2) + sourceport(4) +100;
%     block_w = block_x + 20;
%     block_h = block_y + 30*(num_routing*2); %bus length
%     h = add_block(srcT,dstT);
%     set_param(h,'position',[block_x,block_y,block_w,block_h]);
%     set_param(h,'inputs',num2str(num_routing*2), 'ShowName', 'off');
%     sourceport = get_param(h,'PortHandles');
%     targetpos = get_param(sourceport.Outport(1),'Position');
% 
% 
%     BlockName = ['HAL_'  Channel 'outputs_raw'];
%     dstT = [TargetModel '/' BlockName];
%     block_x = targetpos(1) + 100;
%     block_y = targetpos(2)-5;
%     block_w = block_x + 30;
%     block_h = block_y + 13;    
%     set_param(dstT,'position',[block_x,block_y,block_w,block_h]);
%     targetport = get_param(dstT,'PortHandles');
%     add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
%     end 
    % Add goto and data converter for BUS
     Cnt = 0;
     % cnt_routing = 0;
     for j = 1: length(DD_cell(1:end,1))
         Signalname = char(DD_cell(j,1));
         DataType = char(DD_cell(j,3));
         Message = char(DD_cell(j,12));
         if ~Autosar_flg || contains(Message,'NMm') || ~contains(Signalname,'CANMsgInvalid')
             TargetModel = [new_model '/' Channel];
             dstT = [TargetModel '/' Message];
             sourceport = get_param(dstT,'PortHandles');             
             Cnt = Cnt + 1;
             
             % add goto for Msg block
             targetpos = get_param(sourceport.Outport(Cnt),'Position');
             BlockName = 'Goto';
             block_x = targetpos(1) + 100;
             block_y = targetpos(2)-10;
             block_w = block_x + 250;
             block_h = block_y + 20;
             srcT = 'simulink/Signal Routing/Goto';
             dstT = [TargetModel '/' BlockName];    
             h = add_block(srcT,dstT,'MakeNameUnique','on');     
             set_param(h,'position',[block_x,block_y,block_w,block_h]);
    
             % By Daniel
%              if contains(Signalname,'EBM')
%                  str_m = char(DD_cell(j,1));
%                  new_str = [str_m(1:5) Channel str_m(6:end)]; %can1 & can3
%                  DD_cell(j,1) = {new_str};
%                  Signalname = new_str;
%              end
             %
    
             set_param(h,'Gototag', Signalname, 'ShowName', 'off');
             targetport = get_param(h,'PortHandles');
             add_line(TargetModel,sourceport.Outport(Cnt),targetport.Inport(1));
             %R_Message = char(erase(Message,'_'));
    
             %% Add goto for frame routing raw    
             %
%              % When DD_cell run over the message signal, message block only left one outport from routing raw  
%              if exist('Detect_Frame_routing_can','var') && ~isempty(Detect_Frame_routing_can)
%             
%              frame_routing = strcmp(string(Restore_array_can(:,2)),string(Message));
%              Detect_frame_routing = find(frame_routing == 1);
%             
%              end
%     
%     
%              if exist('Detect_frame_routing','var') && ~isempty(Detect_frame_routing) && (Cnt == (length(sourceport.Outport)-2)) 
%                 targetpos = get_param(sourceport.Outport(Cnt+1),'Position');
%                 BlockName = 'Goto';
%                 block_x = targetpos(1) + 100;
%                 block_y = targetpos(2) - 10;
%                 block_w = block_x + 250;
%                 block_h = block_y + 20;
%                 srcT = 'simulink/Signal Routing/Goto';
%                 dstT = [TargetModel '/' BlockName];
%                 h = add_block(srcT,dstT,'MakeNameUnique','on');     
%                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                 set_param(h,'Gototag',['VHAL_' Channel R_Message '_cnt'], 'ShowName', 'off');
%                 targetport = get_param(h,'PortHandles');
%                 add_line(TargetModel,sourceport.Outport(Cnt+1),targetport.Inport(1));
%                 Cnt = Cnt+1;
%     
%                 targetpos = get_param(sourceport.Outport(Cnt+1),'Position');
%                 BlockName = 'Goto';            
%                 block_x = targetpos(1) + 100;
%                 block_y = targetpos(2) - 10;
%                 block_w = block_x + 250;
%                 block_h = block_y + 20;
%                 srcT = 'simulink/Signal Routing/Goto';
%                 dstT = [TargetModel '/' BlockName];
%                 h = add_block(srcT,dstT,'MakeNameUnique','on');     
%                 set_param(h,'position',[block_x,block_y,block_w,block_h]);
%                 set_param(h,'Gototag',['VHAL_' Channel R_Message '_raw'], 'ShowName', 'off');
%                 targetport = get_param(h,'PortHandles');
%                 add_line(TargetModel,sourceport.Outport(Cnt+1),targetport.Inport(1));
%                 Cnt = Cnt+1;    
%              end
             if Cnt == length(sourceport.Outport)             
                Cnt = 0;              
             end
                      
            % add data type converter
            targetport = get_param([TargetModel '/bus_creator'],'PortHandles');
            targetpos = get_param(targetport.Inport(j),'Position'); 
            BlockName = 'UnitConverter';
            srcT = 'simulink/Signal Attributes/Data Type Conversion';
            dstT = [TargetModel '/' BlockName]; 
            block_x = targetpos(1) - 300;
            block_y = targetpos(2) - 10;
            block_w = block_x + 50;
            block_h = block_y + 20;
            h = add_block(srcT,dstT,'MakeNameUnique','on');     
            set_param(h,'position',[block_x,block_y,block_w,block_h])
            set_param(h,'OutDataTypeStr', DataType,'ShowName', 'off');
            sourceport = get_param(h,'PortHandles');
            h = add_line(TargetModel,sourceport.Outport(1),targetport.Inport(j));
            set_param(h,'name', Signalname);
            set(h,'MustResolveToSignalObject',1);
            
            targetport = sourceport;
            targetpos = get_param(targetport.Inport(1),'Position'); 
            BlockName = 'From';
            block_x = targetpos(1) - 350;
            block_y = targetpos(2) - 10;
            block_w = block_x + 250;
            block_h = block_y + 20;
            srcT = 'simulink/Signal Routing/From';
            dstT = [TargetModel '/' BlockName];   
            h = add_block(srcT,dstT,'MakeNameUnique','on');     
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h,'Gototag', Signalname,'ShowName', 'off');
            sourceport = get_param(h,'PortHandles');
            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));  

         elseif (Autosar_flg && contains(Signalname,'CANMsgInvalid')) && ~contains(Message,'NMm')   
            targetport = get_param([TargetModel '/bus_creator'],'PortHandles');
            targetpos = get_param(targetport.Inport(j),'Position'); 
            BlockName = Signalname;
            srcT = 'FVT_lib/hal/MsgTimeoutJudge_CAN_AUTOSAR';
            dstT = [TargetModel '/' BlockName]; 
            block_x = targetpos(1) - 655;
            block_y = targetpos(2) - 15;
            block_w = block_x + 250;
            block_h = block_y + 30;
            h = add_block(srcT,dstT,'MakeNameUnique','on');     
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h, 'LinkStatus','inactive','NameLocation','left');
            sourceport = get_param(h,'PortHandles');
            %set_param(sourceport.Outport(1),ShowPropagatedSignals="on"); 
            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(j));
            %set_param(h,ShowPropagatedSignals="on"); 

            delete_line([TargetModel '/' BlockName],'UnitConverter/1','Out/1');
            delete_line([TargetModel '/' BlockName],'UnitConverter/1','Unit Delay/1');
            h = add_line([TargetModel '/' BlockName],'UnitConverter/1','Unit Delay/1','autorouting','on');
            set_param(h,'name', Signalname);
            set(h,'MustResolveToSignalObject',1);
            add_line([TargetModel '/' BlockName],'UnitConverter/1','Out/1','autorouting','on');
            %set_param(sourceport.Outport(1),ShowPropagatedSignals="on");                    
         end

        %% Add from for frame routing raw
        % 
%         if (Cnt == 0) && exist('Detect_frame_routing','var') && ~isempty(Detect_frame_routing)            
%            cnt_routing = cnt_routing + 1; 
%            targetport = get_param([TargetModel '/bus_creator_raw'],'PortHandles');
%            targetpos = get_param(targetport.Inport(cnt_routing),'Position'); 
%            BlockName = 'From';
%            block_x = targetpos(1) - 655;
%            block_y = targetpos(2) - 10;
%            block_w = block_x + 250;
%            block_h = block_y + 20;
%            srcT = 'simulink/Signal Routing/From';
%            dstT = [TargetModel '/' BlockName];   
%            h = add_block(srcT,dstT,'MakeNameUnique','on');     
%            set_param(h,'position',[block_x,block_y,block_w,block_h]);
%            set_param(h,'Gototag',['VHAL_' Channel R_Message '_cnt'],'ShowName', 'off');
%            sourceport = get_param(h,'PortHandles');
%            h = add_line(TargetModel,sourceport.Outport(1),targetport.Inport(cnt_routing));   
%            set_param(h,'name',['VHAL_' Channel R_Message '_cnt']); 
% 
%            cnt_routing = cnt_routing + 1; 
%            targetport = get_param([TargetModel '/bus_creator_raw'],'PortHandles');
%            targetpos = get_param(targetport.Inport(cnt_routing),'Position'); 
%            BlockName = 'From';
%            block_x = targetpos(1) - 655;
%            block_y = targetpos(2) - 10;
%            block_w = block_x + 250;
%            block_h = block_y + 20;
%            srcT = 'simulink/Signal Routing/From';
%            dstT = [TargetModel '/' BlockName];   
%            h = add_block(srcT,dstT,'MakeNameUnique','on');     
%            set_param(h,'position',[block_x,block_y,block_w,block_h]);
%            set_param(h,'Gototag',['VHAL_' Channel R_Message '_raw'],'ShowName', 'off');
%            sourceport = get_param(h,'PortHandles');
%            h = add_line(TargetModel,sourceport.Outport(1),targetport.Inport(cnt_routing));   
%            set_param(h,'name',['VHAL_' Channel R_Message '_raw']);
%         end
% 
%         if cnt_routing == num_routing*2
%             cnt_routing = 0;
%         end        
     end

     % create DD file
     DD_path = [arch_Path '\hal\hal_' lower(Channel)];
     cd(DD_path);
     if isfile(['DD_HAL_' upper(Channel) '.xlsx'])
        delete (['DD_HAL_' upper(Channel) '.xlsx']);
     end
     DD_table = cell2table(DD_cell);
     DD_table.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units' 'Enum table' 'Default before and during POWER-UP' 'Default before and during POWER-DOWN' 'Description' 'TxNodes' 'TxMessagge' 'DataSource' 'Signals valid require' 'Signal process In NewInpProcess require' 'New Signal Name'};
     File_name = ['DD_HAL_' upper(Channel) '.xlsx'];
     DD_table_cal = cell2table(DD_cell2);
     DD_table_cal.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units' 'Enum table' 'Default during Running'};
     
     writetable(DD_table,File_name,'Sheet',1);
     writetable(DD_table_cal,File_name,'Sheet',2);
     
     xlsApp = actxserver('Excel.Application');
     ewb = xlsApp.Workbooks.Open([DD_path '\' File_name]);
     ewb.Worksheets.Item(1).name = 'Signals'; 
     ewb.Worksheets.Item(2).name = 'Calibrations'; 
     ewb.Save();
     ewb.Close(true);
     verctrl = 'FVT_export_businfo_v3.0 2022-09-06';
     disp('running FVT BUS info...');
     buildbus(File_name,DD_path,DD_table,DD_table_cal,verctrl);
     cd(arch_Path);
     disp([Channel ' Done!']);
         
end


end


function Unit_modify = UnitChange(Rx_Signal_unit)

Unit_modify = Rx_Signal_unit;

    switch Rx_Signal_unit
        case {'Percent','Percent0-100%','%','percent (%)','percent^%^'}
            Unit_modify = cellstr('pct');   
        case {'km/h'}
            Unit_modify = cellstr('kph');
        case {'RPM','Rpm'}
             Unit_modify = cellstr('rpm');
        case {'Volt','voltage','Voltage'}
             Unit_modify = cellstr('V');
        case {'KW','kw','k-Watt'}
             Unit_modify = cellstr('kW');
        case {'watt.hour'}
             Unit_modify = cellstr('Wh');
        case {'Watt'}
             Unit_modify = cellstr('W');     
        case {'KWh','kwh'}
             Unit_modify = cellstr('kWh');
        case {'wh/km'}
             Unit_modify = cellstr('Whpkm');
        case {'m/s2','m/s^2','m/s 2','m/s?'}
             Unit_modify = cellstr('mps2');
        case {'m/s^3'}
             Unit_modify = cellstr('mps3');
        case {'m/s'}
             Unit_modify = cellstr('mps');
        case {'kg/m^2'}
             Unit_modify = cellstr('kgpm2');
        case {'Wphr'}
             Unit_modify = cellstr('Wph');
        case {'Amp','Ampere'}
             Unit_modify = cellstr('A');
        case {'degC','DegC','Deg C','Deg^C'}
             Unit_modify = cellstr('C');
        case {'deg/s','Deg/s'}
             Unit_modify = cellstr("degps");
        case {'L/100km'}
             Unit_modify = cellstr("Lp100km");
        case {'S','Sec','SECOND'}
            Unit_modify = cellstr('s');
        case {'HOUR'}
            Unit_modify = cellstr('hr');
        case {'MINUTE'}
            Unit_modify = cellstr('min');
        case {"G's"}
            Unit_modify = cellstr('Gps');
        case {'L/min'}
            Unit_modify = cellstr('Lpmin');
        case {'KM'}
            Unit_modify = cellstr('km');
        case {'cycle','cycle(s)'}
            Unit_modify = cellstr('cyc');
        case {'^'}
            Unit_modify = cellstr('enum');
        case {'m^(-1)','1/meter','1/meter^2'}
            Unit_modify = cellstr('raw32');
    end    
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
    str_m = table2cell(signal_table(i,1)); 
    str_m = char(str_m); 
    str_dir = table2cell(signal_table(i,2)); 
    str_dir = char(str_dir); 
    type = table2cell(signal_table(i,3)); 
    type = char(type);     
    unit = extractAfter(str_m,"_");
    unit = extractAfter(unit,"_");   
    
    min = table2cell(signal_table(i,4)); 
    max = table2cell(signal_table(i,5)); 
    
    internal_flg = strcmp(str_dir,'internal'); 
    outputs_flg = strcmp(str_dir,'output');
    
    if (isempty(type)==0)&&(internal_flg==1)
        num_sig_internal = num_sig_internal +1;
        internal_arry(num_sig_internal,1) = cellstr(str_m); 
        internal_arry(num_sig_internal,2) = cellstr(type);
        internal_arry(num_sig_internal,3) = cellstr(unit);        
        internal_arry(num_sig_internal,4) = (min);       
        internal_arry(num_sig_internal,5) = (max);    
    elseif (isempty(type)==0)&&(outputs_flg==1)
        num_sig_outputs = num_sig_outputs +1; 
        output_arry(num_sig_outputs,1) = cellstr(str_m); 
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
    str_m = table2cell(calibration_table(i,1));
    str_tablechk = extractBefore(str_m,"_"); 
    if (str_tablechk~=string(A_str))&&(str_tablechk~=string(m_str))
    str_m = char(str_m); 
    defval = string(table2cell(calibration_table(i,8)));
        if (ismissing(defval)==1)
            defval = '0';
        end 
    sig = strcat("a2l_cal(","'",str_m,"',","     ", defval,")",";");
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
    str_m = output_arry(i,1) ;
    str_m = string(str_m); 
    type = output_arry(i,2) ;
    type = string(type); 
    sens = strcat("{","'", str_m ,"' ", " ,1, ", " '", type ,"' ", " ,-1" , ", 'real'", " ,'Sample'};...");
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
        str_m = table2cell(calibration_table(i,1)); 
        str_m = string(str_m); 
        unit = table2cell(calibration_table(i,6)); 
        unit = string(unit); 
        type = table2cell(calibration_table(i,3)); 
        type = string(type); 
        max = table2cell(calibration_table(i,5)); 
        max = string(max); 
        min = table2cell(calibration_table(i,4)); 
        min = string(min); 

        sens = strcat("a2l_par('", str_m, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
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
        str_m = string(internal_arry(i,1)); 
        unit = string(internal_arry(i,3));
        type = string(internal_arry(i,2));
        max = string(internal_arry(i,5));
        min = string(internal_arry(i,4));
        sens = strcat("a2l_mon('", str_m, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
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
        str_m = string(output_arry(i,1)); 
        unit = string(output_arry(i,3));
        type = string(output_arry(i,2));
        max = string(output_arry(i,5));
        min = string(output_arry(i,4));
        sens = strcat("a2l_mon('", str_m, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
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

