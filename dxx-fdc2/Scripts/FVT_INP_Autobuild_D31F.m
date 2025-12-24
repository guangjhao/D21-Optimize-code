function FVT_INP_Autobuild_D31F()
%% Select Project
q = questdlg({'Check tthe following conditions:','1. Run project_start?',...
    '2. Current folder arch?','3. Halin done?'},'Initial check','Yes','No','Yes');
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

if strcmp(TargetNode,'FUSION')
    channel_list = {'CAN1','CAN2','CAN3','CAN4','CAN5','CAN6','GPIO'};
elseif strcmp(TargetNode,'ZONE_DR')
    channel_list = {'CAN_Dr1','CAN4','LIN_Dr1','LIN_Dr2','LIN_Dr3','LIN_Dr4','GPIO'};
elseif strcmp(TargetNode,'ZONE_FR')
    channel_list = {'CAN_Fr1','CAN4','LIN_Fr1','LIN_Fr2','GPIO'};
else
    error('Undefined target ECU');
end
   
q = listdlg('ListString', channel_list, ...
            'Name', 'Select Channel', ...
			'ListSize', [250 150], ...
            'SelectionMode', 'mutiple' ...
            );
Num_CANChn = length(q);

%% load library
load_system simulink
load_system FVT_lib
top_model = ['INP_temp_' datestr(now,30)];
new_system(top_model);
open_system(top_model);
set_param(top_model,'LibraryLinkDisplay','all');

for i = 1:Num_CANChn
    CANChannel = erase(char(channel_list(q(i))),'_');
    cd([arch_Path '\hal\hal_' lower(CANChannel)]);       
    data = readtable(['DD_HAL_' upper(CANChannel)],'sheet','Signals','PreserveVariableNames',true);
    [data_m,~] = size(data);
    cd([arch_Path '\inp']);

    if contains(CANChannel,'LIN')
        IsLINMessage = boolean(1);
    else
        IsLINMessage = boolean(0);
    end

    %% create top later subsystem elements
    original_x = 0;
    original_y = 0;

    % add subsystem
    BlockName = CANChannel;
    block_x = original_x + 600*i;
    block_y = original_y + 30;
    block_w = block_x + 250;
    block_h = block_y + 400;
    srcT = 'built-in/SubSystem';
    dstT = [top_model '/' BlockName];    
    h = add_block(srcT,dstT);     
    set_param(h,'position',[block_x,block_y,block_w,block_h])
    set_param(h,'ContentPreviewEnabled','off','BackgroundColor','LightBlue');

    % add ports in subsystem
    BlockName = ['INP_' CANChannel '_outputs']; 
    srcT = 'simulink/Sinks/Out1';
    dstT = [top_model '/' CANChannel '/' BlockName]; 
    block_x = original_x + 100;
    block_y = original_y;
    block_w = block_x + 30;
    block_h = block_y + 13;
    h = add_block(srcT,dstT);  
    set_param(h,'position',[block_x,block_y,block_w,block_h]);

    BlockName = ['BHAL_' CANChannel '_outputs']; 
    srcT = 'simulink/Sources/In1';
    dstT = [top_model '/' CANChannel '/' BlockName]; 
    block_x = original_x;
    block_y = original_y;
    block_w = block_x + 30;
    block_h = block_y + 13;
    h = add_block(srcT,dstT);  
    set_param(h,'position',[block_x,block_y,block_w,block_h]);

    

    %% inside message model
    
    new_model = [top_model '/' CANChannel];

    %Data restore 
    Arry_data = table2cell(data);
    Arry_CAN = ["" "" "" "" "" "" ""];
    Numb_CAN = 0; 
    Arry_CANValid = ["" "" "" "" "" ""];
    Numb_CANValid = 0; 
    Arry_Digital = ["" "" "" "" "" ""];
    Numb_Digital = 0;
    Arry_LLSD = ["" "" "" "" "" ""];
    Numb_LLSD = 0;
    Arry_Analog = ["" "" "" "" "" ""];
    Numb_Analog = 0;
    for k = 1:data_m
        str_dir = Arry_data(k,2);
        str_source = Arry_data(k,13); 
        if (string(str_dir) == ("output") && string(str_source) == ("CAN"))
            str = Arry_data(k,1);
            tmp = find(contains(str,"CANMsgInvalid"));
            if isempty(string(tmp))
                Numb_CAN = Numb_CAN+1;        
                Arry_CAN(Numb_CAN,1) = Arry_data(k,1);
                Arry_CAN(Numb_CAN,2) = Arry_data(k,3);
                Arry_CAN(Numb_CAN,3) = Arry_data(k,4);
                Arry_CAN(Numb_CAN,4) = Arry_data(k,5);
                Arry_CAN(Numb_CAN,5) = Arry_data(k,6);
                Arry_CAN(Numb_CAN,6) = Arry_data(k,12);
                Arry_CAN(Numb_CAN,7) = Arry_data(k,14);
            elseif (tmp == 1)
                Numb_CANValid = Numb_CANValid+1;
                Arry_CANValid(Numb_CANValid,1) = Arry_data(k,1);
                Arry_CANValid(Numb_CANValid,2) = Arry_data(k,3);
                Arry_CANValid(Numb_CANValid,3) = Arry_data(k,4);
                Arry_CANValid(Numb_CANValid,4) = Arry_data(k,5);
                Arry_CANValid(Numb_CANValid,5) = Arry_data(k,6);
                Arry_CANValid(Numb_CANValid,6) = Arry_data(k,12);
            end
        elseif (string(str_dir) == ("output") && string(str_source) == ("LIN"))
            str = Arry_data(k,1);
            tmp = find(contains(str,"LINMsgInvalid"));
            if isempty(string(tmp))
                Numb_CAN = Numb_CAN+1;        
                Arry_CAN(Numb_CAN,1) = Arry_data(k,1);
                Arry_CAN(Numb_CAN,2) = Arry_data(k,3);
                Arry_CAN(Numb_CAN,3) = Arry_data(k,4);
                Arry_CAN(Numb_CAN,4) = Arry_data(k,5);
                Arry_CAN(Numb_CAN,5) = Arry_data(k,6);
                Arry_CAN(Numb_CAN,6) = Arry_data(k,12);
                Arry_CAN(Numb_CAN,7) = Arry_data(k,14);
            elseif (tmp == 1)
                Numb_CANValid = Numb_CANValid+1;
                Arry_CANValid(Numb_CANValid,1) = Arry_data(k,1);
                Arry_CANValid(Numb_CANValid,2) = Arry_data(k,3);
                Arry_CANValid(Numb_CANValid,3) = Arry_data(k,4);
                Arry_CANValid(Numb_CANValid,4) = Arry_data(k,5);
                Arry_CANValid(Numb_CANValid,5) = Arry_data(k,6);
                Arry_CANValid(Numb_CANValid,6) = Arry_data(k,12);
            end
        elseif (string(str_dir) == ("output") && string(str_source) == ("digital"))
            Numb_Digital = Numb_Digital+1;
            Arry_Digital(Numb_Digital,1) = Arry_data(k,1);
            Arry_Digital(Numb_Digital,2) = Arry_data(k,3);
            Arry_Digital(Numb_Digital,3) = Arry_data(k,4);
            Arry_Digital(Numb_Digital,4) = Arry_data(k,5);
            Arry_Digital(Numb_Digital,5) = Arry_data(k,6);
            Arry_Digital(Numb_Digital,6) = Arry_data(k,13);
        elseif (string(str_dir) == ("output") && string(str_source) == ("analog"))
            Numb_Analog = Numb_Analog+1;
            Arry_Analog(Numb_Analog,1) = Arry_data(k,1);
            Arry_Analog(Numb_Analog,2) = Arry_data(k,3);
            Arry_Analog(Numb_Analog,3) = Arry_data(k,4);
            Arry_Analog(Numb_Analog,4) = Arry_data(k,5);
            Arry_Analog(Numb_Analog,5) = Arry_data(k,6);
            Arry_Analog(Numb_Analog,6) = Arry_data(k,13);
        elseif (string(str_dir) == ("output") && string(str_source) == ("LLSD"))        
            Numb_LLSD = Numb_LLSD+1;
            Arry_LLSD(Numb_LLSD,1) = Arry_data(k,1);
            Arry_LLSD(Numb_LLSD,2) = Arry_data(k,3);
            Arry_LLSD(Numb_LLSD,3) = Arry_data(k,4);
            Arry_LLSD(Numb_LLSD,4) = Arry_data(k,5);
            Arry_LLSD(Numb_LLSD,5) = Arry_data(k,6);
            Arry_LLSD(Numb_LLSD,6) = Arry_data(k,13);       
        end
    end
 
