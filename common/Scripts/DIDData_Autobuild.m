function DIDData_Autobuild(~)
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
    modelname = 'FoxPi_DID_Model';
    close_system(modelname,0);
    open_system(new_system(modelname));
    original_x = 0;
    original_y = 0;

    %% Read Diagnostic Specificaion .xlsx File
    cd([project_path '/../common/documents'])
    files = dir('*.xlsx');
    DSFile = files(contains({files.name}, 'DiagnosticSpecificaion')).name;
    DSFile_DIDList = string(readcell(DSFile,'Sheet','DIDList'));
    DSFile_DIDData = string(readcell(DSFile,'Sheet','DIDData'));
    DSFile_DIDNum           = DSFile_DIDList(6:end, 1);
    DSFile_DIDDescription   = DSFile_DIDList(6:end, 2);
    DSFile_DIDServiceRead   = DSFile_DIDList(6:end, 6);
    DSFile_DIDServiceWrite  = DSFile_DIDList(6:end, 7);
    DSFile_DIDModelD31L     = DSFile_DIDList(6:end, 12);
    DSFile_DIDModelD31L24   = DSFile_DIDList(6:end, 13);
    DSFile_DIDModelD31F25   = DSFile_DIDList(6:end, 14);
    DSFile_DIDModelD31H     = DSFile_DIDList(6:end, 15);
    DSFile_DIDModelD21      = DSFile_DIDList(6:end, 16);
    DSFile_DIDModelD31X     = DSFile_DIDList(6:end, 17);
    DSFile_DIDFunClass      = DSFile_DIDList(6:end, 28);

    DID_Class = unique(DSFile_DIDFunClass);
    indx = listdlg('PromptString',{'Select the classification you want to build.'},'ListSize',[200,500],'ListString',DID_Class);
    selectedClass = DID_Class(indx);
    last_slash_index = find(project_path == '\', 1, 'last');
    carmodel_folder = project_path(last_slash_index+1:end);
    selectedDIDNum = string([]);
    muxInpos = {[1, 0]};
    disp(['Car Model: ' carmodel_folder])
    switch carmodel_folder
        case 'd31l-fdc'           
            for i = 1:length(DSFile_DIDModelD31L)
                if strcmp(DSFile_DIDModelD31L(i),'Y') && DSFile_DIDFunClass(i) == selectedClass && strcmp(DSFile_DIDServiceRead(i),'Y') && strcmp(DSFile_DIDServiceWrite(i),'N')
                    selectedDIDNum(end+1,1) = string(DSFile_DIDNum(i));
                end
            end
        case 'd31f-fdc'
            for i = 1:length(DSFile_DIDModelD31L24)
                if strcmp(DSFile_DIDModelD31L24(i),'Y') && DSFile_DIDFunClass(i) == selectedClass && strcmp(DSFile_DIDServiceRead(i),'Y') && strcmp(DSFile_DIDServiceWrite(i),'N')
                    selectedDIDNum(end+1,1) = string(DSFile_DIDNum(i));
                end
            end
        case 'd31f-fdc2'
            for i = 1:length(DSFile_DIDModelD31F25)
                if strcmp(DSFile_DIDModelD31F25(i),'Y') && DSFile_DIDFunClass(i) == selectedClass && strcmp(DSFile_DIDServiceRead(i),'Y') && strcmp(DSFile_DIDServiceWrite(i),'N')
                    selectedDIDNum(end+1,1) = string(DSFile_DIDNum(i));
                end
            end
        case 'd31hawd-fdc2'
            for i = 1:length(DSFile_DIDModelD31H)
                if strcmp(DSFile_DIDModelD31H(i),'Y') && DSFile_DIDFunClass(i) == selectedClass && strcmp(DSFile_DIDServiceRead(i),'Y') && strcmp(DSFile_DIDServiceWrite(i),'N')
                    selectedDIDNum(end+1,1) = string(DSFile_DIDNum(i));
                end
            end
        case 'd21awd-fdc2'
            for i = 1:length(DSFile_DIDModelD21)
                if strcmp(DSFile_DIDModelD21(i),'Y') && DSFile_DIDFunClass(i) == selectedClass && strcmp(DSFile_DIDServiceRead(i),'Y') && strcmp(DSFile_DIDServiceWrite(i),'N')
                    selectedDIDNum(end+1,1) = string(DSFile_DIDNum(i));
                end
            end
        case 'd21rwd-fdc2'
            for i = 1:length(DSFile_DIDModelD21)
                if strcmp(DSFile_DIDModelD21(i),'Y') && DSFile_DIDFunClass(i) == selectedClass && strcmp(DSFile_DIDServiceRead(i),'Y') && strcmp(DSFile_DIDServiceWrite(i),'N')
                    selectedDIDNum(end+1,1) = string(DSFile_DIDNum(i));
                end
            end
        case 'd31x-fdc'
            for i = 1:length(DSFile_DIDModelD31X)
                if strcmp(DSFile_DIDModelD31X(i),'Y') && DSFile_DIDFunClass(i) == selectedClass && strcmp(DSFile_DIDServiceRead(i),'Y') && strcmp(DSFile_DIDServiceWrite(i),'N')
                    selectedDIDNum(end+1,1) = string(DSFile_DIDNum(i));
                end
            end
        otherwise
            for i = 1:length(DSFile_DIDModelD31L)
                if strcmp(DSFile_DIDModelD31L(i),'Y') && DSFile_DIDFunClass(i) == selectedClass && strcmp(DSFile_DIDServiceRead(i),'Y') && strcmp(DSFile_DIDServiceWrite(i),'N')
                    selectedDIDNum(end+1,1) = string(DSFile_DIDNum(i));
                end
            end
    end

    %% read DIDData sheet
    DIDData_DIDNum          = DSFile_DIDData(10:end, 2);
    DIDData_DIDDiscript     = replace(replace(replace(DSFile_DIDData(10:end, 3), "-", ""), "_", ""), " ", "");
    DIDData_DIDSize         = DSFile_DIDData(10:end, 4);
    DIDData_StartByte       = str2double(DSFile_DIDData(10:end, 5));
    DIDData_MSBbit          = str2double(DSFile_DIDData(10:end, 6));
    DIDData_LSBbit          = str2double(DSFile_DIDData(10:end, 7));
    DIDData_EndByte         = floor(DIDData_LSBbit/8);
    DIDData_SubData         = replace(replace(replace(DSFile_DIDData(10:end, 8), "-", ""), "_", ""), " ", "");
    DIDData_Factor          = DSFile_DIDData(10:end, 14);
    DIDData_Offset          = DSFile_DIDData(10:end, 15);
    DIDData_DIDRWMode       = DSFile_DIDData(10:end, 16);
    DIDData_FunClass        = DSFile_DIDData(10:end, 24);

    block_x = original_x;
    block_y = original_y;
    block_x0 = original_x -1500;
    bitwiseorportpos(2) = original_y;
    constantportpos(2) = original_y;
    fromportpos = [0,0];
    PortsSpace = 50;
    allDataName = string([]);
    selectedArray = string([]);
    todoIdx = find(ismember(DIDData_DIDNum,selectedDIDNum));

    for i = 1:length(todoIdx)
        NumberOfSignals(i,1) = 0;
        ByteName = string([]);
        currentIdx = todoIdx(i);
        % Array storing signals position
        PackArray = strings(str2double(DIDData_DIDSize(todoIdx(i))),8);

        while ismissing(DIDData_DIDNum(currentIdx + NumberOfSignals(i,1) +1))
            NumberOfSignals(i,1) = NumberOfSignals(i,1) + 1;
        end
        
        for j = 1:NumberOfSignals(i)
            NUM_BYTE = DIDData_EndByte(todoIdx(i)+j) - DIDData_StartByte(todoIdx(i)+j) + 1;
            LeftShiftCnt = rem(DIDData_LSBbit(todoIdx(i)+j), 8);
            
            if NUM_BYTE <= 4

                % From of all signals
                subDataName = [string(DIDData_FunClass(todoIdx(i))) + string(DIDData_SubData(todoIdx(i)+j))];
                selectedArray(end+1,1) = subDataName;
                block_x = original_x - 4000;
                block_y = fromportpos(2) + (NUM_BYTE)*PortsSpace;
                block_w = block_x + 220;
                block_h = block_y + 35;
                BlockName = 'From';
                srcT = 'simulink/Signal Routing/From';
                dstT = [modelname '/' BlockName];
                from = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(from,'position',[block_x,block_y,block_w,block_h]);
                set_param(from,'Gototag',subDataName,'ShowName', 'off');
                fromport = get_param(from,'PortHandles');
                fromportpos = get_param(fromport.Outport(1),'Position');
                
                if NUM_BYTE <= 1; SignalDataType = 'uint8'; 
                elseif (1 < NUM_BYTE) && (NUM_BYTE <= 2); SignalDataType = 'uint16'; 
                elseif (2 < NUM_BYTE) && (NUM_BYTE <= 4); SignalDataType = 'uint32'; 
                elseif (4 < NUM_BYTE) && (NUM_BYTE <= 8); SignalDataType = 'uint64'; 
                else SignalDataType = 'uint8';
                end 

                BlockName = 'convert_out';
                convOutblock_x = fromportpos(1) + 50;
                convOutblock_y = fromportpos(2) - 25;
                block_w = convOutblock_x + 100;
                block_h = convOutblock_y + 50;
                srcT = 'FVT_lib/hal/convert_out';
                dstT = [modelname '/' BlockName];    
                h = add_block(srcT,dstT,'MakeNameUnique','on');     
                set_param(h,'position',[convOutblock_x,convOutblock_y,block_w,block_h]);
                set_param(h, 'MaskValues', {num2str(DIDData_Factor(currentIdx+j)),num2str(DIDData_Offset(currentIdx+j))});
                convOutport = get_param(h,'PortHandles');
                convOutpos = get_param(convOutport.Outport(1),'Position');
                add_line(modelname,fromport.Outport(1),convOutport.Inport(1));


                % add datatype convert
                dataTypeBlock_x = convOutpos(1) + 50;
                dataTypeBlock_y = convOutpos(2) - 15;
                block_w = dataTypeBlock_x + 70;
                block_h = dataTypeBlock_y + 30;
                BlockName = 'UnitConverter';
                srcT = 'simulink/Signal Attributes/Data Type Conversion';
                dstT = [modelname '/' BlockName];
                Convert = add_block(srcT,dstT,'MakeNameUnique','on');     
                set_param(Convert,'position',[dataTypeBlock_x,dataTypeBlock_y,block_w,block_h])
                set_param(Convert, 'OutDataTypeStr', SignalDataType);
                Convertport = get_param(Convert,'PortHandles');
                Convertpos = get_param(Convertport.Outport(1),'Position');

                add_line(modelname,convOutport.Outport,Convertport.Inport,'autorouting','smart');

                % Pack
                if NUM_BYTE == 1
                    
                    BlockName = 'LeftShift';
                    block_x = Convertpos(1) + 50;
                    block_y = Convertpos(2) - 20;
                    block_w = block_x + 100;
                    block_h = block_y + 35;
                    srcT = 'simulink/Logic and Bit Operations/Shift Arithmetic';
                    dstT = [modelname '/' BlockName];
                    leftShift = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(leftShift, 'position', [block_x, block_y, block_w, block_h]);
                    set_param(leftShift, 'BitShiftDirection', 'Left','ShowName', 'off');
                    set_param(leftShift, 'BitShiftNumber', num2str(LeftShiftCnt));
                    leftShiftport = get_param(leftShift, 'PortHandles');
                    leftShiftportpos = get_param(leftShiftport.Outport(1),'Position');
                    add_line(modelname, Convertport.Outport(1), leftShiftport.Inport(1));
    
                    BlockName = 'BitwiseAND';
                    block_x = block_x + 200;
                    block_y = block_y;
                    block_w = block_x + 100;
                    block_h = block_y + 40;
                    srcT = 'simulink/Logic and Bit Operations/Bitwise Operator';
                    dstT = [modelname '/' BlockName];
                    bitwiseand = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                    set_param(bitwiseand, 'position', [block_x, block_y, block_w, block_h]);
                    set_param(bitwiseand, 'UseBitMask', 'on','ShowName', 'off');
                    set_param(bitwiseand, 'logicop', 'AND', 'BitMask', '0xFF');
                    bitwiseandport = get_param(bitwiseand, 'PortHandles');
                    add_line(modelname, leftShiftport.Outport(1), bitwiseandport.Inport);
                    
                    
                    block_x = leftShiftportpos(1) + 250;
                    block_y = leftShiftportpos(2) - 20;
                    block_w = block_x + 220;
                    block_h = block_y + 35;
                    BlockName = 'Goto';
                    srcT = 'simulink/Signal Routing/Goto';
                    dstT = [modelname '/' BlockName];
                    goto = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(goto,'position',[block_x,block_y,block_w,block_h]);
                    Bytepos = strcat('Byte_',num2str(DIDData_EndByte(todoIdx(i)+j)),'_',string(DIDData_SubData(todoIdx(i)+j)));
                    Arraypos = min(find(PackArray(DIDData_EndByte(todoIdx(i)+j)+1,:) == ""));
                    PackArray(DIDData_EndByte(todoIdx(i)+j)+1,Arraypos) = Bytepos;
                    set_param(goto,'Gototag',Bytepos,'ShowName', 'off');
                    ByteName(end+1,1) = Bytepos;
                    gotoport = get_param(goto,'PortHandles');
                    add_line(modelname,bitwiseandport.Outport,gotoport.Inport,'autorouting','smart')
    
                    n = 1;
    
                else
                
                    for n = 1:NUM_BYTE
                        BlockName = 'RightShift';
                        block_x = Convertpos(1) + 50;
                        block_y = Convertpos(2) - 20 - PortsSpace*(NUM_BYTE - n);
                        block_w = block_x + 100;
                        block_h = block_y + 35;
                        srcT = 'simulink/Logic and Bit Operations/Shift Arithmetic';
                        dstT = [modelname '/' BlockName];
                        rightShift = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                        set_param(rightShift, 'position', [block_x, block_y, block_w, block_h]);
                        % set_param(rightShift, 'BitShiftDirection', 'Right','ShowName', 'off');
                        set_param(rightShift, 'BitShiftDirection', 'Bidirectional', 'ShowName', 'off');
                        RightShiftCnt = 8*(NUM_BYTE - n) - LeftShiftCnt;
                        set_param(rightShift, 'BitShiftNumber', num2str(RightShiftCnt));
                        rightShiftport = get_param(rightShift, 'PortHandles');
                        rightShiftportpos = get_param(rightShiftport.Outport(1),'Position');
                        add_line(modelname, Convertport.Outport(1), rightShiftport.Inport(1),'autorouting','smart');
                    
                        BlockName = 'BitwiseAND';
                        block_x = block_x + 200;
                        block_y = block_y;
                        block_w = block_x + 100;
                        block_h = block_y + 40;
                        srcT = 'simulink/Logic and Bit Operations/Bitwise Operator';
                        dstT = [modelname '/' BlockName];
                        bitwiseand = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                        set_param(bitwiseand, 'position', [block_x, block_y, block_w, block_h]);
                        set_param(bitwiseand, 'UseBitMask', 'on','ShowName', 'off');
                        set_param(bitwiseand, 'logicop', 'AND', 'BitMask', '0xFF');
                        bitwiseandport = get_param(bitwiseand, 'PortHandles');
                        add_line(modelname, rightShiftport.Outport(1), bitwiseandport.Inport);
                        
                        block_x = rightShiftportpos(1) + 250;
                        block_y = rightShiftportpos(2) - 20;
                        block_w = block_x + 220;
                        block_h = block_y + 35;
                        BlockName = 'Goto';
                        srcT = 'simulink/Signal Routing/Goto';
                        dstT = [modelname '/' BlockName];
                        goto = add_block(srcT,dstT,'MakeNameUnique','on');
                        set_param(goto,'position',[block_x,block_y,block_w,block_h]);
                        Bytepos = strcat('Byte_',num2str(DIDData_EndByte(todoIdx(i)+j)+n-NUM_BYTE),'_',string(DIDData_SubData(todoIdx(i)+j)));
                        Arraypos = min(find(PackArray(DIDData_EndByte(todoIdx(i)+j)+n-NUM_BYTE+1,:) == ""));
                        PackArray(DIDData_EndByte(todoIdx(i)+j)+n-NUM_BYTE+1,Arraypos) = Bytepos;
                        set_param(goto,'Gototag',Bytepos,'ShowName', 'off');
                        ByteName(end+1,1) = Bytepos;
                        gotoport = get_param(goto,'PortHandles');
                        add_line(modelname,bitwiseandport.Outport,gotoport.Inport,'autorouting','smart')
    
                    end
    
                    
                end
            else

                NUM_BYTE = DIDData_EndByte(todoIdx(i)+j) - DIDData_StartByte(todoIdx(i)+j) + 1;
                LeftShiftCnt = rem(DIDData_LSBbit(todoIdx(i)+j), 8);
                % From of all signals on CAN message
                subDataName = [string(DIDData_FunClass(todoIdx(i))) + string(DIDData_SubData(todoIdx(i)+j))];
                selectedArray(end+1,1) = subDataName;
                block_x = original_x - 4000;
                block_y = fromportpos(2) + PortsSpace;
                block_w = block_x + 220;
                block_h = block_y + 35;
                BlockName = 'From';
                srcT = 'simulink/Signal Routing/From';
                dstT = [modelname '/' BlockName];
                from = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(from,'position',[block_x,block_y,block_w,block_h]);
                set_param(from,'Gototag',subDataName,'ShowName', 'off');
                fromport = get_param(from,'PortHandles');
                fromportpos = get_param(fromport.Outport(1),'Position');

                if NUM_BYTE <= 1; SignalDataType = 'uint8'; 
                elseif (1 < NUM_BYTE) && (NUM_BYTE <= 2); SignalDataType = 'uint16'; 
                elseif (2 < NUM_BYTE) && (NUM_BYTE <= 4); SignalDataType = 'uint32'; 
                elseif (4 < NUM_BYTE) && (NUM_BYTE <= 8); SignalDataType = 'uint64'; 
                else SignalDataType = 'uint8';
                end 

                BlockName = 'convert_out';
                convOutblock_x = fromportpos(1) + 50;
                convOutblock_y = fromportpos(2) - 25;
                block_w = convOutblock_x + 100;
                block_h = convOutblock_y + 50;
                srcT = 'FVT_lib/hal/convert_out';
                dstT = [modelname '/' BlockName];    
                h = add_block(srcT,dstT,'MakeNameUnique','on');     
                set_param(h,'position',[convOutblock_x,convOutblock_y,block_w,block_h]);
                set_param(h, 'MaskValues', {num2str(DIDData_Factor(currentIdx+j)),num2str(DIDData_Offset(currentIdx+j))});
                convOutport = get_param(h,'PortHandles');
                convOutpos = get_param(convOutport.Outport(1),'Position');
                add_line(modelname,fromport.Outport(1),convOutport.Inport(1));


                % add datatype convert
                dataTypeBlock_x = convOutpos(1) + 50;
                dataTypeBlock_y = convOutpos(2) - 15;
                block_w = dataTypeBlock_x + 70;
                block_h = dataTypeBlock_y + 30;
                BlockName = 'UnitConverter';
                srcT = 'simulink/Signal Attributes/Data Type Conversion';
                dstT = [modelname '/' BlockName];
                Convert = add_block(srcT,dstT,'MakeNameUnique','on');     
                set_param(Convert,'position',[dataTypeBlock_x,dataTypeBlock_y,block_w,block_h])
                set_param(Convert, 'OutDataTypeStr', SignalDataType);
                Convertport = get_param(Convert,'PortHandles');
                Convertpos = get_param(Convertport.Outport(1),'Position');

                add_line(modelname,convOutport.Outport,Convertport.Inport,'autorouting','smart');

                block_x = Convertpos(1) + 405;
                block_y = Convertpos(2) -20;
                block_w = block_x + 220;
                block_h = block_y + 35;
                BlockName = 'Goto';
                srcT = 'simulink/Signal Routing/Goto';
                dstT = [modelname '/' BlockName];
                goto = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(goto,'position',[block_x,block_y,block_w,block_h]);
                Bytepos = strcat('Byte_',num2str(DIDData_EndByte(todoIdx(i)+j)+n-NUM_BYTE),'_',string(DIDData_SubData(todoIdx(i)+j)));
%                         Arraypos = min(find(PackArray(DIDData_EndByte(todoIdx(i)+j)+n-NUM_BYTE+1,:) == ""));
%                         PackArray(DIDData_EndByte(todoIdx(i)+j)+n-NUM_BYTE+1,Arraypos) = Bytepos;
                set_param(goto,'Gototag',Bytepos,'ShowName', 'off');
                ByteName(end+1,1) = Bytepos;
                gotoport = get_param(goto,'PortHandles');
                add_line(modelname,Convertport.Outport,gotoport.Inport,'autorouting','smart')

            end
        end
        dataCount = 1;
        for ki = 0:str2double(DIDData_DIDSize(todoIdx(i)))

            if sum(contains(ByteName(:,1),"Byte_" + string(ki) + "_"))
                signalCountInByte = sum(contains(ByteName(:,1),"Byte_" + string(ki) + "_"));
                idx = find(contains(ByteName(:,1), "Byte_" + string(ki) + "_"));
                packSignal = ByteName(idx);

                BlockName = 'BitwiseOR';
                block_x = block_x0;
                block_y = bitwiseorportpos(2) + 150;
                block_w = block_x + 70;
                block_h = block_y + PortsSpace * signalCountInByte;
                srcT = 'simulink/Logic and Bit Operations/Bitwise Operator';
                dstT = [modelname '/' BlockName];
                bitwiseor = add_block(srcT, dstT, 'MakeNameUnique', 'on');
                set_param(bitwiseor, 'position', [block_x, block_y, block_w, block_h]);
                set_param(bitwiseor, 'UseBitMask', 'off','ShowName', 'off');
                set_param(bitwiseor, 'logicop', 'OR');
                set_param(bitwiseor, 'NumInputPorts', num2str(signalCountInByte));
                bitwiseorport = get_param(bitwiseor, 'PortHandles');
                bitwiseorportpos = get_param(bitwiseorport.Inport(end),'Position');

                for kk = 1:signalCountInByte

                    portpos = get_param(bitwiseorport.Inport(kk),'Position');
                    block_x = block_x0 - 200;
                    block_y = portpos(2) - 20;
                    block_w = block_x + 120;
                    block_h = block_y + 35;
                    BlockName = 'Data Type Conversion';
                    srcT = 'simulink/Signal Attributes/Data Type Conversion';
                    dstT = [modelname '/' BlockName];
                    convert = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(convert,'position',[block_x,block_y,block_w,block_h],'OutDataTypeStr','uint8'); 
                    convertport = get_param(convert,'PortHandles');
                    add_line(modelname,convertport.Outport,bitwiseorport.Inport(kk),'autorouting','smart')

                    block_x = block_x0 - 500;
                    block_y = portpos(2) - 20;
                    block_w = block_x + 220;
                    block_h = block_y + 35;
                    BlockName = 'From';
                    srcT = 'simulink/Signal Routing/From';
                    dstT = [modelname '/' BlockName];
                    from = add_block(srcT,dstT,'MakeNameUnique','on');
                    set_param(from,'position',[block_x,block_y,block_w,block_h]);
                    set_param(from,'Gototag',string(packSignal(kk)),'ShowName', 'off');
                    fromport2 = get_param(from,'PortHandles');
                    fromportpos2 = get_param(fromport.Outport(1),'Position');
                    add_line(modelname,fromport2.Outport,convertport.Inport,'autorouting','smart')
                    

                end
                
                portpos = get_param(bitwiseorport.Outport(1),'Position');
                block_x = portpos(1) + 150;
                block_y = portpos(2) - 20;
                block_w = block_x + 220;
                block_h = block_y + 35;
                BlockName = 'Goto';
                srcT = 'simulink/Signal Routing/Goto';
                dstT = [modelname '/' BlockName];
                goto = add_block(srcT,dstT,'MakeNameUnique','on');
                set_param(goto,'position',[block_x,block_y,block_w,block_h]);
                set_param(goto,'Gototag',strcat(DIDData_DIDDiscript(todoIdx(i)),num2str(dataCount)),'ShowName', 'off');
                gotoport = get_param(goto,'PortHandles');
                add_line(modelname,bitwiseorport.Outport,gotoport.Inport,'autorouting','smart')
                dataCount = dataCount + 1;

            end
        end
        dataCount = dataCount -1;
%         if i >  1
%             muxYPos = muxpos(2) + dataCount*PortsSpace;
%         else
%             muxYPos = 0;
%         end
        % mux
        BlockName = 'Mux';
        PortsSpace = 50;
        mux_x = original_x + 100;
        mux_y = muxInpos{end}(2) +55;
        block_w = mux_x + 20;
        block_h = mux_y + dataCount*PortsSpace*2 ;
        srcT = 'simulink/Commonly Used Blocks/Mux';
        dstT = [modelname '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'Inputs',string(dataCount));
        set_param(h,'position',[mux_x,mux_y,block_w,block_h]);
        muxport = get_param(h,'PortHandles');
        muxpos = get_param(muxport.Outport,'Position');
        muxInpos = get_param(muxport.Inport,'Position');

        for ii = 1:dataCount
            block_x = muxInpos{ii}(1) - 500;
            block_y = muxInpos{ii}(2) - 20;
            block_w = block_x + 220;
            block_h = block_y + 35;
            BlockName = 'From';
            srcT = 'simulink/Signal Routing/From';
            dstT = [modelname '/' BlockName];
            from = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(from,'position',[block_x,block_y,block_w,block_h]);
            set_param(from,'Gototag',strcat(DIDData_DIDDiscript(todoIdx(i)),num2str(ii)),'ShowName', 'off');
            fromport3 = get_param(from,'PortHandles');
            fromportpos3 = get_param(fromport.Outport(1),'Position');
            add_line(modelname,fromport3.Outport,muxport.Inport(ii),'autorouting','smart')
        end

        % goto
        goto_x = muxpos(1,1) + 150;
        goto_y = muxpos(1,2) - 20;
        block_w = goto_x + 220;
        block_h = goto_y + 35;
        BlockName = 'Goto';
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [modelname '/' BlockName];
        goto = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(goto,'position',[goto_x,goto_y,block_w,block_h]);
        set_param(goto,'Gototag',['VHAL_DIDSet'+ string(DIDData_DIDDiscript(currentIdx)) + '_raw8'],'ShowName', 'off');
        gotoport = get_param(goto,'PortHandles');
        gotopos = get_param(gotoport.Inport,'Position');
%         add_line(modelname,muxport.Outport,gotoport.Inport,'autorouting','smart')

        add_line(modelname,muxport.Outport,gotoport.Inport,'autorouting','smart')
%         EndPort(end+1,1) = muxport.Outport;
%         muxpos = get_param(muxport.Outport,'Position');
    end

    BlockName ='bus_selector';
    srcT = 'simulink/Signal Routing/Bus Selector';
    dstT = [modelname '/' BlockName];
    PortsSpace = 50;
    block_x = original_x - 5000 ;
    block_y = original_y;
    block_w = block_x + 10;
    block_h = block_y + length(selectedArray)*PortsSpace;
    
%     signalNames = rmmissing(strcat(uniq_allDataName));
    busselector = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(busselector,'position',[block_x,block_y,block_w,block_h]);
    set_param(busselector,'OutputSignals',join( selectedArray,","),'ShowName', 'off');
    busselectorport = get_param(busselector,'PortHandles');
    busselectorpos = get_param(busselector, 'PortConnectivity');

    % Inport
    block_x = busselectorpos(1).Position(1) - 500;
    block_y = busselectorpos(1).Position(2) - 20;
    block_w = block_x + 300;
    block_h = block_y + 35;
    BlockName = 'BOUTP_outputs';
    srcT = 'simulink/Signal Routing/From';
    dstT = [modelname '/' BlockName];
    h = add_block(srcT,dstT,'MakeNameUnique','on');
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'Gototag','BOUTP_outputs','ShowName', 'off');
    Inport = get_param(h,'PortHandles');
    add_line(modelname,Inport.Outport(1),busselectorport.Inport(1),'autorouting','smart');
    
    for i = 1:length(selectedArray)
        block_x = busselectorpos(i+1).Position(1) + 150;
        block_y = busselectorpos(i+1).Position(2) - 20;
        block_w = block_x + 220;
        block_h = block_y + 35;
        BlockName = 'Goto';
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [modelname '/' BlockName];
        goto = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(goto,'position',[block_x,block_y,block_w,block_h]);
        set_param(goto,'Gototag',selectedArray(i),'ShowName', 'off');
        gotoport = get_param(goto,'PortHandles');
        add_line(modelname,busselectorport.Outport(i),gotoport.Inport,'autorouting','smart')
    end

 end







