function FVT_SWC_DID_Autobuild(TargetSWC) 
    %% FVT_SWC_DID
    arch_Path = pwd;
    project_path = extractBefore(arch_Path,'\software');
    cd(project_path);
    
    %% Read DID List .xlsx File
    cd([project_path '/documents'])
    DID_List = string(readcell('FVT_DIDList.xlsx','Sheet',1));
    [row_idx, ~] = unique(find(cellfun(@(x) ischar(x) && contains(x, 'NVMPedalZP'), DID_List(:,7)))); 
    DID_List(row_idx, :) = [];
    DID_Description = DID_List(3:end,2);
    DID_Module = DID_List(3:end,3);
    DID_Datatype = DID_List(3:end,4); % uintX
    DID_Size = DID_List(3:end,5); 
    DID_WRMode = DID_List(3:end,6); % R/W
    DID_CDDName = DID_List(3:end,8); % CSOP_DIDSet_XXX
    DID_Input1 = DID_List(3:end,9); % u16_DIDLen_XXX
    DID_Input2 = DID_List(3:end,10); % u16_DIDNum_XXX
    DID_Input3 = DID_List(3:end,12); %
    DID_Output1 = DID_List(3:end,11); % u8_DIDSta_XXX
    DID_Output2 = DID_List(3:end,13); %
    DID_HALOUTRaw = DID_List(3:end,14); % VHAL_DIDSetXXX_raw
    DID_HALVarName = DID_List(3:end,15); % VHAL_DIDStaXXX_flg
    DID_FlashData = DID_List(3:end,16); %
    
    original_x = 0;
    original_y = 0;

    % DID Write Bus Selector (APP Get)
    j = 1;
    for i =1: length(DID_WRMode)
        if DID_WRMode(i,1) == 'W'
           DID_WriteDataInput(j) =  DID_Output1(i);
           DID_NoMisDataType(j) = DID_Datatype(i);
           DID_NoMisSize(j) = 1;
           j = j+1;
           if ~ismissing(DID_Output2 (i))
               DID_WriteDataInput(j) = DID_Output2(i);
               DID_NoMisDataType(j) = DID_Datatype(i);
               DID_NoMisSize(j) = DID_Size(i);
               j = j+1;
           end
        end
    end

   % DID TPMS Read data
    j = 1;
    for i =2: length(DID_Module)
        if DID_WRMode(i,1) == 'R' && DID_WRMode(i-1,1) == 'R' % && DID_Module(i,1) == 'TPM'
            DID_TPMReadData(j) = DID_HALOUTRaw(i);
            DID_TPMBusSelect(j) = DID_Input3(i);
            j = j+1;
        end     
    end


    DIDGet_CDDModel = {}; % initial Read cell
    DIDSet_CDDModel = {};

    for i = 1:length(DID_CDDName)
        if DID_WRMode(i, 1) == 'W'
            RWwords = 'R_DIDReadCDD_';
            DIDGet_CDDModel{end+1} = [RWwords, char(DID_CDDName(i))];
        else
            RWwords = 'R_DIDWriteCDD_';
            DIDSet_CDDModel{end+1} = [RWwords, char(DID_CDDName(i))];
        end
        
    end 

    %% Read DD_HAL_DID.xlsx
    DD_path = [arch_Path '\hal\hal_did'];
    cd(DD_path);
    File_name = 'DD_HAL_DID.xlsx';
    Original_table = readtable(File_name,'Sheet',1);
    Original_cell = table2cell(Original_table(:,1));
    DD_cell = cell(length(DID_WriteDataInput),16);
    

    %% Expand DID_CDDSubsystem and remove related block
    if strcmp(TargetSWC,'SWC_HALIN_CDD_type') || strcmp(TargetSWC,'All')
        %% Create DID Get subsystem (DIDRead)

        TargetModel = 'SWC_HALIN_CDD_type/run_SWC_HALIN_CDD_Rx_5ms_sys';
        open_system('SWC_HALIN_CDD_type');
        DID_GetSubsystem = [TargetModel '/DIDGet_Subsystem'];
        expand_subsystem(DID_GetSubsystem,TargetModel);
        subsystemName = 'DIDGet_Subsystem';
        h =[];

        for i = 1:numel(DIDGet_CDDModel)
            h(i) = get_param([TargetModel '/' DIDGet_CDDModel{i}], 'Handle');
            portHandles = get_param([TargetModel '/' DIDGet_CDDModel{i}], 'PortHandles');
            removeSrcBlockAndLine(portHandles);
            removeDstBlockAndLine(portHandles);
            set_param(h(i), 'Position', [-2000, 4900+200*i, -1300, 5050+200*i]); 
        end
        Simulink.BlockDiagram.createSubsystem(h,'Name',subsystemName);
        DID_subsystem = get_param([TargetModel '/' subsystemName], 'Handle');
        set_param(DID_subsystem,'position',[-1200,3000,-500,3120]);
        NewModel = [TargetModel '/' subsystemName];
    
        % delete all inport and outport
         for i = 1:numel(DID_CDDName)
            inports = find_system(NewModel, 'SearchDepth', 1, 'BlockType', 'Inport');
            outports = find_system(NewModel, 'SearchDepth', 1, 'BlockType', 'Outport');
            lines = find_system(NewModel, 'FindAll', 'on', 'Type', 'line');
        end
    
        for i = 1:length(inports)
        delete_block(inports{i});
        end
        for i = 1:length(lines)
            delete_line(lines(i));
        end
        for i = 1:length(outports)
            delete_block(outports{i});
        end
        
        % Add subsystem trigger port
        BlockName = 'trigger port';
        block_x = original_x;
        block_y = original_y -500;
        block_w = block_x + 40;
        block_h = block_y + 40;
        srcT = 'simulink/Ports & Subsystems/Trigger';
        dstT = [NewModel '/' BlockName];
        trig = add_block(srcT,dstT,'MakeNameUnique','on'); 
        set_param(trig,'TriggerType','function-call','Name','trig_GetDID');
        set_param(trig,'position',[block_x,block_y,block_w,block_h]);
    
        % DID Write Bus creator
        BlockName ='bus_Creator';
        srcT = 'simulink/Signal Routing/Bus Creator';
        dstT = [NewModel '/' BlockName];
        PortsSpace = 50;
        block_x = original_x + 3000;
        block_y = original_y;
        block_w = block_x + 10;
        block_h = block_y + length(DID_WriteDataInput)*PortsSpace;
        signalNames = strcat( DID_WriteDataInput);
        buscreator = add_block(srcT, dstT,'MakeNameUnique','on');
        set_param(buscreator,'position',[block_x,block_y,block_w,block_h]);
        set_param(buscreator,'Inputs',string(length(signalNames)),'ShowName','on');
        set_param(buscreator,'OutDataTypeStr','Bus:  BHAL_DID_outputs');
        set_param(buscreator,'NonVirtualBus','on');
        sourceport = get_param(buscreator,'PortHandles');
        sourcepos = get_param(buscreator, 'PortConnectivity');
        sourceOutpos = get_param(sourceport.Outport,'Position');
            
        % From  for Bus creator inport
        for i =1: length(DID_WriteDataInput)
            BlockName = 'From';
            block_x = sourcepos(1).Position(1) - 1000;
            block_y = sourcepos(1).Position(2) -20 + PortsSpace*(i-1);
            block_w = block_x + 220;
            block_h = block_y + 40;
            srcT = 'simulink/Signal Routing/From';
            dstT = [NewModel '/' BlockName];    
            from = add_block(srcT,dstT,'MakeNameUnique','on');   
            set_param(from,'position',[block_x,block_y,block_w,block_h]);
            set_param(from,'GotoTag',DID_WriteDataInput(i),'ShowName','off');
            fromport = get_param(from,'PortHandles');
            frompos = get_param(from, 'PortConnectivity');
            % BusLine = add_line(NewModel,fromport.Outport,sourceport.Inport(i));
            % set_param(BusLine, 'Name', DID_WriteDataInput(i)); 
            
            % add datatype convert
            BlockName = 'UnitConverter';
            block_x = frompos.Position(1) + 200;
            block_y = frompos.Position(2) - 20;
            block_w = block_x + 220;
            block_h = block_y + 40;
            srcT = 'simulink/Signal Attributes/Data Type Conversion';
            dstT = [NewModel '/' BlockName];   
            Convert = add_block(srcT,dstT,'MakeNameUnique','on');   
            set_param(Convert,'position',[block_x,block_y,block_w,block_h]);
            GotoTagName = strrep(extractAfter(DID_WriteDataInput(i),'_'), '_', '');
            set_param(Convert, 'OutDataTypeStr', DID_NoMisDataType(i));
            Convertport = get_param(Convert,'PortHandles');
            Convertpos = get_param(Convert, 'PortConnectivity');
            ConvertLine = add_line(NewModel,fromport.Outport,Convertport.Inport);
            set_param(ConvertLine, 'Name', DID_WriteDataInput(i));
            line = add_line(NewModel,Convertport.Outport,sourceport.Inport(i),'autorouting','smart');
            set_param(line, 'Name', ['VHAL_' char(GotoTagName) '_raw']);  
            set(line,'MustResolveToSignalObject',1);
    
            % Add new DD_cell cell
            if ~contains(['VHAL_' char(GotoTagName) '_raw'],Original_cell) && DID_NoMisSize(i) == 1
                DD_Index_Msg = find(cellfun(@isempty,DD_cell(1:end,1)));
                DD_cell(DD_Index_Msg(1),1) = {['VHAL_' char(GotoTagName) '_raw']}; % HAL signal name
                DD_cell(DD_Index_Msg(1),2) = {'output'}; % Direction
                DD_cell(DD_Index_Msg(1),3) = {'uint8'}; % data type
                DD_cell(DD_Index_Msg(1),4) = {0}; % Minimum
                DD_cell(DD_Index_Msg(1),5) = {255}; % Maximun
                DD_cell(DD_Index_Msg(1),6) = {'raw'}; % Unit
                DD_cell(DD_Index_Msg(1),7) = {'N/A'}; % Enum table
                DD_cell(DD_Index_Msg(1),8) = {'N/A'}; % Default before and during POWER-UP
                DD_cell(DD_Index_Msg(1),9) = {'N/A'}; % DDefault before and during POWER-DOWN
                DD_cell(DD_Index_Msg(1),10) = {'N/A'}; % Description
                DD_cell(DD_Index_Msg(1),11) = {'N/A'}; % CAN transmitter
                DD_cell(DD_Index_Msg(1),12) = {'N/A'}; % Message
                DD_cell(DD_Index_Msg(1),13) = {'N/A'};
                DD_cell(DD_Index_Msg(1),14) = {'N/A'};
                DD_cell(DD_Index_Msg(1),15) = {'N/A'};
                DD_cell(DD_Index_Msg(1),16) = {'N/A'};
            elseif ~contains(['VHAL_' char(GotoTagName) '_raw'],Original_cell) &&DID_NoMisSize(i) > 1
                DD_Index_Msg = find(cellfun(@isempty,DD_cell(1:end,1)));
                DD_cell(DD_Index_Msg(1),1) = {['VHAL_' char(GotoTagName) '_raw']}; % HAL signal name
                DD_cell(DD_Index_Msg(1),2) = {'output'}; % Direction
                DD_cell(DD_Index_Msg(1),3) = {['u8Array' num2str(DID_NoMisSize(i))]}; % data type
                DD_cell(DD_Index_Msg(1),4) = {0}; % Minimum
                DD_cell(DD_Index_Msg(1),5) = {255}; % Maximun
                DD_cell(DD_Index_Msg(1),6) = {'raw'}; % Unit
                DD_cell(DD_Index_Msg(1),7) = {'N/A'}; % Enum table
                DD_cell(DD_Index_Msg(1),8) = {'N/A'}; % Default before and during POWER-UP
                DD_cell(DD_Index_Msg(1),9) = {'N/A'}; % DDefault before and during POWER-DOWN
                DD_cell(DD_Index_Msg(1),10) = {'N/A'}; % Description
                DD_cell(DD_Index_Msg(1),11) = {'N/A'}; % CAN transmitter
                DD_cell(DD_Index_Msg(1),12) = {'N/A'}; % Message
                DD_cell(DD_Index_Msg(1),13) = {'N/A'};
                DD_cell(DD_Index_Msg(1),14) = {'N/A'};
                DD_cell(DD_Index_Msg(1),15) = {'N/A'};
                DD_cell(DD_Index_Msg(1),16) = {'N/A'};
            end
        end
    
        % Delete empty DD_cell cell
        for j = length(DD_cell(:,1)):-1:1
            if cellfun(@isempty,DD_cell(j,1))
                DD_cell(j,:) = [];
            end
        end
    
        % Modify DD file
        DD_table = cell2table(DD_cell);
        DD_table.Properties.VariableNames = Original_table.Properties.VariableNames;
        New_table = [Original_table;DD_table];
        writetable(New_table,File_name,'Sheet',1);
        
        % Run FVT_export_businfo
        verctrl = 'FVT_export_businfo_v2.0 2021-11-02';
        signal_table = readtable(File_name,'sheet','Signals','PreserveVariableNames',true);
        calibration_table = readtable(File_name,'sheet','Calibrations','PreserveVariableNames',true);
        buildbus(File_name,DD_path,signal_table,calibration_table,verctrl)
    
        % Outport  for Bus creator outport
        BlockName = 'BHAL_DID_outputs';
        block_x = sourceOutpos(1)+150;
        block_y = sourceOutpos(2)-5;
        block_w = block_x + 20;
        block_h = block_y + 10;
        srcT = 'simulink/Sinks/Out1';
        dstT = [NewModel '/' BlockName];
        Out = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(Out,'position',[block_x,block_y,block_w,block_h]);
        set_param(Out,'UseBusObject','on','BusObject',BlockName);
        Outport = get_param(Out,'PortHandles');
        gotopos = get_param(Out, 'PortConnectivity');
        add_line(NewModel,sourceport.Outport,Outport.Inport);
    
        % Create goto for SetCDD inport
        
        for i =1: length(DID_CDDName)
            if DID_WRMode(i,1) == 'W'
            CDD_Write_model = [NewModel '/' ['R_DIDReadCDD_' char(DID_CDDName(i))]];
            CDD_Wport = get_param(CDD_Write_model,'PortHandles');
            CDD_WInportPos = get_param(CDD_Wport.Inport,'Position');
            CDD_WOutportPos = get_param(CDD_Wport.Outport,'Position');
        
            % inport1
            BlockName = 'DIDLen';
            block_x = CDD_WInportPos{1,1}(1) - 400;
            block_y = CDD_WInportPos{1,1}(2) - 15;
            block_w = block_x + 240;
            block_h = block_y + 30;
            srcT = 'simulink/Commonly Used Blocks/Constant';
            dstT = [NewModel '/' BlockName];
            DIDLen = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(DIDLen,'position',[block_x,block_y,block_w,block_h]);
            set_param(DIDLen,'value',char(extractAfter(DID_Input2(i),'_')),'ShowName','off');
            DIDLenport = get_param(DIDLen,'PortHandles');
            add_line(NewModel,DIDLenport.Outport,CDD_Wport.Inport(1));
        
            % inport2
            BlockName = 'DIDNum';
            block_x = CDD_WInportPos{2,1}(1) - 400;
            block_y = CDD_WInportPos{2,1}(2) - 15;
            block_w = block_x + 240;
            block_h = block_y + 30;
            srcT = 'simulink/Commonly Used Blocks/Constant';
            dstT = [NewModel '/' BlockName];
            DIDNum = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(DIDNum,'position',[block_x,block_y,block_w,block_h]);
            set_param(DIDNum,'value',char(extractAfter(DID_Input1(i),'_')),'ShowName','off');
            DIDNumport = get_param(DIDNum,'PortHandles');
            add_line(NewModel,DIDNumport.Outport,CDD_Wport.Inport(2));
        
            % outport1
            BlockName = 'Goto';
            block_x = CDD_WOutportPos{1,1}(1) + 300;
            block_y = CDD_WOutportPos{1,1}(2) - 15;
            block_w = block_x + 240;
            block_h = block_y + 30;
            srcT = 'simulink/Signal Routing/Goto';
            dstT = [NewModel '/' BlockName];
            goto = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(goto,'position',[block_x,block_y,block_w,block_h]);
            set_param(goto,'GotoTag',char(DID_Output2(i)),'ShowName','off');
            gotoport = get_param(goto,'PortHandles');
            add_line(NewModel,CDD_Wport.Outport(1),gotoport.Inport);
            
            % outport2
            BlockName = 'Goto';
            block_x = CDD_WOutportPos{2,1}(1) + 300;
            block_y = CDD_WOutportPos{2,1}(2) - 15;
            block_w = block_x + 240;
            block_h = block_y + 30;
            srcT = 'simulink/Signal Routing/Goto';
            dstT = [NewModel '/' BlockName];
            goto = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(goto,'position',[block_x,block_y,block_w,block_h]);
            set_param(goto,'GotoTag',DID_Output1(i),'ShowName','off');
            gotoport = get_param(goto,'PortHandles');
            add_line(NewModel,CDD_Wport.Outport(2),gotoport.Inport);  
            end
        end
        
        DID_subsystem = get_param([TargetModel '/' subsystemName], 'PortHandles');
        TrigPos = get_param(DID_subsystem.Trigger,'Position');
        OutPos = get_param(DID_subsystem.Outport,'Position');
        BlockName = 'From';
        block_x = TrigPos(1) - 755;
        block_y = TrigPos(2) - 100;
        block_w = block_x + 240;
        block_h = block_y + 30;
        srcT = 'simulink/Signal Routing/From';
        dstT = [TargetModel '/' subsystemName];
        From = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(From,'position',[block_x,block_y,block_w,block_h]);
        set_param(From,'GotoTag','trig_GetDID','ShowName','off');
        Fromport = get_param(From,'PortHandles');
        add_line(TargetModel,Fromport.Outport,DID_subsystem.Trigger(1),'autorouting','smart');
    
        BlockName = 'Goto';
        block_x = OutPos(1) + 100;
        block_y = OutPos(2) - 15;
        block_w = block_x + 240;
        block_h = block_y + 30;
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [TargetModel '/' subsystemName];
        goto = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(goto,'position',[block_x,block_y,block_w,block_h]);
        set_param(goto,'GotoTag','BHAL_DID_outputs','ShowName','off');
        gotoport = get_param(goto,'PortHandles');
        add_line(TargetModel,DID_subsystem.Outport,gotoport.Inport);

    elseif strcmp(TargetSWC,'SWC_HALOUT_type') || strcmp(TargetSWC,'All')
        
        %% Create DID Set subsystem (DIDWrite)
        TargetModel = 'SWC_HALOUT_type/run_SWC_HALOUT_Tx_5ms_sys';
        DID_SetSubsystem = [TargetModel '/DIDSet_Subsystem'];
        expand_subsystem(DID_SetSubsystem,TargetModel);
        subsystemName = 'DIDSet_Subsystem';
        h =[];
        for i = 1:numel(DIDSet_CDDModel) 
            h(i) = get_param([TargetModel '/' DIDSet_CDDModel{i}], 'Handle');
            portHandles = get_param([TargetModel '/' DIDSet_CDDModel{i}], 'PortHandles');
            removeSrcBlockAndLine(portHandles);
            removeDstBlockAndLine(portHandles);
            set_param(h(i), 'Position', [-2000, 5200+200*i, -1300, 5350+200*i]); 
        end
        Simulink.BlockDiagram.createSubsystem(h,'Name',subsystemName);
        NewModel = [TargetModel '/' subsystemName];
    
        % delete all inport and outport
        for i = 1:numel(DID_CDDName)
            inports = find_system(NewModel, 'SearchDepth', 1, 'BlockType', 'Inport');
            outports = find_system(NewModel, 'SearchDepth', 1, 'BlockType', 'Outport');
            lines = find_system(NewModel, 'FindAll', 'on', 'Type', 'line');
        end
    
        for i = 1:length(inports)
        delete_block(inports{i});
        end
        for i = 1:length(lines)
            delete_line(lines(i));
        end
        for i = 1:length(outports)
            delete_block(outports{i});
        end
    
        DID_subsystem = get_param([TargetModel '/' subsystemName], 'Handle');
        set_param(DID_subsystem,'position',[-1200,3500,-500,3700]);
        
        % Add subsystem trigger port
        BlockName = 'trigger port';
        block_x = original_x;
        block_y = original_y -500;
        block_w = block_x + 40;
        block_h = block_y + 40;
        srcT = 'simulink/Ports & Subsystems/Trigger';
        dstT = [NewModel '/' BlockName];
        trig = add_block(srcT,dstT,'MakeNameUnique','on'); 
        set_param(trig,'TriggerType','function-call','Name','trig_SetDID');
        set_param(trig,'position',[block_x,block_y,block_w,block_h]);
        
        % DID TPMS data Bus selector
        BlockName ='bus_selector';
        srcT = 'simulink/Signal Routing/Bus Selector';
        dstT = [NewModel '/' BlockName];
        PortsSpace = 50;
        block_x = original_x - 1500;
        block_y = original_y;
        block_w = block_x + 10;
        blockb_h = block_y + length(DID_TPMReadData)*PortsSpace;
        signalNames = strcat(DID_TPMReadData);
        busselector = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(busselector,'position',[block_x,block_y,block_w,blockb_h]);
        set_param(busselector,'OutputSignals',join( signalNames,","),'ShowName', 'off');
        busselectorport = get_param(busselector,'PortHandles');
        busselectorpos = get_param(busselector, 'PortConnectivity');  
    
        % GoTo for TPMS bus selector
        for i = 1: length(DID_TPMReadData)
            BlockName = 'Goto';
            block_x = busselectorpos(i+1).Position(1) + 300;
            block_y = busselectorpos(i+1).Position(2) -15;
            block_w = block_x + 240;
            block_h = block_y + 30;
            srcT = 'simulink/Signal Routing/Goto';
            dstT = [NewModel '/' BlockName];
            goto = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(goto,'position',[block_x,block_y,block_w,block_h]);
            set_param(goto,'GotoTag',char(DID_TPMBusSelect(i)),'ShowName','off');
            gotoport = get_param(goto,'PortHandles');
            add_line(NewModel,busselectorport.Outport(i),gotoport.Inport);
        end
    
        % TPM data inport to bus selector
        block_x = busselectorpos(1).Position(1) - 300;
        block_y = busselectorpos(1).Position(2) - 10;
        block_w = block_x + 30;
        block_h = block_y + 15;
        BlockName = 'BOUTP_DIDSetData_outputs';
        srcT = 'simulink/Sources/In1';
        dstT = [NewModel '/' BlockName];
        inport1 = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(inport1,'position',[block_x,block_y,block_w,block_h]);
        Inport = get_param(inport1,'PortHandles');
        Inpos = get_param(inport1, 'PortConnectivity');
        add_line(NewModel,Inport.Outport,busselectorport.Inport);
    
        % DID_WriteDataInput Bus selector
        BlockName ='bus_selector';
        srcT = 'simulink/Signal Routing/Bus Selector';
        dstT = [NewModel '/' BlockName];
        PortsSpace = 50;
        block_x = original_x - 1500;
        block_y = blockb_h + 200;
        block_w = block_x + 10;
        block_h = block_y + length(DID_WriteDataInput)*PortsSpace;
        GotoTagName = strrep(extractAfter(DID_WriteDataInput,'_'), '_', '');
        signalNames = strcat('VHAL_', GotoTagName,'_raw');
        busselector = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(busselector,'position',[block_x,block_y,block_w,block_h]);
        set_param(busselector,'OutputSignals',join( signalNames,","),'ShowName', 'off');
        busselectorport2 = get_param(busselector,'PortHandles');
        busselectorpos2 = get_param(busselector, 'PortConnectivity');
    
        % GoTo for DID_WriteDataInput bus selector
        for i = 1: length(DID_WriteDataInput)
            BlockName = 'Goto';
            block_x = busselectorpos2(i+1).Position(1) + 300;
            block_y = busselectorpos2(i+1).Position(2) -15;
            block_w = block_x + 240;
            block_h = block_y + 30;
            srcT = 'simulink/Signal Routing/Goto';
            dstT = [NewModel '/' BlockName];
            goto = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(goto,'position',[block_x,block_y,block_w,block_h]);
            set_param(goto,'GotoTag',char(DID_WriteDataInput(i)),'ShowName','off');
            gotoport = get_param(goto,'PortHandles');
            add_line(NewModel,busselectorport2.Outport(i),gotoport.Inport);
        end
    
        % DID_WriteData bus selector inport
        block_x = busselectorpos2(1).Position(1) - 300;
        block_y = busselectorpos2(1).Position(2) - 10;
        block_w = block_x + 30;
        block_h = block_y + 15;
        BlockName = 'BHAL_DID_outputs';
        srcT = 'simulink/Sources/In1';
        dstT = [NewModel '/' BlockName];
        inport2 = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(inport2,'position',[block_x,block_y,block_w,block_h]);
        Inport2 = get_param(inport2,'PortHandles');
        Inpos2 = get_param(inport2, 'PortConnectivity');
        add_line(NewModel,Inport2.Outport,busselectorport2.Inport);
    
        % Create goto for SetCDD inport
        
        for i =1: length(DID_CDDName)
        
            if DID_WRMode(i,1) == 'R'
                CDD_Read_model = [NewModel '/' ['R_DIDWriteCDD_' char(DID_CDDName(i))]];
                CDD_Rport = get_param(CDD_Read_model,'PortHandles');
                CDD_RInportPos = get_param(CDD_Rport.Inport,'Position');
                CDD_ROutportPos = get_param(CDD_Rport.Outport,'Position');
            
                % inport1
                BlockName = 'DIDLen';
                block_x = CDD_RInportPos{1,1}(1) - 400;
                block_y = CDD_RInportPos{1,1}(2) - 15;
                block_w = block_x + 240;
                block_h = block_y + 30;
                srcT = 'simulink/Commonly Used Blocks/Constant';
                dstT = [NewModel '/' BlockName];
                DIDLen = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(DIDLen,'position',[block_x,block_y,block_w,block_h]);
                set_param(DIDLen,'value',char(extractAfter(DID_Input2(i),'_')),'ShowName','off');
                DIDLenport = get_param(DIDLen,'PortHandles');
                add_line(NewModel,DIDLenport.Outport,CDD_Rport.Inport(1));
            
                % inport2
                BlockName = 'DIDNum';
                block_x = CDD_RInportPos{2,1}(1) - 400;
                block_y = CDD_RInportPos{2,1}(2) - 15;
                block_w = block_x + 240;
                block_h = block_y + 30;
                srcT = 'simulink/Commonly Used Blocks/Constant';
                dstT = [NewModel '/' BlockName];
                DIDNum = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(DIDNum,'position',[block_x,block_y,block_w,block_h]);
                set_param(DIDNum,'value',char(extractAfter(DID_Input1(i),'_')),'ShowName','off');
                DIDNumport = get_param(DIDNum,'PortHandles');
                add_line(NewModel,DIDNumport.Outport,CDD_Rport.Inport(2));
            
                % inport3
                BlockName = 'From';
                block_x = CDD_RInportPos{3,1}(1) - 400;
                block_y = CDD_RInportPos{3,1}(2) - 15;
                block_w = block_x + 240;
                block_h = block_y + 30;
                srcT = 'simulink/Signal Routing/From';
                dstT = [NewModel '/' BlockName];
                From = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(From,'position',[block_x,block_y,block_w,block_h]);
                set_param(From,'GotoTag',char(DID_Input3(i)),'ShowName','off');
                Fromport = get_param(From,'PortHandles');
                add_line(NewModel,Fromport.Outport,CDD_Rport.Inport(3));
            end
        end
        
        DID_subsystem = get_param([TargetModel '/' subsystemName], 'PortHandles');
        TrigPos = get_param(DID_subsystem.Trigger,'Position');
        InPos = get_param(DID_subsystem.Inport,'Position');
    %     OutPos = get_param(DID_subsystem.Outport,'Position');
        % ADD goto for DID_subsystem inport, ouport and trigger
        BlockName = 'From';
        block_x = InPos{1}(1) - 400;
        block_y = InPos{1}(2) - 15;
        block_w = block_x + 240;
        block_h = block_y + 30;
        srcT = 'simulink/Signal Routing/From';
        dstT = [TargetModel '/' subsystemName];
        From = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(From,'position',[block_x,block_y,block_w,block_h]);
        set_param(From,'GotoTag','BOUTP_DIDSetData_outputs','ShowName','off');
        Fromport = get_param(From,'PortHandles');
        add_line(TargetModel,Fromport.Outport,DID_subsystem.Inport(1));
    
        BlockName = 'From';
        block_x = InPos{2}(1) - 400;
        block_y = InPos{2}(2) - 15;
        block_w = block_x + 240;
        block_h = block_y + 30;
        srcT = 'simulink/Signal Routing/From';
        dstT = [TargetModel '/' subsystemName];
        From = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(From,'position',[block_x,block_y,block_w,block_h]);
        set_param(From,'GotoTag','BHAL_DID_outputs','ShowName','off');
        Fromport = get_param(From,'PortHandles');
        add_line(TargetModel,Fromport.Outport,DID_subsystem.Inport(2));
        
        BlockName = 'From';
        block_x = TrigPos(1) - 755;
        block_y = TrigPos(2) - 100;
        block_w = block_x + 240;
        block_h = block_y + 30;
        srcT = 'simulink/Signal Routing/From';
        dstT = [TargetModel '/' subsystemName];
        From = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(From,'position',[block_x,block_y,block_w,block_h]);
        set_param(From,'GotoTag','trig_SetDID','ShowName','off');
        Fromport = get_param(From,'PortHandles');
        add_line(TargetModel,Fromport.Outport,DID_subsystem.Trigger(1),'autorouting','smart');
    
        % remove area
        areas = find_system(TargetModel,'SearchDepth', 1,'FindAll', 'on', 'Type', 'annotation', 'AnnotationType', 'area_annotation');
        delete(areas);
    end

