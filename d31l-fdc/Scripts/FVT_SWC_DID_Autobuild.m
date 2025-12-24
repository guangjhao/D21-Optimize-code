function FVT_SWC_DID_Autobuild(~) 
    %% FVT_SWC_DID
    q = questdlg({'Check the following conditions:','1. Run project_start?',...
        '2. Current folder arch?','3. SWC_FDC_type.slx has not been modified?'},...
        'Initial check','Yes','No','Yes');
    if ~contains(q, 'Yes')
        return
    end
    arch_Path = pwd;
    if ~contains(arch_Path, 'arch'), error('current folder is not under arch'), end
    project_path = extractBefore(arch_Path,'\software');
    
    
    %% Open SWC_FDC_type.slx
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TargetModel = run_SWC_FDC_RxTx_5ms_sys %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    cd(project_path);
    open_system('SWC_FDC_type');
    TargetModel = 'SWC_FDC_type/run_SWC_FDC_RxTx_5ms_sys';
    open_system(TargetModel);
    
    %% Read DID List .xlsx File
    cd([project_path '/documents'])
    DID_List = string(readcell('FVT_DIDList.xlsx','Sheet',1));
    DID_Description = DID_List(3:end,2);
    DID_Module = DID_List(3:end,3);
    DID_Datatype = DID_List(3:end,4); % uintX
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
           j = j+1;
           if ~ismissing(DID_Output2 (i))
               DID_WriteDataInput(j) = DID_Output2(i);
               DID_NoMisDataType(j) = DID_Datatype(i);
               j = j+1;
           end
        end     
    end

   % DID TPMS Read data
    j = 1;
    for i =1: length(DID_Module)
        if DID_Module(i,1) == 'TPM' && DID_WRMode(i,1) == 'R'
            DID_TPMReadData(j) = DID_HALOUTRaw(i);
            DID_TPMBusSelect(j) = DID_Input3(i);
            j = j+1;
        end     
    end

%     DID_ReadCDD = {}; % initial Read cell
%     DID_WriteCDD = {}; % initial Write cell
%     
%     for i = 1:length(DID_CDDName)
%         if DID_WRMode(i, 1) == 'W'
%             RWwords = 'R_DIDReadCDD_';
%             DID_ReadCDD{end+1} = [RWwords, char(DID_CDDName(i))];
%         else
%             RWwords = 'R_DIDWriteCDD_';
%             DID_WriteCDD{end+1} = [RWwords, char(DID_CDDName(i))];
%         end
%     end

    DID_CDDModel = {}; % initial Read cell
    
    for i = 1:length(DID_CDDName)
        if DID_WRMode(i, 1) == 'W'
            RWwords = 'R_DIDReadCDD_';
        else
            RWwords = 'R_DIDWriteCDD_';      
        end
        DID_CDDModel{end+1} = [RWwords, char(DID_CDDName(i))];
    end
    subsystemName = 'DID_CDDSubsystem';
    for i = 1:numel(DID_CDDName)
        h(i) = get_param([TargetModel '/' DID_CDDModel{i}], 'Handle');  
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
    
    % Add trigger port
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
    
    % DID TPMS data Bus selector
    BlockName ='bus_selector';
    srcT = 'simulink/Signal Routing/Bus Selector';
    dstT = [NewModel '/' BlockName];
    PortsSpace = 50;
    block_x = original_x - 1500;
    block_y = original_x;
    block_w = block_x + 10;
    block_h = block_y + length(DID_TPMReadData)*PortsSpace;
    signalNames = strcat(DID_TPMReadData);
    busselector = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(busselector,'position',[block_x,block_y,block_w,block_h]);
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
    sourceport = get_param(buscreator,'PortHandles');
    sourcepos = get_param(buscreator, 'PortConnectivity');
    sourceOutpos = get_param(sourceport.Outport,'Position');
        
    % From  for Bus creator inport
    for i =1: length(DID_WriteDataInput)
        BlockName = 'From';
        block_x = sourcepos(1).Position(1) - 300;
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
        BusLine = add_line(NewModel,fromport.Outport,sourceport.Inport(i));
        set_param(BusLine, 'Name', DID_WriteDataInput(i)); 
    end

    % Outport  for Bus creator outport
    BlockName = 'BHAL_DIDGetData_raw';
    block_x = sourceOutpos(1)+150;
    block_y = sourceOutpos(2)-5;
    block_w = block_x + 20;
    block_h = block_y + 10;
    srcT = 'simulink/Sinks/Out1';
    dstT = [NewModel '/' BlockName];
    Out = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(Out,'position',[block_x,block_y,block_w,block_h]);
    Outport = get_param(Out,'PortHandles');
    gotopos = get_param(Out, 'PortConnectivity');
    add_line(NewModel,sourceport.Outport,Outport.Inport);

    % Create goto for CDD inport
    
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
    
        else  % DID_WRMode(i,1) == 'R'
    
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
    OutPos = get_param(DID_subsystem.Outport,'Position');
    % ADD goto for DID_subsystem inport, ouport and trigger
    BlockName = 'From';
    block_x = InPos(1) - 400;
    block_y = InPos(2) - 15;
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
    set_param(goto,'GotoTag','BHAL_DIDGetData_raw','ShowName','off');
    gotoport = get_param(goto,'PortHandles');
    add_line(TargetModel,DID_subsystem.Outport,gotoport.Inport);


end





