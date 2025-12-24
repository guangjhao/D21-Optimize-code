%% AutoBuild APP DTC_list Data Model
    
function DTC_List_AutoBuild(~) 
    
    %% Check
    q = questdlg({'Check the following conditions:','1. Run "project_start"?',...
        '2. Confirm "DTC_listMap" version?','3. Current folder arch?'},'Initial check','Yes','No','Yes');
    if ~contains(q, 'Yes')
        return
    end
    arch_Path = pwd;
    if ~contains(arch_Path, 'arch'), error('current folder is not under arch'), end
    project_path = extractBefore(arch_Path,'\software');
    
    %% Create and Open the Model
    new_model = 'DTC_list';
    open_system(new_system(new_model));
    original_x = 0;
    original_y = 0;
    
    %% Read uds_dem_config
    cd(project_path)
    cd ..\..
    fileID = fopen('source\fvt_cdd\common\uds\generated\uds_dem_config.c', 'r');
    fileContent = fread(fileID, '*char')';
    fclose(fileID);
 
    startStr = 'static uint8_t  STATUS_BYTE[STATUS_BYTES_LEN];';
    endStr = 'static uint8_t OPERATION_CYCLE_REF[STATUS_BYTES_LEN];';
    startIndex = strfind(fileContent, startStr);
    endIndex = strfind(fileContent, endStr);
    if ~isempty(startIndex) && ~isempty(endIndex)
        startIndex = startIndex(1) + length(startStr);
        endIndex = endIndex(1) - 1;
        extractedCode = fileContent(startIndex:endIndex);
    else
        disp('Matrix not found');
    end
 
    startStr = '{';
    endStr = '}';
    startIndex = strfind(extractedCode, startStr);
    endIndex = strfind(extractedCode, endStr);
    startIndex = startIndex(1) + length(startStr);
    endIndex = endIndex(1) - 1;
    extractedMatrix = extractedCode(startIndex:endIndex);
    data = regexprep(extractedMatrix, '[^0-9xA-Fa-f,]', '');
    matrix = string(strsplit(data, ',')');
    
    %% Read DTC Map .xlsx File
    cd([project_path '\documents'])
    
    Excel = string(readcell('FVT_DTCList'));
    
    FVT_DTC_ID = Excel(3:end,1);
    FVT_DTC_SigName = Excel(3:end,2);

    for i = 1:length(FVT_DTC_ID)
        [~, idx] = ismember(FVT_DTC_ID(i), matrix);
        if idx ~= 0
            matrix(idx,2) = FVT_DTC_SigName(i);
            Excel(i+2,3) = idx-1;
        end
    end

    ExcelData = Excel(:,3);
    xlswrite('FVT_DTCList.xlsx', ExcelData, 1, 'C');

    DTC_ID = matrix(:,1);
    DTC_SigName = matrix(:,2);

    for i =1: length(DTC_ID)
        DTC_Array(i,1) = i-1;
    end


    %% Read Diagnostic Specificaion .xlsx File
    cd([project_path '/documents'])
    files = dir('*.xlsx');
    DSFile = files(contains({files.name}, 'DiagnosticSpecificaion')).name;
    DSFile_DTCList = string(readcell(DSFile,'Sheet','DTCList'));
    DSFile_DTCDis           = DSFile_DTCList(6:end, 1);
    DSFile_DTCByte          = DSFile_DTCList(6:end, 2);
    DSFile_DTCMean          = DSFile_DTCList(6:end, 3);
    DSFile_DTCModelD31L     = DSFile_DTCList(6:end, 7);
    DSFile_DTCModelD31L24   = DSFile_DTCList(6:end, 8);
    DSFile_DTCModelD31F25   = DSFile_DTCList(6:end, 9);
    DSFile_DTCModelD31H     = DSFile_DTCList(6:end, 10);
    DSFile_DTCModelD21      = DSFile_DTCList(6:end, 11);
    DSFile_DTCFunClass      = DSFile_DTCList(6:end, 25);
    DSFile_UsedDTCByte       = string([]);

    last_slash_index = find(project_path == '\', 1, 'last');
    carmodel_folder = project_path(last_slash_index+1:end);

    switch carmodel_folder
        case 'd31l-fdc'
            DSFile_CarModel = DSFile_DTCModelD31L;
        case 'd31f-fdc'
            DSFile_CarModel = DSFile_DTCModelD31L24;
        case 'd31f-fdc2'
            DSFile_CarModel = DSFile_DTCModelD31F25;
        case 'd31h-fdc2'
            DSFile_CarModel = DSFile_DTCModelD31H;    
        case 'd21-fdc2'
            DSFile_CarModel = DSFile_DTCModelD21;
        otherwise
            DSFile_CarModel = DSFile_DTCModelD31L;
    end

    
    for i = 1:length(DSFile_DTCByte)
        if strcmp(DSFile_CarModel(i,1),'Y')
            DSFile_UsedDTCByte(end+1,1) = DSFile_DTCByte(i,1);
        end
    end
    
    DTC_ID_NoMissing = FVT_DTC_ID(~ismissing(FVT_DTC_ID));
    DTCByte_Del = setdiff(DTC_ID_NoMissing, DSFile_UsedDTCByte);
    if isempty(DTCByte_Del)
        disp('DTC List not changed')
    else % ~isempty(DTCByte_Del)
        fprintf('DTC deleted:\n')
        for i = 1:length(DTCByte_Del)
            disp(DTCByte_Del(i,1))
        end
    end
    

%     DTC_HeaderEle = Excel(6:end,10);
%     for i =1: length(DTC_ID)
%         DTC_Array(i,1) = i-1;
%         if ismissing(DTC_HeaderEle(i))
%             DTC_HeaderEle(i) =  DTC_HeaderEle(i-1);
%         end
%     end
%     DTC_HeaderBit = Excel(6:end,11);
%     DTC_Worklist = [ DTC_ID DTC_SigName DTC_HeaderBit];

    DTCArraySize = 320 ;
    HeaderRow = 10;

    %% Subsystem DTC_list
    BlockName = 'DTC_list';
    block_x = original_x;
    block_y = original_y;
    block_w = block_x + 250;
    block_h = block_y + 400;
    srcT = 'simulink/Ports & Subsystems/Subsystem';
    dstT = [new_model '/' BlockName];    
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'ContentPreviewEnabled','off','BackgroundColor','LightBlue');
    
    delete_line([new_model '/' BlockName],'In1/1','Out1/1');
    delete_block([new_model '/' BlockName '/In1']);
    delete_block([new_model '/' BlockName '/Out1']);
    modelname = [new_model '/' BlockName];
    j = 1;
    for i =1: length(DTC_SigName)
        if  ~ismissing(DTC_SigName (i))
            NoMisData(j,1) = DTC_ID(i);
            NoMisData(j,2) = DTC_SigName(i);
%             NoMisData(j,3) = DTC_Array(i);
%             NoMisData(j,4) = DTC_HeaderEle(i);
%             NoMisData(j,5) = DTC_HeaderBit(i);
            j=j+1;
        end
    end
    % DDM DTC_raw32 Bus Selector
    BlockName ='bus_selector';
    srcT = 'simulink/Signal Routing/Bus Selector';
    dstT = [modelname '/' BlockName];
    PortsSpace = 50;
    block_x = original_x - 1000 ;
    block_y = original_y;
    block_w = block_x + 10;
    block_h = block_y + length(NoMisData)*PortsSpace;
    signalNames = strcat('VOUTP_', NoMisData(:,2),'DTC_raw32');
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
    
    
    for i = 1:length(NoMisData)
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
    
    block_x = original_x;
    block_y = original_y -300;
    j = 0;
    % Library
    for i = 1:length(DTC_ID)
   
    if ~ismissing(DTC_SigName (i))
    block_x = block_x ;
    block_y = block_y + 300;
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
    set_param(h,'value',DTC_ID(i),'ShowName', 'off');
    sourceport = get_param(h,'PortHandles');
    add_line(modelname,sourceport.Outport(1),targetport(1));
    
    block_x1 = block_x1;
    block_y1 = block_y1 + 75;
    block_w1 = block_x1 + 200;
    block_h1 = block_y1 + 40;
    BlockName = 'From';
    srcT = 'simulink/Signal Routing/From';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x1,block_y1,block_w1,block_h1]);
    set_param(h,'GotoTag',['VOUTP_' char(DTC_SigName(i)) 'DTC_raw32'],'ShowName','off');
    sourceport = get_param(h,'PortHandles');
    add_line(modelname,sourceport.Outport(1),targetport(2));
    
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
    block_x = original_x + 1000;
    block_y = original_y;
    block_w = block_x + 20;
    block_h = block_y + length(DTC_Array)*PortsSpace;
    srcT = 'simulink/Commonly Used Blocks/Mux';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT);
    set_param(h,'Inputs',num2str(ceil(length(DTC_Array))));
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    targetport = get_param(h,'PortHandles');
    targetpos = get_param(h, 'PortConnectivity');
    targetOutport = targetport.Outport;
    targetOutpos = get_param(targetOutport,'Position');


    % from to mux