end

function removeSrcBlockAndLine(portHandles)
    % remove Inport Srcblock & line
    for i = 1:length(portHandles.Inport)
        line = get_param(portHandles.Inport(i), 'Line');
        if line ~= -1 % If there is a line connected
            srcBlock = get_param(line, 'SrcBlockHandle');
            delete(srcBlock);
            delete(line);
        end
    end       
end

function removeDstBlockAndLine(portHandles)
    % remove Outport Dstblock & line
    for i = 1:length(portHandles.Outport)
        line = get_param(portHandles.Outport(i), 'Line');
        if line ~= -1 % If there is a line connected
            DstBlock = get_param(line, 'DstBlockHandle');
            delete(DstBlock);
            delete(line);
        end
    end
end

function removeSrcTrigAndLine(portHandles)
    % remove Trigger Srcblock & line
    for i = 1:length(portHandles.Trigger)
        line = get_param(portHandles.Trigger(i), 'Line');
        if line ~= -1 % If there is a line connected
            srcBlock = get_param(line, 'SrcBlockHandle');
            delete(srcBlock);
            delete(line);
        end
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
%% Filter Duplicated table definitions
num_M = num_calarry + num_caltable;
M_name = cell(num_M, 1);
extractBetween(str, '_', '_');
for i = 1:num_M
    if i <= num_calarry
        M_name(i, 1) = extractBetween(calarry(i, 1), '_', '_');
    else
        M_name(i, 1) = extractBetween(caltable(i - num_calarry, 1), '_', '_');
    end