%%
    original_x = 0;
    original_y = 0;
    Numb_TotalCal = 0;
    Numb_Outputs = 0;

    ModuleName_Valid = 'CommunicationCheck';
    block_x=original_x;
    block_y=original_y;
    block_w=block_x+200;
    block_h=block_y+100;
    srcT = 'built-in/SubSystem';
    dstT = [new_model '/' ModuleName_Valid];    
    h = add_block(srcT,dstT);     
    set_param(h,'position',[block_x,block_y,block_w,block_h],'ContentPreviewEnabled','off'); 
    
    if ~(strcmp(string(CANChannel),"CAN99"))
    ModuleName_Com = 'SignalCheck';
    block_x=original_x+400;
    block_y=original_y;
    block_w=block_x+200;
    block_h=block_y+300;
    srcT = 'built-in/SubSystem';
    dstT = [new_model '/' ModuleName_Com];    
    h = add_block(srcT,dstT);     
    set_param(h,'position',[block_x,block_y,block_w,block_h],'ContentPreviewEnabled','off'); 
    end
    
    ModuleName_Bus = 'CreateBus';
    block_x=original_x+900;
    block_y=original_y;
    block_w=block_x+200;
    block_h=block_y+300;
    srcT = 'built-in/SubSystem';
    dstT = [new_model '/' ModuleName_Bus];    
    h = add_block(srcT,dstT);     
    set_param(h,'position',[block_x,block_y,block_w,block_h],'ContentPreviewEnabled','off'); 

    % ModuleName_New= 'InpNewSignalProcess';
    % block_x=original_x+400;
    % block_y=original_y+400;
    % block_w=block_x+200;
    % block_h=block_y+300;
    % srcT = 'built-in/SubSystem';
    % dstT = [new_model '/' ModuleName_New];    
    % h = add_block(srcT,dstT,'position',[block_x,block_y,block_w,block_h],'BackgroundColor','green','ContentPreviewEnabled','off');
    %% CANMsgValid

    if Numb_CANValid ~= 0
        Cal_CANValid = {'_ovrdflg','_ovrdval'};
        srcT = 'simulink/Sources/In1';
        dstT = [new_model '/' ModuleName_Valid '/BHAL_outputs']; 
        block_x=original_x;
        block_y=original_y+28;
        block_w=block_x+30;
        block_h=block_y+15;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]);  

        srcT = 'simulink/Signal Routing/Goto';
        dstT = [new_model '/' ModuleName_Valid '/Goto']; 
        block_x=original_x+120;
        block_y=original_y+20;
        block_w=block_x+100;
        block_h=block_y+30;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag','BHAL_outputs'); 

        dstT=[new_model '/' ModuleName_Valid];
        h=add_line(dstT,'BHAL_outputs/1','Goto/1');
        set_param(h,'name','<BHAL_outputs>');

        Ssrct_name1='bus_selector'; 
        srcT = 'simulink/Signal Routing/Bus Selector';
        dstT = [new_model '/' ModuleName_Valid '/' Ssrct_name1]; 
        block_x=original_x-200;
        block_y=original_y+150;
        block_w=block_x+10;
        block_h=block_y+50*Numb_CANValid;
        h = add_block(srcT,dstT); 

        sigoutputs = "";
        for k=1:Numb_CANValid
            str = char(Arry_CANValid(k,1));
            if (k==1)
                sigoutputs = str;
            else
                sigoutputs = strcat(sigoutputs,',',str);
            end
        end 
        set_param(h,'position',[block_x,block_y,block_w,block_h], 'outputsignals',sigoutputs); 

        Sscrt_name2='bus_creator'; 
        srcT = 'simulink/Signal Routing/Bus Creator';
        dstT = [new_model '/' ModuleName_Valid '/' Sscrt_name2]; 
        block_x=original_x+550;
        block_y=original_y+150;
        block_w=block_x+10;
        block_h=block_y+50*Numb_CANValid;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'ShowName','off','inputs',num2str(Numb_CANValid)); 

        for k=1:Numb_CANValid
            dstT = [new_model '/' ModuleName_Valid '/' Ssrct_name1];
            port = get_param(dstT,'PortHandles'); 
            port_pos  = get_param(port.Outport(k),'position');   
            
            ModuleName = char(Arry_CANValid(k,1));
            ModuleName = erase(ModuleName,"VHAL_");
            ModuleName = erase(ModuleName,"_flg");
            srcT = 'FVT_lib/inp/CAN_Msg_Validity_Process_template';
            dstT = [new_model '/' ModuleName_Valid '/' ModuleName];
            block_x=port_pos(1)+200;
            block_y=port_pos(2)-15;
            block_w=block_x+200;
            block_h=block_y+30;
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
%             set_param(h,'LinkStatus', 'inactive');
            
            srcT1 = 'simulink/Logic and Bit Operations/Logical Operator';
            dstT1 = [new_model '/' ModuleName_Valid '/not' num2str(k)]; 
            block_x=port_pos(1)+450;
            block_y=port_pos(2)-15;
            block_w=block_x+30;
            block_h=block_y+30;
            h = add_block(srcT1,dstT1);
            set_param(h,'position',[block_x,block_y,block_w,block_h],'Operator','NOT','showname','off'); 
            str = char(Arry_CANValid(k,1));      
            newstr=strrep(str,'VHAL','KINP'); 
            for j=1:length(Cal_CANValid)
                 Blockname_cal = char(Cal_CANValid(j));
                 Blockname_cal = erase(Blockname_cal,"_");
                 Cal_str = Cal_CANValid(j);
                 str = strcat(newstr,Cal_str); 
                 kblock_value = char(str);
                 dstT = [new_model '/' ModuleName_Valid '/' ModuleName '/' Blockname_cal]; 
                 set_param(dstT,'Value',kblock_value);          
                 Numb_TotalCal = Numb_TotalCal + 1;
                 Arry_Cal(Numb_TotalCal,1) = cellstr(kblock_value);
                 switch j 
                     case {1,2}
                         Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                         Arry_Cal(Numb_TotalCal,3) = cellstr('boolean');                 
                         Arry_Cal(Numb_TotalCal,4) = num2cell(0);
                         Arry_Cal(Numb_TotalCal,5) = num2cell(1);
                         Arry_Cal(Numb_TotalCal,6) = cellstr('flg');
                         Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                         Arry_Cal(Numb_TotalCal,8) = num2cell(0);
