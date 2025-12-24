function RoutingTableCreate_D31F()
%% Loading excel
q = questdlg({'Check the following conditions:','1. Run project_start?',...
    '2. Current folder arch?'},'Initial check','Yes','No','Yes');
if ~contains(q, 'Yes')
    return
end

arch_Path = pwd;
if ~contains(arch_Path, 'arch'), error('current folder is not under arch'), end
project_path = extractBefore(arch_Path,'\software');

ECU_list = {'FUSION','ZONE_DR','ZONE_FR'};
q = listdlg('PromptString','Select target ECU:','ListString', ECU_list, ...
            'Name', 'Select target ECU', ...
			'ListSize', [250 150],'SelectionMode','single');

if isempty(q), error('No ECU selected'), end
TargetNode = ECU_list(q);

% Select routing table
path = [project_path '\..\common\documents\MessageMap\'];
filenames = dir(path);
filenames = string({filenames.name});
RoutingTableName = char(filenames(contains(filenames,['RoutingTable_' char(TargetNode)])));
passwordFile = 'password.txt';
cd(path)
if isfile(passwordFile)
    password = strtrim(fileread(passwordFile));
else
    password = filenames(contains(filenames,'to@'));
    password = extractBefore(password,'.txt');
end
cd(arch_Path)

xlsAPP = actxserver('excel.application');
xlsAPP.Visible = 1;
xlsWB = xlsAPP.Workbooks;
xlsFile = xlsWB.Open([path RoutingTableName],[],false,[],password);
exlSheet1 = xlsFile.Sheets.Item('RoutingTable');
dat_range = exlSheet1.UsedRange;
raw_data = dat_range.value;
xlsFile.Close(false);
xlsAPP.Quit;

%% Data filter
[data_m , ~] = size(raw_data);
Numb_restore = 0;
Restore_array = cell(1,1);
raw_data(cellfun(@(x) all(ismissing(x)), raw_data)) = {'Invalid'};
raw_data(end+1,:) = {'Invalid'};
for i = 1:data_m
    SignalName = raw_data(i,1);
    Rx_MessageName = raw_data(i,2);
    Tx_MessageName = raw_data(i,5);
    str_s = string(SignalName);
    
    if ~strcmp(raw_data(i,1),'Invalid')
        % Here is use for save parameter from raw_data to Restore_array       
        Array_space = isspace(str_s);
        Numb_space = sum(Array_space);

        if strcmp(SignalName,'Signal Name')
            CAN_chn = extractAfter(raw_data(i-1,1),'source:');
            CAN_chn_res = char(CAN_chn);
            CAN_chn = extractAfter(raw_data(i-1,4),'target:');
            CAN_chn_out = char(erase(CAN_chn,'_'));
        end
        if (Numb_space==0)
            Numb_restore = Numb_restore+1;
            Restore_array(Numb_restore,1) = cellstr(CAN_chn_res);
            Restore_array(Numb_restore,2) = SignalName;

            if ~strcmp(Rx_MessageName,'Invalid')
                Restore_array(Numb_restore,3) = Rx_MessageName;
            else
                Restore_array(Numb_restore,3) = Restore_array(Numb_restore-1,3);
            end

            Restore_array(Numb_restore,4) = cellstr(CAN_chn_out);
            Restore_array(Numb_restore,5) = raw_data(i,4);

            if ~strcmp(Tx_MessageName,'Invalid')
                Restore_array(Numb_restore,6) = Tx_MessageName;
            else
                Restore_array(Numb_restore,6) = Restore_array(Numb_restore-1,6);
            end

            Restore_array(Numb_restore,7) = raw_data(i,10);
        end
    end
end

Restore_array = sortrows(Restore_array,1);
target_channel_array = unique(Restore_array(:,1)); 

% Numb_categty is total CAN channel found in Restore_array
if strcmp(TargetNode,'FUSION')
categty = {'CAN1';'CAN2';'CAN3';'CAN4';'CAN5';'CAN6'};
Numb_categty = length(categty);
elseif strcmp(TargetNode,'ZONE_DR')
categty = {'CAN4';'CANDr1';'LINDr1';'LINDr2';'LINDr3';'LINDr4'};
Numb_categty = length(categty);
elseif strcmp(TargetNode,'ZONE_FR')
categty = {'CAN4';'CANFr1';'LINFr1';'LINFr2'};
Numb_categty = length(categty);
end

%% import INP and HAL excel file here
inp_DD_path = [arch_Path '\inp']; % Choose inp folder (bypass now)
cd (inp_DD_path);
DD_path = inp_DD_path;
% need to creat a table for save values in for loop
Table_sum = table;
Table_sum_hal = table;

for i = 1:Numb_categty
    inp_PathName =[inp_DD_path '\inp_' lower(char(categty(i))) '\'];
    inp_FileName =['DD_INP_' upper(char(categty(i)))];
    Table_DD = readtable([inp_PathName inp_FileName],'sheet','Signals','PreserveVariableNames',true);
    Table_sum = vertcat(Table_sum,Table_DD);
end

hal_DD_path = [arch_Path '\hal'];
cd (hal_DD_path);
for i = 1:Numb_categty
    hal_PathName =[hal_DD_path '\hal_' lower(char(categty(i))) '\'];
    hal_FileName =['\DD_HAL_' upper(char(categty(i)))];
    Table_DD_hal = readtable([hal_PathName hal_FileName],'sheet','Signals','PreserveVariableNames',true);
    Table_sum_hal = vertcat(Table_sum_hal,Table_DD_hal);
end
          
%% for creat a table to "match" signal name
[Table_sum_m, Table_sum_n] = size(Table_sum);
for i = 1:Table_sum_m
    str = string(table2cell(Table_sum(i,1)));
    str_tmp = extractAfter(str,"_");
    str_tmp = extractBefore(str_tmp,"_");
    str_tmp = cellstr(str_tmp);
    Table_sum(i,Table_sum_n+1) = str_tmp;
end

%% Create simulink model
new_model = ['RoutingTable_' datestr(now,30)];
new_system(new_model);
open_system(new_model);
set_param(new_model,'LibraryLinkDisplay','all');
original_x = 0;
original_y = 0;
%%
ModuleName = 'RoutingTable';
srcT = 'built-in/SubSystem';
dstT = [new_model '/' ModuleName];
block_x=original_x;
block_y=original_y;
block_w=original_x+400;
block_h=block_y+Numb_restore*30;
Hal = add_block(srcT,dstT);
set_param(Hal,'position',[block_x,block_y,block_w,block_h],'ContentPreviewEnabled','off');
%%
for i = 1:Numb_categty
    str = ['BINP_' upper(char(categty(i))) '_outputs'];
    Blockname = str;
    srcT2 = 'simulink/Sources/In1';
    dstT = [new_model '/' ModuleName '/' Blockname];
    block_x=original_x;
    block_y=original_y - 500 +50*i;
    block_w=block_x+30;
    block_h=block_y+13;
    Hal = add_block(srcT2,dstT);
    set_param(Hal,'position',[block_x,block_y,block_w,block_h]);
    dstT = [new_model '/' ModuleName '/' Blockname];
    port = get_param(dstT,'PortHandles');
    port_pos  = get_param(port.Outport(1),'position');
    
    Blockname = ['goto_' upper(char(categty(i)))];
    srcT = 'simulink/Signal Routing/Goto';
    dstT = [new_model '/' ModuleName '/' Blockname];
    block_x=port_pos(1)+150;
    block_y=port_pos(2)-15 ;
    block_w=block_x+120;
    block_h=block_y+30;
    Hal = add_block(srcT,dstT);
    set_param(Hal,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag',str);
    
    dstT=[new_model '/' ModuleName];
    H_line=add_line(dstT, [str '/1'],['goto_' upper(char(categty(i))) '/1']);
    set_param(H_line,'name',['<' str '>']);
end

    
%% Select SCP signal source CAN map
Array_DD = table2cell(Table_sum);
Array_ref = Array_DD(:,7);
Numb_out = 0;

for k = 1:length(target_channel_array)   
    target_channel = target_channel_array(k,1);
    idx = strcmp(Restore_array(:,1),target_channel);
    CANSignalRouting_array = Restore_array(idx,:);
    Numb_CANSignalRouting = length(CANSignalRouting_array(:,1));
        
    % read DBC or LIN message map
    cd(arch_Path);
    Channel = char(target_channel);
 
    if contains(Channel,'CAN')
        IsLINMessage = boolean(0);
        path = [project_path '\..\common\documents\MessageMap\']; 
        filenames = dir(path);
        filenames = string({filenames.name});
        FileName = string(filenames(contains(filenames,Channel)));
        FileName = char(FileName(contains(FileName,'.dbc')));
        DBC= canDatabase([path FileName]);
    else
        Filepath = [project_path '\..\common\documents\MessageMap\'];
        filenames = dir(Filepath);
        filenames = string({filenames.name});
        FileName = string(filenames(contains(filenames,Channel)));
        FileName = char(FileName(contains(FileName,'.xlsx')));
        DBC = LinDatabase(Filepath,FileName,Channel,arch_Path);
        IsLINMessage = boolean(1);
    end
%     Channel = erase(Channel, '_');

    %% generate RxMsgTable and define CAN filter
    RxMsgTable = cell(length(DBC.Messages),8);
    MsgCnt = 0;
    SignalCnt = 0;

    for j = 1:length(DBC.Messages)
        if any(strcmp(string(CANSignalRouting_array(:,3)),DBC.MessageInfo(j).Name))

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
            else
                RxMsgTable(j,7) = num2cell(DBC.MessageInfo(j).AttributeInfo(strcmp(DBC.MessageInfo(j).Attributes(:,1),'GenMsgCycleTime')).Value);
                RxMsgTable(j,8) = cellstr('0');
            end
            MsgCnt = MsgCnt + 1;
            
            SignalCnt = SignalCnt + length(DBC.MessageInfo(j).Signals);
        end   
    end
    for j = length(RxMsgTable(:,1)):-1:1
        if cellfun(@isempty,RxMsgTable(j,1))
            RxMsgTable(j,:) = [];
        end
    end
    RxMsgTable = [{'DBCidx','ID/PID(dec)','DLC','MsgName','MsgName_DD','TxNode','MsgCycleTime','LIN Delay time'};RxMsgTable]; 
   
    % Find target signal offset and resolution
    for i = 1:Numb_CANSignalRouting
        target_msg = CANSignalRouting_array(i,3);
        Tx_channel = char(CANSignalRouting_array(i,4));
        Msg_idx = strcmp(RxMsgTable(:,4),target_msg);
        Signal_idx = strcmp(DBC.MessageInfo(cell2mat(RxMsgTable(Msg_idx,strcmp(RxMsgTable(1,:),'DBCidx')))).Signals,char(CANSignalRouting_array(i,2)));
        SignalResolution = DBC.MessageInfo(cell2mat(RxMsgTable(Msg_idx,strcmp(RxMsgTable(1,:),'DBCidx')))).SignalInfo(Signal_idx).Factor;
        SignalOffset = DBC.MessageInfo(cell2mat(RxMsgTable(Msg_idx,strcmp(RxMsgTable(1,:),'DBCidx')))).SignalInfo(Signal_idx).Offset;
        SignalConvert = {num2str(SignalResolution), num2str(SignalOffset)};

        CAN_chn = CANSignalRouting_array(i,1);
        str_in = CANSignalRouting_array(i,2);
    
        str_in = erase(str_in,"_");
    
        strmsg_in = CANSignalRouting_array(i,3);
        str_out = CANSignalRouting_array(i,5);
        strmsg_out = CANSignalRouting_array(i,6);
        ini_val = CANSignalRouting_array(i,7);
        cmp_tmp = string(str_in);
    
        if contains(CAN_chn,'LIN')
            IsLINMessage = boolean(1);
        else
            IsLINMessage = boolean(0);
        end
        % Transfer from CANMsg "Invalid" begging signal to CANMsg "valid".
        if contains(cmp_tmp,'CANMsgInvalid')==0 
            
            rep = find(strcmp(Array_ref,cmp_tmp));
            strend_out = string(Array_DD(rep,1));
            strend_out = extractAfter(strend_out,"_");
            strend_out = extractAfter(strend_out,"_");
            strmsg_in = erase(string(strmsg_in),"_");
            strmsg_out = erase(string(strmsg_out),"_");
            str_out = erase(string(str_out),"_");
            out_tmp = ['VSCP_' Tx_channel char(strmsg_out) char(str_out) '_' char(strend_out)];
            
            if (i~=1)
                Array_tmp = Array_out(1:Numb_out,1);
                rep_tmp = find(strcmp(Array_tmp,out_tmp), 1);
            end
            if (i==1)||isempty(rep_tmp)
                Numb_out = Numb_out+1;
                Array_out(Numb_out,1) = cellstr(out_tmp);
                Array_out(Numb_out,2) = cellstr('output');
                Array_out(Numb_out,3:6) = Array_DD(rep,3:6);
                Array_out(Numb_out,7) = Array_DD(rep,1);
                k_ini = ['KSCP_IniGW' char(str_out) '_' char(strend_out)];
                Array_cal(Numb_out,1) = cellstr(k_ini);
                Array_cal(Numb_out,2) = cellstr('output');
                Array_cal(Numb_out,3:6) = Array_DD(rep,3:6);
                Array_cal(Numb_out,7) = cellstr('N/A');
                Array_cal(Numb_out,8) = num2cell(0);
                
                %creat SWITCH block
                BlockName_sw = ['sw_' num2str(Numb_out)];
                srcT = 'simulink/Signal Routing/Switch';
                dstT = [new_model '/' ModuleName '/' BlockName_sw];
                block_x=original_x+50;
                block_y=original_y+Numb_out*120;
                block_w=block_x+70;
                block_h=block_y+100;
                Hal = add_block(srcT,dstT);
                set_param(Hal,'position',[block_x,block_y,block_w,block_h],'showname','off');
                
                dstT = [new_model '/' ModuleName '/' BlockName_sw];
                port = get_param(dstT,'PortHandles');
                port_pos  = get_param(port.Inport(1),'position');
                
                %creat FROM block
                str = ['BINP_' upper(char(erase(CAN_chn,'_'))) '_outputs'];
                BlockName_From = ['From_' num2str(Numb_out)];
                srcT = 'simulink/Signal Routing/From';
                dstT = [new_model '/' ModuleName '/' BlockName_From];
                block_x=port_pos(1)-450;
                block_y=port_pos(2)-15 ;
                block_w=block_x+120;
                block_h=block_y+30;
                Hal = add_block(srcT,dstT);
                set_param(Hal,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag',str);
                
                %creat BUS SELECT
                str_sig = string(Array_DD(rep,1));
                BlockName_slc_1 = ['slr_' num2str(Numb_out)];
                srcT = 'simulink/Signal Routing/Bus Selector';
                dstT = [new_model '/' ModuleName '/' BlockName_slc_1];
                block_x=port_pos(1)-300;
                block_y=port_pos(2)-10;
                block_w=block_x+5;
                block_h=block_y+20;
                Hal = add_block(srcT,dstT);
                set_param(Hal,'position',[block_x,block_y,block_w,block_h],'showname','off', 'outputsignals',(str_sig));
                
                dstT=[new_model '/' ModuleName];
                add_line(dstT, [BlockName_From '/1'],[BlockName_slc_1 '/1']); %Draw Line from FROM to BUS SELECT
                add_line(dstT, [BlockName_slc_1 '/1'],[BlockName_sw '/1']); %Draw Line from BUS SELECT to SWITCH
                
                dstT = [new_model '/' ModuleName '/' BlockName_sw];
                port = get_param(dstT,'PortHandles');
                port_pos  = get_param(port.Inport(2),'position');
                
                %creat SECOND FROM block
                str = ['BINP_' upper(char(erase(CAN_chn,'_'))) '_outputs'];
                BlockName_From_2 = ['From2_' num2str(Numb_out)];
                srcT = 'simulink/Signal Routing/From';
                dstT = [new_model '/' ModuleName '/' BlockName_From_2];
                block_x=port_pos(1)-450;
                block_y=port_pos(2)-15 ;
                block_w=block_x+120;
                block_h=block_y+30;
                Hal = add_block(srcT,dstT);
                set_param(Hal,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag',str);
                
                %creat BUS SELECT
                if IsLINMessage
                    str_sig = ['VINP_LINMsgValid' char(strmsg_in) '_flg'];
                else
                    str_sig = ['VINP_CANMsgValid' char(strmsg_in) '_flg'];
                end
                BlockName_slc_2 = ['slr2_' num2str(Numb_out)];
                srcT = 'simulink/Signal Routing/Bus Selector';
                dstT = [new_model '/' ModuleName '/' BlockName_slc_2];
                block_x=port_pos(1)-300;
                block_y=port_pos(2)-10;
                block_w=block_x+5;
                block_h=block_y+20;
                Hal = add_block(srcT,dstT);
                set_param(Hal,'position',[block_x,block_y,block_w,block_h],'showname','off', 'outputsignals',(str_sig));
                
                dstT=[new_model '/' ModuleName];
                add_line(dstT, [BlockName_From_2 '/1'],[BlockName_slc_2 '/1']); % Draw LINE from 2nd FROM to BUS SELECT
                add_line(dstT, [BlockName_slc_2 '/1'],[BlockName_sw '/2']);      % Draw LINE from BUS SELECT to SWITCH
                
                dstT = [new_model '/' ModuleName '/' BlockName_sw];
                port = get_param(dstT,'PortHandles');
                port_pos  = get_param(port.Inport(3),'position');
                
                % create CONSTANT block
                BlockName_cons = ['cst_' num2str(Numb_out)];
                block_x=port_pos(1)-450;
                block_y=port_pos(2)-15;
                block_w=block_x+100;
                block_h=block_y+30;
                srcT = 'simulink/Sources/Constant';
                dstT = [new_model '/' ModuleName '/' BlockName_cons];
                h = add_block(srcT,dstT);
                set_param(h,'position',[block_x,block_y,block_w,block_h],'showname','off','value',char(ini_val));
                sourceport = get_param(h,'PortHandles');

                % Create convert_in block for raw value if in need
                if SignalOffset ~=0 || SignalResolution ~= 1
                    BlockName = 'convert_in';
                    block_x = port_pos(1) - 300;
                    block_y = port_pos(2) - 15;
                    block_w = block_x + 100;
                    block_h = block_y + 30;
                    srcT = 'FVT_lib/hal/convert_in';
                    dstT = [new_model '/' ModuleName '/' BlockName];   
                    h = add_block(srcT,dstT,'MakeNameUnique','on');     
                    set_param(h,'position',[block_x,block_y,block_w,block_h]);
                    set_param(h, 'MaskValues', SignalConvert);
                    targetport = get_param(h,'PortHandles');
                    add_line([new_model '/' ModuleName],sourceport.Outport(1),targetport.Inport(1));  
                    sourceport = get_param(h,'PortHandles');
                end
                
                % DATA_TYPE_CONVERT new @ 20220816 by YEE (22079)
                % Create CONVERT block
                BlockName_convert = ['convert' num2str(Numb_out)];
                block_x=port_pos(1)-170;
                block_y=port_pos(2)-15;
                block_w=block_x+100;
                block_h=block_y+30;
                srcT = 'simulink/Signal Attributes/Data Type Conversion';
                dstT = [new_model '/' ModuleName '/' BlockName_convert];
                Convert_1 = add_block(srcT,dstT,'OutDataTypeStr',string(Array_DD(rep,3)));
                targetport = get_param(Convert_1,'PortHandles');

                dstT = [new_model '/' ModuleName];
                set_param(Convert_1,'position',[block_x,block_y,block_w,block_h],'showname','off');
                
                add_line(dstT,sourceport.Outport(1),targetport.Inport(1));   % Draw LINE from constant to DATA_TYPE_CONVERT
                add_line(dstT, [BlockName_convert '/1'],[BlockName_sw '/3']);      % Draw LINE from DATA_TYPE_CONVERT to SWITCH
                
                
                dstT = [new_model '/' ModuleName '/' BlockName_sw];
                port = get_param(dstT,'PortHandles');
                port_pos  = get_param(port.Outport(1),'position');
                
                % create OUTPUT block
                BlockName_out = out_tmp;
                block_x=port_pos(1)+200;
                block_y=port_pos(2)-7.5;
                block_w=block_x+30;
                block_h=block_y+15;
                srcT = 'simulink/Sinks/Out1';
                dstT = [new_model '/' ModuleName '/' BlockName_out];
                add_block(srcT,dstT,'position',[block_x,block_y,block_w,block_h],'name',char(out_tmp));
                
                dstT=[new_model '/' ModuleName];
                H_line=add_line(dstT, [BlockName_sw '/1'],[BlockName_out '/1']);   % Draw LINE from SWITCH to OUTPUT
                set_param(H_line,'name',out_tmp);
                
                % Select RESOLVE SINGAL or not, if resolve than ""set(H_line,'MustResolveToSignalObject',1); ""
                % set(H_line,'MustResolveToSignalObject',1);   (bypass @20220816 for not to reslove signal)
                
            else
                continue;
            end
        else
        end
    end
end
%% Create input signal connect to Routhing table & adjust position
dstT = [new_model '/' ModuleName];

port=get_param(dstT,'PortConnectivity');

for i=1:Numb_categty
    
    str = ['BINP_' upper(char(categty(i))) '_outputs'];
    Blockname = str;
    srcT2 = 'simulink/Sources/In1';
    input_outside=add_block(srcT2,[new_model '/' Blockname]);
    Binp_outport_pos=port(i).Position;
    block_x=Binp_outport_pos(1,1)-150;
    block_y=Binp_outport_pos(1,2)-10 ;
    block_w=block_x+30;
    block_h=block_y+20;
    set_param(input_outside,'position',[block_x,block_y,block_w,block_h]);
    H_line=add_line(new_model,[str '/1'] ,[ModuleName '/' num2str(i)] );
    set_param(H_line,'name',['<' str '>']);
    %     port_pos=set_param(port.Outport,'UseBusObject',{'on'},'BusObject',char(str));
    set_param(input_outside,'UseBusObject','on','BusObject',Blockname,'Name',Blockname);
end
%% Bus Creator
% h = add_block(srcT,'BSCP_outputs','position',[block_x,block_y,block_w,block_h]);
% add_block(srcT,dstT,'name','BSCP_outputs','Inputs',Numb_out);
BlockName_busselect='Bus Creator';
srcT = 'simulink/Signal Routing/Bus Creator';
dstT = [new_model '/' ModuleName ];

port = get_param(dstT,'PortHandles'); 
port_pos  = get_param(port.Outport(1),'position'); 
block_x=original_x + 500;
block_y=port_pos(2)-15;
block_w=block_x+10;
block_h=block_y + +30*length(Restore_array);

dstT = [new_model '/' num2str(1)];
bus_select=add_block(srcT,dstT,'Inputs',string(length(Restore_array)));
set_param(bus_select,'position',[block_x,block_y,block_w,block_h],'name',BlockName_busselect);

for a=1:length(Restore_array)
    dstT = new_model;
    add_line(dstT, [ModuleName '/' num2str(a)] , [BlockName_busselect '/' num2str(a)]);
end

%% output
sourceport = get_param(bus_select,'PortHandles'); 
sourcepos = get_param(sourceport.Outport(1),'position'); 
BlockName_outport='BSCP_outputs';
srcT = 'simulink/Sinks/Out1';
dstT = [new_model '/' BlockName_outport];
outside_output=add_block(srcT,dstT);
block_x = sourcepos(1) + 150;
block_y = sourcepos(2) - 5;
block_w = block_x+30;
block_h = block_y+13;
set_param(outside_output,'position',[block_x,block_y,block_w,block_h]);
% get_param(outside_output, 'Position'); %for know where is the position
dstT = new_model;
H_line=add_line(dstT, ['Bus Creator' '/1'],[BlockName_outport '/1']);   % Draw LINE from SWITCH to OUTPUT

set_param(H_line,'name','BSCP_outputs');
set_param(outside_output,'UseBusObject','on','BusObject',BlockName_outport,'Name',BlockName_outport); %here

%% EXPORT & SAVE result in excel to SCP folder
scp_docs = strfind(DD_path,'\');
scp_dir = DD_path(1:scp_docs(end));
scp_dir =[scp_dir 'app\scp'];
cd (scp_dir)
disp('Writing DD file...');
delete DD_SCP.xlsx
Table_output = cell2table(Array_out);
Table_output.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units' 'Source Signal'};

Table_cal = cell2table(Array_cal);
Table_cal.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units' 'Enum Table' 'Default during Running'};
% File_name=strcat('DD_SCP_',char(date),'.xlsx');
File_name=strcat('DD_SCP.xlsx');

writetable(Table_output,File_name,'Sheet',1);
writetable(Table_cal,File_name,'Sheet',2);

File_pos = [scp_dir '\' File_name];
xlsApp = actxserver('Excel.Application');
ewb = xlsApp.Workbooks.Open(File_pos);
ewb.Worksheets.Item(1).name = 'Signals';
ewb.Worksheets.Item(1).Range('A1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('B1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('C1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('D1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('E1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('F1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('G1').Interior.ColorIndex = 4;
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
disp('Write DD finish');

%%  Select DD file which inside SCP folder, run the Scripts for import scp_cal & scp_val & BSCP_outputs file
% run FVT_export_businfo_modified
% cd(arch_Path);

% create DD file
DD_path = [arch_Path '\app\scp'];
cd(DD_path);
if isfile('DD_SCP.xlsx')
delete ('DD_SCP.xlsx');
end
DD_table = cell2table(Array_out);
DD_table.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units' 'Source Signal'};
File_name = 'DD_SCP.xlsx';
DD_table_cal = cell2table(Array_cal);
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
disp('Done!');
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

function database = LinDatabase(Filepath,FileName,Linchannel,arch_Path)
%% read excel file
project_path = extractBefore(arch_Path,'\software');
cd([project_path '\..\common\documents\MessageMap\']);
filenames = dir;
filenames = string({filenames.name});
password = filenames(contains(filenames,'to@'));
password = extractBefore(password,'.txt');
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