end
[uniqueStrings, ~, idx] = unique(M_name);
counts = histcounts(idx, 1:(length(uniqueStrings)+1));
repeatedStrings = uniqueStrings(counts > 1);

if ~isempty(repeatedStrings)
    disp('Duplicated table definitions found.');
    disp(repeatedStrings);
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
if ~isempty(calibration_table)
str_firstcali = (string(table2cell(calibration_table(1,1))));
end
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
    elseif str_tablechk == string(A_str) 
        str = char(str);
        if any(strcmp(sheets, str))
            table_array = readtable([PathName FileName], 'sheet', str);
            array = table2array(table_array);
            if array(1) < calibration_table{i, 4}
                disp([str, ' is smaller than lower limit!'])
            elseif array(end) > calibration_table{i,5}
                disp([str, ' is larger than upper limit!'])
            end
            defval = strcat('[', strjoin(string(array), ' '), ']');
            if ~ismissing(defval)
                sig = strcat("a2l_cal(","'",str,"',","     ", defval,")",";");
                fprintf(fileID,'%s \n',char(sig));
            end
        end
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
    if contains(type, 'Array')
        array_dims = extractAfter(type, 'Array');
        if strcmp(extractBefore(type, 'Array'),'u16')
            sens = strcat("{","'", str ,"' ", " ,", array_dims, ",  'uint16' " , " ,-1" , ", 'real'", " ,'Sample'};...");
        elseif strcmp(extractBefore(type, 'Array'),'u32')
            sens = strcat("{","'", str ,"' ", " ,", array_dims, ",  'uint32' " , " ,-1" , ", 'real'", " ,'Sample'};...");
        else
            sens = strcat("{","'", str ,"' ", " ,", array_dims, ",  'uint8' " , " ,-1" , ", 'real'", " ,'Sample'};...");
        end
    else % ~contains(type, 'Array')
        sens = strcat("{","'", str ,"' ", " ,1, ", " '", type ,"' ", " ,-1" , ", 'real'", " ,'Sample'};...");
    end
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

        if contains(type, 'Array')
            continue;
        end

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

        if contains(type, 'Array')
            continue;
        end

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

        if contains(type, 'Array')
            continue;
        end

        sens = strcat("a2l_mon('", str, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
        fprintf(fileID,[ char(sens)  '\n'...
                       ]);
    end   
end 

% Close the file.
fclose(fileID);
% Open the file in the editor.
% save(varfile);



%% build xxx_array.m

arrayfile = strcat(lower(module_name),"_array.m"); 
arrayfile = char(arrayfile);
fileID = fopen(arrayfile, 'w');
datetime.setDefaultFormats('default','yyyy-MM-dd HH:mm:ss');

fprintf(fileID,'%%===========$Update Time :  %s $=========\n',datetime);
fprintf(fileID,'disp(''Loading $Id: %s  %s    foxtron $      %s'')',arrayfile,datetime,verctrl); 
fprintf(fileID,['\n'...
                '%%%% Array declaration' '\n'...
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

        if contains(type, 'Array')
            variable_name = str;
            fprintf(fileID, '\nglobal %s;\n', variable_name);
            fprintf(fileID, '%s = Simulink.Signal;\n', variable_name);
            fprintf(fileID, '%s.CoderInfo.StorageClass = ''ExportedGlobal'';\n', variable_name);
            if strcmp(extractBefore(type, 'Array'),'u16')
                fprintf(fileID, '%s.DataType = ''uint16'';\n', variable_name);
            elseif strcmp(extractBefore(type, 'Array'),'u32')
                fprintf(fileID, '%s.DataType = ''uint32'';\n', variable_name);
            else
                fprintf(fileID, '%s.DataType = ''uint8'';\n', variable_name);
            end
        end
    end
    
    
end

if (num_sig_internal~=0)
    for i = 1:num_sig_internal
        str = string(internal_arry(i,1)); 
        unit = string(internal_arry(i,3));
        type = string(internal_arry(i,2));
        max = string(internal_arry(i,5));
        min = string(internal_arry(i,4));

        if contains(type, 'Array')
            variable_name = str;
            fprintf(fileID, '\nglobal %s;\n', variable_name);
            fprintf(fileID, '%s = Simulink.Signal;\n', variable_name);
            fprintf(fileID, '%s.CoderInfo.StorageClass = ''ExportedGlobal'';\n', variable_name);
            if strcmp(extractBefore(type, 'Array'),'u16')
                fprintf(fileID, '%s.DataType = ''uint16'';\n', variable_name);
            elseif strcmp(extractBefore(type, 'Array'),'u32')
                fprintf(fileID, '%s.DataType = ''uint32'';\n', variable_name);
            else
                fprintf(fileID, '%s.DataType = ''uint8'';\n', variable_name);
            end
        end        
    end
end

if (num_sig_outputs~=0)
    for i = 1:num_sig_outputs
        str = string(output_arry(i,1)); 
        unit = string(output_arry(i,3));
        type = string(output_arry(i,2));
        max = string(output_arry(i,5));
        min = string(output_arry(i,4));

        if contains(type, 'Array')
            variable_name = str;
            fprintf(fileID, '\nglobal %s;\n', variable_name);
            fprintf(fileID, '%s = Simulink.Signal;\n', variable_name);
            fprintf(fileID, '%s.CoderInfo.StorageClass = ''ExportedGlobal'';\n', variable_name);
            if strcmp(extractBefore(type, 'Array'),'u16')
                fprintf(fileID, '%s.DataType = ''uint16'';\n', variable_name);
            elseif strcmp(extractBefore(type, 'Array'),'u32')
                fprintf(fileID, '%s.DataType = ''uint32'';\n', variable_name);
            else
                fprintf(fileID, '%s.DataType = ''uint8'';\n', variable_name);
            end
        end        
    end
end


% Close the file.
fclose(fileID);
% Open the file in the editor.
% save(arrayfile);
end

function expand_subsystem(expand_subsyatem,search_model)
    if ismember(expand_subsyatem, find_system(search_model))
        Get_portHandles = get_param(expand_subsyatem, 'PortHandles');
        removeSrcBlockAndLine(Get_portHandles);
        removeDstBlockAndLine(Get_portHandles);
        removeSrcTrigAndLine(Get_portHandles);
        GetfunCallSubsystems = find_system(expand_subsyatem);
        Useless_block = GetfunCallSubsystems(~contains(GetfunCallSubsystems,'R_DID'));
        for i = 2:length(Useless_block)
            delete_block(Useless_block(i));
        end
        allLines = find_system(expand_subsyatem, 'FindAll', 'on', 'Type', 'Line');
        for i = 1:length(allLines)
                delete_line(allLines(i));
        end
        currentPosition = get_param(expand_subsyatem, 'Position');
        Offset = 15000;
        newPosition = currentPosition + [Offset Offset Offset Offset];    
        set_param(expand_subsyatem, 'Position', newPosition);
        subsystemHandle = get_param(expand_subsyatem, 'Handle');
        Simulink.BlockDiagram.expandSubsystem(subsystemHandle);
    end
end