%                      case {2}
%                          Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
%                          Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
%                          Arry_Cal(Numb_TotalCal,4) = num2cell(0);
%                          Arry_Cal(Numb_TotalCal,5) = num2cell(255);
%                          Arry_Cal(Numb_TotalCal,6) = cellstr('cnt'); 
%                          Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');                
%                          Arry_Cal(Numb_TotalCal,8) = num2cell(100);
%                      case {3}
%                          Arry_Cal(Numb_TotalCal,2) = cellstr('internal');                 
%                          Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
%                          Arry_Cal(Numb_TotalCal,4) = num2cell(0);
%                          Arry_Cal(Numb_TotalCal,5) = num2cell(255);
%                          Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
%                          Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');  
%                          Arry_Cal(Numb_TotalCal,8) = num2cell(100);  
%                      case {4}
%                          Arry_Cal(Numb_TotalCal,2) = cellstr('internal');   
%                          Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
%                          Arry_Cal(Numb_TotalCal,4) = num2cell(0);
%                          Arry_Cal(Numb_TotalCal,5) = num2cell(255);
%                          Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
%                          Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');  
%                          Arry_Cal(Numb_TotalCal,8) = num2cell(100);
                 end
            end   
            
            dstT=[new_model '/' ModuleName_Valid];
            add_line(dstT,[Ssrct_name1,'/' num2str(k)],[ModuleName,'/' num2str(1)]);
            add_line(dstT,[ModuleName '/1'],['not' num2str(k) '/1']);
            h=add_line(dstT,['not' num2str(k) '/1'],[Sscrt_name2,'/' num2str(k)]);
            str = char(Arry_CANValid(k,1));
            newstr = strrep(str,'VHAL','VINP'); 
            newstr = strrep(newstr,'Invalid','Valid'); 
            set(h,'name',newstr);
        
            Numb_Outputs = Numb_Outputs+1;    
            Arry_outputs(Numb_Outputs,1) = cellstr(newstr);
            Arry_outputs(Numb_Outputs,2) = cellstr('output');
            Arry_outputs(Numb_Outputs,3) = cellstr('boolean');
            Arry_outputs(Numb_Outputs,4) = num2cell(0);
            Arry_outputs(Numb_Outputs,5) = num2cell(1);
            Arry_outputs(Numb_Outputs,6) = cellstr('flg');
        end

        BlockName= 'From';
        block_x=original_x-500;
        block_y=original_y+135+(50*Numb_CANValid)/2;
        block_w=block_x+100;
        block_h=block_y+30;
        srcT = 'simulink/Signal Routing/From';
        dstT = [new_model '/' ModuleName_Valid '/' BlockName];    
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'showname','off','Gototag','BHAL_outputs'); 

        BlockName= 'Out1';
        block_x=original_x+650;
        block_y=original_y+140+(50*Numb_CANValid)/2;
        block_w=block_x+30;
        block_h=block_y+15;
        srcT = 'simulink/Sinks/Out1';
        dstT = [new_model '/' ModuleName_Valid '/' BlockName];    
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'name','inp_CanValid_bus');

        dstT = [new_model '/' ModuleName_Valid];
        add_line(dstT,['From', '/1'],[Ssrct_name1, '/1']);
        add_line(dstT,[Sscrt_name2, '/1'],['inp_CanValid_bus', '/1']);
    end

    %% SignalCheck
    
    if ~(strcmp(string(CANChannel),"CAN99"))
    Blockname = 'inp_CanValid_bus';    
    srcT2 = 'simulink/Sources/In1';
    dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
    block_x=original_x;
    block_y=original_y;
    block_w=block_x+30;
    block_h=block_y+13;
    h = add_block(srcT2,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]); 
    dstT = [new_model '/' ModuleName_Com '/' Blockname];
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Outport(1),'position'); 

    Blockname = 'goto1';
    srcT = 'simulink/Signal Routing/Goto';
    dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
    block_x=port_pos(1)+150;
    block_y=port_pos(2)-15 ;
    block_w=block_x+120;
    block_h=block_y+30;
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'showname','off','Gototag','inp_CanValid_bus');

    dstT=[new_model '/' ModuleName_Com];
    h=add_line(dstT, 'inp_CanValid_bus/1','goto1/1');
    set_param(h,'name','<inp_CanValid_bus>');

    Blockname = 'TASK_TIME_S';    
    srcT2 = 'simulink/Sources/In1';
    dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
    block_x=original_x;
    block_y=port_pos(2)+30 ;
    block_w=block_x+30;
    block_h=block_y+13;
    h = add_block(srcT2,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]); 
    dstT = [new_model '/' ModuleName_Com '/' Blockname];
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Outport(1),'position'); 

    Blockname = 'goto2';
    srcT = 'simulink/Signal Routing/Goto'; 
    dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
    block_x=port_pos(1)+150;
    block_y=port_pos(2)-15 ;
    block_w=block_x+120;
    block_h=block_y+30;
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'showname','off','Gototag','TASK_TIME_S');

    dstT=[new_model '/' ModuleName_Com];
    h=add_line(dstT, 'TASK_TIME_S/1','goto2/1');
    set_param(h,'name','<TASK_TIME_S>');

    Blockname = 'BHAL_outputs';    
    srcT2 = 'simulink/Sources/In1';
    dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
    block_x=original_x;
    block_y=port_pos(2)+30 ;
    block_w=block_x+30;
    block_h=block_y+13;
    h = add_block(srcT2,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]); 
    dstT = [new_model '/' ModuleName_Com '/' Blockname];
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Outport(1),'position'); 

    Blockname = 'goto3';
    srcT = 'simulink/Signal Routing/Goto'; 
    dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
    block_x=port_pos(1)+150;
    block_y=port_pos(2)-15 ;
    block_w=block_x+120;
    block_h=block_y+30;
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'showname','off','Gototag','BHAL_outputs');
    
    dstT=[new_model '/' ModuleName_Com];
    h=add_line(dstT, 'BHAL_outputs/1','goto3/1');
    set_param(h,'name','<BHAL_outputs>');
    SubModule = '';
    end
    %% Analog
    if Numb_Analog ~= 0
        SubModule = 'Analog'; 
        srcT = 'built-in/SubSystem';
        dstT = [new_model '/' ModuleName_Com '/' SubModule]; 
        block_x=original_x+150;
        block_y=original_y+200;
        block_w=block_x+300;
        block_h=block_y+(Numb_Analog*4)*40;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'ContentPreviewEnabled','off'); 
    
        Blockname = 'BHAL_outputs';    
        srcT2 = 'simulink/Sources/In1';
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname]; 
        block_x=original_x;
        block_y=original_y;
        block_w=block_x+30;
        block_h=block_y+13;
        h = add_block(srcT2,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]); 
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname];
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Outport(1),'position'); 

        Blockname = 'goto1';
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname]; 
        block_x=port_pos(1)+150;
        block_y=port_pos(2)-15 ;
        block_w=block_x+120;
        block_h=block_y+30;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'showname','off','Gototag','BHAL_outputs');

        dstT=[new_model '/' ModuleName_Com '/' SubModule];
        h=add_line(dstT, 'BHAL_outputs/1','goto1/1');
        set_param(h,'name','<BHAL_outputs>');

        Blockname = 'TASK_TIME_S';    
        srcT2 = 'simulink/Sources/In1';
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname]; 
        block_x=original_x;
        block_y=port_pos(2)+30 ;
        block_w=block_x+30;
        block_h=block_y+13;
        h = add_block(srcT2,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]); 
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname]; 
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Outport(1),'position'); 

        Blockname = 'goto2';
        srcT = 'simulink/Signal Routing/Goto'; 
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname]; 
        block_x=port_pos(1)+150;
        block_y=port_pos(2)-15 ;
        block_w=block_x+120;
        block_h=block_y+30;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'showname','off','Gototag','TASK_TIME_S');

        dstT=[new_model '/' ModuleName_Com '/' SubModule];
        h=add_line(dstT, 'TASK_TIME_S/1','goto2/1');
        set_param(h,'name','<TASK_TIME_S>');

        dstT = [new_model '/' ModuleName_Com '/' SubModule];
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Inport(1),'position'); 
        Blockname = 'Goto1_Analog';
        srcT = 'simulink/Signal Routing/From'; 
        dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
        block_x=port_pos(1)-250;
        block_y=port_pos(2)-15 ;
        block_w=block_x+120;
        block_h=block_y+30;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'showname','off','Gototag','BHAL_outputs');
        dstT=[new_model '/' ModuleName_Com];
        h=add_line(dstT, ['Goto1_Analog' '/1'],[SubModule '/1']);
        set_param(h,'name',['<','BHAL_outputs','>']);

        dstT = [new_model '/' ModuleName_Com '/' SubModule];
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Inport(2),'position'); 
        Blockname = 'Goto2_Analog';
        srcT = 'simulink/Signal Routing/From'; 
        dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
        block_x=port_pos(1)-250;
        block_y=port_pos(2)-15 ;
        block_w=block_x+120;
        block_h=block_y+30;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'showname','off','Gototag','TASK_TIME_S');

        dstT=[new_model '/' ModuleName_Com];
        h=add_line(dstT, ['Goto2_Analog' '/1'],[SubModule '/2']);
        set_param(h,'name',['<','TASK_TIME_S','>']);

        Cal_Analog={'_limupr','_limlow','_tcfilt','_fftlim','_fftinc','_fftdec','_defval','_ovrdflg','_ovrdval','_srvcflg','_srvcval'};
        for k = 1:Numb_Analog
            str = Arry_Analog(k,1);
            char(str);
            Subsubmodule = erase(str,'VHAL_');
            block_x=original_x;
            block_y=original_y+170*k;
            block_w=block_x+200;
            block_h=block_y+150;
            srcT = 'FVT_lib/inp/ad_signal_template';
            dstT = [new_model '/' ModuleName_Com '/' SubModule  '/' char(Subsubmodule)];   
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h])
%             set_param(h,'LinkStatus', 'inactive');

            for j = 1:length(Cal_Analog)
                cal = char(Cal_Analog(j));
                Block_cal = erase(cal,'_');
                Cal_value = strcat('KINP_',Subsubmodule,cal);
                dstT = [new_model '/' ModuleName_Com '/' SubModule '/' char(Subsubmodule) '/' Block_cal];   
                set_param(dstT,'Value',char(Cal_value));
                Numb_TotalCal = Numb_TotalCal + 1;
                Arry_Cal(Numb_TotalCal,1) = cellstr(Cal_value);
                switch j 
                    case {1}                                                       %limupr
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal'); 
                        Arry_Cal(Numb_TotalCal,3) = cellstr('single');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(str2double(Arry_Analog(k,3)));
                        Arry_Cal(Numb_TotalCal,5) = num2cell(str2double(Arry_Analog(k,4)));
                        Arry_Cal(Numb_TotalCal,6) = cellstr(Arry_Analog(k,5));
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        Arry_Cal(Numb_TotalCal,8) = num2cell(str2double(Arry_Analog(k,4)));
                     case {2}                                                      %limlow
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal'); 
                        Arry_Cal(Numb_TotalCal,3) = cellstr('single');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(str2double(Arry_Analog(k,3)));
                        Arry_Cal(Numb_TotalCal,5) = num2cell(str2double(Arry_Analog(k,4)));
                        Arry_Cal(Numb_TotalCal,6) = cellstr(Arry_Analog(k,5));
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        Arry_Cal(Numb_TotalCal,8) = num2cell(str2double(Arry_Analog(k,3)));
                     case {3}                                                      %tcfilt
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal'); 
                        Arry_Cal(Numb_TotalCal,3) = cellstr('single');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(0);
                        Arry_Cal(Numb_TotalCal,5) = num2cell(1);
                        Arry_Cal(Numb_TotalCal,6) = cellstr('tc');
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');                
                        Arry_Cal(Numb_TotalCal,8) = num2cell(0.05);
                     case {4}                                                      %fftlim
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal'); 
                        Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(0);
                        Arry_Cal(Numb_TotalCal,5) = num2cell(255);
                        Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        Arry_Cal(Numb_TotalCal,8) = num2cell(100);   
                     case {5}                                                      %fftinc
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                        Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(0);
                        Arry_Cal(Numb_TotalCal,5) = num2cell(255);
                        Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        Arry_Cal(Numb_TotalCal,8) = num2cell(1);  
                     case {6}                                                      %fftdec
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                        Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(0);
                        Arry_Cal(Numb_TotalCal,5) = num2cell(255);
                        Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        Arry_Cal(Numb_TotalCal,8) = num2cell(5);   
                     case {7,9,11}                                                 %defval,ovrdval,srvcval
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                        Arry_Cal(Numb_TotalCal,3) = cellstr('single');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(str2double(Arry_Analog(k,3)));
                        Arry_Cal(Numb_TotalCal,5) = num2cell(str2double(Arry_Analog(k,4)));
                        Arry_Cal(Numb_TotalCal,6) = cellstr(Arry_Analog(k,5));
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        Arry_Cal(Numb_TotalCal,8) = num2cell(0);
                     case {8,10}                                                  %ovrdflg,srvcflg
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                        Arry_Cal(Numb_TotalCal,3) = cellstr('boolean');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(0);
                        Arry_Cal(Numb_TotalCal,5) = num2cell(1);
                        Arry_Cal(Numb_TotalCal,6) = cellstr('flg');
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        Arry_Cal(Numb_TotalCal,8) = num2cell(0);  
                 end        
            end
            Outputs = {'ShortHigh_enum','ShortLow_enum','','Valid_flg'};
            for j = 1:4
                dstT = [new_model '/' ModuleName_Com '/' SubModule '/' char(Subsubmodule)]; 
                port = get_param(dstT,'PortHandles'); 
                port_pos  = get_param(port.Outport(j),'position');
                if (j==3)
                    Outstr  = strcat('VINP_',Subsubmodule);
                else
                    tmp = extractBefore(Subsubmodule,'_');
                    Outstr = strcat('VINP_',tmp,Outputs(j));
                end
                BlockName = char(Outstr);
                block_x=port_pos(1)+300;
                block_y=port_pos(2)-7.5;
                block_w=block_x+30;
                block_h=block_y+15;
                srcT = 'simulink/Sinks/Out1';
                dstT = [new_model '/' ModuleName_Com '/' SubModule '/' BlockName];    
                h = add_block(srcT,dstT);
                set_param(h,'position',[block_x,block_y,block_w,block_h],'name',char(Outstr)); 
                
                dstT=[new_model '/' ModuleName_Com '/' SubModule];
                h=add_line(dstT, [char(Subsubmodule) '/' num2str(j)],[char(Outstr) '/1']);
                set_param(h,'name',char(Outstr));
                
                Numb_Outputs = Numb_Outputs+1;
                switch j
                    case {1,2}
                    Arry_outputs(Numb_Outputs,1) = cellstr(Outstr);
                    Arry_outputs(Numb_Outputs,2) = cellstr('output');
                    Arry_outputs(Numb_Outputs,3) = cellstr('uint8');
                    Arry_outputs(Numb_Outputs,4) =  num2cell(0);
                    Arry_outputs(Numb_Outputs,5) =  num2cell(255);
                    Arry_outputs(Numb_Outputs,6) = cellstr('cnt');
                    case (3)
                    Arry_outputs(Numb_Outputs,1) = cellstr(Outstr);
                    Arry_outputs(Numb_Outputs,2) = cellstr('output');
                    Arry_outputs(Numb_Outputs,3) = cellstr('single');
                    Arry_outputs(Numb_Outputs,4) = num2cell(str2double(Arry_Analog(k,3)));
                    Arry_outputs(Numb_Outputs,5) = num2cell(str2double(Arry_Analog(k,4)));
                    Arry_outputs(Numb_Outputs,6) = cellstr(Arry_Analog(k,5));
                    case (4)
                    Arry_outputs(Numb_Outputs,1) = cellstr(Outstr);
                    Arry_outputs(Numb_Outputs,2) = cellstr('output');
                    Arry_outputs(Numb_Outputs,3) = cellstr('boolean');
                    Arry_outputs(Numb_Outputs,4) =  num2cell(0);
                    Arry_outputs(Numb_Outputs,5) =  num2cell(1);
                    Arry_outputs(Numb_Outputs,6) = cellstr('flg');
                end
            end
        end

        dstT = [new_model '/' ModuleName_Com '/' SubModule]; 
        port = get_param(dstT,'PortHandles'); 
        numb = length(port.Outport);
        for k = 1:numb
            port_pos  = get_param(port.Outport(k),'position');
            str = char(Arry_outputs(Numb_Outputs-numb+k,1));
            Blockname = str;
            srcT = 'simulink/Signal Routing/Goto'; 
            dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
            block_x=port_pos(1)+150;
            block_y=port_pos(2)-15 ;
            block_w=block_x+200;
            block_h=block_y+30;
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h])
            set_param(h,'showname','off','Gototag',str);
            dstT=[new_model '/' ModuleName_Com];
            h=add_line(dstT, [SubModule '/' num2str(k)],[str '/1']);
            set_param(h,'name',['<',str,'>']);
        end
    end

    %% Digital

    if Numb_Digital ~= 0
        dstT = [new_model '/' ModuleName_Com '/' SubModule]; 
        pos = get_param(dstT,'Position'); 

        SubModule = 'Digital'; 
        srcT = 'built-in/SubSystem';
        dstT = [new_model '/' ModuleName_Com '/' SubModule]; 
        block_x=pos(1);
        block_y=pos(4)+30;    
        block_w=pos(3);
        block_h=block_y+Numb_Digital*40;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'ContentPreviewEnabled','off');

        Blockname = 'BHAL_outputs';    
        srcT2 = 'simulink/Sources/In1';
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname]; 
        block_x=original_x;
        block_y=original_y;
        block_w=block_x+30;
        block_h=block_y+13;
        h = add_block(srcT2,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]); 
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname];
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Outport(1),'position'); 
        
        Blockname = 'goto1';
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname]; 
        block_x=port_pos(1)+150;
        block_y=port_pos(2)-15 ;
        block_w=block_x+120;
        block_h=block_y+30;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'showname','off','Gototag','BHAL_outputs');

        dstT=[new_model '/' ModuleName_Com '/' SubModule];
        h=add_line(dstT, 'BHAL_outputs/1','goto1/1');
        set_param(h,'name','<BHAL_outputs>');

        dstT = [new_model '/' ModuleName_Com '/' SubModule];
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Inport(1),'position'); 
        Blockname = 'Goto_Digtial';
        srcT = 'simulink/Signal Routing/From'; 
        dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
        block_x=port_pos(1)-250;
        block_y=port_pos(2)-15 ;
        block_w=block_x+120;
        block_h=block_y+30;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'showname','off','Gototag','BHAL_outputs');

        dstT=[new_model '/' ModuleName_Com];
        h=add_line(dstT, ['Goto_Digtial' '/1'],[SubModule '/1']);
        set_param(h,'name',['<','BHAL_outputs','>']);
    
        Cal_Digital={'_inverse','_deblim','_debinc','_debdec','_ovrdflg','_ovrdval','_srvcflg','_srvcval'};
        for k = 1:Numb_Digital
            str = Arry_Digital(k,1);
            char(str);
            str_unit = erase(str,'VHAL_');
            Subsubmodule = extractBefore(str_unit,'_');
            block_x=original_x;
            block_y=original_y+100*k;
            block_w=block_x+200;
            block_h=block_y+70;
            srcT = 'FVT_lib/inp/di_signal_template';
            dstT = [new_model '/' ModuleName_Com '/' SubModule  '/' char(Subsubmodule)];   
            h = add_block(srcT,dstT);
