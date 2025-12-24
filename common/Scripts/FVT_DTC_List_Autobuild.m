%% AutoBuild APP DTC_list Data Model
    
function FVT_DTC_List_Autobuild(~) 

    %% Check
    q = questdlg({'Check the following conditions:','1. Run "project_start"?',...
        '2. Confirm "FVT_DTCList" version?','3. Current folder arch?'},'Initial check','Yes','No','Yes');
    if ~contains(q, 'Yes')
        return
    end
    archPath = pwd;
    if ~contains(archPath, 'arch'), error('current folder is not under arch'), end
    projectPath = extractBefore(archPath,'\software');
    
    %% Create and Open the Model
    newModel = 'DTC_list';
    open_system(new_system(newModel));
    originalX = 0;
    originalY = 0;
    
    %% Read DTC Map .xlsx File
    cd([projectPath '\documents'])    
    excel = string(readcell('FVT_DTCList'));
    
    fvtDtcId = excel(3:end,1);
    FvtDtcSigName = excel(3:end,2);
    matrix(:,1) = fvtDtcId;
    matrix(:,2) = FvtDtcSigName;
    DtcId = matrix(:,1);
    DtcSigName = matrix(:,2);

    for i = 1:length(DtcId)
        DtcArray(i,1) = i-1;
    end

    %% Read Diagnostic Specificaion .xlsx File
    cd([projectPath '/../common/documents'])
    files = dir('*.xlsx');
    dsFile = files(contains({files.name}, 'DiagnosticSpecificaion')).name;
    dsFileDtcList = string(readcell(dsFile,'Sheet','DTCList'));
    dsFileDtcDis           = dsFileDtcList(6:end, 1);
    dsFileDtcByte          = dsFileDtcList(6:end, 2);
    dsFileDtcMean          = dsFileDtcList(6:end, 3);
    dsFileDtcModelD31l     = dsFileDtcList(6:end, 7);
    dsFileDtcModelD31l24   = dsFileDtcList(6:end, 8);
    dsFileDtcModelD31f25   = dsFileDtcList(6:end, 9);
    dsFileDtcModelD31h     = dsFileDtcList(6:end, 10);
    dsFileDtcModelD21      = dsFileDtcList(6:end, 11);
    dsFileDtcFunClass      = dsFileDtcList(6:end, 27);
    dsFileUsedDtcByte      = string([]);

    lastSlashIndex = find(projectPath == '\', 1, 'last');
    carModelFolder = projectPath(lastSlashIndex+1:end);
    
    disp(['Car Model: ' carModelFolder])

    switch carModelFolder
        case 'd31l-fdc'
            dsFileCarModel = dsFileDtcModelD31l;
        case 'd31f-fdc'
            dsFileCarModel = dsFileDtcModelD31l24;
        case 'd31f-fdc2'
            dsFileCarModel = dsFileDtcModelD31f25;
        case 'd31hawd-fdc2'
            dsFileCarModel = dsFileDtcModelD31h; 
        case 'd31hrwd-fdc2'
            dsFileCarModel = dsFileDtcModelD31h;    
        case 'd21awd-fdc2'
            dsFileCarModel = dsFileDtcModelD21;
        case 'd21rwd-fdc2'
            dsFileCarModel = dsFileDtcModelD21;
        otherwise
            dsFileCarModel = dsFileDtcModelD31l;
    end

    
    for i = 1:length(dsFileDtcByte)
        if strcmp(dsFileCarModel(i,1),'Y') && (contains(dsFileDtcFunClass(i,1),'FD') || ...
            contains(dsFileDtcFunClass(i,1),'VCU') || contains(dsFileDtcFunClass(i,1),'BCM') || contains(dsFileDtcFunClass(i,1),'TPM') || ...
            contains(dsFileDtcFunClass(i,1),'VMC') || contains(dsFileDtcFunClass(i,1),'ZEV') || contains(dsFileDtcFunClass(i,1),'APS'))
            dsFileUsedDtcByte(end+1,1) = dsFileDtcByte(i,1);
        end
    end
    
    dtcIdNoMissing = fvtDtcId(~ismissing(fvtDtcId));
    dtcByteDel = setdiff(dtcIdNoMissing, dsFileUsedDtcByte);
    dtcByteNotImplemented = setdiff(dsFileUsedDtcByte, dtcIdNoMissing);

    if isempty(dtcByteNotImplemented)
        disp('All DTCs are implemented')
    else % ~isempty(dtcByteNotImplemented)
        fprintf('DTC not implemented:\n')
        for i = 1:length(dtcByteNotImplemented)
            disp(dtcByteNotImplemented(i,1))
        end
    end

    disp('==========================')

    if isempty(dtcByteDel)
        disp('DTC List not changed')
    else % ~isempty(dtcByteDel)
        fprintf('DTC deleted:\n')
        for i = 1:length(dtcByteDel)
            disp(dtcByteDel(i,1))
        end
    end

    dtcArraySize = 320 ;
    headerRow = 10;

    %% Subsystem DTC_list
    BlockName = 'DTC_list';
    block_x = originalX;
    block_y = originalY;
    block_w = block_x + 250;
    block_h = block_y + 400;
    srcT = 'simulink/Ports & Subsystems/Subsystem';
    dstT = [newModel '/' BlockName];    
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'ContentPreviewEnabled','off','BackgroundColor','LightBlue');
    
    delete_line([newModel '/' BlockName],'In1/1','Out1/1');
    delete_block([newModel '/' BlockName '/In1']);
    delete_block([newModel '/' BlockName '/Out1']);
    modelname = [newModel '/' BlockName];
    j = 1;
    for i =1: length(DtcSigName)
        if  ~ismissing(DtcSigName (i))
            NoMisData(j,1) = DtcId(i);
            NoMisData(j,2) = DtcSigName(i);
            j=j+1;
        end
    end
    % DDM DTC_raw32 Bus Selector
    BlockName ='bus_selector';
    srcT = 'simulink/Signal Routing/Bus Selector';
    dstT = [modelname '/' BlockName];
    SelectDtcData = {};  % Initialize SelectDtcData as a cell array  
    for i = 1:length(NoMisData(:,2))  
        splitData = split(NoMisData{i, 2});  % Split the data for the current row  
        SelectDtcData = string(unique([SelectDtcData; splitData(:)]));  % Append the split data as a column  
    end
    PortsSpace = 50;
    block_x = originalX - 1000 ;
    block_y = originalY;
    block_w = block_x + 10;
    block_h = block_y + length(SelectDtcData)*PortsSpace;
    
    signalNames = strcat('VOUTP_', SelectDtcData,'DTC_raw32');
    busselector = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(busselector,'position',[block_x,block_y,block_w,block_h]);
    set_param(busselector,'OutputSignals',join( signalNames,","),'ShowName', 'off');
    busselectorport = get_param(busselector,'PortHandles');
    busselectorpos = get_param(busselector, 'PortConnectivity');

    % Inport
    block_x = busselectorpos(1).Position(1) - 200;
    block_y = busselectorpos(1).Position(2) - 10;
    block_w = block_x + 30;
    block_h = block_y + 15;
    BlockName = 'BOUTP_outputs';
    srcT = 'simulink/Sources/In1';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    Inport = get_param(h,'PortHandles');
    add_line(modelname,Inport.Outport(1),busselectorport.Inport(1),'autorouting','smart');
    
    
    for i = 1:length(SelectDtcData)
        block_x = busselectorpos(i+1).Position(1) + 150;
        block_y = busselectorpos(i+1).Position(2) - 20;
        block_w = block_x + 220;
        block_h = block_y + 35;
        BlockName = 'Goto';
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [modelname '/' BlockName];
        goto = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(goto,'position',[block_x,block_y,block_w,block_h]);
        set_param(goto,'Gototag',signalNames(i),'ShowName', 'off');
        gotoport = get_param(goto,'PortHandles');
        add_line(modelname,busselectorport.Outport(i),gotoport.Inport,'autorouting','smart')
    end
    
    block_x = originalX;
    block_y = originalY -300;
    j = 0;
    % Library
    for i = 1:length(DtcId)
   
        if ~ismissing(DtcSigName(i))
        split_DTCSig = split(DtcSigName(i));
        block_x = block_x ;
        block_y = block_y + 300 +10*length(split_DTCSig);
        block_w = block_x + 200;
        block_h = block_y + 150;
        BlockName = 'DTCID+Status';
        srcT = 'FVT_lib/hal/DTC_ID_and_Info';
        dstT = [modelname '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'ShowName', 'off');
        sourceport = get_param(h,'PortHandles');
        targetport = sourceport.Inport;
        targetOutport = sourceport.Outport(1);
        targetpos = get_param(targetport(1),'Position');
        targetpos2 = get_param(targetport(2),'Position');
        targetOutpos = get_param(targetOutport(1),'Position'); 
    
        block_x1 = targetpos(1) - 250;
        block_y1 = targetpos(2) - 20;
        block_w1 = block_x1 +200;
        block_h1 = block_y1 + 40;
        BlockName = 'DTCID';
        srcT = 'simulink/Commonly Used Blocks/Constant';
        dstT = [modelname '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x1,block_y1,block_w1,block_h1]);
        set_param(h,'value',DtcId(i),'ShowName', 'off');
        sourceport = get_param(h,'PortHandles');
        add_line(modelname,sourceport.Outport(1),targetport(1));
        
        if length(split_DTCSig) < 2
            block_x1 = block_x1;
            block_y1 = block_y1 + 75;
            block_w1 = block_x1 + 200;
            block_h1 = block_y1 + 40;
            BlockName = 'From';
            srcT = 'simulink/Signal Routing/From';
            dstT = [modelname '/' BlockName];
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_x1,block_y1,block_w1,block_h1]);
            set_param(h,'GotoTag',['VOUTP_' char(split_DTCSig) 'DTC_raw32'],'ShowName','off');
            sourceport = get_param(h,'PortHandles');
            add_line(modelname,sourceport.Outport(1),targetport(2));
        else
            % Add OR model
            block_Or_x = targetpos2(1) - 300;
            block_Or_y = targetpos2(2) - (30*length(split_DTCSig));
            block_w = block_Or_x + 30;
            block_h = block_Or_y + 60*length(split_DTCSig);
            BlockName = 'OR';
            srcT = 'simulink/Commonly Used Blocks/Logical Operator';
            dstT = [modelname '/' BlockName];
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_Or_x,block_Or_y,block_w,block_h]);
            set_param(h,'Inputs', string(length(split_DTCSig)));
            set_param(h,'Operator','OR');
            Orport = get_param(h,'PortHandles');
            OrInpos = get_param(Orport.Inport,'Position');
            block_y = OrInpos{end}(2) -150;
            add_line(modelname,Orport.Outport,targetport(2),'autorouting','smart');
    
            for j = 1: length(split_DTCSig)
                block_x1 = OrInpos{j}(1) - 250;
                block_y1 = OrInpos{j}(2) - 20;
                block_w1 = block_x1 + 200;
                block_h1 = block_y1 + 40;
                BlockName = 'From';
                srcT = 'simulink/Signal Routing/From';
                dstT = [modelname '/' BlockName];
                h = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(h,'position',[block_x1,block_y1,block_w1,block_h1]);
                set_param(h,'GotoTag',['VOUTP_' char(split_DTCSig(j)) 'DTC_raw32'],'ShowName','off');
                sourceport = get_param(h,'PortHandles');
                add_line(modelname,sourceport.Outport,Orport.Inport(j));
            end
        end
        block_x2 = targetOutpos(1) + 120;
        block_y2 = targetOutpos(2) - 20;
        block_w2 = block_x2 +200;
        block_h2 = block_y2 + 40;
        BlockName = 'Goto';
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [modelname '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x2,block_y2,block_w2,block_h2]);
        set_param(h,'GotoTag',['DTC_raw' num2str(i-1)],'ShowName', 'off');
        sourceport = get_param(h,'PortHandles');
        add_line(modelname,targetOutport,sourceport.Inport(1));
        
        end
    end

    % mux
    BlockName = 'Mux';
    block_x = originalX + 1000;
    block_y = originalY;
    block_w = block_x + 20;
    block_h = block_y + length(DtcArray)*PortsSpace;
    srcT = 'simulink/Commonly Used Blocks/Mux';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT);
    set_param(h,'Inputs',num2str(ceil(length(DtcArray))));
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    targetport = get_param(h,'PortHandles');
    targetpos = get_param(h, 'PortConnectivity');
    targetOutport = targetport.Outport;
    targetOutpos = get_param(targetOutport,'Position');


    % from to mux

    headerFileName = 'uds_dem_config.h';
    datetime.setDefaultFormats('default','yyyy-MM-dd HH:mm:ss');
    DTCConstantArrayDef = sprintf([
    '%% =========== $Update Time :  %s $ =========\n' ...
    'disp(''Loading $Id: DTC_Constant_Definition.m  %s    foxtron $'')\n' ...
    '%% DTC Costant Definition \n'...
    newline ...
    ],datetime,datetime);

    for i = 1:length(DtcSigName)
        block_x = targetpos(i).Position(1) - 300;
        block_y = targetpos(i).Position(2) - 20;
        block_w = block_x + 220;
        block_h = block_y + 35;
        BlockName = 'Constant';
        srcT = 'simulink/Commonly Used Blocks/Constant';
        dstT = [modelname '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'OutDataTypeStr', 'uint16');
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        DTCConstantStr = strcat("DTC_", erase(DtcId(i), "0x"));
        set_param(h,'Value',DTCConstantStr,'ShowName', 'off');
        gotoport = get_param(h,'PortHandles');
        add_line(modelname,gotoport.Outport,targetport.Inport(i),'autorouting','smart')
        DTCConstantDef = sprintf([
        '%s = Simulink.Parameter;\n' ...
        '%s.Value = 0;\n' ...
        '%s.CoderInfo.StorageClass = ''Custom'';\n' ...
        '%s.CoderInfo.CustomStorageClass = ''ImportFromFile'';\n' ...
        '%s.CoderInfo.CustomAttributes.HeaderFile = ''%s'';\n' ...
         ], DTCConstantStr, DTCConstantStr, DTCConstantStr, DTCConstantStr, DTCConstantStr, headerFileName);
        DTCConstantArrayDef = [DTCConstantArrayDef DTCConstantDef newline];
    end

    cd(archPath)
    fid = fopen('DTC_Constant_Definition.m', 'w');
    fwrite(fid, DTCConstantArrayDef);
    fclose(fid);

    % mux to mux
    block_x2 = targetOutpos(1) + 300;
    block_y2 = targetOutpos(2) - 25;
    block_w2 = block_x2 +20;
    block_h2 = block_y2 + 100;
    BlockName = 'Mux';
    srcT = 'simulink/Commonly Used Blocks/Mux';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x2,block_y2,block_w2,block_h2]);
    muxport = get_param(h,'PortHandles');
    muxpos = get_param(h, 'PortConnectivity');
    add_line(modelname,targetOutport,muxport.Inport(1),'autorouting','smart');
    muxOutport = muxport.Outport;
    muxOutpos = get_param(muxOutport,'Position');

    % constant to mux
    block_x = targetOutpos(1) + 50;
    block_y = targetOutpos(2) + 35;
    block_w = block_x + 200;
    block_h = block_y + 30;
    BlockName = 'Constant';
    srcT = 'simulink/Commonly Used Blocks/Constant';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'OutDataTypeStr', 'uint16');
    set_param(h,'Value',mat2str(zeros(1,(dtcArraySize-length(DtcId)))),'ShowName', 'on')
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    conport = get_param(h,'PortHandles');
    add_line(modelname,conport.Outport,muxport.Inport(2),'autorouting','smart');
    
    % datatype convert
    block_x = muxOutpos(1) + 100;
    block_y = muxOutpos(2) - 15;
    block_w = block_x + 150;
    block_h = block_y + 30;
    BlockName = 'UnitConverter';
    srcT = 'simulink/Signal Attributes/Data Type Conversion';
    Convert = add_block(srcT,dstT,'MakeNameUnique','on');     
    set_param(Convert,'position',[block_x,block_y,block_w,block_h])
    Convertport = get_param(Convert,'PortHandles');
    add_line(modelname,muxport.Outport,Convertport.Inport,'autorouting','smart');

    % goto
    block_x = muxOutpos(1) + 400;
    block_y = muxOutpos(2) - 15;
    block_w = block_x + 200;
    block_h = block_y + 30;
    BlockName = 'Goto';
    srcT = 'simulink/Signal Routing/Goto';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'GotoTag','DTC_Constant_Array','ShowName', 'off');
    gotoport = get_param(h,'PortHandles');
    add_line(modelname,Convertport.Outport(1),gotoport.Inport(1),'autorouting','smart');

    % Outport
    block_x = block_x ;
    block_y = block_y + 100;
    block_w = block_x + 30;
    block_h = block_y + 15;
    BlockName = 'DTC_Constant_Array';
    srcT = 'simulink/Sinks/Out1';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    Outport = get_param(h,'PortHandles');
    add_line(modelname,muxport.Outport(1),Outport.Inport(1),'autorouting','smart');

    % mux
    BlockName = 'Mux';
    block_x = originalX + 2500;
    block_y = originalY;
    block_w = block_x + 20;
    block_h = block_y + length(DtcArray)*PortsSpace;
    srcT = 'simulink/Commonly Used Blocks/Mux';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'Inputs',num2str(ceil(length(DtcArray))));
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    targetport = get_param(h,'PortHandles');
    targetpos = get_param(h, 'PortConnectivity');
    targetOutport = targetport.Outport;
    targetOutpos = get_param(targetOutport,'Position');


    % from to mux
    for i = 1:length(DtcSigName)
        if ~ismissing(DtcSigName (i))
            block_x = targetpos(i).Position(1) - 300;
            block_y = targetpos(i).Position(2) - 20;
            block_w = block_x + 220;
            block_h = block_y + 35;
            BlockName = 'From';
            srcT = 'simulink/Signal Routing/From';
            dstT = [modelname '/' BlockName];
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h,'Gototag',['DTC_raw' num2str(i-1)],'ShowName', 'off');
            gotoport = get_param(h,'PortHandles');
            add_line(modelname,gotoport.Outport,targetport.Inport(i),'autorouting','smart')

        else
            block_x = targetpos(i).Position(1) - 300;
            block_y = targetpos(i).Position(2) - 20;
            block_w = block_x + 220;
            block_h = block_y + 35;
            BlockName = 'Constant';
            srcT = 'simulink/Commonly Used Blocks/Constant';
            dstT = [modelname '/' BlockName];
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'OutDataTypeStr', 'uint32');
            set_param(h,'Value','ZERO_INT','ShowName', 'on')
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            gotoport = get_param(h,'PortHandles');
            add_line(modelname,gotoport.Outport,targetport.Inport(i),'autorouting','smart')
        end

    end

    % mux to mux
    block_x2 = targetOutpos(1) + 300;
    block_y2 = targetOutpos(2) - 25;
    block_w2 = block_x2 +20;
    block_h2 = block_y2 + 100;
    BlockName = 'Mux';
    srcT = 'simulink/Commonly Used Blocks/Mux';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x2,block_y2,block_w2,block_h2]);
    muxport = get_param(h,'PortHandles');
    muxpos = get_param(h, 'PortConnectivity');
    add_line(modelname,targetOutport,muxport.Inport(1),'autorouting','smart');
    muxOutport = muxport.Outport;
    muxOutpos = get_param(muxOutport,'Position');

    % constant to mux
    block_x = targetOutpos(1) + 50;
    block_y = targetOutpos(2) + 35;
    block_w = block_x + 200;
    block_h = block_y + 30;
    BlockName = 'Constant';
    srcT = 'simulink/Commonly Used Blocks/Constant';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'OutDataTypeStr', 'uint32');
    set_param(h,'Value',mat2str(zeros(1,(dtcArraySize-length(DtcId)))),'ShowName', 'on')
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    conport = get_param(h,'PortHandles');
    add_line(modelname,conport.Outport,muxport.Inport(2),'autorouting','smart');
    
    % datatype convert
    block_x = muxOutpos(1) + 100;
    block_y = muxOutpos(2) - 15;
    block_w = block_x + 150;
    block_h = block_y + 30;
    BlockName = 'UnitConverter';
    srcT = 'simulink/Signal Attributes/Data Type Conversion';
    Convert = add_block(srcT,dstT,'MakeNameUnique','on');     
    set_param(Convert,'position',[block_x,block_y,block_w,block_h])
    Convertport = get_param(Convert,'PortHandles');
    add_line(modelname,muxport.Outport,Convertport.Inport,'autorouting','smart');

    % goto
    block_x = muxOutpos(1) + 400;
    block_y = muxOutpos(2) - 15;
    block_w = block_x + 200;
    block_h = block_y + 30;
    BlockName = 'Goto';
    srcT = 'simulink/Signal Routing/Goto';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'GotoTag','DtcArray','ShowName', 'off');
    gotoport = get_param(h,'PortHandles');
    lineHandle = add_line(modelname,Convertport.Outport(1),gotoport.Inport(1),'autorouting','smart');
    set_param(lineHandle, 'Name', 'VDTC_DTCArray_raw32');  
    set(lineHandle,'MustResolveToSignalObject',1);

    % Outport
    block_x = block_x ;
    block_y = block_y + 100;
    block_w = block_x + 30;
    block_h = block_y + 15;
    BlockName = 'DtcArray';
    srcT = 'simulink/Sinks/Out1';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    Outport = get_param(h,'PortHandles');
    add_line(modelname,muxport.Outport(1),Outport.Inport(1),'autorouting','smart');

