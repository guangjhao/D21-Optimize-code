function FVT_SWC_Autobuild_D31F(Update_newDID)
arch_Path = pwd;
if ~contains(arch_Path, 'arch'), error('current folder is not under arch'), end
project_path = extractBefore(arch_Path,'\software');
addpath(project_path);
addpath([project_path '/Scripts']);
addpath([project_path '/documents/ARXML_output']);
addpath([project_path '/documents']);

%% Read SWC_FDC.arxml
fileID = fopen('SWC_FDC.arxml');
SWC_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(SWC_arxml{1,1}),1);
for i = 1:length(SWC_arxml{1,1})
    tmpCell{i,1} = SWC_arxml{1,1}{i,1};
end
SWC_arxml = tmpCell;
fclose(fileID);

%% Read CDD.arxml
fileID = fopen('FVT_CDD.arxml');
CDD_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(CDD_arxml{1,1}),1);
for i = 1:length(CDD_arxml{1,1})
    tmpCell{i,1} = CDD_arxml{1,1}{i,1};
end
CDD_arxml = tmpCell;
fclose(fileID);

%% Open SWC_FDC_type.slx
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TargetModel = run_SWC_FDC_RxTx_5ms_sys %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(project_path);
open_system('SWC_FDC_type');
TargetModel = 'SWC_FDC_type/run_SWC_FDC_RxTx_5ms_sys';
open_system(TargetModel);

%% Get SWC message input array
% <DATA-RECEIVE-POINT-BY-ARGUMENTS>
Raw_start = find(contains(SWC_arxml(:,1),'<DATA-RECEIVE-POINT-BY-ARGUMENTS>'),1,"last");
Raw_end = find(contains(SWC_arxml(:,1),'</DATA-RECEIVE-POINT-BY-ARGUMENTS>'),1,"last");

% PORT-PROTOTYPE-REF
h = find(contains(SWC_arxml(Raw_start:Raw_end,1),'<PORT-PROTOTYPE-REF'));
tmpCell1 = extractBetween(SWC_arxml(Raw_start+h-1,1),'SWC_FDC_type/','</PORT-PROTOTYPE-REF>');

% CANx_SG_XXX 
h = find(contains(SWC_arxml(Raw_start:Raw_end,1),'<SHORT-NAME>'));
tmpCell2 = extractBetween(SWC_arxml(Raw_start+h-1,1),'<SHORT-NAME>drparg','</SHORT-NAME>');

% <READ-LOCAL-VARIABLES>
h = find(contains(SWC_arxml(:,1),'<READ-LOCAL-VARIABLES>'));
idx = find(h>Raw_start,1,"first");
Raw_start = h(idx);
h = find(contains(SWC_arxml(:,1),'</READ-LOCAL-VARIABLES>'));
idx = find(h>Raw_start,1,"first");
Raw_end = h(idx);
h = find(contains(SWC_arxml(Raw_start:Raw_end,1),'<VARIABLE-ACCESS>'));
tmpCell3 = extractBetween(SWC_arxml(Raw_start+h,1),'<SHORT-NAME>','</SHORT-NAME>');

% Create CAN message input array
SWC_Input_array = strings(length(tmpCell1)+length(tmpCell3),1);
SWC_Input_array(1:length(tmpCell1)) = string(tmpCell1) + string(tmpCell2) + '_read'; 
SWC_Input_array(length(tmpCell1)+1:end) = string(tmpCell3) + '_read';

% <DATA-RECEIVE-POINT-BY-ARGUMENTS> (Find back Raw_start)
Raw_start = find(contains(SWC_arxml(:,1),'<DATA-RECEIVE-POINT-BY-ARGUMENTS>'),1,"last");

%% Get CAN message output array

% <DATA-RECEIVE-POINT-BY-ARGUMENTS>
h = find(contains(SWC_arxml(:,1),'<DATA-SEND-POINTS>'));
idx = find(h>Raw_start,1,"first");
Raw_start = h(idx);
h = find(contains(SWC_arxml(:,1),'</DATA-SEND-POINTS>'));
idx = find(h>Raw_start,1,"first");
Raw_end = h(idx);

% P_CANx_FD_xxx_CANx_SG_FD_xxx_write
% PORT-PROTOTYPE-REF
h = find(contains(SWC_arxml(Raw_start:Raw_end,1),'<PORT-PROTOTYPE-REF'));
tmpCell1 = extractBetween(SWC_arxml(Raw_start+h-1,1),'SWC_FDC_type/','</PORT-PROTOTYPE-REF>');

% CANx_SG_XXX 
h = find(contains(SWC_arxml(Raw_start:Raw_end,1),'<SHORT-NAME>'));
tmpCell2 = extractBetween(SWC_arxml(Raw_start+h-1,1),'<SHORT-NAME>dsp','</SHORT-NAME>');

% IRV_CANx_SG_FD_xxx_write
% <WRITTEN-LOCAL-VARIABLES>
h = find(contains(SWC_arxml(:,1),'<WRITTEN-LOCAL-VARIABLES>'));
idx = find(h>Raw_start,1,"first");
Raw_start = h(idx);
h = find(contains(SWC_arxml(:,1),'</WRITTEN-LOCAL-VARIABLES>'));
idx = find(h>Raw_start,1,"first");
Raw_end = h(idx);

% IRV_CANx_SG_FD_xxx_write 
h = find(contains(SWC_arxml(Raw_start:Raw_end,1),'<SHORT-NAME>'));
tmpCell3 = extractBetween(SWC_arxml(Raw_start+h-1,1),'<SHORT-NAME>','</SHORT-NAME>');

% Create CAN message output array
SWC_Output_array = strings(length(tmpCell1)+length(tmpCell3),1);
SWC_Output_array(1:length(tmpCell1)) = string(tmpCell1) + string(tmpCell2) + '_write';
SWC_Output_array(length(tmpCell1)+1:end) = string(tmpCell3) + '_write';
SWC_Output_array = cellstr(SWC_Output_array);

%% Get CDD function
% <CLIENT-SERVER-OPERATION>
h = find(contains(CDD_arxml(:,1),'CSOP_'));
tmpCell = extractBetween(CDD_arxml(h,1),'<SHORT-NAME>','</SHORT-NAME>');

%% Get Runnables 
% <CLIENT-SERVER-OPERATION>
h = find(contains(SWC_arxml(:,1),'<RUNNABLE-ENTITY>'));
RUNNABLE_array = extractBetween(SWC_arxml(h+1,1),'<SHORT-NAME>','</SHORT-NAME>');

%% Modify Terminator/Ground/out block
BlockList = find_system(TargetModel,'SearchDepth','1');
Function_x = 1865;
Function_y = - 1010;
Function_w = 100;
Function_h = 100; 
back_x = 3000;
Outputport_array = SWC_Output_array;

% Call Modify_Terminator_Ground_out_block fuction
Modify_Terminator_Ground_out_block(BlockList,Function_x,Function_y,Function_w,Function_h,back_x,Outputport_array);

%% Set SWC Rx Inport postion again and create input 
% Sort Inport
idx = 0;
idy = 0;
for i = 1:length(SWC_Input_array)
    if ~startsWith(SWC_Input_array(i),'R_CAN')... 
        && ~startsWith(SWC_Input_array(i),'IRV_CAN')...
		&& ~startsWith(SWC_Input_array(i),'IRV_E2E_CAN')
        idx = idx + 1;
        Else_Input_array(idx,1) = SWC_Input_array(i);
    else
        idy = idy + 1;
        CAN_Msg_Input_array(idy,1) = SWC_Input_array(i);
    end
end

% Set CAN Msg Rx port position
for i = 2:length(CAN_Msg_Input_array)
    targetpos = get_param([TargetModel '/' char(CAN_Msg_Input_array(i-1))],'Position');
    block_x = targetpos(1);
    block_y = targetpos(2) + 40;
    block_w = targetpos(3);
    block_h = block_y + 14 ;
    set_param([TargetModel '/' char(CAN_Msg_Input_array(i))],'Position',[block_x,block_y,block_w,block_h]);
end