%             set_param(h,'LinkStatus', 'inactive');
            set_param(h,'position',[block_x,block_y,block_w,block_h]);

            for j = 1:length(Cal_Digital)
                cal = char(Cal_Digital(j));
                Block_cal = erase(cal,'_');
                Cal_value = strcat('KINP_',str_unit,cal);
                dstT = [new_model '/' ModuleName_Com '/' SubModule '/' char(Subsubmodule) '/' Block_cal];   
                set_param(dstT,'Value',char(Cal_value));
                Numb_TotalCal = Numb_TotalCal + 1;
                Arry_Cal(Numb_TotalCal,1) = cellstr(Cal_value);
                switch j 
                    case {1,5,6,7,8}
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                        Arry_Cal(Numb_TotalCal,3) = cellstr('boolean');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(0);
                        Arry_Cal(Numb_TotalCal,5) = num2cell(1);
                        Arry_Cal(Numb_TotalCal,6) = cellstr('flg');
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        Arry_Cal(Numb_TotalCal,8) = num2cell(0);
                     case {2}
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                        Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(0);
                        Arry_Cal(Numb_TotalCal,5) = num2cell(255);
                        Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        Arry_Cal(Numb_TotalCal,8) = num2cell(100);
                     case {3}
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                        Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(0);
                        Arry_Cal(Numb_TotalCal,5) = num2cell(255);
                        Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        Arry_Cal(Numb_TotalCal,8) = num2cell(1);  
                     case {4}
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                        Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(0);
                        Arry_Cal(Numb_TotalCal,5) = num2cell(255);
                        Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        Arry_Cal(Numb_TotalCal,8) = num2cell(5);      
                 end        
            end
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' char(Subsubmodule)];
            port = get_param(dstT,'PortHandles'); 
            port_pos  = get_param(port.Outport(1),'position');
            
            str = ['VINP_',char(Subsubmodule),'_flg'];
            BlockName = char(str);
            block_x=port_pos(1)+300;
            block_y=port_pos(2)-7.5;
            block_w=block_x+30;
            block_h=block_y+15;
            srcT = 'simulink/Sinks/Out1';
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' BlockName];    
            add_block(srcT,dstT,'position',[block_x,block_y,block_w,block_h],'name',char(str)); 
            dstT=[new_model '/' ModuleName_Com '/' SubModule];
            h=add_line(dstT, [char(Subsubmodule) '/1'],[char(str) '/1']);
            set_param(h,'name',char(str));
            
            BlockName = ['From_' char(str)];
            srcT = 'simulink/Signal Routing/From';
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' BlockName];
            block_x=port_pos(1)-550;
            block_y=port_pos(2)-15;
            block_w=block_x+120;
            block_h=block_y+30;
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag','BHAL_outputs'); 
             
            str_sig = char(Arry_Digital(k,1));
            BlockName = ['slr_' char(str)];
            srcT = 'simulink/Signal Routing/Bus Selector';
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' BlockName];
            block_x=port_pos(1)-300;
            block_y=port_pos(2)-10;
            block_w=block_x+5;
            block_h=block_y+20;
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h],'showname','off', 'outputsignals',(str_sig));
                 
            dstT = [new_model '/' ModuleName_Com '/' SubModule];      
            add_line(dstT,['From_' char(str), '/1'],['slr_' char(str), '/1']); 
            add_line(dstT,['slr_' char(str), '/1'],[char(Subsubmodule), '/1']);
            
            Numb_Outputs = Numb_Outputs+1;
            Arry_outputs(Numb_Outputs,1) = cellstr(str);
            Arry_outputs(Numb_Outputs,2) = cellstr('output');
            Arry_outputs(Numb_Outputs,3) = cellstr('boolean');
            Arry_outputs(Numb_Outputs,4) =  num2cell(0);
            Arry_outputs(Numb_Outputs,5) =  num2cell(1);
            Arry_outputs(Numb_Outputs,6) = cellstr('flg');
        end

        dstT = [new_model '/' ModuleName_Com '/' SubModule]; 
        port = get_param(dstT,'PortHandles'); 
        numb = length(port.Outport);
        for k = 1:numb
            port_pos  = get_param(port.Outport(k),'position');
            str = char(Arry_outputs(Numb_Outputs-numb+k,1));
            Blockname = str;
            srcT = 'simulink/Signal Routing/Goto'; 
            dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
            block_x=port_pos(1)+150;
            block_y=port_pos(2)-15 ;
            block_w=block_x+200;
            block_h=block_y+30;
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h,'showname','off','Gototag',str);
            dstT=[new_model '/' ModuleName_Com];
            h=add_line(dstT, [SubModule '/' num2str(k)],[str '/1']);
            set_param(h,'name',['<',str,'>']);
        end
    end

    %% CAN

    if ~(strcmp(string(CANChannel),"CAN99"))
    categ = categorical(Arry_CAN(:,6));
    categty = categories(categ);
    countcats_A = countcats(categ);
    Numb_categty = length(categty);
    Cal_CAN ={'_defval','_ovrdflg','_ovrdval'};
    for k = 1:Numb_categty
        if isempty(SubModule)
            pos = [0,782,450,200];
        else
            dstT = [new_model '/' ModuleName_Com '/' SubModule]; 
            pos = get_param(dstT,'Position');
        end
        SubModule = char(categty(k,1));
        srcT = 'built-in/SubSystem';
        dstT = [new_model '/' ModuleName_Com '/' SubModule]; 
        block_x=pos(1);
        block_y=pos(4)+30;    
        block_w=pos(3);
        block_h=block_y+countcats_A(k)*40;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h],'ContentPreviewEnabled','off');
        
        Blockname = 'BHAL_outputs';    
        srcT2 = 'simulink/Sources/In1';
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname]; 
        block_x=original_x;
        block_y=original_y;
        block_w=block_x+30;
        block_h=block_y+13;
        h = add_block(srcT2,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]); 
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname];
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Outport(1),'position'); 
    
        Blockname = 'goto1';
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname]; 
        block_x=port_pos(1)+150;
        block_y=port_pos(2)-15 ;
        block_w=block_x+120;
        block_h=block_y+30;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'showname','off','Gototag','BHAL_outputs');
    
        dstT=[new_model '/' ModuleName_Com '/' SubModule];
        h=add_line(dstT, 'BHAL_outputs/1','goto1/1');
        set_param(h,'name','<BHAL_outputs>');
    
        Blockname = 'inp_CanValid_bus';    
        srcT2 = 'simulink/Sources/In1';
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname]; 
        block_x=original_x;
        block_y=port_pos(2)+30 ;
        block_w=block_x+30;
        block_h=block_y+13;
        h = add_block(srcT2,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]); 
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname]; 
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Outport(1),'position'); 
    
        Blockname = 'goto2';
        srcT = 'simulink/Signal Routing/Goto'; 
        dstT = [new_model '/' ModuleName_Com '/' SubModule '/' Blockname]; 
        block_x=port_pos(1)+150;
        block_y=port_pos(2)-15 ;
        block_w=block_x+120;
        block_h=block_y+30;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'showname','off','Gototag','inp_CanValid_bus');
    
        dstT=[new_model '/' ModuleName_Com '/' SubModule];
        h=add_line(dstT, 'inp_CanValid_bus/1','goto2/1');
        set_param(h,'name','<inp_CanValid_bus>');
        
        dstT = [new_model '/' ModuleName_Com '/' SubModule];
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Inport(1),'position'); 
        Blockname = ['Goto_' num2str(k)];
        srcT = 'simulink/Signal Routing/From'; 
        dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
        block_x=port_pos(1)-250;
        block_y=port_pos(2)-15 ;
        block_w=block_x+120;
        block_h=block_y+30;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag','BHAL_outputs');
        dstT=[new_model '/' ModuleName_Com];
        h=add_line(dstT, ['Goto_' num2str(k) '/1'],[SubModule '/1']);
        set_param(h,'name',['<','BHAL_outputs','>']);
        
        dstT = [new_model '/' ModuleName_Com '/' SubModule];
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Inport(2),'position'); 
        Blockname = ['Goto1_' num2str(k)];
        srcT = 'simulink/Signal Routing/From'; 
        dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
        block_x=port_pos(1)-250;
        block_y=port_pos(2)-15 ;
        block_w=block_x+120;
        block_h=block_y+30;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag','inp_CanValid_bus');
        dstT=[new_model '/' ModuleName_Com];
        h=add_line(dstT, ['Goto1_' num2str(k) '/1'],[SubModule '/2']);
        set_param(h,'name',['<','inp_CanValid_bus','>']);
        
        SignalPlace = find(contains(Arry_CAN(1:end,6),categty(k)));
        m = SignalPlace(1);
        n = m + countcats_A(k) - 1;
        
        j_in = 0;
        clear Arry_temp; 
        Arry_temp = {'','',''};
        Numb_outport = 0;
        tmp_cnt =0;
        for j = m:n
            j_in = j_in+1; 
            tmp_cnt = tmp_cnt +1;
            str = Arry_CAN(j,1); 
            str_unit = erase(str,'VHAL_');
            Subsubmodule = extractBefore(str_unit,'_');        
            srcT = 'FVT_lib/inp/can_signal_template';
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' char(Subsubmodule)]; 
            block_x = original_x+300;
            block_y = original_y+170*j_in;
            block_w = block_x+350;
            block_h = block_y+150;
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h])
%             set_param(h,'LinkStatus', 'inactive');
    
            for s = 1:length(Cal_CAN) 
                cal = char(Cal_CAN(s));
                Block_cal = erase(cal,'_');
                Cal_value = strcat('KINP_',str_unit,cal);
                dstT = [new_model '/' ModuleName_Com '/' SubModule '/' char(Subsubmodule) '/' Block_cal];   
                set_param(dstT,'Value',char(Cal_value));
                Numb_TotalCal = Numb_TotalCal + 1;
                Arry_Cal(Numb_TotalCal,1) = cellstr(Cal_value);

                switch s
                    case {1}
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                        Arry_Cal(Numb_TotalCal,3) = cellstr(Arry_CAN(j,2));
                        Arry_Cal(Numb_TotalCal,4) = num2cell(str2double(Arry_CAN(j,3)));
                        Arry_Cal(Numb_TotalCal,5) = num2cell(str2double(Arry_CAN(j,4)));
                        Arry_Cal(Numb_TotalCal,6) = cellstr(Arry_CAN(j,5));
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        if (0<str2double(Arry_CAN(j,3)))
                            Arry_Cal(Numb_TotalCal,8) = num2cell(str2double(Arry_CAN(j,3)));
                        else
                            Arry_Cal(Numb_TotalCal,8) = num2cell(0);
                        end