for i = 1:length(DTC_SigName)
    if ~ismissing(DTC_SigName (i))
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
    set_param(h,'Value',mat2str(zeros(1,(DTCArraySize-length(DTC_ID)))),'ShowName', 'on')
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
    set_param(h,'GotoTag','DTC_Array','ShowName', 'off');
    gotoport = get_param(h,'PortHandles');
    lineHandle = add_line(modelname,Convertport.Outport(1),gotoport.Inport(1),'autorouting','smart');
    set_param(lineHandle, 'Name', 'VDTC_DTCArray_raw32');  
    set(lineHandle,'MustResolveToSignalObject',1);

    % Outport
    block_x = block_x ;
    block_y = block_y + 100;
    block_w = block_x + 30;
    block_h = block_y + 15;
    BlockName = 'DTC_Array';
    srcT = 'simulink/Sinks/Out1';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    Outport = get_param(h,'PortHandles');
    add_line(modelname,muxport.Outport(1),Outport.Inport(1),'autorouting','smart');

%%%%%%%%%%%%%%%%%%%%%%%%%% Header array %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % from
    block_x = original_x + 1300;
    block_y = original_y +45;
    block_w = block_x + 200;
    block_h = block_y + 30;
    BlockName = 'From';
    srcT = 'simulink/Signal Routing/From';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'GotoTag','DTC_Array','ShowName', 'off');
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
    block_h = block_y + HeaderRow*PortsSpace;
    BlockName = 'Mux2';
    srcT = 'simulink/Commonly Used Blocks/Mux';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT);
    set_param(h,'Inputs',num2str(ceil(HeaderRow)));
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    targetport = get_param(h,'PortHandles');
    targetpos = get_param(h, 'PortConnectivity');
    targetOutport = targetport.Outport;
    targetOutpos = get_param(targetOutport,'Position');
    block_x1 = targetpos(1).Position(1) -600;
    block_y1 = targetpos(1).Position(2) -125;

    for i = 1: HeaderRow

        block_x1 = block_x1;
        block_y1 = block_y1 + 100;
        block_w1 = block_x1 + 100;
        block_h1 = block_y1 + 50; 
        BlockName='Selector';
        srcT = 'simulink/Signal Routing/Selector';
        dstT = [modelname '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x1,block_y1,block_w1,block_h1]);
        set_param(h,'InputPortWidth',num2str(DTCArraySize));
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
