%% AutoBuild APP DID Data Model
    
function FVT_DID_List_Autobuild(~) 
    
    %% Check
    q = questdlg({'Check the following conditions:','1. Run "project_start"?',...
        '2. Confirm "FVT_DIDList" version?','3. Current folder arch?'},'Initial check','Yes','No','Yes');
    if ~contains(q, 'Yes')
        return
    end
    arch_Path = pwd;
    if ~contains(arch_Path, 'arch'), error('current folder is not under arch'), end
    project_path = extractBefore(arch_Path,'\software');

    %% Create and Open the Model
    new_model = 'DID_Model';
    close_system(new_model,0);
    open_system(new_system(new_model));
    original_x = 0;
    original_y = 0;
    

    %% Read DID List .xlsx File
    cd([project_path '/documents'])
    DID_List = string(readcell('FVT_DIDList.xlsx','Sheet',1));
    DID_Num         = DID_List(3:end,1);
    DID_Description = DID_List(3:end,2);
    DID_Datatype    = DID_List(3:end,4);
    DID_Size        = DID_List(3:end,5);
    DID_WRMode      = DID_List(3:end,6);
    DID_Input1      = DID_List(3:end,9);
    DID_Input2      = DID_List(3:end,10);
    DID_Input3      = DID_List(3:end,12);
    DID_Output1     = DID_List(3:end,11);
    DID_Output2     = DID_List(3:end,13);
    DID_HALVarName  = DID_List(3:end,16);
    DID_FlashData   = DID_List(3:end,18);
    

    %% Read Diagnostic Specificaion .xlsx File
    cd([project_path '/documents'])
    files = dir('*.xlsx');
    DSFile = files(contains({files.name}, 'DiagnosticSpecificaion')).name;
    DSFile_DIDList = string(readcell(DSFile,'Sheet','DIDList'));
    DSFile_DIDNum           = DSFile_DIDList(6:end, 1);
    DSFile_DIDDescription   = DSFile_DIDList(6:end, 2);
    DSFile_DIDServiceRead   = DSFile_DIDList(6:end, 6);
    DSFile_DIDServiceWrite  = DSFile_DIDList(6:end, 7);
    DSFile_DIDModelD31L     = DSFile_DIDList(6:end, 12);
    DSFile_DIDModelD31L24   = DSFile_DIDList(6:end, 13);
    DSFile_DIDModelD31F25   = DSFile_DIDList(6:end, 14);
    DSFile_DIDModelD31H     = DSFile_DIDList(6:end, 15);
    DSFile_DIDModelD21      = DSFile_DIDList(6:end, 16);
    DSFile_DIDFunClass      = DSFile_DIDList(6:end, 28);
    DSFile_UsedDIDNum       = string([]);

    last_slash_index = find(project_path == '\', 1, 'last');
    carmodel_folder = project_path(last_slash_index+1:end);
    
    disp(['Car Model: ' carmodel_folder])

    switch carmodel_folder
        case 'd31l-fdc'
            DSFile_CarModel = DSFile_DIDModelD31L;
        case 'd31f-fdc'
            DSFile_CarModel = DSFile_DIDModelD31L24;
        case 'd31f-fdc2'
            DSFile_CarModel = DSFile_DIDModelD31F25;
        case 'd31hawd-fdc2'
            DSFile_CarModel = DSFile_DIDModelD31H;    
        case 'd21-fdc2'
            DSFile_CarModel = DSFile_DIDModelD21;
        otherwise
            DSFile_CarModel = DSFile_DIDModelD31L;
    end

    for i = 1:length(DSFile_DIDNum)
        if strcmp(DSFile_CarModel(i,1),'Y') && (strcmp(DSFile_DIDServiceRead(i,1),'Y') || strcmp(DSFile_DIDServiceWrite(i,1),'Y')) && ...
            (contains(DSFile_DIDFunClass(i,1),'VCU') || contains(DSFile_DIDFunClass(i,1),'BCM') || contains(DSFile_DIDFunClass(i,1),'TPM') || ...
             contains(DSFile_DIDFunClass(i,1),'APS') || contains(DSFile_DIDFunClass(i,1),'ZEV'))
            DSFile_UsedDIDNum(end+1,1) = DSFile_DIDNum(i,1);
        end
    end
    
    DID_Num_NoMissing = DID_Num(~ismissing(DID_Num));
    DIDNum_Add = setdiff(DSFile_UsedDIDNum, DID_Num_NoMissing);
    DIDNum_Del = setdiff(DID_Num_NoMissing, DSFile_UsedDIDNum);
    if isempty(DIDNum_Add) && isempty(DIDNum_Del)
        disp('DID List not changed')
    else
        if ~isempty(DIDNum_Add)
            fprintf('DID added:\n')
            for i = 1:length(DIDNum_Add)
                disp(DIDNum_Add(i,1))
            end
        end
        if ~isempty(DIDNum_Del)
            fprintf('DID deleted:\n')
            for i = 1:length(DIDNum_Del)
                disp(DIDNum_Del(i,1))
            end
        end
    end

    % Flash Data valid
    j = 1;
    for i =1: length(DID_FlashData)
        if ~ismissing(DID_FlashData(i,1))
           FlashDataValid(j) =  DID_FlashData(i);
           j = j+1;
        end     
    end

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

    % DID Read Bus Selector (APP Set)
    j = 1;
    for i =1: length(DID_WRMode)
        if DID_WRMode(i,1) == 'R'
           DID_ReadDataOutput(j) =  DID_Input1(i);
           j = j+1;
           if ~ismissing(DID_Input2 (i))
               DID_ReadDataOutput(j) =  DID_Input2(i);
               j = j+1;
           end
           if ~ismissing(DID_Input3 (i))
               DID_ReadDataOutput(j) = DID_Input3(i);
               j = j+1;
           end
        end     
    end

    % DID Write Bus creator
    BlockName ='bus_Creator';
    srcT = 'simulink/Signal Routing/Bus Creator';
    dstT = [new_model '/' BlockName];
    PortsSpace = 50;
    block_x = original_x;
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
        dstT = [new_model '/' BlockName];    
        from = add_block(srcT,dstT,'MakeNameUnique','on');   
        set_param(from,'position',[block_x,block_y,block_w,block_h]);
        set_param(from,'GotoTag',DID_WriteDataInput(i),'ShowName','off');
        fromport = get_param(from,'PortHandles');
        frompos = get_param(from, 'PortConnectivity');
        BusLine = add_line(new_model,fromport.Outport,sourceport.Inport(i));
        set_param(BusLine, 'Name', DID_WriteDataInput(i)); 
    end

    % GoTo  for Bus creator outport
    BlockName = 'Goto';
    block_x = sourceOutpos(1)+150;
    block_y = sourceOutpos(2)-20;
    block_w = block_x + 220;
    block_h = block_y + 40;
    srcT = 'simulink/Signal Routing/Goto';
    dstT = [new_model '/' BlockName];
    goto = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(goto,'position',[block_x,block_y,block_w,block_h]);
    set_param(goto,'GotoTag','BHAL_DIDGetData_raw','ShowName','off');
    gotoport = get_param(goto,'PortHandles');
    gotopos = get_param(goto, 'PortConnectivity');
    add_line(new_model,sourceport.Outport,gotoport.Inport);

    % DID Read Bus Selector
    BlockName ='bus_selector';
    srcT = 'simulink/Signal Routing/Bus Selector';
    dstT = [new_model '/' BlockName];
    PortsSpace = 50;
    block_x = sourcepos(1).Position(1) + 1000 ;
    block_y = sourcepos(1).Position(2)-30;
    block_w = block_x + 10;
    block_h = block_y + length(DID_ReadDataOutput)*PortsSpace;
    signalNames = strcat(DID_ReadDataOutput);
    busselector = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(busselector,'position',[block_x,block_y,block_w,block_h]);
    set_param(busselector,'OutputSignals',join( signalNames,","),'ShowName', 'off');
    busselectorport = get_param(busselector,'PortHandles');
    busselectorpos = get_param(busselector, 'PortConnectivity');    

    % From for bus creator
    BlockName = 'From';
    block_x = busselectorpos(1).Position(1) - 300;
    block_y = busselectorpos(1).Position(2) -20;
    block_w = block_x + 220;
    block_h = block_y + 40;
    srcT = 'simulink/Signal Routing/From';
    dstT = [new_model '/' BlockName];    
    from = add_block(srcT,dstT,'MakeNameUnique','on');   
    set_param(from,'position',[block_x,block_y,block_w,block_h]);
    set_param(from,'GotoTag','BHAL_DIDSetData_raw','ShowName','off');
    fromport = get_param(from,'PortHandles');
    frompos = get_param(from, 'PortConnectivity');
    add_line(new_model,fromport.Outport,busselectorport.Inport);

    for i =1: length(DID_ReadDataOutput)
        BlockName = 'Goto';
        block_x = busselectorpos(i+1).Position(1) + 300;
        block_y = busselectorpos(i+1).Position(2) -20;
        block_w = block_x + 220;
        block_h = block_y + 40;
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [new_model '/' BlockName];    
        Goto = add_block(srcT,dstT,'MakeNameUnique','on');   
        set_param(Goto,'position',[block_x,block_y,block_w,block_h]);
        set_param(Goto,'GotoTag',DID_ReadDataOutput(i),'ShowName','off');
        Gotoport = get_param(Goto,'PortHandles');
        Gotopos = get_param(Goto, 'PortConnectivity');
        add_line(new_model,busselectorport.Outport(i),Gotoport.Inport);
        
    end
    %% DID get subsystem
    % Create subsystem (dstT = [modelname '/' BlockName] modelname = DIDGet_List)
    BlockName = 'DIDGet_List';
    block_x = busselectorpos(2).Position(1) + 1500;
    block_y = busselectorpos(2).Position(2) ;
    block_w = block_x + 400;
    block_h = block_y + 700;
    srcT = 'simulink/Ports & Subsystems/Subsystem';
    dstT = [new_model '/' BlockName];    
    subsystem = add_block(srcT,dstT);
    set_param(subsystem,'position',[block_x,block_y,block_w,block_h]);
    set_param(subsystem,'ContentPreviewEnabled','off','BackgroundColor','DarkGreen');
    delete_line([new_model '/' BlockName],'In1/1','Out1/1');
    delete_block([new_model '/' BlockName '/In1']);
    delete_block([new_model '/' BlockName '/Out1']);
    modelname = [new_model '/' BlockName];
    
    % Add inport in subsystem
    block_x = original_x;
    block_y = original_y;
    block_w = block_x + 30;
    block_h = block_y + 15;
    BlockName = 'BHAL_DIDGetData_raw';
    srcT = 'simulink/Sources/In1';
    dstT = [modelname '/' BlockName];
    inport1 = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(inport1,'position',[block_x,block_y,block_w,block_h]);
    subsystemPort = get_param(subsystem,'PortHandles');
    Inport = get_param(inport1,'PortHandles');
    Inpos = get_param(inport1, 'PortConnectivity');
    
    % Goto for subsystem inport
    block_x = Inpos.Position(1) + 300;
    block_y = Inpos.Position(2) - 15;
    block_w = block_x + 220;
    block_h = block_y + 30;
    BlockName = 'Goto';
    srcT = 'simulink/Signal Routing/Goto';
    dstT = [modelname '/' BlockName];
    goto = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(goto,'position',[block_x,block_y,block_w,block_h]);
    set_param(goto,'Gototag','BHAL_DIDGetData_raw','ShowName', 'off');
    gotoport = get_param(goto,'PortHandles');
    add_line(modelname,Inport.Outport,gotoport.Inport,'autorouting','smart')


    % Flash Data Inport
    for i = 1:length(FlashDataValid)
        block_x = original_x;
        block_y = Inpos.Position(2) + 80*(i);
        block_w = block_x + 30;
        block_h = block_y + 15;
        BlockName = 'FlashInport';
        srcT = 'simulink/Sources/In1';
        dstT = [modelname '/' BlockName];
        inport = add_block(srcT,dstT,'MakeNameUnique','on');
        newInportName = [FlashDataValid(i) num2str(i)];
        set_param(inport, 'Name', newInportName);
        set_param(inport,'position',[block_x,block_y,block_w,block_h]);
        FlashInport = get_param(inport,'PortHandles');
        FlashInpos = get_param(inport, 'PortConnectivity');
        
        block_x = FlashInpos.Position(1) + 300;
        block_y = FlashInpos.Position(2) - 15;
        block_w = block_x + 220;
        block_h = block_y + 30;
        BlockName = 'Goto';
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [modelname '/' BlockName];
        goto = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(goto,'position',[block_x,block_y,block_w,block_h]);
        set_param(goto,'Gototag',FlashDataValid(i),'ShowName', 'off');
        gotoport = get_param(goto,'PortHandles');
        add_line(modelname,FlashInport.Outport,gotoport.Inport,'autorouting','smart')

    end

    % DID Get data busselector 
    
    BlockName ='bus_selector';
    srcT = 'simulink/Signal Routing/Bus Selector';
    dstT = [modelname '/' BlockName];
    PortsSpace = 50;
    block_x = original_x + 1200 ;
    block_y = original_y;
    block_w = block_x + 10;
    block_h = block_y + length(DID_WriteDataInput)*PortsSpace;
    signalNames = strcat(DID_WriteDataInput);
    GotoTagName = strcat('VHAL_',strrep(extractAfter(signalNames,'_'), '_', ''),'_raw');
    busselector = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(busselector,'position',[block_x,block_y,block_w,block_h]);
    set_param(busselector,'OutputSignals',join( GotoTagName,","),'ShowName', 'off');
    busselectorport = get_param(busselector,'PortHandles');
    busselectorpos = get_param(busselector, 'PortConnectivity'); 
    
    % From for bus selector
    BlockName = 'From';
    block_x = busselectorpos(1).Position(1) - 300;
    block_y = busselectorpos(1).Position(2) -20;
    block_w = block_x + 220;
    block_h = block_y + 40;
    srcT = 'simulink/Signal Routing/From';
    dstT = [modelname '/' BlockName];    
    From = add_block(srcT,dstT,'MakeNameUnique','on');   
    set_param(From,'position',[block_x,block_y,block_w,block_h]);
    set_param(From,'GotoTag','BHAL_DIDGetData_raw','ShowName','off');
    Fromport = get_param(From,'PortHandles');
    add_line(modelname,Fromport.Outport,busselectorport.Inport,'autorouting','smart');
    
    DD_cell = cell(length(DID_WriteDataInput),16);

    % Read DD_HAL_SYS.xlsx
    DD_path = [arch_Path '\hal\hal_sys'];
    cd(DD_path);
    File_name = 'DD_HAL_SYS.xlsx';
    Original_table = readtable(File_name,'Sheet',1);
    Original_cell = table2cell(Original_table(:,1));

    for i = 1: length(DID_WriteDataInput)
        % add datatype convert
        block_x = busselectorpos(i+1).Position(1) + 200;
        block_y = busselectorpos(i+1).Position(2) -15;
        block_w = block_x + 80;
        block_h = block_y + 30;
        BlockName = 'UnitConverter';
        srcT = 'simulink/Signal Attributes/Data Type Conversion';
        dstT = [modelname '/' BlockName];
        Convert = add_block(srcT,dstT,'MakeNameUnique','on');     
        set_param(Convert,'position',[block_x,block_y,block_w,block_h])
        set_param(Convert, 'OutDataTypeStr', DID_NoMisDataType(i));
        Convertport = get_param(Convert,'PortHandles');
        add_line(modelname,busselectorport.Outport(i),Convertport.Inport,'autorouting','smart');

        % Goto for busselector
        BlockName = 'Goto';
        block_x = busselectorpos(i+1).Position(1) + 400;
        block_y = busselectorpos(i+1).Position(2) -20;
        block_w = block_x + 220;
        block_h = block_y + 40;
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [modelname '/' BlockName];    
        Goto = add_block(srcT,dstT,'MakeNameUnique','on');   
        set_param(Goto,'position',[block_x,block_y,block_w,block_h]);
        GotoTagName = strrep(extractAfter(DID_WriteDataInput(i),'_'), '_', '');
        set_param(Goto,'GotoTag',['VHAL_' char(GotoTagName) '_raw'],'ShowName','off');
        Gotoport = get_param(Goto,'PortHandles');
        Gotopos = get_param(Goto, 'PortConnectivity');
        line = add_line(modelname,Convertport.Outport,Gotoport.Inport,'autorouting','smart');
        set_param(line, 'Name', ['VHAL_' char(GotoTagName) '_raw']);  

        % Add new DD_cell cell
        if ~contains(['VHAL_' char(GotoTagName) '_raw'],Original_cell) && DID_NoMisSize(i) == 1
            DD_Index_Msg = find(cellfun(@isempty,DD_cell(1:end,1)));
            DD_cell(DD_Index_Msg(1),1) = {['VHAL_' char(GotoTagName) '_raw']}; % HAL signal name
            DD_cell(DD_Index_Msg(1),2) = {'internal'}; % Direction
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
        elseif ~contains(['VHAL_' char(GotoTagName) '_raw'],Original_cell) && DID_NoMisSize(i) > 1
            DD_Index_Msg = find(cellfun(@isempty,DD_cell(1:end,1)));
            DD_cell(DD_Index_Msg(1),1) = {['VHAL_' char(GotoTagName) '_raw']}; % HAL signal name
            DD_cell(DD_Index_Msg(1),2) = {'internal'}; % Direction
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

    % % Delete empty DD_cell cell
    % for j = length(DD_cell(:,1)):-1:1
    %     if cellfun(@isempty,DD_cell(j,1))
    %         DD_cell(j,:) = [];
    %     end
    % end
    % 
    % % Modify DD file
    % 
    % DD_table = cell2table(DD_cell);
    % DD_table.Properties.VariableNames = Original_table.Properties.VariableNames;
    % New_table = [Original_table;DD_table];
    % writetable(New_table,File_name,'Sheet',1);
    j = 1;
    % Add inport to subsystem
    for i = 1:length(DID_WRMode)
        if DID_WRMode(i) =='W'
            
            % Add hcu_lib subsystem
            BlockName = char(DID_Description(i));
            block_x = busselectorpos(2).Position(1) + 1200;
            block_y = busselectorpos(2).Position(2) + 300*(j-1);
            block_w = block_x + 300;
            block_h = block_y + 250;
            srcT = 'hcu_lib/Basic_Blocks/DIDReadData';
            dstT = [modelname '/' BlockName];
            DIDblock = add_block(srcT, dstT, 'MakeNameUnique', 'on');
            set_param(DIDblock, 'position', [block_x, block_y, block_w, block_h])
            DIDblockport = get_param(DIDblock, 'PortHandles');
            DIDblockpos = get_param(DIDblock, 'PortConnectivity');
            j = j+1;
            % From of DID Data

            BlockName = 'From';
            block_x = DIDblockpos(1).Position(1) - 300;
            block_y = DIDblockpos(1).Position(2) -20;
            block_w = block_x + 220;
            block_h = block_y + 40;
            srcT = 'simulink/Signal Routing/From';
            dstT = [modelname '/' BlockName];    
            From = add_block(srcT,dstT,'MakeNameUnique','on'); 
            FromTagName = strrep(extractAfter(DID_Output2(i),'_'), '_', '');
            set_param(From,'position',[block_x,block_y,block_w,block_h]);
            set_param(From,'GotoTag',['VHAL_' char(FromTagName) '_raw'],'ShowName','off');
            Fromport = get_param(From,'PortHandles');
            add_line(modelname,Fromport.Outport,DIDblockport.Inport(1),'autorouting','smart');

            % From of DID State
            
            BlockName = 'From';
            block_x = DIDblockpos(2).Position(1) - 300;
            block_y = DIDblockpos(2).Position(2) -20;
            block_w = block_x + 220;
            block_h = block_y + 40;
            srcT = 'simulink/Signal Routing/From';
            dstT = [modelname '/' BlockName];    
            From = add_block(srcT,dstT,'MakeNameUnique','on'); 
            FromTagName = strrep(extractAfter(DID_Output1(i),'_'), '_', '');
            set_param(From,'position',[block_x,block_y,block_w,block_h]);
            set_param(From,'GotoTag',['VHAL_' char(FromTagName) '_raw'],'ShowName','off');
            Fromport = get_param(From,'PortHandles');
            add_line(modelname,Fromport.Outport,DIDblockport.Inport(2),'autorouting','smart');

            % From of Flash Data

            BlockName = 'From';
            block_x = DIDblockpos(3).Position(1) - 300;
            block_y = DIDblockpos(3).Position(2) -20;
            block_w = block_x + 220;
            block_h = block_y + 40;
            srcT = 'simulink/Signal Routing/From';
            dstT = [modelname '/' BlockName];    
            From = add_block(srcT,dstT,'MakeNameUnique','on');   
            set_param(From,'position',[block_x,block_y,block_w,block_h]);
            set_param(From,'GotoTag',DID_FlashData(i),'ShowName','off');
            Fromport = get_param(From,'PortHandles');
            add_line(modelname,Fromport.Outport,DIDblockport.Inport(3),'autorouting','smart');

            % Goto for hcu_lib output

            BlockName = 'Goto';
            block_x = DIDblockpos(4).Position(1) + 200;
            block_y = DIDblockpos(4).Position(2) -20;
            block_w = block_x + 220;
            block_h = block_y + 40;
            srcT = 'simulink/Signal Routing/Goto';
            dstT = [modelname '/' BlockName];    
            Goto = add_block(srcT,dstT,'MakeNameUnique','on');   
            set_param(Goto,'position',[block_x,block_y,block_w,block_h]);
            set_param(Goto,'GotoTag',DID_HALVarName(i),'ShowName','off');
            Gotoport = get_param(Goto,'PortHandles');
            add_line(modelname,DIDblockport.Outport,Gotoport.Inport,'autorouting','smart');
        end
    end

    % Create buscreator
    NoMis_HALName = DID_HALVarName(~ismissing(DID_HALVarName));
    BlockName ='bus_Creator';
    srcT = 'simulink/Signal Routing/Bus Creator';
    dstT = [modelname '/' BlockName];
    PortsSpace = 80;
    block_x = original_x + 3800;
    block_y = original_y;
    block_w = block_x + 10;
    block_h = block_y + length(NoMis_HALName)*PortsSpace;
    buscreator = add_block(srcT, dstT,'MakeNameUnique','on');
    set_param(buscreator,'position',[block_x,block_y,block_w,block_h]);
    set_param(buscreator,'Inputs',string(length(NoMis_HALName)),'ShowName','off');
    sourceport = get_param(buscreator,'PortHandles');
    sourcepos = get_param(buscreator, 'PortConnectivity');
    sourceOutpos = get_param(sourceport.Outport,'Position');

    % From to buscreator
    for i = 1:length(NoMis_HALName)
        BlockName = 'From';
        block_x = sourcepos(i).Position(1) - 300;
        block_y = sourcepos(i).Position(2) -20;
        block_w = block_x + 220;
        block_h = block_y + 40;
        srcT = 'simulink/Signal Routing/From';
        dstT = [modelname '/' BlockName];    
        From = add_block(srcT,dstT,'MakeNameUnique','on');   
        set_param(From,'position',[block_x,block_y,block_w,block_h]);
        set_param(From,'GotoTag',NoMis_HALName(i),'ShowName','off');
        Fromport = get_param(From,'PortHandles');
        BusLine = add_line(modelname,Fromport.Outport,sourceport.Inport(i),'autorouting','smart');
        set_param(BusLine, 'Name', NoMis_HALName(i)); 

    end
    
    % Outport for buscreator
    block_x = sourceOutpos(1) + 100 ;
    block_y = sourceOutpos(2) -5;
    block_w = block_x + 20;
    block_h = block_y + 10;
    BlockName = 'BHAL_DIDOrigOutput_raw8';
    srcT = 'simulink/Sinks/Out1';
    dstT = [modelname '/' BlockName];
    Out = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(Out,'position',[block_x,block_y,block_w,block_h]);
    Outport = get_param(Out,'PortHandles');
    add_line(modelname,sourceport.Outport,Outport.Inport,'autorouting','smart');


    % Add from to DID List subsystem
    SubsystemPort = get_param(subsystem,'PortHandles');
    inportHandle = SubsystemPort.Inport;
    OutportHandle = SubsystemPort.Outport;
    SubsystemPos = get_param(subsystem,'Position');
    subsystemHandle = get_param(subsystem,'Handle');
    inportBlocks = find_system(subsystemHandle, 'SearchDepth', 1, 'BlockType', 'Inport');
    inportName = get_param(inportBlocks, 'Name');
    for i = 1:length (inportName)
        InPosition = get_param(inportHandle(i), 'Position');
        BlockName = 'From';
        block_x = InPosition(1) - 500;
        block_y = InPosition(2) - 15;
        block_w = block_x + 220;
        block_h = block_y + 30;
        srcT = 'simulink/Signal Routing/From';
        dstT = [new_model '/' BlockName];    
        from = add_block(srcT,dstT,'MakeNameUnique','on');   
        set_param(from,'position',[block_x,block_y,block_w,block_h]);
        set_param(from,'GotoTag',string(inportName(i)),'ShowName','off');
        fromport = get_param(from,'PortHandles');
        frompos = get_param(from, 'PortConnectivity');
        add_line(new_model,fromport.Outport,SubsystemPort.Inport(i));
    end
    
    % Add goto for DID List subsystem output
    OutPosition = get_param(OutportHandle, 'Position');
    BlockName = 'Goto';
    block_x = OutPosition(1) + 500;
    block_y = OutPosition(2) - 20;
    block_w = block_x + 220;
    block_h = block_y + 40;
    srcT = 'simulink/Signal Routing/Goto';
    dstT = [new_model '/' BlockName];    
    Goto = add_block(srcT,dstT,'MakeNameUnique','on');   
    set_param(Goto,'position',[block_x,block_y,block_w,block_h]);
    set_param(Goto,'GotoTag','BHAL_DIDOrigOutput_raw8','ShowName','off');
    Gotoport = get_param(Goto,'PortHandles');
    add_line(new_model,SubsystemPort.Outport,Gotoport.Inport,'autorouting','smart');

end
