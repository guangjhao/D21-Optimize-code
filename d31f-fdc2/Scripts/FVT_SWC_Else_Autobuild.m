function FVT_SWC_Else_Autobuild(Target_SWC)
q = questdlg({['Check the following conditions:','1. Run project_start?',...
    '2. ' Target_SWC '_type.slx has not been modified?']},...
    'Initial check','Yes','No','Yes');
if ~contains(q, 'Yes')
    return
end
project_path = pwd;
addpath(project_path);
addpath([project_path '/Scripts']);
addpath([project_path '/documents/ARXML_output']);
addpath([project_path '/../common/documents']);
arch_Path = [project_path '/software/sw_development/arch'];
cd(arch_Path);
if strcmp(Target_SWC,'SWC_FDC')
    ARXML_Name = 'SWC_FDC.arxml';
else
    ARXML_Name = ['FVT_' erase(Target_SWC,'SWC_') '.arxml'];
end
%% Read SWC.arxml
fileID = fopen(ARXML_Name);
SWC_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(SWC_arxml{1,1}),1);
for i = 1:length(SWC_arxml{1,1})
    tmpCell{i,1} = SWC_arxml{1,1}{i,1};
end
SWC_arxml = tmpCell;
fclose(fileID);


%% Open SWC_HAL_type.slx
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TargetModel = run_SWC_Target_SWC_5ms_sys %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(project_path);
open_system([Target_SWC '_type']);
if strcmp(Target_SWC,'SWC_HALIN')
    TargetModel = [Target_SWC '_type/run_' Target_SWC '_Rx_5ms_sys'];
elseif strcmp(Target_SWC,'SWC_FDC')
    TargetModel = 'SWC_FDC_type/run_SWC_FDC_RxTx_5ms_sys';
else
    TargetModel = [Target_SWC '_type/run_' Target_SWC '_5ms_sys'];
end
open_system(TargetModel);

%% Get SWC message input array
% <DATA-RECEIVE-POINT-BY-ARGUMENTS>
Raw_start = find(contains(SWC_arxml(:,1),'<DATA-RECEIVE-POINT-BY-ARGUMENTS>'),1,"first");
Raw_end = find(contains(SWC_arxml(:,1),'</DATA-RECEIVE-POINT-BY-ARGUMENTS>'),1,"first");

% PORT-PROTOTYPE-REF
h = find(contains(SWC_arxml(Raw_start:Raw_end,1),'<PORT-PROTOTYPE-REF'));
tmpCell1 = extractBetween(SWC_arxml(Raw_start+h-1,1),[Target_SWC 'type/'],'</PORT-PROTOTYPE-REF>');

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
Raw_start = find(contains(SWC_arxml(:,1),'<DATA-RECEIVE-POINT-BY-ARGUMENTS>'),1,"first");

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
tmpCell1 = extractBetween(SWC_arxml(Raw_start+h-1,1),[Target_SWC '_type/'],'</PORT-PROTOTYPE-REF>');

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

%% Modify Terminator/Ground/out block
BlockList = find_system(TargetModel,'SearchDepth','1');
Function_x = 0;
Function_y = -200;
Function_w = 100;
Function_h = 100; 
back_x = 0;
Outputport_array = SWC_Output_array;

% Call Modify_Terminator_Ground_out_block fuction
Modify_Terminator_Ground_out_block(BlockList,Function_x,Function_y,Function_w,Function_h,back_x,Outputport_array);

%% Auto fix RUNNABLES
if strcmp(Target_SWC,'SWC_HALIN')
    % Get Runnables
    TargetModel = 'SWC_HALIN_type/run_SWC_HALIN_INIT';
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
                h = strcmp(extractBetween(Outputport_array,'SG_','_write'),extractBetween(Input_Name,'SG_','_read'));      
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