% Set else Rx port position
for i = 1:length(Else_Input_array)
    if i == 1 
    targetpos = get_param([TargetModel '/' char(CAN_Msg_Input_array(end))],'Position');
    block_x = targetpos(1);
    block_y = targetpos(2) + 500;
    block_w = targetpos(3);
    block_h = block_y + 14 ;
    else
    targetpos = get_param([TargetModel '/' char(Else_Input_array(i-1))],'Position');
    block_x = targetpos(1);
    block_y = targetpos(2) + 40;
    block_w = targetpos(3);
    block_h = block_y + 14 ;
    end
    set_param([TargetModel '/' char(Else_Input_array(i))],'Position',[block_x,block_y,block_w,block_h]);
    % Add Goto for else input port
    targetport = get_param([TargetModel '/' char(Else_Input_array(i))],'PortHandles');
    targetpos = get_param(targetport.Outport(1),'Position');
    BlockName = 'Goto';
    block_x = targetpos(1) + 200;
    block_y = targetpos(2) - 15;
    block_w = block_x + 240;
    block_h = block_y + 30;
    srcT = 'simulink/Signal Routing/Goto';
    dstT = [TargetModel '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'Gototag',char(extractBetween(Else_Input_array(i),'IRV_','_read')),'ShowName', 'off');
    sourceport = targetport;
    targetport = get_param(h,'PortHandles');
    add_line(TargetModel, sourceport.Outport(1), targetport.Inport(1));
    targetpos = get_param([TargetModel '/' char(Else_Input_array(i))],'Position');
end

%% Set SWC Tx outport postion again and create input 
% Arrange outport 
idx = 0;
idy = 0;
for i = 1:length(SWC_Output_array)
    if ~startsWith(SWC_Output_array(i),'P_CAN')... 
        && ~startsWith(SWC_Output_array(i),'IRV_ms')... 
        && ~contains(SWC_Output_array(i),'0_CAN')...
		&& ~startsWith(SWC_Output_array(i),'IRV_E2E_CAN')
        idx = idx + 1;
        Else_Output_array(idx,1) = SWC_Output_array(i);
    else
        idy = idy + 1;
        CAN_Msg_Output_array(idy,1) = SWC_Output_array(i);
    end
end

% Set CAN Msg Tx port position
for i = 2:length(CAN_Msg_Output_array)
    targetpos = get_param([TargetModel '/' char(CAN_Msg_Output_array(i-1))],'Position');
    block_x = targetpos(1);
    block_y = targetpos(2) + 40;
    block_w = targetpos(3);
    block_h = block_y + 14 ;
    set_param([TargetModel '/' char(CAN_Msg_Output_array(i))],'Position',[block_x,block_y,block_w,block_h]);
end

% Add Goto for "Halout" else Tx port
ElseOutport_array = {'VOUTP_NetworkReq_flg';'VOUTP_SysPowerMode_enum';'VOUTP_NvWriteReqRisingEdge_flg';...
                    'VOUTP_FdcSlpReqRisingEdge_flg';'VOUTP_FdcSlpTime_sec';'VOUTP_IVIRST_flg';...
                    'E2E_CAN3_VCU1_Trigger';'E2E_CAN3_VCU1_toNIDEC_Trigger';'E2E_CAN4_VCU1_Trigger'};

for i =1:length(ElseOutport_array)
    if i == 1
    targetpos = get_param([TargetModel '/' char(CAN_Msg_Output_array(end))],'Position');
    block_x = targetpos(1);
    block_y = targetpos(2) + 30;
    block_w = block_x + 240;
    block_h = block_y + 30;
    else
    block_x = targetpos(1);
    block_y = targetpos(2) + 40;
    block_w = block_x + 240;
    block_h = block_y + 30;
    end
    BlockName = 'Goto';
    srcT = 'simulink/Signal Routing/Goto';
    dstT = [TargetModel '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'Gototag',char(ElseOutport_array(i)),'ShowName', 'off');
    targetpos = get_param(h,'Position');
end

% Set else Tx port position
for i = 1:length(Else_Output_array)
    if i == 1 
    targetpos = get_param([TargetModel '/' char(CAN_Msg_Output_array(end))],'Position');
    block_x = targetpos(1);
    block_y = targetpos(2) + 800;
    block_w = targetpos(3);
    block_h = block_y + 14 ;
    else
    targetpos = get_param([TargetModel '/' char(Else_Output_array(i-1))],'Position');
    block_x = targetpos(1);
    block_y = targetpos(2) + 40;
    block_w = targetpos(3);
    block_h = block_y + 14 ;
    end
    set_param([TargetModel '/' char(Else_Output_array(i))],'Position',[block_x,block_y,block_w,block_h]);
    % Add Goto for else input port
    targetport = get_param([TargetModel '/' char(Else_Output_array(i))],'PortHandles');
    targetpos = get_param(targetport.Inport(1),'Position');
    BlockName = 'From';
    block_x = targetpos(1) - 500;
    block_y = targetpos(2) - 15;
    block_w = block_x + 240;
    block_h = block_y + 30;
    srcT = 'simulink/Signal Routing/From';
    dstT = [TargetModel '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'Gototag',char(extractBetween(Else_Output_array(i),'IRV_','_write')),'ShowName', 'off');
    sourceport = get_param(h,'PortHandles');
    add_line(TargetModel, sourceport.Outport(1), targetport.Inport(1));
end

%% Set CDD FunctionCaller block
% Find CDD FunctionCaller block
CDD_BlockList = find_system(TargetModel,'SearchDepth','1','BlockType','FunctionCaller');
CDD_cell = {};
for i = 1:length(CDD_BlockList)
    BlockName = char(get_param(CDD_BlockList(i),'Name'));  
    Blockpos = get_param([TargetModel '/' BlockName],'position');
    CDD_cell(i,1) = {BlockName}; 
    CDD_cell(i,2) = {Blockpos(1)};
    CDD_cell(i,3) = {Blockpos(2)};
    CDD_cell(i,4) = {Blockpos(3)};
    CDD_cell(i,5) = {Blockpos(4)};
end

% Set HALINCDD Info & position 
% find First HALINCDD FunctionCaller on the top
CDD_cell = sortrows(CDD_cell,3);
HALIN_CDD_Info = {'CDD_Name','Input_Name','Output_Name';
                  'R_HALINCDD_CSOP_AnyNmID','','AnyNMID';...
                  'R_HALINCDD_CSOP_DIDgetDKCdata',{'DIDVCUKeyLength';'DID_VCUKey'},{'VHAL_DIDVCUKeyReadSta_flg';'VHAL_GetDIDVCUKey_enum'};...
                  'R_HALINCDD_CSOP_DIDgetXWDdata',{'uint16(ONE_INT)';'DID_XWD'},{'VHAL_DidXWDSta_flg';'VHAL_DidXWDData_enum'};...
                  'R_HALINCDD_CSOP_DKCDecrypt','','';...
                  'R_HALINCDD_CSOP_GetAcoreReadyToSleep','','VHAL_AcoreReadyToSlp_flg';...
                  'R_HALINCDD_CSOP_GetAuxBattVoltage','','';...
                  'R_HALINCDD_CSOP_GetBootReason','','';...
                  'R_HALINCDD_CSOP_GetEvccAplusPwrUpReq','','';...
                  'R_HALINCDD_u8Array4_HWID','','';...
                  'R_HALINCDD_CSOP_GetNvmProtectState','','';...
                  'R_HALINCDD_CSOP_GetNmState','','CurrentNMState';...
                  'R_HALINCDD_CSOP_GetSWID','','u8_SWID_30byte';...
                  'R_HALINCDD_CSOP_GetVinpAllowMoveThdOta','','VHAL_AllowMovThd_OTA_enum';...
                  'R_HALINCDD_CSOP_GetVinpPwrReqOta','','VHAL_PwrReq_OTA_enum';...
                  'R_HALINCDD_CSOP_GetWISR','','';...
                  'R_HALINCDD_CSOP_HALINCDD_DIRECT','',{'BrakeSW';'BrakeLamp';'Pedal1Vol';'Pedal2Vol'};...
                  'R_UDSCDD_CSOP_DdmClearDTCNotification','','';...
                  'R_HALIN_IMU_CSOP_IMUGetSixAxisVal','','';...
                  'R_HALIN_APS_CSOP_ApsGetData','','';...
                  'R_HALINCDD_CSOP_GetAcoreRebootCmd','','';...
                  'R_HALINCDD_CSOP_CAN1BusOff','','';...
                  'R_HALINCDD_CSOP_CAN2BusOff','','';...
                  'R_HALINCDD_CSOP_CAN3BusOff','','';...
                  'R_HALINCDD_CSOP_CAN4BusOff','','';...
                  'R_HALINCDD_CSOP_CAN5BusOff','','';
                  };

% Find CDD FunctionCaller block
CDD_BlockList = find_system(TargetModel,'SearchDepth','1','BlockType','FunctionCaller');
HALIN_CDD_cell = {};
HALIN_CDD_unknow_cell = {};
cnt = 0;
cnt2 = 0;
for i = 1:length(CDD_BlockList)
    BlockName = char(get_param(CDD_BlockList(i),'Name'));  
    if any(strcmp(HALIN_CDD_Info(2:end,1),BlockName))
    cnt = cnt +1;    
    Blockpos = get_param([TargetModel '/' BlockName],'position');
    HALIN_CDD_cell(cnt,1) = {BlockName}; 
    HALIN_CDD_cell(cnt,2) = {Blockpos(1)};
    HALIN_CDD_cell(cnt,3) = {Blockpos(2)};
    HALIN_CDD_cell(cnt,4) = {Blockpos(3)};
    HALIN_CDD_cell(cnt,5) = {Blockpos(4)};
    end
end

for i = 1:length(CDD_BlockList)
    BlockName = char(get_param(CDD_BlockList(i),'Name'));  
    if ~any(strcmp(HALIN_CDD_Info(2:end,1),BlockName)) && contains(BlockName,'HALIN') && strcmp(BlockName,'R_HALIN_IMU_CSOP_IMUGetSixAxisVal')
    cnt = cnt +1;    
    Blockpos = get_param([TargetModel '/' BlockName],'position');
    HALIN_CDD_cell(cnt,1) = {BlockName}; 
    HALIN_CDD_cell(cnt,2) = {Blockpos(1)};
    HALIN_CDD_cell(cnt,3) = {Blockpos(2)};
    HALIN_CDD_cell(cnt,4) = {Blockpos(3)};
    HALIN_CDD_cell(cnt,5) = {Blockpos(4)};
    end
end

for i = 1:length(HALIN_CDD_cell)
    CDDModel = char(HALIN_CDD_cell(i,1)); 
    block_x = cell2mat(HALIN_CDD_cell(1,2));
    if i == 1
    targetpos = get_param([TargetModel '/' char(Else_Input_array(end))],'Position');    
    block_y = targetpos(2) + 200;
    else
    lastblock = get_param([TargetModel '/' char(HALIN_CDD_cell(i-1,1))],'Position');   
    lastblock_y = lastblock(4);
    block_y = lastblock_y + 30;
    end
    block_w = block_x + 700;
    block_h = block_y + 120;
    targetport = get_param([TargetModel '/' CDDModel],'PortHandles');
    if length(targetport.Outport)>2
    block_h = block_h + 30*length(targetport.Outport);
    end
    set_param([TargetModel '/' char(HALIN_CDD_cell(i,1))],'position',[block_x,block_y,block_w,block_h]);
    
    % Conncet HALINCDD Inport
    idx = strcmp(string(HALIN_CDD_Info(:,1)),CDDModel);
    if any(idx)
        if ~isempty(HALIN_CDD_Info{idx,2})
        Inputport_Num = length(string(HALIN_CDD_Info{idx,2}));
        Intputport_array = (string(HALIN_CDD_Info{idx,2}));
            for k = 1:Inputport_Num
                CDD_Input_Name = char(Intputport_array(k));
                targetport = get_param([TargetModel '/' CDDModel],'PortHandles');
                targetpos = get_param(targetport.Inport(k),'Position');
                BlockName = 'Constant';
                block_x = targetpos(1) - 300;
                block_y = targetpos(2) - 20;
                block_w = block_x + 220;
                block_h = block_y + 40;
                srcT = 'simulink/Commonly Used Blocks/Constant';
                dstT = [TargetModel '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Value',CDD_Input_Name,'ShowName', 'off');
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel, sourceport.Outport(1),targetport.Inport(k));
            end
        end
    end

    % Conncet HALINCDD outport
    CDD_port_info = get_param([TargetModel '/' CDDModel],'PortHandles');
    FunctionPrototype = string(get_param([TargetModel '/' CDDModel],'FunctionPrototype'));

    % Get CDD Output name for connect
    if length(CDD_port_info.Outport)==1
    CDD_output_array = extractBefore(FunctionPrototype,' = ');
    elseif length(CDD_port_info.Outport)>1
    CDD_output_array = extractBetween(FunctionPrototype,'[',']');
    else
    CDD_output_array = [];    
    end

    if ~isempty(CDD_output_array)
        idx  = strfind(CDD_output_array,',');
        
        % 1 by 1
        for k = 1:length(idx)+1
            if idx >= 1
                if k==1
                    Output_Name = extractBefore(CDD_output_array,idx(k));
                elseif k == length(idx)+1
                    Output_Name = extractAfter(CDD_output_array,idx(k-1));
                else
                    Output_Name = extractBetween(CDD_output_array,idx(k-1)+1,idx(k)-1);
                end
            else
                Output_Name = CDD_output_array;
            end

            targetport = get_param([TargetModel '/' CDDModel],'PortHandles');
            targetpos = get_param(targetport.Outport(k),'Position');
            BlockName = 'Goto';
            block_x = targetpos(1) + 100;
            block_y = targetpos(2)-15;
            block_w = block_x + 240;
            block_h = block_y + 30;
            srcT = 'simulink/Signal Routing/Goto';
            dstT = [TargetModel '/' BlockName];
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h,'Gototag',Output_Name,'ShowName', 'off');
            sourceport = targetport;
            targetport = get_param(h,'PortHandles');
            add_line(TargetModel, sourceport.Outport(k),targetport.Inport(1));
        end
    end
end

% Set HALOUTCDD position
idx = ~contains(string(CDD_cell(:,1)),{'HALINCDD';'R_UDSCDD_CSOP_DdmClearDTCNotification';'R_HALIN_IMU_CSOP_IMUGetSixAxisVal';'R_HALIN_APS_CSOP_ApsGetData';'R_HALIN_IMU_CSOP_IMUGetOffsetVal';'R_HALOUT_APS_CSOP_ApsSetTimeout';'R_HALOUT_APS_CSOP_ApsSetData'});
HALOUT_CDD_cell = CDD_cell(idx,:);

for i = 1:length(HALOUT_CDD_cell)
    CDDModel = [TargetModel '/' char(HALOUT_CDD_cell(i,1))];
    if i == 1 
    targetpos = get_param([TargetModel '/' char(HALIN_CDD_cell(1,1))],'Position');
    block_x = targetpos(1) + 6500;
    block_y = targetpos(2);
    else
    lastblock = get_param([TargetModel '/' char(HALOUT_CDD_cell(i-1,1))],'Position');   
    lastblock_y = lastblock(4);
    block_y = lastblock_y + 30; 
    block_x = lastblock(1);
    end
    block_w = block_x + 700;
    block_h = block_y + 120;
    targetport = get_param(CDDModel,'PortHandles');
    if length(targetport.Inport)>2
    block_h = block_h + 30*length(targetport.Inport);
    end
    set_param(CDDModel,'position',[block_x,block_y,block_w,block_h]);
end

% Set R_HALOUT_APS position
idx = contains(string(CDD_cell(:,1)),'R_HALOUT_APS');
HALOUT_APS_cell = CDD_cell(idx,:);
for i = 1:length(HALOUT_APS_cell(:,1))
    CDDModel = [TargetModel '/' char(HALOUT_APS_cell(i,1))];
    if i == 1 
    targetpos = get_param([TargetModel '/' char(HALOUT_CDD_cell(1,1))],'Position');
    block_x = targetpos(1) + 1500;
    block_y = targetpos(2);
    else
    lastblock = get_param([TargetModel '/' char(HALOUT_APS_cell(i-1,1))],'Position');   
    lastblock_x = lastblock(1);
    block_x = lastblock_x + 1500;
    block_y = lastblock(2); 
    end
    block_w = block_x + 700;
    block_h = block_y + 120;
    targetport = get_param(CDDModel,'PortHandles');
    if length(targetport.Inport)>2
    block_h = block_h + 30*length(targetport.Inport);
    end
    set_param(CDDModel,'position',[block_x,block_y,block_w,block_h]);
end

%% Set Input/Position/Subsystem of HALOUT CDD & else Function block 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% run_SWC_FDC_RxTx_5ms_sys Level      %%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Create SubSystem for each CDD block %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% R_HALOUTCDD_CSOP_AppNmStateReq
CDDModel = 'R_HALOUTCDD_CSOP_AppNmStateReq';
h = get_param([TargetModel '/' CDDModel],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
h = get_param([TargetModel '/Subsystem'],'Handle');
set_param(h,'Name',CDDModel);

% R_NVMReadCDD_Inner_NVM_ReadOperation
CDDModel = 'R_NVMReadCDD_Inner_NVM_ReadOperation';
h = get_param([TargetModel '/' CDDModel],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
h = get_param([TargetModel '/Subsystem'],'Handle');
P = get_param([TargetModel '/' char(SWC_Input_array(1))],'Position');
block_x = P(1) - 1200;
block_y = P(2);
block_w = block_x + 700;
block_h = block_y + 120;
set_param(h,'Name',CDDModel,'Position',[block_x,block_y,block_w,block_h]);

% R_WDGCDD_CSOP_Call_Watchdog
CDDModel = 'R_WDGCDD_CSOP_Call_Watchdog';
h = get_param([TargetModel '/' CDDModel],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
h = get_param([TargetModel '/Subsystem'],'Handle');
block_y = block_y + 500;
block_w = block_x + 700;
block_h = block_y + 120;
set_param(h,'Name',CDDModel,'Position',[block_x,block_y,block_w,block_h]);

% R_HALIN_IMU_CSOP_IMUGetOffsetVal
CDDModel = 'R_HALIN_IMU_CSOP_IMUGetOffsetVal';
h = get_param([TargetModel '/' CDDModel],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
h = get_param([TargetModel '/Subsystem'],'Handle');
block_y = block_y + 500;
block_w = block_x + 700;
block_h = block_y + 120;
set_param(h,'Name',CDDModel,'Position',[block_x,block_y,block_w,block_h]);

% R_WDGCDD_CSOP_Call_WDG_AppStart
CDDModel = 'R_WDGCDD_CSOP_Call_WDG_AppStart';
h = get_param([TargetModel '/' CDDModel],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
h = get_param([TargetModel '/Subsystem'],'Handle');
block_x = block_x  -1500;
block_w = block_x + 700;
block_h = block_y + 120;
set_param(h,'Name',CDDModel,'Position',[block_x,block_y,block_w,block_h]);

% R_HALOUTCDD_CSOP_SleepRequest
CDDModel = 'R_HALOUTCDD_CSOP_SleepRequest';
h = get_param([TargetModel '/' CDDModel],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
h = get_param([TargetModel '/Subsystem'],'Handle');
set_param(h,'Name',CDDModel);

% R_WDGCDD_CSOP_Call_WDG_AppEnd
CDDModel = 'R_WDGCDD_CSOP_Call_WDG_AppEnd';
h = get_param([TargetModel '/' CDDModel],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
h = get_param([TargetModel '/Subsystem'],'Handle');
set_param(h,'Name',CDDModel);

% R_FDCCDD_Inner_CSOP_FDC_AppCallSleep
CDDModel = 'R_FDCCDD_Inner_CSOP_FDC_AppCallSleep';
h = get_param([TargetModel '/' CDDModel],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
h = get_param([TargetModel '/Subsystem'],'Handle');
set_param(h,'Name',CDDModel);

% R_UDSCDD_CSOP_SetDTCStatus
CDDModel = 'R_UDSCDD_CSOP_SetDTCStatus';
h = get_param([TargetModel '/' CDDModel],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
h = get_param([TargetModel '/Subsystem'],'Handle');
set_param(h,'Name',CDDModel);

% R_UDSCDD_CSOP_DdmRestartOperationCycle
CDDModel = 'R_UDSCDD_CSOP_DdmRestartOperationCycle';
h = get_param([TargetModel '/' CDDModel],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
h = get_param([TargetModel '/Subsystem'],'Handle');
set_param(h,'Name',CDDModel);

% R_HALOUTCDD_CSOP_SetAcoreRebootCmdACK
CDDModel = 'R_HALOUTCDD_CSOP_SetAcoreRebootCmdACK';
h = get_param([TargetModel '/' CDDModel],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
h = get_param([TargetModel '/Subsystem'],'Handle');
set_param(h,'Name',CDDModel);

% R_HALIN_IMU_CSOP_IMUSetSta
CDDModel = 'R_HALIN_IMU_CSOP_IMUSetSta';
h = get_param([TargetModel '/' CDDModel],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
h = get_param([TargetModel '/Subsystem'],'Handle');
set_param(h,'Name',CDDModel);

% R_E2E_CAN3_VCU1_CSOP_Write_CAN3_VCU1
% R_E2E_CAN3_VCU1_CSOP_Write_CAN3_VCU1_toNIDEC
% R_E2E_CAN4_VCU1_CSOP_Write_CAN4_VCU1
CDDModel = {'R_E2E_CAN3_VCU1_CSOP_Write_CAN3_VCU1';'R_E2E_CAN3_VCU1_toNIDEC_CSOP_Write_CAN3_VCU1_toNIDEC';'R_E2E_CAN4_VCU1_CSOP_Write_CAN4_VCU1'};
h(1) = get_param([TargetModel '/' char(CDDModel(1))],'Handle');
h(2) = get_param([TargetModel '/' char(CDDModel(2))],'Handle');
h(3) = get_param([TargetModel '/' char(CDDModel(3))],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
Simulink.BlockDiagram.createSubsystem(h(1));
Simulink.BlockDiagram.createSubsystem(h(2));
Simulink.BlockDiagram.createSubsystem(h(3));
h = get_param([TargetModel '/Subsystem/Subsystem'],'Handle');
set_param(h,'Name',char(CDDModel(1)));
h = get_param([TargetModel '/Subsystem/Subsystem1'],'Handle');
set_param(h,'Name',char(CDDModel(2)));
h = get_param([TargetModel '/Subsystem/Subsystem2'],'Handle');
set_param(h,'Name',char(CDDModel(3)));
h = get_param([TargetModel '/Subsystem'],'Handle');
P = get_param([TargetModel '/' char(SWC_Output_array(1))],'Position');
block_x = P(1) + 1000;
block_y = P(2);
block_w = block_x + 700;
block_h = block_y + 120;
set_param(h,'Name','HALOUT_AFTER','Position',[block_x,block_y,block_w,block_h]);

% R_NVMWriteCDD_Inner_NVM_WriteOperation
CDDModel = 'R_NVMWriteCDD_Inner_NVM_WriteOperation';
h = get_param([TargetModel '/' CDDModel],'Handle');
Simulink.BlockDiagram.createSubsystem(h);
h = get_param([TargetModel '/Subsystem'],'Handle');
set_param(h,'Name',CDDModel);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Each CDD SubSystem Level         %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Create trigger & Input port name %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

HALOUT_CDD_Info = {'CDD_Name','Inputport_Name','Input_Name','Trigger_Name';...
                   'R_HALOUTCDD_CSOP_AppNmStateReq',{'WakeReq';'SleepReq'},{'VOUTP_NetworkReq_flg/uint8';'VOUTP_NetworkReq_flg/NOT/uint8'},'VOUTP_NetworkReq_flg/DetectChange';...
                   'R_NVMWriteCDD_Inner_NVM_WriteOperation','','','VOUTP_NvWriteReqRisingEdge_flg';...
                   'R_HALOUTCDD_CSOP_IVIReset','','VOUTP_IVIRST_flg/uint8','';
                   'R_HALOUTCDD_CSOP_SetSysPwrStat','','VOUTP_SysPowerMode_enum/uint8','';...
                   'R_HALOUTCDD_CSOP_SleepRequest',{'SleepState';'WakeUpTime'},{'Ground';'VOUTP_FdcSlpTime_sec/uint32'},'VOUTP_FdcSlpReqRisingEdge_flg';...
                   'R_WDGCDD_CSOP_Call_WDG_AppEnd','','','VOUTP_FdcSlpReqRisingEdge_flg/UnitDelay';...
                   'R_FDCCDD_Inner_CSOP_FDC_AppCallSleep','','','VOUTP_FdcSlpReqRisingEdge_flg/UnitDelay/UnitDelay';...
                   'R_UDSCDD_CSOP_SetDTCStatus',{'Header_Array';'DTC_Array'},{'Header_Array';'DTC_Array'},'DTC_Trigger';...
                   'R_UDSCDD_CSOP_DdmRestartOperationCycle','','','';...
                   'R_HALIN_IMU_CSOP_IMUSetSta','u8_IMUEnaCmd','','';...
                   'R_HALOUTCDD_CSOP_SetAcoreRebootCmdACK','','','';...
                   'HALOUT_AFTER',{'E2E_CAN3_VCU1_Trigger';'E2E_CAN3_VCU1_Trigger_toNIDEC';'E2E_CAN4_VCU1_Trigger'},{'E2E_CAN3_VCU1_Trigger';'E2E_CAN3_VCU1_toNIDEC_Trigger';'E2E_CAN4_VCU1_Trigger'},'trig_HAL_OUTAFTER_50_1';...
                   'R_NVMReadCDD_Inner_NVM_ReadOperation','','','trig_Read_NVM_00';...
                   'R_WDGCDD_CSOP_Call_Watchdog','','','trig_WDG';...
                   'R_WDGCDD_CSOP_Call_WDG_AppStart','','','TRUE/DetectIncrease';...
                   'R_HALIN_IMU_CSOP_IMUGetOffsetVal','','','trig_ReadIMUOffset_00'};
  
% R_HALOUTCDD_CSOP_AppNmStateReq
CDDModel = 'R_HALOUTCDD_CSOP_AppNmStateReq';
BlockName = 'Enable';
srcT = 'simulink/Ports & Subsystems/Enable';
dstT = [TargetModel '/' CDDModel '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);

Inputport_Origin_array = find_system([TargetModel '/' CDDModel],'regexp','on','blocktype','port');
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Inputport_Num = length(string(HALOUT_CDD_Info{idx,2}));
Intputport_array = (string(HALOUT_CDD_Info{idx,2}));
for k = 1:Inputport_Num
    set_param(char(Inputport_Origin_array(k)),'Name',Intputport_array(k));
end

% R_WDGCDD_CSOP_Call_WDG_AppEnd
CDDModel = 'R_WDGCDD_CSOP_Call_WDG_AppEnd';
BlockName = 'Enable';
srcT = 'simulink/Ports & Subsystems/Enable';
dstT = [TargetModel '/' CDDModel '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);

% R_FDCCDD_Inner_CSOP_FDC_AppCallSleep
CDDModel = 'R_FDCCDD_Inner_CSOP_FDC_AppCallSleep';
BlockName = 'Enable';
srcT = 'simulink/Ports & Subsystems/Enable';
dstT = [TargetModel '/' CDDModel '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);

% R_HALOUTCDD_CSOP_SleepRequest
CDDModel = 'R_HALOUTCDD_CSOP_SleepRequest';
BlockName = 'Enable';
srcT = 'simulink/Ports & Subsystems/Enable';
dstT = [TargetModel '/' CDDModel '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);

Inputport_Origin_array = find_system([TargetModel '/' CDDModel],'regexp','on','blocktype','port');
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Inputport_Num = length(string(HALOUT_CDD_Info{idx,2}));
Intputport_array = (string(HALOUT_CDD_Info{idx,2}));
for k = 1:Inputport_Num
    set_param(char(Inputport_Origin_array(k)),'Name',Intputport_array(k));
end

% R_UDSCDD_CSOP_DdmRestartOperationCycle
CDDModel = 'R_UDSCDD_CSOP_DdmRestartOperationCycle';
BlockName = 'Enable';
srcT = 'simulink/Ports & Subsystems/Enable';
dstT = [TargetModel '/' CDDModel '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);

% R_UDSCDD_CSOP_SetDTCStatus
CDDModel = 'R_UDSCDD_CSOP_SetDTCStatus';
BlockName = 'Enable';
srcT = 'simulink/Ports & Subsystems/Enable';
dstT = [TargetModel '/' CDDModel '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);

Inputport_Origin_array = find_system([TargetModel '/' CDDModel],'regexp','on','blocktype','port');
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Inputport_Num = length(string(HALOUT_CDD_Info{idx,2}));
Intputport_array = (string(HALOUT_CDD_Info{idx,2}));
for k = 1:Inputport_Num
    set_param(char(Inputport_Origin_array(k)),'Name',Intputport_array(k));
end

% R_HALIN_IMU_CSOP_IMUSetSta
CDDModel = 'R_HALIN_IMU_CSOP_IMUSetSta';
BlockName = 'Enable';
srcT = 'simulink/Ports & Subsystems/Enable';
dstT = [TargetModel '/' CDDModel '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);

Inputport_Origin_array = find_system([TargetModel '/' CDDModel],'regexp','on','blocktype','port');
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Inputport_Num = length(string(HALOUT_CDD_Info{idx,2}));
Intputport_array = (string(HALOUT_CDD_Info{idx,2}));
for k = 1:Inputport_Num
    set_param(char(Inputport_Origin_array(k)),'Name',Intputport_array(k));
end

% R_HALOUTCDD_CSOP_SetAcoreRebootCmdACK
CDDModel = 'R_HALOUTCDD_CSOP_SetAcoreRebootCmdACK';
BlockName = 'Enable';
srcT = 'simulink/Ports & Subsystems/Enable';
dstT = [TargetModel '/' CDDModel '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);

% R_NVMWriteCDD_Inner_NVM_WriteOperation
CDDModel = 'R_NVMWriteCDD_Inner_NVM_WriteOperation';
BlockName = 'Enable';
srcT = 'simulink/Ports & Subsystems/Enable';
dstT = [TargetModel '/' CDDModel '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);

% R_NVMReadCDD_Inner_NVM_ReadOperation
CDDModel = 'R_NVMReadCDD_Inner_NVM_ReadOperation';
BlockName = 'Trigger';
srcT = 'simulink/Ports & Subsystems/Trigger';
dstT = [TargetModel '/' CDDModel '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);
set_param(h,'TriggerType','function-call','Name','trig_ReadNVM');

% R_WDGCDD_CSOP_Call_Watchdog
CDDModel = 'R_WDGCDD_CSOP_Call_Watchdog';
BlockName = 'Trigger';
srcT = 'simulink/Ports & Subsystems/Trigger';
dstT = [TargetModel '/' CDDModel '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);
set_param(h,'TriggerType','function-call','Name','trig_WDG');

% R_WDGCDD_CSOP_Call_WDG_AppStart
CDDModel = 'R_WDGCDD_CSOP_Call_WDG_AppStart';
BlockName = 'Enable';
srcT = 'simulink/Ports & Subsystems/Enable';
dstT = [TargetModel '/' CDDModel '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);

% R_HALIN_IMU_CSOP_IMUGetOffsetVal
CDDModel = 'R_HALIN_IMU_CSOP_IMUGetOffsetVal';
BlockName = 'Trigger';
srcT = 'simulink/Ports & Subsystems/Trigger';
dstT = [TargetModel '/' CDDModel '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);
set_param(h,'TriggerType','function-call','Name','trig_ReadIMUOffset_00');

% HALOUT_AFTER
CDDModel = 'HALOUT_AFTER';
CDDModel_array = ["R_E2E_CAN3_VCU1_CSOP_Write_CAN3_VCU1";"R_E2E_CAN3_VCU1_toNIDEC_CSOP_Write_CAN3_VCU1_toNIDEC";"R_E2E_CAN4_VCU1_CSOP_Write_CAN4_VCU1"];
BlockName = 'Enable';
for i = 1:length(CDDModel_array)
srcT = 'simulink/Ports & Subsystems/Enable';
dstT = [TargetModel '/' CDDModel '/' char(CDDModel_array(i)) '/' BlockName];
block_x = 350;
block_y = -100;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);

idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Intputport_array = string(HALOUT_CDD_Info{idx,2});
targetport = get_param([TargetModel '/' CDDModel '/' char(CDDModel_array(i))],'PortHandles');
targetpos = get_param(targetport.Enable,'Position');
BlockName = 'In1';
dstT = [TargetModel '/' CDDModel '/' BlockName];
srcT = 'simulink/Sources/In1';
block_x = targetpos(1)-400;
block_y = targetpos(2)-100;
block_w = block_x + 30;
block_h = block_y + 13;
h = add_block(srcT,dstT,'MakeNameUnique','on');
sourceport = get_param(h,'PortHandles');
set_param(h,'Position',[block_x,block_y,block_w,block_h],'Name',Intputport_array(i));
add_line([TargetModel '/' CDDModel],sourceport.Outport,targetport.Enable,'autorouting','on');
end

BlockName = 'function';
dstT = [TargetModel '/' CDDModel '/' BlockName];
srcT = 'simulink/Ports & Subsystems/Trigger';
block_x = 350;
block_y = -200;
block_w = block_x + 35;
block_h = block_y + 35;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'Position',[block_x,block_y,block_w,block_h]);
set_param(h,'TriggerType','function-call');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% run_SWC_FDC_RxTx_5ms_sys Level               %%%%%%%%%%%
%%%%%%%%% Create Trigger/From/Input for each CDD block %%%%%%%%%%%
%%%%%%%%% Set HALOUTCDD block position again           %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% R_HALOUTCDD_CSOP_IVIReset (First postion, input, no Trigger)
CDDModel = 'R_HALOUTCDD_CSOP_IVIReset';
targetpos = get_param([TargetModel '/' char(HALOUT_CDD_cell(1,1))],'Position');
block_x = targetpos(1)-500;
block_y = targetpos(2);
block_w = targetpos(3)-500;
block_h = targetpos(4);
set_param([TargetModel '/' CDDModel],'Position',[block_x,block_y,block_w,block_h]);
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Input_array = string(HALOUT_CDD_Info{idx,3});
Inputport_Num = length(Input_array);
% Call CDD input function
Add_CDD_input(Inputport_Num,Input_array,TargetModel,CDDModel);


% R_HALOUTCDD_CSOP_SetSysPwrStat (input, no trigger)
lastblock = get_param([TargetModel '/' CDDModel],'Position');
lastblock_y = lastblock(4);
CDDModel = 'R_HALOUTCDD_CSOP_SetSysPwrStat';
targetpos = get_param([TargetModel '/' CDDModel],'Position');
block_x = targetpos(1)-500;
block_y = lastblock_y + 150;
block_w = targetpos(3)-500;
block_h = block_y + 120;
set_param([TargetModel '/' CDDModel],'Position',[block_x,block_y,block_w,block_h]);
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Input_array = string(HALOUT_CDD_Info{idx,3});
Inputport_Num = length(Input_array);
% Call CDD input function
Add_CDD_input(Inputport_Num,Input_array,TargetModel,CDDModel);


% R_HALOUTCDD_CSOP_AppNmStateReq (input, trigger)
lastblock = get_param([TargetModel '/' CDDModel],'Position');
lastblock_y = lastblock(4);
CDDModel = 'R_HALOUTCDD_CSOP_AppNmStateReq';
targetpos = get_param([TargetModel '/' CDDModel],'Position');
block_x = targetpos(1)-500;
block_y = lastblock_y + 150;
block_w = targetpos(3)-500;
block_h = block_y + 120;
set_param([TargetModel '/' CDDModel],'Position',[block_x,block_y,block_w,block_h]);
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Input_array = string(HALOUT_CDD_Info{idx,3});
Inputport_Num = length(Input_array);
Trigger_Name = string(HALOUT_CDD_Info{idx,4});
% Call CDD input function
Add_CDD_input(Inputport_Num,Input_array,TargetModel,CDDModel);
% Call CDD Trigger or Enable function
Add_CDD_trigger(TargetModel,CDDModel,Trigger_Name);


% R_NVMWriteCDD_Inner_NVM_WriteOperation (no input, trigger)
lastblock = get_param([TargetModel '/' CDDModel],'Position');
lastblock_y = lastblock(4);
CDDModel = 'R_NVMWriteCDD_Inner_NVM_WriteOperation';
targetpos = get_param([TargetModel '/' CDDModel],'Position');
block_x = targetpos(1)-500;
block_y = lastblock_y + 150;
block_w = targetpos(3)-500;
block_h = block_y + 120;
set_param([TargetModel '/' CDDModel],'Position',[block_x,block_y,block_w,block_h]);
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Trigger_Name = string(HALOUT_CDD_Info{idx,4});
% Call CDD Trigger or Enable function
Add_CDD_trigger(TargetModel,CDDModel,Trigger_Name);


% R_HALOUTCDD_CSOP_SleepRequest (input, trigger)
lastblock = get_param([TargetModel '/' CDDModel],'Position');
lastblock_y = lastblock(4);
CDDModel = 'R_HALOUTCDD_CSOP_SleepRequest';
targetpos = get_param([TargetModel '/' CDDModel],'Position');
block_x = targetpos(1)-500;
block_y = lastblock_y + 150;
block_w = targetpos(3)-500;
block_h = block_y + 120;
set_param([TargetModel '/' CDDModel],'Position',[block_x,block_y,block_w,block_h]);
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Input_array = string(HALOUT_CDD_Info{idx,3});
Inputport_Num = length(Input_array);
Trigger_Name = string(HALOUT_CDD_Info{idx,4});
% Call CDD input function
Add_CDD_input(Inputport_Num,Input_array,TargetModel,CDDModel);
% Call CDD Trigger or Enable function
Add_CDD_trigger(TargetModel,CDDModel,Trigger_Name);

% R_WDGCDD_CSOP_Call_WDG_AppEnd (no input, trigger)
lastblock = get_param([TargetModel '/' CDDModel],'Position');
lastblock_y = lastblock(4);
CDDModel = 'R_WDGCDD_CSOP_Call_WDG_AppEnd';
targetpos = get_param([TargetModel '/' CDDModel],'Position');
block_x = targetpos(1)-500;
block_y = lastblock_y + 150;
block_w = targetpos(3)-500;
block_h = block_y + 120;
set_param([TargetModel '/' CDDModel],'Position',[block_x,block_y,block_w,block_h]);
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Trigger_Name = string(HALOUT_CDD_Info{idx,4});
% Call CDD Trigger or Enable function
Add_CDD_trigger(TargetModel,CDDModel,Trigger_Name);

% R_FDCCDD_Inner_CSOP_FDC_AppCallSleep (no input, trigger)
lastblock = get_param([TargetModel '/' CDDModel],'Position');
lastblock_y = lastblock(4);
CDDModel = 'R_FDCCDD_Inner_CSOP_FDC_AppCallSleep';
targetpos = get_param([TargetModel '/' CDDModel],'Position');
block_x = targetpos(1)-500;
block_y = lastblock_y + 150;
block_w = targetpos(3)-500;
block_h = block_y + 120;
set_param([TargetModel '/' CDDModel],'Position',[block_x,block_y,block_w,block_h]);
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Trigger_Name = string(HALOUT_CDD_Info{idx,4});
% Call CDD Trigger or Enable function
Add_CDD_trigger(TargetModel,CDDModel,Trigger_Name);

% R_UDSCDD_CSOP_SetDTCStatus (input, trigger)
lastblock = get_param([TargetModel '/' CDDModel],'Position');
lastblock_y = lastblock(4);
CDDModel = 'R_UDSCDD_CSOP_SetDTCStatus';
targetpos = get_param([TargetModel '/' CDDModel],'Position');
block_x = targetpos(1)-500;
block_y = lastblock_y + 150;
block_w = targetpos(3)-500;
block_h = block_y + 120;
set_param([TargetModel '/' CDDModel],'Position',[block_x,block_y,block_w,block_h]);
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Input_array = string(HALOUT_CDD_Info{idx,3});
Inputport_Num = length(Input_array);
Trigger_Name = string(HALOUT_CDD_Info{idx,4});
% Call CDD input function
Add_CDD_input(Inputport_Num,Input_array,TargetModel,CDDModel);
% Call CDD Trigger or Enable function
Add_CDD_trigger(TargetModel,CDDModel,Trigger_Name);

% R_UDSCDD_CSOP_DdmRestartOperationCycle (no input, no trigger)
lastblock = get_param([TargetModel '/' CDDModel],'Position');
lastblock_y = lastblock(4);
CDDModel = 'R_UDSCDD_CSOP_DdmRestartOperationCycle';
targetpos = get_param([TargetModel '/' CDDModel],'Position');
block_x = targetpos(1)-500;
block_y = lastblock_y + 150;
block_w = targetpos(3)-500;
block_h = block_y + 120;
set_param([TargetModel '/' CDDModel],'Position',[block_x,block_y,block_w,block_h]);
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Trigger_Name = string(HALOUT_CDD_Info{idx,4});

% VOUTP_AcoreRebootCmdACK_flg (trigger)
lastblock = get_param([TargetModel '/' CDDModel],'Position');
lastblock_y = lastblock(4);
CDDModel = 'R_HALOUTCDD_CSOP_SetAcoreRebootCmdACK';
targetpos = get_param([TargetModel '/' CDDModel],'Position');
block_x = targetpos(1)-500;
block_y = lastblock_y + 150;
block_w = targetpos(3)-500;
block_h = block_y + 120;
set_param([TargetModel '/' CDDModel],'Position',[block_x,block_y,block_w,block_h]);


% R_HALIN_IMU_CSOP_IMUSetSta (input, trigger)
lastblock = get_param([TargetModel '/' CDDModel],'Position');
lastblock_y = lastblock(4);
CDDModel = 'R_HALIN_IMU_CSOP_IMUSetSta';
targetpos = get_param([TargetModel '/' CDDModel],'Position');
block_x = targetpos(1)-500;
block_y = lastblock_y + 150;
block_w = targetpos(3)-500;
block_h = block_y + 120;
set_param([TargetModel '/' CDDModel],'Position',[block_x,block_y,block_w,block_h]);
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Input_array = string(HALOUT_CDD_Info{idx,3});
Inputport_Num = length(Input_array);
Trigger_Name = string(HALOUT_CDD_Info{idx,4});

% R_NVMReadCDD_Inner_NVM_ReadOperation (no input, trigger)
CDDModel = 'R_NVMReadCDD_Inner_NVM_ReadOperation';
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Trigger_Name = string(HALOUT_CDD_Info{idx,4});
% Call CDD Trigger or Enable function
Add_CDD_trigger(TargetModel,CDDModel,Trigger_Name);

% R_WDGCDD_CSOP_Call_Watchdog (no input, trigger)
CDDModel = 'R_WDGCDD_CSOP_Call_Watchdog';
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Trigger_Name = string(HALOUT_CDD_Info{idx,4});
% Call CDD Trigger or Enable function
Add_CDD_trigger(TargetModel,CDDModel,Trigger_Name);

% R_WDGCDD_CSOP_Call_WDG_AppStart (no input, trigger)
CDDModel = 'R_WDGCDD_CSOP_Call_WDG_AppStart';
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Trigger_Name = string(HALOUT_CDD_Info{idx,4});
% Call CDD Trigger or Enable function
Add_CDD_trigger(TargetModel,CDDModel,Trigger_Name);

% R_HALIN_IMU_CSOP_IMUGetOffsetVal (no input, trigger)
CDDModel = 'R_HALIN_IMU_CSOP_IMUGetOffsetVal';
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Trigger_Name = string(HALOUT_CDD_Info{idx,4});
% Call CDD Trigger or Enable function
Add_CDD_trigger(TargetModel,CDDModel,Trigger_Name);

targetport = get_param([TargetModel '/' CDDModel],'PortHandles');
targetpos = get_param(targetport.Outport(1),'Position');
BlockName = 'Goto';
block_x = targetpos(1) + 100;
block_y = targetpos(2) - 15;
block_w = block_x + 240;
block_h = block_y + 30;
srcT = 'simulink/Signal Routing/Goto';
dstT = [TargetModel '/' BlockName];
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'position',[block_x,block_y,block_w,block_h]);
set_param(h,'Gototag','s16_IMUOffsetVal','ShowName', 'off');
sourceport = targetport;
targetport = get_param(h,'PortHandles');
add_line(TargetModel, sourceport.Outport(1), targetport.Inport(1));

targetport = get_param([TargetModel '/' CDDModel],'PortHandles');
targetpos = get_param(targetport.Outport(2),'Position');
BlockName = 'Goto';
block_x = targetpos(1) + 100;
block_y = targetpos(2) - 15;
block_w = block_x + 240;
block_h = block_y + 30;
srcT = 'simulink/Signal Routing/Goto';
dstT = [TargetModel '/' BlockName];
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'position',[block_x,block_y,block_w,block_h]);
set_param(h,'Gototag','u8_IMUOffsetValSta','ShowName', 'off');
sourceport = targetport;
targetport = get_param(h,'PortHandles');
add_line(TargetModel, sourceport.Outport(2), targetport.Inport(1));

% HALOUT_AFTER (input, trigger)
CDDModel = 'HALOUT_AFTER';
idx = strcmp(string(HALOUT_CDD_Info(:,1)),CDDModel);
Input_array = string(HALOUT_CDD_Info{idx,3});
Inputport_Num = length(Input_array);
Trigger_Name = string(HALOUT_CDD_Info{idx,4});
% Call CDD input function
Add_CDD_input(Inputport_Num,Input_array,TargetModel,CDDModel);
% Call CDD Trigger or Enable function
Add_CDD_trigger(TargetModel,CDDModel,Trigger_Name);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% run_SWC_FDC_RxTx_5ms_sys end %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RUNNABLES action %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TargetModel = run_SWC_FDC_AppCallSleep_sys
TargetModel = 'SWC_FDC_type/run_SWC_FDC_AppCallSleep_sys';
open_system(TargetModel);
BlockList = find_system(TargetModel,'SearchDepth','1');
Function_x = 0;
Function_y = - 100;
Function_w = 25;
Function_h = 25; 
back_x = 0;
Outputport_array = string(find_system(TargetModel,'SearchDepth','1','regexp','on','BlockType','Out'));

% Call Modify_Terminator_Ground_out_block fuction
Modify_Terminator_Ground_out_block(BlockList,Function_x,Function_y,Function_w,Function_h,back_x,Outputport_array);

% Add input for P_AppModeReq_requestedMode_write
targetport = get_param(Outputport_array,'PortHandles');
targetpos = get_param(targetport.Inport,'Position');

BlockName = 'Data Type Conversion';
srcT = 'simulink/Signal Attributes/Data Type Conversion';
dstT = [TargetModel '/' BlockName];
block_x = targetpos(1) - 200;
block_y = targetpos(2) - 20;
block_w = block_x + 100;
block_h = block_y + 40;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'position',[block_x,block_y,block_w,block_h]);
set_param(h,'RndMeth','Floor');
set_param(h,'OutDataTypeStr','Enum: AppModeRequestType','ShowName', 'off');
sourceport = get_param(h,'PortHandles');
add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));

targetport = sourceport;
targetpos = get_param(targetport.Inport(1),'Position');
BlockName = 'Data Type Conversion';
srcT = 'simulink/Signal Attributes/Data Type Conversion';
dstT = [TargetModel '/' BlockName];
block_x = targetpos(1) - 200;
block_y = targetpos(2) - 20;
block_w = block_x + 100;
block_h = block_y + 40;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'position',[block_x,block_y,block_w,block_h]);
set_param(h,'RndMeth','Floor');
set_param(h,'OutDataTypeStr','uint8','ShowName', 'off')
sourceport = get_param(h,'PortHandles');
add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));

targetport = sourceport;
targetpos = get_param(targetport.Inport(1),'Position');
BlockName = 'Constant';
srcT = 'simulink/Commonly Used Blocks/Constant';
dstT = [TargetModel '/' BlockName];
block_x = targetpos(1) - 200;
block_y = targetpos(2) - 20;
block_w = block_x + 100;
block_h = block_y + 40;
h = add_block(srcT,dstT,'MakeNameUnique','on');
set_param(h,'position',[block_x,block_y,block_w,block_h]);
set_param(h,'Value','TRUE','ShowName', 'off');
sourceport = get_param(h,'PortHandles');
add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on');

%% TargetModel = P_WDGCDD
TargetModel = 'SWC_FDC_type/P_WDGCDD';
targetpos = get_param('SWC_FDC_type/run_SWC_FDC_UDS_10ms_sys','Position');
block_x = targetpos(1);
block_y = targetpos(2) +200;
block_w = block_x + targetpos(3) - targetpos(1);
block_h = block_y + targetpos(4) - targetpos(2);
set_param(TargetModel,'Position',[block_x,block_y,block_w,block_h])

%% TargetModel = run_SWC_FDC_CDD_10ms_sys
TargetModel = 'SWC_FDC_type/run_SWC_FDC_CDD_10ms_sys';
open_system(TargetModel);
BlockList = find_system(TargetModel,'SearchDepth','1');
Function_x = 0;
Function_y = - 100;
Function_w = 25;
Function_h = 25; 
back_x = 1500;
Outputport_array = string(find_system(TargetModel,'SearchDepth','1','regexp','on','BlockType','Out'));

% Call Modify_Terminator_Ground_out_block fuction
Modify_Terminator_Ground_out_block(BlockList,Function_x,Function_y,Function_w,Function_h,back_x,Outputport_array);

CDD_BlockList = string(find_system(TargetModel,'SearchDepth','1','BlockType','FunctionCaller'));
warning_flg = boolean(0);
% Set CDD block bigger
for i = 1:length(CDD_BlockList)
    h = get_param(CDD_BlockList(i),'PortHandles');
    Output_num = length(h.Outport);
    targetpos = get_param(CDD_BlockList(i),'Position');
    block_x = targetpos(1);
    block_y = targetpos(2);
    block_w = targetpos(3);
    block_h = block_y + Output_num * 40;
    set_param(CDD_BlockList(i),'Position',[block_x,block_y,block_w,block_h]);
    
    % Get CDD output name array and set Outputport position first avoid blocked
    CDD_output_array = string(extractBetween((get_param(CDD_BlockList(i),'FunctionPrototype')),'[',']'));
    idx  = strfind(CDD_output_array,',');
    Outputport_array = find_system(TargetModel,'regexp','on','blocktype','Out');
    
    % 1 by 1
    for k = 1:length(idx)+1
        if k==1
            Output_Name = extractBefore(CDD_output_array,idx(k));
        elseif k == length(idx)+1
            Output_Name = extractAfter(CDD_output_array,idx(k-1));
        else
            Output_Name = extractBetween(CDD_output_array,idx(k-1)+1,idx(k)-1);
        end
        
        % Connect CDD and outport
        h = strcmp(extractBetween(string(Outputport_array),'IRV_','_write'),Output_Name);
        if sum(h) > 1 || ~any(h)
            if ~warning_flg
            disp(['Not connect all port successfully ' '<a href="matlab:Simulink.SimulationData.BlockPath.hilite_block (''' TargetModel ''')">' TargetModel '</a>']);
            warning_flg = boolean(1);
            end           
        continue
        elseif sum(h) == 1  
            sourceport = get_param(CDD_BlockList(i),'PortHandles');     
            targetpos = get_param(sourceport.Outport(k),'Position');
            block_x = targetpos(1) + 100;
            block_y = targetpos(2) - 5;
            block_w = block_x + 30;
            block_h = block_y + 14;
            set_param(char(Outputport_array(h)),'Position',[block_x,block_y,block_w,block_h]);

            targetport = get_param(char(Outputport_array(h)),'PortHandles');
            add_line(TargetModel,sourceport.Outport(k),targetport.Inport(1));
        end
    end
end

%% TargetModel = run_SWC_FDC_Tx_10ms_sys
TargetModel = 'SWC_FDC_type/run_SWC_FDC_Tx_10ms_sys';
open_system(TargetModel);
BlockList = find_system(TargetModel,'SearchDepth','1');
Function_x = 0;
Function_y = - 100;
Function_w = 25;
Function_h = 25; 
back_x = 200;
Outputport_array = string(find_system(TargetModel,'SearchDepth','1','regexp','on','BlockType','Out'));
Inputport_array = string(find_system(TargetModel,'SearchDepth','1','regexp','on','blocktype','In'));
warning_flg = boolean(0);

% Call Modify_Terminator_Ground_out_block fuction
Modify_Terminator_Ground_out_block(BlockList,Function_x,Function_y,Function_w,Function_h,back_x,Outputport_array);

% Set CDD block bigger and position
CDD_BlockList = string(find_system(TargetModel,'SearchDepth','1','BlockType','FunctionCaller'));
CDD_cell = {};
for i = 1:length(CDD_BlockList)
BlockName = char(get_param(CDD_BlockList(i),'Name'));  
Blockpos = get_param([TargetModel '/' BlockName],'position');
CDD_cell(i,1) = {BlockName}; 
CDD_cell(i,2) = {Blockpos(1)};
CDD_cell(i,3) = {Blockpos(2)};
CDD_cell(i,4) = {Blockpos(3)};
CDD_cell(i,5) = {Blockpos(4)};
CDD_cell = sortrows(CDD_cell,3);
end

for i = 1:length(CDD_cell)
    h = get_param([TargetModel '/' char(CDD_cell(i,1))],'PortHandles');
    Input_num = length(h.Inport);
    Output_num = length(h.Outport);
    num_max = max(Input_num,Output_num);
    targetpos = get_param([TargetModel '/' char(CDD_cell(i,1))],'Position');
    block_x = cell2mat(CDD_cell(1,2));

    if i == 1
        block_y = targetpos(2) + 200;
        block_w = targetpos(3) - targetpos(1) + 300;
    else
        lastblock = get_param([TargetModel '/' char(CDD_cell(i-1,1))],'Position');   
        lastblock_y = lastblock(4);
        lastblock_w = lastblock(3) - lastblock(1);
        block_y = lastblock_y + 30;
        block_w = targetpos(1) + lastblock_w;
    end
        block_h = block_y + num_max * 50;
    set_param([TargetModel '/' char(CDD_cell(i,1))],'position',[block_x,block_y,block_w,block_h]);
    
    % Get CDD Input name for connect
    CDD_port_info = get_param([TargetModel '/' char(CDD_cell(i,1))],'PortHandles');
    FunctionPrototype = string(get_param([TargetModel '/' char(CDD_cell(i,1))],'FunctionPrototype'));
    CDD_Input_array = char(extractBetween(FunctionPrototype,'(',')'));
    
    if ~isempty(CDD_Input_array)
        idx  = strfind(CDD_Input_array,',');
        
        % 1 by 1
        for k = 1:length(idx)+1
            if idx >= 1
                if k==1
                    Input_Name = extractBefore(CDD_Input_array,idx(k));
                elseif k == length(idx)+1
                    Input_Name = extractAfter(CDD_Input_array,idx(k-1));
                else
                    Input_Name = extractBetween(CDD_Input_array,idx(k-1)+1,idx(k)-1);
                end
            else
                Input_Name = CDD_Input_array;
            end
            
            h = strcmp(extractBetween(extractAfter(string(Inputport_array),TargetModel),'_','_read'),Input_Name);

            if sum(h) > 1 || ~any(h)
                if ~warning_flg
                disp(['Not connect all port successfully ' '<a href="matlab:Simulink.SimulationData.BlockPath.hilite_block (''' TargetModel ''')">' TargetModel '</a>'])
                warning_flg = boolean(1);
                end           
            continue    
            elseif sum(h) == 1   
                targetport = get_param([TargetModel '/' char(CDD_cell(i,1))],'PortHandles');     
                targetpos = get_param(targetport.Inport(k),'Position');
                block_x = targetpos(1) - 130;
                block_y = targetpos(2) - 5;
                block_w = block_x + 30;
                block_h = block_y + 14;
                set_param(char(Inputport_array(h)),'Position',[block_x,block_y,block_w,block_h]);
    
                sourceport = get_param(char(Inputport_array(h)),'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(k));
            end
        end
    end

    % Get CDD Output name for connect
    if length(CDD_port_info.Outport)==1
    CDD_output_array = extractBefore(FunctionPrototype,' = ');
    elseif length(CDD_port_info.Outport)>1
    CDD_output_array = extractBetween(FunctionPrototype,'[',']');
    else
    CDD_output_array = [];    
    end

    if ~isempty(CDD_output_array)
        idx  = strfind(CDD_output_array,',');
        
        % 1 by 1
        for k = 1:length(idx)+1
            if idx >= 1
                if k==1
                    Output_Name = extractBefore(CDD_output_array,idx(k));
                elseif k == length(idx)+1
                    Output_Name = extractAfter(CDD_output_array,idx(k-1));
                else
                    Output_Name = extractBetween(CDD_output_array,idx(k-1)+1,idx(k)-1);
                end
            else
                Output_Name = CDD_output_array;
            end
            
            h = strcmp(extractBetween(extractAfter(string(Outputport_array),TargetModel),'_','_write'),Output_Name);

            if sum(h) > 1 || ~any(h)
                if ~warning_flg
                disp(['Not connect all port successfully ' '<a href="matlab:Simulink.SimulationData.BlockPath.hilite_block (''' TargetModel ''')">' TargetModel '</a>'])
                warning_flg = boolean(1);
                end           
            continue           
            elseif sum(h) == 1   
                sourceport = get_param([TargetModel '/' char(CDD_cell(i,1))],'PortHandles');     
                targetpos = get_param(sourceport.Outport(k),'Position');
                block_x = targetpos(1) + 100;
                block_y = targetpos(2) - 5;
                block_w = block_x + 30;
                block_h = block_y + 14;
                set_param(char(Outputport_array(h)),'Position',[block_x,block_y,block_w,block_h]);
    
                targetport = get_param(char(Outputport_array(h)),'PortHandles');
                add_line(TargetModel,sourceport.Outport(k),targetport.Inport(1));
            end
        end
    end
end

% Call Add_connect_line_between_Inport_and_Outport function
Add_connect_line_between_Inport_and_Outport(Inputport_array,Outputport_array,TargetModel,warning_flg);

%% Auto fix RUNNABLES
TargetModel = 'SWC_FDC_type';
RUNNABLES_BlockList = find_system(TargetModel,'SearchDepth','1','BlockType','SubSystem');
idx = contains(RUNNABLE_array,{'AppCallWDG';'AppCallSleep';'run_SWC_FDC_CDD_10ms';'run_SWC_FDC_Tx_10ms'});
RUNNABLE_array(idx) = [];

for i = 1:length(RUNNABLE_array)
    idx = contains(RUNNABLES_BlockList,[char(RUNNABLE_array(i)) '_sys']);
    if ~any(idx)
        disp(['Not connect all port successfully => ' char(RUNNABLE_array(i))]);
    end
    TargetModel = RUNNABLES_BlockList(idx);
    BlockList = find_system(TargetModel,'SearchDepth','1');

    % Call Modify_Terminator_Ground_out_block fuction
    Function_x = 0;
    Function_y = - 100;
    Function_w = 25;
    Function_h = 25; 
    back_x = 0;
    Outputport_array = string(find_system(TargetModel,'SearchDepth','1','regexp','on','BlockType','Out'));
    Modify_Terminator_Ground_out_block(BlockList,Function_x,Function_y,Function_w,Function_h,back_x,Outputport_array);
    
    % Call Add_connect_line_between_Inport_and_Outport function
    Inputport_array = find_system(TargetModel,'SearchDepth','1','regexp','on','blocktype','In');
    warning_flg = boolean(0);
    Add_connect_line_between_Inport_and_Outport(Inputport_array,Outputport_array,TargetModel,warning_flg);
end

%% All RUNNABLES inport outport check
idx = contains(RUNNABLES_BlockList,{'run_SWC_FDC_RxTx_5ms'});
RUNNABLES_BlockList(idx) = [];

for i = 1:length(RUNNABLES_BlockList)
    TargetModel = char(RUNNABLES_BlockList(i));
    Outputport_array = find_system(TargetModel,'SearchDepth','1','regexp','on','BlockType','Out');
    Inputport_array = find_system(TargetModel,'SearchDepth','1','regexp','on','blocktype','In');
    if ~isempty(Outputport_array)
        for g = 1:length(Outputport_array)    
            h = get_param(string(Outputport_array(g)),'LineHandles');
            if h.Inport == -1 
                disp(['Not connect port successfully ' '<a href="matlab:Simulink.SimulationData.BlockPath.hilite_block (''' char(Outputport_array(g)) ''')">' TargetModel '</a>'])
            end
        end
    end

    if ~isempty(Inputport_array)
        for g = 1:length(Inputport_array)    
            h = get_param(string(Inputport_array(g)),'LineHandles');
            if h.Outport == -1 
                disp(['Not connect port successfully ' '<a href="matlab:Simulink.SimulationData.BlockPath.hilite_block (''' char(Inputport_array(g)) ''')">' TargetModel '</a>'])
            end
        end
    end
end

cd(arch_Path);

% disp('Delete all Terminator block Done!');
% disp('Delete all Ground block Done!');
% disp('Set all output port is Non-virtual Done!');
TargetModel = 'SWC_FDC_type';
open_system(TargetModel);
disp('SWC_FDC_type Done!');

% Autobuild DID CDD in SWC_FDC_type
cd(arch_Path);
FVT_SWC_DID_Autobuild(Update_newDID)
disp('DID_Autobuild Done!');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Function Call %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Modify Terminator Ground out block
function Modify_Terminator_Ground_out_block(BlockList,Function_x,Function_y,Function_w,Function_h,back_x,Outputport_array)

    for i = 2:length(BlockList)
        BlockName = char(get_param(BlockList(i),'Name'));  
        % Set Function block bigger
        if contains(BlockName,'function')
            targetpos = get_param(string(BlockList(i)),'Position');
            block_x = targetpos(1) + Function_x;
            block_y = targetpos(2) + Function_y;
            block_w = block_x + Function_w;
            block_h = block_y + Function_h;
            set_param(string(BlockList(i)),'Position',[block_x,block_y,block_w,block_h]);
        end
    
        % Delete all Terminator block
        if contains(BlockName,'Terminator')
            h = get_param(string(BlockList(i)),'LineHandles');
            delete_line(h.Inport(1));
            delete_block(string(BlockList(i)));
        end
        
        % Delete all Ground block
        if contains(BlockName,'Ground')
            h = get_param(string(BlockList(i)),'LineHandles');
            delete_line(h.Outport(1));
            delete_block(string(BlockList(i)));
        end
    
        % Set all output port is Non-virtual and positon
        if any(contains(string(Outputport_array),BlockName))
            set_param(char(BlockList(i)),'EnsureOutportIsVirtual','off');
            targetpos = get_param(char(BlockList(i)),'Position');
            block_x = targetpos(1) + back_x;
            block_y = targetpos(2);
            block_w = block_x + targetpos(3)-targetpos(1);
            block_h = block_y + targetpos(4)-targetpos(2);
            set_param(char(BlockList(i)),'Position',[block_x,block_y,block_w,block_h]);
        end
        
    end
end

%% Add CDD input in run_SWC_FDC_RxTx_5ms_sys
function Add_CDD_input(Inputport_Num,Input_array,TargetModel,CDDModel)
    for i =1:Inputport_Num
        targetport = get_param([TargetModel '/' CDDModel],'PortHandles');
        Input_Name = Input_array(i);
        targetpos = get_param(targetport.Inport(i),'Position');
        
        if contains(Input_Name,'Ground')
        BlockName = 'Ground';
        block_x = targetpos(1) - 60;
        block_y = targetpos(2) - 15;
        block_w = block_x + 30;
        block_h = block_y + 30;
        srcT = 'simulink/Commonly Used Blocks/Ground';
        dstT = [TargetModel '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        sourceport = get_param(h,'PortHandles');
        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(i));
        continue
        end
        if contains(Input_Name,'/')
            if contains(Input_Name,'/uint')
                BlockName = 'Data Type Conversion';
                idx = strfind(Input_Name,'/');
                idx = idx(end);
                SignalDataType = char(extractAfter(Input_Name,idx));
                srcT = 'simulink/Signal Attributes/Data Type Conversion';
                dstT = [TargetModel '/' BlockName];
                block_x = targetpos(1) - 170;
                block_y = targetpos(2) - 20;
                block_w = block_x + 100;
                block_h = block_y + 40;
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'OutDataTypeStr', SignalDataType,'ShowName', 'off');
                set_param(h,'RndMeth', 'Floor');
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(i));
                targetport = sourceport;
                targetpos = get_param(targetport.Inport,'Position');
            end
        
            if contains(Input_Name,'/NOT/')
                BlockName = 'NOT';
                block_x = targetpos(1)-80;
                block_y = targetpos(2)-30;
                block_w = block_x + 50;
                block_h = block_y + 50;
                srcT = 'simulink/Commonly Used Blocks/Logical Operator';
                dstT = [TargetModel '/' BlockName];    
                h = add_block(srcT,dstT,'MakeNameUnique','on');     
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'Inputs', '1');
                set_param(h,'Operator','NOT');
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                targetport = sourceport;
                targetpos = get_param(targetport.Inport,'Position');
    
                Input_Name = char(extractBefore(Input_Name,'/'));
                BlockName = 'From';
                block_x = targetpos(1) - 265;
                block_y = targetpos(2) - 20;
                block_w = block_x + 240;
                block_h = block_y + 40;
                srcT = 'simulink/Signal Routing/From';
                dstT = [TargetModel '/' BlockName];    
                h = add_block(srcT,dstT,'MakeNameUnique','on');     
                set_param(h,'position',[block_x,block_y,block_w,block_h]);
                set_param(h,'GotoTag',Input_Name,'ShowName','off');    
                sourceport = get_param(h,'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1)); 
                continue
            end

            Input_Name = char(extractBefore(Input_Name,'/'));
            BlockName = 'From';
            block_x = targetpos(1) - 350;
            block_y = targetpos(2) - 20;
            block_w = block_x + 240;
            block_h = block_y + 40;
            srcT = 'simulink/Signal Routing/From';
            dstT = [TargetModel '/' BlockName];    
            h = add_block(srcT,dstT,'MakeNameUnique','on');     
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h,'GotoTag',Input_Name,'ShowName','off');    
            sourceport = get_param(h,'PortHandles');
            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));          
        else
        BlockName = 'From';
        block_x = targetpos(1) - 525;
        block_y = targetpos(2) - 20;
        block_w = block_x + 240;
        block_h = block_y + 40;
        srcT = 'simulink/Signal Routing/From';
        dstT = [TargetModel '/' BlockName];    
        h = add_block(srcT,dstT,'MakeNameUnique','on');     
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'GotoTag',Input_Name,'ShowName','off');    
        sourceport = get_param(h,'PortHandles');
        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(i)); 
        end
    end
end


%% Add CDD trigger in run_SWC_FDC_RxTx_5ms_sys
function Add_CDD_trigger(TargetModel,CDDModel,Trigger_Name)
    targetport = get_param([TargetModel '/' CDDModel],'PortHandles');
    if ~isempty(targetport.Enable)
    targetpos = get_param(targetport.Enable(1),'Position');
    else  
    targetpos = get_param(targetport.Trigger(1),'Position');
    end

    if contains(Trigger_Name,'/DetectChange')
        BlockName='detect_change';
        srcT = 'simulink/Logic and Bit Operations/Detect Change';
        dstT = [TargetModel '/' BlockName];
        block_x = targetpos(1) - 350;
        block_y = targetpos(2) - 80;
        block_w = block_x + 70;
        block_h = block_y + 30;
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x,block_y,block_w,block_h],'ShowName', 'off');
        sourceport = get_param(h,'PortHandles');
        add_line(TargetModel,sourceport.Outport(1),targetport.Enable(1),'autorouting','on');
        targetport = sourceport;
        targetpos = get_param(targetport.Inport,'Position');

        Trigger_Name = char(extractBefore(Trigger_Name,'/'));
        BlockName = 'From';
        block_x = targetpos(1) - 525;
        block_y = targetpos(2) - 20;
        block_w = block_x + 220;
        block_h = block_y + 40;
        srcT = 'simulink/Signal Routing/From';
        dstT = [TargetModel '/' BlockName];    
        h = add_block(srcT,dstT,'MakeNameUnique','on');     
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'GotoTag',Trigger_Name,'ShowName','off');    
        sourceport = get_param(h,'PortHandles');
        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
        return
    end
    
    if contains(Trigger_Name,'/DetectIncrease')
        BlockName='detect_Increase';
        srcT = 'simulink/Logic and Bit Operations/Detect Increase';
        dstT = [TargetModel '/' BlockName];
        block_x = targetpos(1) - 350;
        block_y = targetpos(2) - 80;
        block_w = block_x + 70;
        block_h = block_y + 30;
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x,block_y,block_w,block_h],'ShowName', 'off');
        sourceport = get_param(h,'PortHandles');
        add_line(TargetModel,sourceport.Outport(1),targetport.Enable(1),'autorouting','on');
        targetport = sourceport;
        targetpos = get_param(targetport.Inport,'Position');

        Constant_value = char(extractBefore(Trigger_Name,'/'));
        BlockName = 'Constant';
        srcT = 'simulink/Commonly Used Blocks/Constant';
        dstT = [TargetModel '/' BlockName];
        block_x = targetpos(1) - 200;
        block_y = targetpos(2) - 20;
        block_w = block_x + 100;
        block_h = block_y + 40;
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'Value',Constant_value,'ShowName', 'off')       
        sourceport = get_param(h,'PortHandles');
        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
        return
    end

    if contains(Trigger_Name,'/UnitDelay')
        BlockName='Unit Delay';
        srcT = 'simulink/Discrete/Unit Delay';
        dstT = [TargetModel '/' BlockName];
        block_x = targetpos(1) - 350;
        block_y = targetpos(2) - 75;
        block_w = block_x + 50;
        block_h = block_y + 50;
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x,block_y,block_w,block_h],'ShowName', 'off');
        sourceport = get_param(h,'PortHandles');
        add_line(TargetModel,sourceport.Outport(1),targetport.Enable(1),'autorouting','on');
        targetport = sourceport;
        targetpos = get_param(targetport.Inport,'Position');
        
        if contains(Trigger_Name,'/UnitDelay/')
            BlockName='Unit Delay';
            srcT = 'simulink/Discrete/Unit Delay';
            dstT = [TargetModel '/' BlockName];
            block_x = targetpos(1) - 350;
            block_y = targetpos(2) - 75;
            block_w = block_x + 50;
            block_h = block_y + 50;
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_x,block_y,block_w,block_h],'ShowName', 'off');
            sourceport = get_param(h,'PortHandles');
            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1),'autorouting','on');
            targetport = sourceport;
            targetpos = get_param(targetport.Inport,'Position');
        end

        Trigger_Name = char(extractBefore(Trigger_Name,'/'));
        BlockName = 'From';
        block_x = targetpos(1) - 525;
        block_y = targetpos(2) - 20;
        block_w = block_x + 220;
        block_h = block_y + 40;
        srcT = 'simulink/Signal Routing/From';
        dstT = [TargetModel '/' BlockName];    
        h = add_block(srcT,dstT,'MakeNameUnique','on');     
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'GotoTag',Trigger_Name,'ShowName','off');    
        sourceport = get_param(h,'PortHandles');
        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
        return
    end
    BlockName = 'From';
    block_x = targetpos(1) - 880;
    block_y = targetpos(2) - 80;
    block_w = block_x + 240;
    block_h = block_y + 40;
    srcT = 'simulink/Signal Routing/From';
    dstT = [TargetModel '/' BlockName];    
    h = add_block(srcT,dstT,'MakeNameUnique','on');     
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'GotoTag',Trigger_Name,'ShowName','off');    
    sourceport = get_param(h,'PortHandles');
    if ~isempty(targetport.Enable)
    add_line(TargetModel,sourceport.Outport(1),targetport.Enable(1),'autorouting','on');
    else
    add_line(TargetModel,sourceport.Outport(1),targetport.Trigger(1),'autorouting','on');
    set_param(h,'ForegroundColor','blue');
    end
end


%% Add connect line between Inport and Outport for run_SWC_XXX
function Add_connect_line_between_Inport_and_Outport(Inputport_array,Outputport_array,TargetModel,warning_flg)
    
    if length(Inputport_array) == length(Outputport_array) && length(Outputport_array) == 1
        sourceport = get_param(char(Inputport_array),'PortHandles');
        targetport = get_param(char(Outputport_array),'PortHandles');
        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
    else
        for i = 1:length(Inputport_array)
            Input_Name = char(get_param(Inputport_array(i),'Name'));
            if startsWith(Input_Name,'IRV_ms')
                h = contains(string(Outputport_array),string(extractBetween(Input_Name,'0_','_read')));      
                sourceport = get_param(char(Inputport_array(i)),'PortHandles');
                targetpos = get_param(sourceport.Outport(1),'Position');
                block_x = targetpos(1) + 500;
                block_y = targetpos(2) - 5;
                block_w = block_x + 30;
                block_h = block_y + 14;
                if sum(h) > 1 || ~any(h)
                    if ~warning_flg
                    disp(['Not connect all port successfully ' '<a href="matlab:Simulink.SimulationData.BlockPath.hilite_block (''' TargetModel ''')">' TargetModel '</a>'])
                    warning_flg = boolean(1);
                    end           
                continue 
                elseif sum(h) == 1 
                set_param(char(Outputport_array(h)),'Position',[block_x,block_y,block_w,block_h]);
                targetport = get_param(char(Outputport_array(h)),'PortHandles');
                add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
                end
            end
        end
    end
end