%%%%%%%%%%%%%%%%%%%%%%%%%% Header array %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % from
    block_x = originalX + 3500;
    block_y = originalY +45;
    block_w = block_x + 200;
    block_h = block_y + 30;
    BlockName = 'From';
    srcT = 'simulink/Signal Routing/From';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'GotoTag','DtcArray','ShowName', 'off');
    fromport = get_param(h,'PortHandles');
    frompos = get_param(h, 'PortConnectivity');

    % BitwiseAND
    block_x = block_x + 300;
    block_y = block_y ;
    block_w = block_x + 100;
    block_h = block_y + 30;   
    BlockName = 'BitwiseAND';
    srcT = 'simulink/Logic and Bit Operations/Bitwise Operator';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'logicop','AND');
    set_param(h,'BitMask','0x0001');
    Bitwiseport = get_param(h,'PortHandles');
    add_line(modelname,fromport.Outport,Bitwiseport.Inport(1),'autorouting','smart');

    % detect change
    block_x = block_x + 300;
    block_y = block_y ;
    block_w = block_x + 100;
    block_h = block_y + 30;   
    BlockName='detect_change';
    srcT = 'simulink/Logic and Bit Operations/Detect Change';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    DCport = get_param(h,'PortHandles');
    DCpos = get_param(h, 'PortConnectivity');
    add_line(modelname,Bitwiseport.Outport,DCport.Inport(1),'autorouting','smart');

    % mux
    PortsSpace = 100;
    block_x = block_x + 800;
    block_y = block_y - 35;
    block_w = block_x + 20;
    block_h = block_y + headerRow*PortsSpace;
    BlockName = 'Mux2';
    srcT = 'simulink/Commonly Used Blocks/Mux';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'Inputs',num2str(ceil(headerRow)));
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    targetport = get_param(h,'PortHandles');
    targetpos = get_param(h, 'PortConnectivity');
    targetOutport = targetport.Outport;
    targetOutpos = get_param(targetOutport,'Position');
    block_x1 = targetpos(1).Position(1) -600;
    block_y1 = targetpos(1).Position(2) -125;

    for i = 1: headerRow

        block_x1 = block_x1;
        block_y1 = block_y1 + 100;
        block_w1 = block_x1 + 100;
        block_h1 = block_y1 + 50; 
        BlockName='Selector';
        srcT = 'simulink/Signal Routing/Selector';
        dstT = [modelname '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x1,block_y1,block_w1,block_h1]);
        set_param(h,'InputPortWidth',num2str(dtcArraySize));
        set_param(h,'Indices',['[' num2str(1+(i-1)*32) ':' num2str(32+(i-1)*32) ']']);
        Seletport = get_param(h,'PortHandles');
        Seletpos = get_param(h, 'PortConnectivity');
        add_line(modelname,DCport.Outport(1),Seletport.Inport(1),'autorouting','smart');
        
        block_x2 = block_x1 + 300;
        block_y2 = block_y1 ;
        block_w2 = block_x2 + 100;
        block_h2 = block_y2 + 50;
        BlockName = 'DTCHeader';
        srcT = 'FVT_lib/hal/DTC_Header';
        dstT = [modelname '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x2,block_y2,block_w2,block_h2]);
        set_param(h,'ShowName', 'off');
        Headerport = get_param(h,'PortHandles');
        Headerpos = get_param(h, 'PortConnectivity');
        add_line(modelname,Seletport.Outport(1),Headerport.Inport(1),'autorouting','smart');
        add_line(modelname,Headerport.Outport(1),targetport.Inport(i),'autorouting','smart');
    end

    % Converter
    block_x = targetOutpos(1) + 150;
    block_y = targetOutpos(2) - 25;
    block_w = block_x + 100;
    block_h = block_y + 50;
    BlockName = 'UnitConverter';
    srcT = 'simulink/Signal Attributes/Data Type Conversion';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    Converterport = get_param(h,'PortHandles');
    add_line(modelname,targetOutport,Converterport.Inport(1),'autorouting','smart');


    % Outport
    block_x = targetOutpos(1) + 400;
    block_y = targetOutpos(2) - 10;
    block_w = block_x + 30;
    block_h = block_y + 15;
    BlockName = 'Header_Array';
    srcT = 'simulink/Sinks/Out1';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'Port',num2str(1));
    Outport = get_param(h,'PortHandles');
    HeaderLine = add_line(modelname,Converterport.Outport(1),Outport.Inport(1),'autorouting','smart');
    set_param(HeaderLine, 'Name', 'VDTC_HeaderArray_raw32');  
    set(HeaderLine,'MustResolveToSignalObject',1);

    % or 
    block_x = targetOutpos(1) + 150;
    block_y = targetOutpos(2) - 100;
    block_w = block_x + 30;
    block_h = block_y + 30;
    BlockName = 'OR';
    srcT = 'simulink/Commonly Used Blocks/Logical Operator';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'Inputs', '1');
    set_param(h,'Operator','OR');
    Orport = get_param(h,'PortHandles');
    add_line(modelname,targetOutport,Orport.Inport(1),'autorouting','smart');

    % Outport
    block_x = block_x + 200;
    block_y = block_y + 10;
    block_w = block_x + 30;
    block_h = block_y + 15;
    BlockName = 'Trigger';
    srcT = 'simulink/Sinks/Out1';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'Port',num2str(1));
    Outport = get_param(h,'PortHandles');
    TriggerLine = add_line(modelname,Orport.Outport(1),Outport.Inport(1),'autorouting','smart');
    set_param(TriggerLine, 'Name', 'VHAL_TriggerDTC_flg');  
    set(TriggerLine,'MustResolveToSignalObject',1);
end