%                      case {2}
%                         Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
%                         Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
%                         Arry_Cal(Numb_TotalCal,4) = num2cell(0);
%                         Arry_Cal(Numb_TotalCal,5) = num2cell(255);
%                         Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
%                         Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
%                         Arry_Cal(Numb_TotalCal,8) = num2cell(100);
%                      case {3}
%                         Arry_Cal(Numb_TotalCal,2) = cellstr('internal'); 
%                         Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
%                         Arry_Cal(Numb_TotalCal,4) = num2cell(0);
%                         Arry_Cal(Numb_TotalCal,5) = num2cell(255);
%                         Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
%                         Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
%                         Arry_Cal(Numb_TotalCal,8) = num2cell(5);  
%                      case {4}
%                         Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
%                         Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
%                         Arry_Cal(Numb_TotalCal,4) = num2cell(0);
%                         Arry_Cal(Numb_TotalCal,5) = num2cell(255);
%                         Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
%                         Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
%                         Arry_Cal(Numb_TotalCal,8) = num2cell(10);
                     case {2}
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                        Arry_Cal(Numb_TotalCal,3) = cellstr('boolean');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(0);
                        Arry_Cal(Numb_TotalCal,5) = num2cell(1);
                        Arry_Cal(Numb_TotalCal,6) = cellstr('flg');
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        Arry_Cal(Numb_TotalCal,8) = num2cell(0);
                     case {3}
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal'); 
                        Arry_Cal(Numb_TotalCal,3) = cellstr(Arry_CAN(j,2));
                        Arry_Cal(Numb_TotalCal,4) = num2cell(str2double(Arry_CAN(j,3)));
                        Arry_Cal(Numb_TotalCal,5) = num2cell(str2double(Arry_CAN(j,4)));
                        Arry_Cal(Numb_TotalCal,6) = cellstr(Arry_CAN(j,5));
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        if (0<str2double(Arry_CAN(j,3)))
                            Arry_Cal(Numb_TotalCal,8) = num2cell(str2double(Arry_CAN(j,3)));
                        else
                            Arry_Cal(Numb_TotalCal,8) = num2cell(0);
                        end
                end
            end

            
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' char(Subsubmodule)];
            port = get_param(dstT,'PortHandles'); 
            port_pos  = get_param(port.Inport(1),'position');
            BlockName = ['From_' char(str)];
            srcT = 'simulink/Signal Routing/From';
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' BlockName];
            block_x=port_pos(1)-400;
            block_y=port_pos(2)-15;
            block_w=block_x+120;
            block_h=block_y+30;
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag','BHAL_outputs'); 
            BlockName = ['slr_' char(str)];
            srcT = 'simulink/Signal Routing/Bus Selector';
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' BlockName];
            block_x=port_pos(1)-200;
            block_y=port_pos(2)-10;
            block_w=block_x+5;
            block_h=block_y+20;
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h],'showname','off', 'outputsignals',(str));
            dstT = [new_model '/' ModuleName_Com '/' SubModule];      
            add_line(dstT,['From_' char(str), '/1'],['slr_' char(str), '/1']); 
            add_line(dstT,['slr_' char(str), '/1'],[char(Subsubmodule), '/1']);
            
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' char(Subsubmodule)];
            port = get_param(dstT,'PortHandles'); 
            port_pos  = get_param(port.Inport(2),'position');
            BlockName = ['True_' char(str)];
            block_x=port_pos(1)-150;
            block_y=port_pos(2)-10;
            block_w=block_x+60; 
            block_h=block_y+20;
            srcT = 'simulink/Sources/Constant';
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' BlockName];
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h],'showname','off','value','TRUE','OutDataTypeStr','boolean');
            dstT = [new_model '/' ModuleName_Com '/' SubModule];      
            add_line(dstT,['True_' char(str), '/1'],[char(Subsubmodule), '/2']);
    
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' char(Subsubmodule)];
            port = get_param(dstT,'PortHandles'); 
            port_pos  = get_param(port.Inport(3),'position');
            BlockName = ['From1_' char(str)];
            srcT = 'simulink/Signal Routing/From';
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' BlockName];
            block_x=port_pos(1)-400;
            block_y=port_pos(2)-15;
            block_w=block_x+120;
            block_h=block_y+30;
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag','inp_CanValid_bus');
            if IsLINMessage
                str_valid = ['VINP_LINMsgValid' erase(SubModule,'_') '_flg'];

            elseif strcmp(string(CANChannel),"CAN99")
                str_valid = ['VINP_CAN6CANMsgValid' erase(SubModule,'_') '_flg']; 
          
            else
                str_valid = ['VINP_CANMsgValid' erase(SubModule,'_') '_flg']; 
            end

            BlockName = ['slr1_' num2str(tmp_cnt)];
            srcT = 'simulink/Signal Routing/Bus Selector';
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' BlockName];
            block_x=port_pos(1)-200;
            block_y=port_pos(2)-10;
            block_w=block_x+5;
            block_h=block_y+20;
            h = add_block(srcT,dstT);
            set_param(h,'position',[block_x,block_y,block_w,block_h],'showname','off', 'outputsignals',char(str_valid));
            dstT = [new_model '/' ModuleName_Com '/' SubModule];   
            str_1 = Arry_CAN(j,1);
            add_line(dstT,['From1_' char(str_1), '/1'],['slr1_' num2str(tmp_cnt), '/1']); 
            add_line(dstT,['slr1_' num2str(tmp_cnt), '/1'],[char(Subsubmodule), '/3']);
            
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' char(Subsubmodule)];
            port = get_param(dstT,'PortHandles'); 
            port_pos  = get_param(port.Outport(1),'position');
            
            str_out = erase(str,'VHAL');
            str_out = ['VINP',char(str_out)];
            BlockName = char(str_out);
            block_x=port_pos(1)+200;
            block_y=port_pos(2)-7.5;
            block_w=block_x+30;
            block_h=block_y+15;
            srcT = 'simulink/Sinks/Out1';
            dstT = [new_model '/' ModuleName_Com '/' SubModule '/' BlockName];    
            add_block(srcT,dstT,'position',[block_x,block_y,block_w,block_h],'name',char(str_out)); 
            dstT=[new_model '/' ModuleName_Com '/' SubModule];
            h=add_line(dstT, [char(Subsubmodule) '/1'],[char(str_out) '/1']);
            set_param(h,'name',char(str_out));

            Numb_outport = Numb_outport + 1;
            Arry_temp(Numb_outport,1) = cellstr(str_out);
            Arry_temp(Numb_outport,2) = cellstr('x'); 
            sig_valid = Arry_CAN(j,7);
            Numb_Outputs = Numb_Outputs+1;
            Arry_outputs(Numb_Outputs,1) = cellstr(str_out);
            Arry_outputs(Numb_Outputs,2) = cellstr('output');
            Arry_outputs(Numb_Outputs,3) = cellstr(Arry_CAN(j,2));
            Arry_outputs(Numb_Outputs,4) = num2cell(str2double(Arry_CAN(j,3)));
            Arry_outputs(Numb_Outputs,5) = num2cell(str2double(Arry_CAN(j,4)));
            Arry_outputs(Numb_Outputs,6) = cellstr(Arry_CAN(j,5));
            if (sig_valid=='V')
                str_out = erase(str,'VHAL_');
                str_out = extractBefore(str_out,'_');
                str_out = ['VINP_' char(str_out) 'Valid' '_flg'];
                Numb_outport = Numb_outport + 1;
                Arry_temp(Numb_outport,1) = cellstr(str_out);
                Arry_temp(Numb_outport,2) = cellstr('v'); 
                dstT = [new_model '/' ModuleName_Com '/' SubModule '/' char(Subsubmodule)];
                port = get_param(dstT,'PortHandles'); 
                port_pos  = get_param(port.Outport(2),'position');

                BlockName = char(str_out);
                block_x=port_pos(1)+200;
                block_y=port_pos(2)-7.5;
                block_w=block_x+30;
                block_h=block_y+15;
                srcT = 'simulink/Sinks/Out1';
                dstT = [new_model '/' ModuleName_Com '/' SubModule '/' BlockName];    
                add_block(srcT,dstT,'position',[block_x,block_y,block_w,block_h],'name',char(str_out),'BackgroundColor','red'); 
                dstT=[new_model '/' ModuleName_Com '/' SubModule];
                h=add_line(dstT, [char(Subsubmodule) '/2'],[char(str_out) '/1']);
                set_param(h,'name',char(str_out));   
                
                Numb_Outputs = Numb_Outputs+1;
                Arry_outputs(Numb_Outputs,1) = cellstr(str_out);
                Arry_outputs(Numb_Outputs,2) = cellstr('output');
                Arry_outputs(Numb_Outputs,3) = cellstr('boolean');
                Arry_outputs(Numb_Outputs,4) = num2cell(0);
                Arry_outputs(Numb_Outputs,5) = num2cell(1);
                Arry_outputs(Numb_Outputs,6) = cellstr('flg');
            else
                dstT = [new_model '/' ModuleName_Com '/' SubModule '/' char(Subsubmodule)];
                port = get_param(dstT,'PortHandles'); 
                port_pos  = get_param(port.Outport(2),'position');
                BlockName = ['Terminator_' num2str(j_in)];
                block_x=port_pos(1)+200;
                block_y=port_pos(2)-15;
                block_w=block_x+30;
                block_h=block_y+30;
                srcT = 'simulink/Sinks/Terminator';
                dstT = [new_model '/' ModuleName_Com '/' SubModule '/' BlockName];    
                add_block(srcT,dstT,'position',[block_x,block_y,block_w,block_h],'showname','off'); 
                dstT=[new_model '/' ModuleName_Com '/' SubModule];
                add_line(dstT, [char(Subsubmodule) '/2'],['Terminator_' num2str(j_in) '/1']);
            end                         
        end

        for temp_i = 1:Numb_outport
            dstT = [new_model '/' ModuleName_Com '/' SubModule];
            port = get_param(dstT,'PortHandles'); 
            port_pos  = get_param(port.Outport(temp_i),'position');
                
            Blockname = char(Arry_temp(temp_i,1));
            srcT = 'simulink/Signal Routing/Goto'; 
            dstT = [new_model '/' ModuleName_Com '/' Blockname]; 
            block_x=port_pos(1)+150;
            block_y=port_pos(2)-15 ;
            block_w=block_x+200;
            block_h=block_y+30;            
    
            if (char(Arry_temp(temp_i,2)) =='v')        
                h = add_block(srcT,dstT);
                set_param(h,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag',char(Blockname),'BackgroundColor','red');
            else 
                h = add_block(srcT,dstT);
                set_param(h,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag',char(Blockname));
            end
            dstT=[new_model '/' ModuleName_Com];
            h=add_line(dstT, [SubModule '/' num2str(temp_i)],[Blockname '/1']);
            set_param(h,'name',['<',Blockname,'>']); 
        end
    end
%
    temp_i = 0;
    for k = Numb_CANValid+1:Numb_Outputs
        temp_i = temp_i+1;
        str = char(Arry_outputs(k,1));
        BlockName= ['From_' str];
        block_x=original_x+1200;
        block_y=original_y+150+050*temp_i;
        block_w=block_x+200;
        block_h=block_y+30;
        srcT = 'simulink/Signal Routing/From';
        dstT = [new_model '/' ModuleName_Com '/' BlockName];    
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'showname','off','Gototag',str);    
    end

    Sscrt='bus_creator'; 
    srcT = 'simulink/Signal Routing/Bus Creator';
    dstT = [new_model '/' ModuleName_Com '/' Sscrt]; 
    block_x=original_x+1600;
    block_y=original_y+190;
    block_w=block_x+10;
    block_h=block_y+50*temp_i;
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h],'ShowName','off','inputs',num2str(temp_i)); 
    dstT = [new_model '/' ModuleName_Com '/' Sscrt];
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Outport(1),'position');

    str_out = 'inp_Hal_bus';
    BlockName = char(str_out);
    block_x=port_pos(1)+200;
    block_y=port_pos(2)-7.5;
    block_w=block_x+30;
    block_h=block_y+15;
    srcT = 'simulink/Sinks/Out1';
    dstT = [new_model '/' ModuleName_Com '/' BlockName];    
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h])
    set_param(h,'name',char(str_out));

    dstT=[new_model '/' ModuleName_Com];
    h=add_line(dstT, [Sscrt '/1'],[char(str_out) '/1']);
    set_param(h,'name',['<',str_out,'>']);

    temp_i = 0;
    for k = Numb_CANValid+1:Numb_Outputs
        temp_i = temp_i+1;
        str = char(Arry_outputs(k,1));    
        dstT=[new_model '/' ModuleName_Com];
        h=add_line(dstT, ['From_' str '/1'],[Sscrt '/' num2str(temp_i)]);
        set_param(h,'name',['<',char(str),'>']);  
    end 
    end
    %% CreateBus
    if ~(strcmp(string(CANChannel),"CAN99"))
    Blockname = 'inp_CanValid_bus';    
    srcT2 = 'simulink/Sources/In1';
    dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
    block_x=original_x;
    block_y=original_y;
    block_w=block_x+30;
    block_h=block_y+13;
    h = add_block(srcT2,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]); 
    dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Outport(1),'position'); 

    Blockname = 'goto1';
    srcT = 'simulink/Signal Routing/Goto';
    dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
    block_x=port_pos(1)+150;
    block_y=port_pos(2)-15 ;
    block_w=block_x+120;
    block_h=block_y+30;
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h])
    set_param(h,'showname','off','Gototag','inp_CanValid_bus');

    dstT=[new_model '/' ModuleName_Bus];
    h=add_line(dstT, 'inp_CanValid_bus/1','goto1/1');
    set_param(h,'name','<inp_CanValid_bus>');

    Blockname = 'inp_Hal_bus';    
    srcT2 = 'simulink/Sources/In1';
    dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
    block_x=original_x;
    block_y=port_pos(2)+30 ;
    block_w=block_x+30;
    block_h=block_y+13;
    h = add_block(srcT2,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]); 
    dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Outport(1),'position'); 

    Blockname = 'goto2';
    srcT = 'simulink/Signal Routing/Goto'; 
    dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
    block_x=port_pos(1)+150;
    block_y=port_pos(2)-15 ;
    block_w=block_x+120;
    block_h=block_y+30;
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h])
    set_param(h,'showname','off','Gototag','inp_Hal_bus');

    dstT = [new_model '/' ModuleName_Bus]; 
    h=add_line(dstT, 'inp_Hal_bus/1','goto2/1');
    set_param(h,'name','<inp_Hal_bus>');
    
    % Blockname = 'inp_InNew_bus';    
    % srcT2 = 'simulink/Sources/In1';
    % dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
    % block_x=original_x;
    % block_y=port_pos(2)+30 ;
    % block_w=block_x+30;
    % block_h=block_y+13;
    % Hal = add_block(srcT2,dstT);
    % set_param(Hal,'position',[block_x,block_y,block_w,block_h]); 
    % dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
    % port = get_param(dstT,'PortHandles'); 
    % port_pos  = get_param(port.Outport(1),'position'); 
    % 
    % Blockname = 'goto3';
    % srcT = 'simulink/Signal Routing/Goto'; 
    % dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
    % block_x=port_pos(1)+150;
    % block_y=port_pos(2)-15 ;
    % block_w=block_x+120;
    % block_h=block_y+30;
    % Hal = add_block(srcT,dstT);
    % set_param(Hal,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag','inp_InNew_bus');
    % 
    % dstT = [new_model '/' ModuleName_Bus]; 
    % H_line=add_line(dstT, ['inp_InNew_bus/1'],['goto3/1']);
    % set_param(H_line,'name','<inp_InNew_bus>');
    
    dstT = [new_model '/' ModuleName_Bus '/inp_Hal_bus']; 
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Outport(1),'position'); 


    Ssrct_name='bus_selector'; 
    srcT = 'simulink/Signal Routing/Bus Selector';
    dstT = [new_model '/' ModuleName_Bus '/' Ssrct_name]; 
    block_x=port_pos(1);
    block_y=port_pos(2)+50;
    block_w=block_x+10;
    block_h=block_y+50*Numb_CANValid;
    h = add_block(srcT,dstT); 

    sigoutputs = "";
    for k=1:Numb_CANValid
        str = char(Arry_outputs(k,1));
        if (k==1)
            sigoutputs = str;
        else
            sigoutputs = strcat(sigoutputs,',',str);
        end
    end
    if Numb_CANValid ~= 0
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'ShowName','off','outputsignals',sigoutputs); 
    end
 
    dstT = [new_model '/' ModuleName_Bus '/' Ssrct_name]; 
    port = get_param(dstT,'Position'); 

    Ssrct_name1='bus_selector_1'; 
    srcT = 'simulink/Signal Routing/Bus Selector';
    dstT = [new_model '/' ModuleName_Bus '/' Ssrct_name1]; 
    block_x=port(1);
    block_y=port(4);
    block_w=block_x+10;
    block_h=block_y+50*(Numb_Outputs-Numb_CANValid);
    h = add_block(srcT,dstT); 

    sigoutputs = "";
    for k=Numb_CANValid+1:Numb_Outputs
        str = char(Arry_outputs(k,1));
        if (k==Numb_CANValid+1)
            sigoutputs = str;
        else
            sigoutputs = strcat(sigoutputs,',',str);
        end
    end 
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'ShowName','off','outputsignals',sigoutputs);


    Sscrt_name2='bus_creator'; 
    srcT = 'simulink/Signal Routing/Bus Creator';
    dstT = [new_model '/' ModuleName_Bus '/' Sscrt_name2]; 
    block_x=port(1)+500;
    block_y=port(2);
    block_w=block_x+10;
    block_h=block_y+50*Numb_Outputs;
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'ShowName','off','inputs',num2str(Numb_Outputs));
    %
 
    temp_i = 0;
    for k = 1:Numb_Outputs
        dstT = [new_model '/' ModuleName_Bus '/' Sscrt_name2]; 
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Inport(k),'position');
        str = Arry_outputs(k,1);
        unit = Arry_outputs(k,3);
        Blockname = ['UnitConverter_' num2str(k)];
        srcT = 'simulink/Signal Attributes/Data Type Conversion';
        dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
        block_x=port_pos(1)-300;
        block_y=port_pos(2)-15;
        block_w=block_x+80;
        block_h=block_y+30;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'showname','off','OutDataTypeStr',char(unit)); 
        
        dstT=[new_model '/' ModuleName_Bus];
        if (k <=Numb_CANValid)
            add_line(dstT, [Ssrct_name '/' num2str(k)],[Blockname '/1']);
            h=add_line(dstT, [Blockname '/1'],[Sscrt_name2 '/' num2str(k)]);
        else
            temp_i = temp_i +1;
            add_line(dstT, [Ssrct_name1 '/' num2str(temp_i)],[Blockname '/1']);
            h=add_line(dstT, [Blockname '/1'],[Sscrt_name2 '/' num2str(k)]);       
        end
        set(h,'name',char(str));
        set(h,'MustResolveToSignalObject',1);
    end
 
    dstT = [new_model '/' ModuleName_Bus '/' Ssrct_name]; 
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Inport(1),'position');
    BlockName = 'Goto_1';
    srcT = 'simulink/Signal Routing/From';
    dstT = [new_model '/' ModuleName_Bus '/' BlockName];
    block_x=port_pos(1)-150;
    block_y=port_pos(2)-15;
    block_w=block_x+120;
    block_h=block_y+30;
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h])
    set_param(h,'showname','off','Gototag','inp_CanValid_bus'); 
    dstT=[new_model '/' ModuleName_Bus];
    add_line(dstT, [BlockName '/1'],[Ssrct_name '/1']);

    dstT = [new_model '/' ModuleName_Bus '/' Ssrct_name1]; 
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Inport(1),'position');
    BlockName = 'Goto_2';
    srcT = 'simulink/Signal Routing/From';
    dstT = [new_model '/' ModuleName_Bus '/' BlockName];
    block_x=port_pos(1)-150;
    block_y=port_pos(2)-15;
    block_w=block_x+120;
    block_h=block_y+30;
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'showname','off','Gototag','inp_Hal_bus'); 

    dstT=[new_model '/' ModuleName_Bus];
    add_line(dstT, [BlockName '/1'],[Ssrct_name1 '/1']);

    dstT = [new_model '/' ModuleName_Bus '/' Sscrt_name2]; 
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Outport(1),'position');
    BlockName= 'BINP_outputs';
    block_x=port_pos(1)+150;
    block_y=port_pos(2)-7.5;
    block_w=block_x+30;
    block_h=block_y+15;
    srcT = 'simulink/Sinks/Out1';
    dstT = [new_model '/CreateBus' '/' BlockName];     
    add_block(srcT,dstT,'position',[block_x,block_y,block_w,block_h]); 

    dstT=[new_model '/' ModuleName_Bus];
    h=add_line(dstT, [Sscrt_name2 '/1'],['BINP_outputs' '/1']);
    set_param(h,'name','<BINP_outputs>');
    
    %% Main frame
    % dstT = [new_model '/' ModuleName_New];
    if Numb_CANValid ~= 0
        % Blockname = 'inp_CanValid_bus';    
        % srcT2 = 'simulink/Sources/In1';
        % dstT = [new_model '/' ModuleName_New '/' Blockname]; 
        % block_x=original_x;
        % block_y=original_y;
        % block_w=block_x+30;
        % block_h=block_y+13;
        % Hal = add_block(srcT2,dstT);
        % set_param(Hal,'position',[block_x,block_y,block_w,block_h]); 
        % dstT = [new_model '/' ModuleName_New '/' Blockname]; 
        % port = get_param(dstT,'PortHandles'); 
        % port_pos  = get_param(port.Outport(1),'position'); 
        % Blockname = 'goto1';
        % srcT = 'simulink/Signal Routing/Goto';
        % dstT = [new_model '/' ModuleName_New '/' Blockname]; 
        % block_x=port_pos(1)+150;
        % block_y=port_pos(2)-15 ;
        % block_w=block_x+120;
        % block_h=block_y+30;
        % Hal = add_block(srcT,dstT);
        % set_param(Hal,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag','inp_CanValid_bus');
        % dstT=[new_model '/' ModuleName_New];
        % H_line=add_line(dstT, ['inp_CanValid_bus' '/1'],[Blockname '/1']);
        % set_param(H_line,'name','<inp_CanValid_bus>');
        
        % dstT = [new_model '/' ModuleName_New]; 
        % str_out = 'inp_InNew_bus';
        % BlockName = char(str_out);
        % block_x=port_pos(1)+350;
        % block_y=port_pos(2);
        % block_w=block_x+30;
        % block_h=block_y+15;
        % srcT = 'simulink/Sinks/Out1';
        % dstT = [new_model '/' ModuleName_New '/' BlockName];    
        % h = add_block(srcT,dstT,'position',[block_x,block_y,block_w,block_h],'name',str_out); 
        
        dstT = [new_model '/' ModuleName_Valid]; 
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Outport(1),'position');
        Blockname= 'inp_CanValid_bus';
        block_x=port_pos(1)+50;
        block_y=port_pos(2)-150;
        block_w=block_x+100;
        block_h=block_y+30;
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [new_model '/' Blockname];    
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'showname','off','Gototag','inp_CanValid_bus');  
        
        dstT = [new_model '/' ModuleName_Bus]; 
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Inport(1),'position');
        Blockname= 'From_inp_CanValid_bus';
        block_x=port_pos(1)-150;
        block_y=port_pos(2)-15;
        block_w=block_x+100;
        block_h=block_y+30;
        srcT = 'simulink/Signal Routing/From';
        dstT = [new_model '/' Blockname];    
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'showname','off','Gototag','inp_CanValid_bus');  
        
        % dstT = [new_model '/' ModuleName_New]; 
        % port = get_param(dstT,'PortHandles'); 
        % port_pos  = get_param(port.Inport(1),'position');
        % Blockname= 'From_inp_CanValid_bus1';
        % block_x=port_pos(1)-150;
        % block_y=port_pos(2)-15;
        % block_w=block_x+100;
        % block_h=block_y+30;
        % srcT = 'simulink/Signal Routing/From';
        % dstT = [new_model '/' Blockname];    
        % h = add_block(srcT,dstT,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag','inp_CanValid_bus');  
    
        dstT = [new_model '/' ModuleName_Valid]; 
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Inport(1),'position');
        Blockname = ['BHAL_' CANChannel '_outputs'];    
        dstT = [new_model '/' Blockname]; 
        block_x=port_pos(1)-150;
        block_y=port_pos(2)-6.5 ;
        block_w=block_x+30;
        block_h=block_y+13;
        set_param(dstT,'position',[block_x,block_y,block_w,block_h]);
    end

    dstT = [new_model '/' ModuleName_Bus]; 
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Outport(1),'position');
    Blockname = ['INP_' CANChannel '_outputs'];    
    dstT = [new_model '/' Blockname]; 
    block_x=port_pos(1)+150;
    block_y=port_pos(2)-6.5 ;
    block_w=block_x+30;
    block_h=block_y+13;
    set_param(dstT,'position',[block_x,block_y,block_w,block_h]);  

    dstT = [new_model '/' ModuleName_Com]; 
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Inport(2),'position');
    Blockname = 'ctasktime';
    block_x=port_pos(1)-150;
    block_y=port_pos(2)-15;
    block_w=block_x+100;
    block_h=block_y+30;
    srcT = 'simulink/Sources/Constant';
    dstT = [new_model '/' Blockname]; 
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h])
    set_param(h,'showname','off','value','C_TASK_5MS_S','OutDataTypeStr','single');

    dstT = new_model;
    
    if Numb_CANValid ~= 0
        add_line(dstT, [ModuleName_Bus '/1'],['INP_' CANChannel '_outputs' '/1']);
        add_line(dstT, [ModuleName_Valid '/1'],['inp_CanValid_bus' '/1'],'autorouting','on');
        add_line(dstT, ['From_inp_CanValid_bus' '/1'],[ModuleName_Bus '/1']);
        % H4=add_line(dstT, ['From_inp_CanValid_bus1' '/1'],[ModuleName_New '/1']);
        % H5=add_line(dstT, [ModuleName_New '/1'],[ModuleName_Bus '/3'],'autorouting','on');
        add_line(dstT, ['BHAL_' CANChannel '_outputs' '/1'],[ModuleName_Valid '/1'],'autorouting','on');
        add_line(dstT, ['BHAL_' CANChannel '_outputs' '/1'],[ModuleName_Com '/3'],'autorouting','on');
        add_line(dstT, [ModuleName_Valid '/1'],[ModuleName_Com '/1']);
        add_line(dstT, [ModuleName_Com '/1'],[ModuleName_Bus '/2'],'autorouting','on');
        add_line(dstT, ['ctasktime' '/1'],[ModuleName_Com '/2']);
    end
 else
    %% For Can6
    Blockname = 'inp_CanValid_bus';    
    srcT2 = 'simulink/Sources/In1';
    dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
    block_x=original_x;
    block_y=original_y;
    block_w=block_x+30;
    block_h=block_y+13;
    h = add_block(srcT2,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]); 
    dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Outport(1),'position'); 

    Blockname = 'goto1';
    srcT = 'simulink/Signal Routing/Goto';
    dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
    block_x=port_pos(1)+150;
    block_y=port_pos(2)-15 ;
    block_w=block_x+120;
    block_h=block_y+30;
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h])
    set_param(h,'showname','off','Gototag','inp_CanValid_bus');

    dstT=[new_model '/' ModuleName_Bus];
    h=add_line(dstT, 'inp_CanValid_bus/1','goto1/1');
    set_param(h,'name','<inp_CanValid_bus>');

    Ssrct_name='bus_selector'; 
    srcT = 'simulink/Signal Routing/Bus Selector';
    dstT = [new_model '/' ModuleName_Bus '/' Ssrct_name]; 
    block_x=port_pos(1);
    block_y=port_pos(2)+50;
    block_w=block_x+10;
    block_h=block_y+50*Numb_CANValid;
    h = add_block(srcT,dstT); 

    sigoutputs = "";
    for k=1:Numb_CANValid
        str = char(Arry_outputs(k,1));
        if (k==1)
            sigoutputs = str;
        else
            sigoutputs = strcat(sigoutputs,',',str);
        end
    end
    if Numb_CANValid ~= 0
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'ShowName','off','outputsignals',sigoutputs); 
    end

    Sscrt_name2='bus_creator'; 
    srcT = 'simulink/Signal Routing/Bus Creator';
    dstT = [new_model '/' ModuleName_Bus '/' Sscrt_name2]; 
    block_x=port_pos(1)+500;
    block_y=port_pos(2)+50;
    block_w=block_x+10;
    block_h=block_y+50*Numb_Outputs;
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'ShowName','off','inputs',num2str(Numb_Outputs));
    %
 
    temp_i = 0;
    for k = 1:Numb_Outputs
        dstT = [new_model '/' ModuleName_Bus '/' Sscrt_name2]; 
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Inport(k),'position');
        str = Arry_outputs(k,1);
        unit = Arry_outputs(k,3);
        Blockname = ['UnitConverter_' num2str(k)];
        srcT = 'simulink/Signal Attributes/Data Type Conversion';
        dstT = [new_model '/' ModuleName_Bus '/' Blockname]; 
        block_x=port_pos(1)-300;
        block_y=port_pos(2)-15;
        block_w=block_x+80;
        block_h=block_y+30;
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'showname','off','OutDataTypeStr',char(unit)); 
        
        dstT=[new_model '/' ModuleName_Bus];
        if (k <=Numb_CANValid)
            add_line(dstT, [Ssrct_name '/' num2str(k)],[Blockname '/1']);
            h=add_line(dstT, [Blockname '/1'],[Sscrt_name2 '/' num2str(k)]);
        else
            temp_i = temp_i +1;
            add_line(dstT, [Ssrct_name1 '/' num2str(temp_i)],[Blockname '/1']);
            h=add_line(dstT, [Blockname '/1'],[Sscrt_name2 '/' num2str(k)]);       
        end
        set(h,'name',char(str));
        set(h,'MustResolveToSignalObject',1);
    end
 
    dstT = [new_model '/' ModuleName_Bus '/' Ssrct_name]; 
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Inport(1),'position');
    BlockName = 'Goto_1';
    srcT = 'simulink/Signal Routing/From';
    dstT = [new_model '/' ModuleName_Bus '/' BlockName];
    block_x=port_pos(1)-150;
    block_y=port_pos(2)-15;
    block_w=block_x+120;
    block_h=block_y+30;
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h])
    set_param(h,'showname','off','Gototag','inp_CanValid_bus'); 
    dstT=[new_model '/' ModuleName_Bus];
    add_line(dstT, [BlockName '/1'],[Ssrct_name '/1']);

    dstT = [new_model '/' ModuleName_Bus '/' Sscrt_name2]; 
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Outport(1),'position');
    BlockName= 'BINP_outputs';
    block_x=port_pos(1)+150;
    block_y=port_pos(2)-7.5;
    block_w=block_x+30;
    block_h=block_y+15;
    srcT = 'simulink/Sinks/Out1';
    dstT = [new_model '/CreateBus' '/' BlockName];     
    add_block(srcT,dstT,'position',[block_x,block_y,block_w,block_h]); 

    dstT=[new_model '/' ModuleName_Bus];
    h=add_line(dstT, [Sscrt_name2 '/1'],['BINP_outputs' '/1']);
    set_param(h,'name','<BINP_outputs>');
    
    %% Main frame
    % dstT = [new_model '/' ModuleName_New];
    if Numb_CANValid ~= 0
        % Blockname = 'inp_CanValid_bus';    
        % srcT2 = 'simulink/Sources/In1';
        % dstT = [new_model '/' ModuleName_New '/' Blockname]; 
        % block_x=original_x;
        % block_y=original_y;
        % block_w=block_x+30;
        % block_h=block_y+13;
        % Hal = add_block(srcT2,dstT);
        % set_param(Hal,'position',[block_x,block_y,block_w,block_h]); 
        % dstT = [new_model '/' ModuleName_New '/' Blockname]; 
        % port = get_param(dstT,'PortHandles'); 
        % port_pos  = get_param(port.Outport(1),'position'); 
        % Blockname = 'goto1';
        % srcT = 'simulink/Signal Routing/Goto';
        % dstT = [new_model '/' ModuleName_New '/' Blockname]; 
        % block_x=port_pos(1)+150;
        % block_y=port_pos(2)-15 ;
        % block_w=block_x+120;
        % block_h=block_y+30;
        % Hal = add_block(srcT,dstT);
        % set_param(Hal,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag','inp_CanValid_bus');
        % dstT=[new_model '/' ModuleName_New];
        % H_line=add_line(dstT, ['inp_CanValid_bus' '/1'],[Blockname '/1']);
        % set_param(H_line,'name','<inp_CanValid_bus>');
        
        % dstT = [new_model '/' ModuleName_New]; 
        % str_out = 'inp_InNew_bus';
        % BlockName = char(str_out);
        % block_x=port_pos(1)+350;
        % block_y=port_pos(2);
        % block_w=block_x+30;
        % block_h=block_y+15;
        % srcT = 'simulink/Sinks/Out1';
        % dstT = [new_model '/' ModuleName_New '/' BlockName];    
        % h = add_block(srcT,dstT,'position',[block_x,block_y,block_w,block_h],'name',str_out); 
        
        dstT = [new_model '/' ModuleName_Valid]; 
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Outport(1),'position');
        Blockname= 'inp_CanValid_bus';
        block_x=port_pos(1)+50;
        block_y=port_pos(2)-150;
        block_w=block_x+100;
        block_h=block_y+30;
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [new_model '/' Blockname];    
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'showname','off','Gototag','inp_CanValid_bus');  
        
        dstT = [new_model '/' ModuleName_Bus]; 
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Inport(1),'position');
        Blockname= 'From_inp_CanValid_bus';
        block_x=port_pos(1)-150;
        block_y=port_pos(2)-15;
        block_w=block_x+100;
        block_h=block_y+30;
        srcT = 'simulink/Signal Routing/From';
        dstT = [new_model '/' Blockname];    
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h])
        set_param(h,'showname','off','Gototag','inp_CanValid_bus');  
        
        % dstT = [new_model '/' ModuleName_New]; 
        % port = get_param(dstT,'PortHandles'); 
        % port_pos  = get_param(port.Inport(1),'position');
        % Blockname= 'From_inp_CanValid_bus1';
        % block_x=port_pos(1)-150;
        % block_y=port_pos(2)-15;
        % block_w=block_x+100;
        % block_h=block_y+30;
        % srcT = 'simulink/Signal Routing/From';
        % dstT = [new_model '/' Blockname];    
        % h = add_block(srcT,dstT,'position',[block_x,block_y,block_w,block_h],'showname','off','Gototag','inp_CanValid_bus');  
    
        dstT = [new_model '/' ModuleName_Valid]; 
        port = get_param(dstT,'PortHandles'); 
        port_pos  = get_param(port.Inport(1),'position');
        Blockname = ['BHAL_' CANChannel '_outputs'];    
        dstT = [new_model '/' Blockname]; 
        block_x=port_pos(1)-150;
        block_y=port_pos(2)-6.5 ;
        block_w=block_x+30;
        block_h=block_y+13;
        set_param(dstT,'position',[block_x,block_y,block_w,block_h]);
    end

    dstT = [new_model '/' ModuleName_Bus]; 
    port = get_param(dstT,'PortHandles'); 
    port_pos  = get_param(port.Outport(1),'position');
    Blockname = ['INP_' CANChannel '_outputs'];    
    dstT = [new_model '/' Blockname]; 
    block_x=port_pos(1)+150;
    block_y=port_pos(2)-6.5 ;
    block_w=block_x+30;
    block_h=block_y+13;
    set_param(dstT,'position',[block_x,block_y,block_w,block_h]);  

    dstT = new_model;
    
    if Numb_CANValid ~= 0
        add_line(dstT, [ModuleName_Bus '/1'],['INP_' CANChannel '_outputs' '/1']);
        add_line(dstT, [ModuleName_Valid '/1'],['inp_CanValid_bus' '/1'],'autorouting','on');
        add_line(dstT, ['From_inp_CanValid_bus' '/1'],[ModuleName_Bus '/1']);
        add_line(dstT, ['BHAL_' CANChannel '_outputs' '/1'],[ModuleName_Valid '/1'],'autorouting','on');
%         add_line(dstT, ['BHAL_' CANChannel '_outputs' '/1'],[ModuleName_Com '/3'],'autorouting','on');
%         add_line(dstT, [ModuleName_Valid '/1'],[ModuleName_Com '/1']);
%         add_line(dstT, [ModuleName_Com '/1'],[ModuleName_Bus '/2'],'autorouting','on');
    end
 end
    %% Write DD
    DD_path = [arch_Path '\inp\inp_' lower(CANChannel)];
    cd (DD_path);
    disp('Writing DD file...');
    Table_output = cell2table(Arry_outputs);
    Table_output.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units'};
    
    Table_cal = cell2table(Arry_Cal);
    Table_cal.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units' 'Enum Table' 'Default during Running'};
    File_name = ['DD_INP_' upper(CANChannel) '_temp.xlsx'];
    writetable(Table_output,File_name,'Sheet',1);
    writetable(Table_cal,File_name,'Sheet',2);

    File_pos = [DD_path '\' File_name];
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
    disp('Write DD finish');

    choice = {'Yes','No'};
    s = listdlg('ListString', choice, ...
		        'Name', 'Copy calibration data from another file?', ...
		        'ListSize', [400 50], ...
			    'SelectionMode', 'single' ...
			    );
    if (isempty(s)==1) 
        disp('no select');
    elseif (s == 1)
        disp('comparing ...');
        [FileName_Old,PathName_old] = uigetfile({'*.xls;*.xlsx;', 'Excel Files (*.xls, *.xlsx)'; '*.*', 'All Files (*.*)'}, 'Select Old file(.xls)');
        data_o=readtable([PathName_old FileName_Old],'sheet','Calibrations','PreserveVariableNames',true);
        [data_o_m,~]=size(data_o);
        data_o_Varialbe = data_o.Properties.VariableNames;
        row_default = find(strcmp(data_o_Varialbe,"Default during Running"));
        %data_n_arry = table2cell(tot_calibration_table);
        %[n_arry_y ~] = size(tot_calibration_table);
        data_o_arry = table2cell(data_o);
        data_n_arry_var = Arry_Cal(:,1);
        
        num_color = 0;
%         num_cal_arry = 0;
        for k = 1:data_o_m
            str = char(data_o_arry(k,1));
%             cal_val = data_o_arry(k,row_default);
            re = find(strcmp(str,data_n_arry_var));
            if (isempty(re)==0)
                cal_val = data_o_arry(k,row_default);
                cal_val_new = Arry_Cal(re,row_default);
                if (cell2mat(cal_val) ~= (cell2mat(cal_val_new)))
                    Arry_Cal(re,row_default) = cal_val;
                    re = re+1;
                    num_color = num_color+1;
                    color_val(num_color,1) = cellstr(['H' num2str(re)]);
                end 
            end 
        end
        data_new = cell2table(Arry_Cal); 
        data_new.Properties.VariableNames = {'Calibrations Name' 'Direction' 'Data Type' 'Min' 'Max' 'Units' 'Enum Table' 'Default during Running'};
        writetable(data_new,File_pos,'Sheet',2);
    
    
        File_pos = [DD_path '\' File_name];
        xlsApp = actxserver('Excel.Application');
        ewb = xlsApp.Workbooks.Open(File_pos);
        if (num_color~=0)
            for k = 1:length(color_val)
                str = char(color_val(k,1));
                ewb.Worksheets.Item(2).Range(str).Interior.ColorIndex = 5;
            end
        end
%         cal_ref = ['A','B','C','D','E','F','G','H','I','J'];
    
        % Save Workbook
        ewb.Save();
        % Close Workbook
        ewb.Close();
        % Quit Excel Excel.Quit();
        disp('New DD.xls of INP updated from old file');
    else
        disp('New DD.xls finished');
    end

DD_file = ['DD_INP_' upper(CANChannel) '.xlsx'];
delete(['DD_INP_' upper(CANChannel) '.xlsx']);
movefile(File_name,DD_file);

% clear old arrays
Arry_outputs = {};
Arry_Cal = {};

%% run FVT_businfo
signal_table = readtable(DD_file,'sheet','Signals','PreserveVariableNames',true);
calibration_table = readtable(DD_file,'sheet','Calibrations','PreserveVariableNames',true);
verctrl = 'FVT_export_businfo_v3.0 2022-09-06';
disp('running FVT BUS info...');
buildbus(DD_file,DD_path,signal_table,calibration_table,verctrl);
disp([CANChannel ' Done!']);
cd(arch_Path);

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