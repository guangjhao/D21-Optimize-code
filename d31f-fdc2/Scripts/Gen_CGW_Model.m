function Gen_CGW_Model(TargetECU,RoutingTable,Channel_list,Channel_list_LIN)
project_path = pwd;
ScriptVersion = '2024.06.19';

%% Get all CAN DTs from source arxml

Channel_list_all = union(Channel_list,Channel_list_LIN);
DTcnt = 0;
DTCell = {};

for i = 1:length(Channel_list_all)
    Channel = char(Channel_list_all(i));
    cd([project_path '/documents/ARXML_output'])
    fileID = fopen([Channel '.arxml']);
    Source_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
    tmpCell = cell(length(Source_arxml{1,1}),1);
    for j = 1:length(Source_arxml{1,1})
        tmpCell{j,1} = Source_arxml{1,1}{j,1};
    end
    Source_arxml = tmpCell;

    for k = 1:length(Source_arxml)
        if contains(Source_arxml(k),['<SHORT-NAME>DT_' Channel '_'])

            DTName = char(extractBetween(Source_arxml(k),'>','<'));
            Raw_start = k;
            Raw_end = k + find(contains(Source_arxml(k:end),'</IMPLEMENTATION-DATA-TYPE>'),1,"first") -1;
            tmpCell = Source_arxml(Raw_start:Raw_end);

            idx = find(contains(tmpCell,'<IMPLEMENTATION-DATA-TYPE-ELEMENT>'));
            for n = 1:length(idx)
                DTcnt = DTcnt + 1;
                ElementName = char(extractBetween(tmpCell(idx(n)+1),'>','<'));
                DTCell(DTcnt,1) = cellstr(DTName);
                DTCell(DTcnt,2) = cellstr(ElementName);
            end
        else
            continue
        end
    end
    fclose(fileID);
    cd(project_path);
end

%% Get CAN Tx routing signals
SignalRouting = {};
cnt = 0;
for n = 1:length(Channel_list)
    Channel = char(Channel_list(n));
    if contains(Channel,'Dr')
        Channel_long = [extractBefore(Channel,'Dr') '_' extractAfter(Channel,'CAN')];
    else
        Channel_long = Channel;
    end
    Raw_start = find(contains(RoutingTable(:,4),['distributed messages, target:' Channel_long])) + 2;

    for i = 1:length(Raw_start)
        Channel_source = char(RoutingTable(Raw_start(i)-2,1));
        Channel_source = erase(extractAfter(Channel_source,'requested signals, source:'),'_');
        Raw_end = Raw_start(i) + find(contains(RoutingTable(Raw_start(i):end,4),'distributed messages, target'),1,'first') - 2;
        if isempty(Raw_end); Raw_end = length(RoutingTable(:,1)); end

        for k = Raw_start(i):Raw_end
            if ~strcmp(RoutingTable(k,4),'Invalid')
                cnt = cnt + 1;

                if strcmp(RoutingTable(k,2),'Invalid')
                    h = find(~strcmp(RoutingTable(1:k,2),'Invalid'),1,'last');
                    SourceMsgName = RoutingTable(h,2);
                    TargetMsgName = RoutingTable(h,5);
                else
                    SourceMsgName = RoutingTable(k,2);
                    TargetMsgName = RoutingTable(k,5);
                end

                SignalRouting(cnt,1) = cellstr([Channel_source '_' char(RoutingTable(k,1))]); % source signal
                SignalRouting(cnt,2) = cellstr([Channel_source '_' char(SourceMsgName)]); % source message name
                SignalRouting(cnt,3) = cellstr([Channel '_' char(RoutingTable(k,4))]); % target signal
                SignalRouting(cnt,4) =  TargetMsgName; % target message name

            else
                continue
            end
        end
    end
end

%% Get LIN Tx routing signals
for n = 1:length(Channel_list_LIN)
    Channel = char(Channel_list_LIN(n));

    if contains(Channel,'Dr')
        Channel_long = [extractBefore(Channel,'Dr') '_' extractAfter(Channel,'LIN')];
    else
        Channel_long = Channel;
    end
    Raw_start = find(contains(RoutingTable(:,4),['distributed messages, target:' Channel_long])) + 2;

    for i = 1:length(Raw_start)
        Channel_source = char(RoutingTable(Raw_start(i)-2,1));
        Channel_source = erase(extractAfter(Channel_source,'requested signals, source:'),'_');
        Raw_end = Raw_start(i) + find(contains(RoutingTable(Raw_start(i):end,4),'distributed messages, target'),1,'first') - 2;
        if isempty(Raw_end); Raw_end = length(RoutingTable(:,1)); end

        for k = Raw_start(i):Raw_end
            if ~strcmp(RoutingTable(k,4),'Invalid')
                cnt = cnt + 1;
                if strcmp(RoutingTable(k,2),'Invalid')
                    h = find(~strcmp(RoutingTable(1:k,2),'Invalid'),1,'last');
                    SourceMsgName = RoutingTable(h,2);
                    TargetMsgName = RoutingTable(h,5);
                else
                    SourceMsgName = RoutingTable(k,2);
                    TargetMsgName = RoutingTable(k,5);
                end

                SignalRouting(cnt,1) = cellstr([Channel_source '_' char(RoutingTable(k,1))]); % source signal
                SignalRouting(cnt,2) = cellstr([Channel_source '_' char(SourceMsgName)]); % source message name
                SignalRouting(cnt,3) = cellstr([Channel '_' char(RoutingTable(k,4))]); % target signal
                SignalRouting(cnt,4) =  TargetMsgName; % target message name
            else
                continue
            end
        end
    end
end

%% Get R and P ports
cnt = 0;
Port_SWC_CGW = {};

cd([project_path '/documents/ARXML_output'])
fileID = fopen('SWC_CGW.arxml');
Source_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Source_arxml{1,1}),1);
for j = 1:length(Source_arxml{1,1})
    tmpCell{j,1} = Source_arxml{1,1}{j,1};
end
Source_arxml = tmpCell;
for k = 1:length(Source_arxml)
    if strcmp(strip(char(Source_arxml(k)),'left'),'<R-PORT-PROTOTYPE>') ||...
            strcmp(strip(char(Source_arxml(k)),'left'),'<P-PORT-PROTOTYPE>')
        cnt = cnt + 1;
        Port_SWC_CGW(cnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
        %         Port_SWC_CGW(cnt,2) = cellstr([char(extractBetween(Source_arxml(k+2),'>' ,'<')) '/' char(extractBetween(Source_arxml(k+2),'/IF_' ,'<'))]);
        %         Port_SWC_CGW(cnt,3) = cellstr(['/' char(extractBetween(Source_arxml(k+2),'IF_' ,'_')) '/SignalGroup/' char(extractBetween(Source_arxml(k+2),'/IF_' ,'<'))]);
    end
end

%% Create subsystem
new_model = ['SWC_CGW_temp_' datestr(now,30)];
new_system(new_model);
open_system(new_model);
original_x = 0;
original_y = 0;

BlockName = 'CGW';
block_x = original_x;
block_y = original_y;
block_w = block_x + 250;
block_h = block_y + length(find(contains(Port_SWC_CGW,'R_')))*35;
srcT = 'simulink/Ports & Subsystems/Subsystem';
dstT = [new_model '/' BlockName];
h = add_block(srcT,dstT);
set_param(h,'position',[block_x,block_y,block_w,block_h]);
set_param(h,'ContentPreviewEnabled','off','BackgroundColor','LightBlue');

%% Create in ports and goto tag
TargetModel = [new_model '/CGW'];
delete_line(TargetModel, 'In1/1','Out1/1');
delete_block([TargetModel '/In1']);
delete_block([TargetModel '/Out1']);

cnt = 0;
for i = 1:length(Port_SWC_CGW)

    if startsWith(Port_SWC_CGW(i),'P_') || startsWith(Port_SWC_CGW(i),'R_ExtTrig_CGW')
        continue
    else
        cnt = cnt + 1;
        RPortName = char(Port_SWC_CGW(i));

        % Add inport
        BlockName = RPortName;
        block_x = original_x;
        block_y = original_y+50*cnt;
        block_w = block_x + 30;
        block_h = block_y + 13;
        srcT = 'simulink/Sources/In1';
        dstT = [TargetModel '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x,block_y,block_w,block_h]);

        % Add goto and connect line
        sourceport = get_param([TargetModel '/' BlockName],'PortHandles');
        targetpos = get_param(sourceport.Outport(1),'Position');
        BlockName = 'Goto';
        block_x = targetpos(1) + 100;
        block_y = targetpos(2) - 20;
        block_w = block_x + 220;
        block_h = block_y + 40;
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [TargetModel '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'Gototag', RPortName,'ShowName','off');
        targetport = get_param(h,'PortHandles');
        add_line(TargetModel, sourceport.Outport(1), targetport.Inport(1));
    end
end

%% Create out ports and subsystem
TargetModel = [new_model '/CGW'];

cnt = 0;
for i = 1:length(Port_SWC_CGW)

    if startsWith(Port_SWC_CGW(i),'R_')
        continue
    else
        cnt = cnt + 1;
        PPortName = char(Port_SWC_CGW(i));

        % Add subsystem
        BlockName = ['Sys_' PPortName];
        block_x = original_x+1000;
        block_y = original_y+400*cnt;
        block_w = block_x + 220;
        block_h = block_y + 350;
        srcT = 'simulink/Ports & Subsystems/Subsystem';
        dstT = [TargetModel '/' BlockName];
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'ContentPreviewEnabled','off','BackgroundColor','Gray');
        delete_line([TargetModel '/' BlockName], 'In1/1','Out1/1');
        delete_block([TargetModel '/' BlockName '/In1']);

        % Add outport
        sourceport = get_param([TargetModel '/' BlockName],'PortHandles');
        targetpos = get_param(sourceport.Outport(1),'Position');
        BlockName = PPortName;
        block_x = targetpos(1) + 150;
        block_y = targetpos(2) - 5;
        block_w = block_x + 30;
        block_h = block_y + 13;
        srcT = 'simulink/Sinks/Out1';
        dstT = [TargetModel '/' BlockName];
        h = add_block(srcT,dstT);
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        targetport = get_param(h,'PortHandles');
        add_line(TargetModel, sourceport.Outport(1), targetport.Inport(1));
    end
end

%% Add inport and connect signals inside subsystem

% Rework DTCell for later use
for i = 1:length(DTCell(:,1))
    DTCell(i,1) = cellstr(erase(erase(char(DTCell(i,1)),'DT_'),'SG_'));
end

for i = 1:length(Port_SWC_CGW)

    if startsWith(Port_SWC_CGW(i),'R_')
        continue
    else
        cnt = cnt + 1;
        TargetModel = [new_model '/CGW/Sys_' char(Port_SWC_CGW(i))];
    end

    TargetDT = erase(char(Port_SWC_CGW(i)),'P_');
    idx = find(strcmp(DTCell(:,1),TargetDT));

    % Add bus creator
    BlockName ='bus_creator';
    srcT = 'simulink/Signal Routing/Bus Creator';
    dstT = [TargetModel '/' BlockName];
    block_x = original_x;
    block_y = original_y;
    block_w = block_x + 20;
    block_h = block_y + 80*(length(idx)); %bus length
    h = add_block(srcT,dstT);
    set_param(h,'position',[block_x,block_y,block_w,block_h]);
    set_param(h,'inputs',num2str(length(idx)), 'ShowName', 'off');
    set_param(h,'OutDataTypeStr',['Bus: DT_' extractBefore(TargetDT,'_') '_SG_' extractAfter(TargetDT,'_')]);
    set_param(h,'NonVirtualBus','on');
    sourceport = get_param(h,'PortHandles');
    targetpos = get_param(sourceport.Outport(1),'Position');

    % Set outport position and name, then add line
    block_x = targetpos(1) + 150;
    block_y = targetpos(2) - 5;
    block_w = block_x + 30;
    block_h = block_y + 13;
    set_param([TargetModel '/Out1'],'position',[block_x,block_y,block_w,block_h]);
    targetport = get_param([TargetModel '/Out1'],'PortHandles');
    add_line(TargetModel, sourceport.Outport(1), targetport.Inport(1));
    set_param([TargetModel '/Out1'],'Name',char(Port_SWC_CGW(i)));

    % Add from tag and bus selector and connect to bus creator
    tmpCell = {};
    for k = 1:length(idx)
        targetport = get_param([TargetModel '/bus_creator'],'PortHandles'); % initialize targetport
        targetpos = get_param(targetport.Inport(k),'Position');
        DestSignalName = DTCell(idx(k),2);
        SourceSignalName = char(SignalRouting(strcmp(SignalRouting(:,3),DestSignalName),1));

        if isempty(SourceSignalName)
            disp([char(DestSignalName) ' has no source signal!!']);
            tmpCell(k) = cellstr('NONE');

            BlockName='ground';
            srcT = 'simulink/Commonly Used Blocks/Ground';
            dstT = [TargetModel '/' BlockName];
            block_x = targetpos(1) - 100;
            block_y = targetpos(2) - 15;
            block_w = block_x + 30;
            block_h = block_y + 30;
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            sourceport = get_param(h,'PortHandles');
            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(k));

        else
            SourceMsgName = char(SignalRouting(strcmp(SignalRouting(:,3),DestSignalName),2));
            tmpCell(k) = cellstr(SourceMsgName);

            BlockName='bus_selector';
            srcT = 'simulink/Signal Routing/Bus Selector';
            dstT = [TargetModel '/' BlockName];
            block_x = targetpos(1) - 250;
            block_y = targetpos(2) - 20;
            block_w = block_x + 10;
            block_h = block_y + 30;
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h,'outputsignals',SourceSignalName,'ShowName', 'off');
            sourceport = get_param(h,'PortHandles');
            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(k));

            targetport = sourceport; % bus selector change to target now
            targetpos = get_param(targetport.Inport(1),'Position');

            BlockName = 'From';
            block_x = targetpos(1) - 300;
            block_y = targetpos(2) - 20;
            block_w = block_x + 220;
            block_h = block_y + 40;
            srcT = 'simulink/Signal Routing/From';
            dstT = [TargetModel '/' BlockName];
            h = add_block(srcT,dstT,'MakeNameUnique','on');
            set_param(h,'position',[block_x,block_y,block_w,block_h]);
            set_param(h,'Gototag', ['R_' SourceMsgName],'ShowName', 'off');
            sourceport = get_param(h,'PortHandles');
            add_line(TargetModel,sourceport.Outport(1),targetport.Inport(1));
        end
    end

    % Add inport and goto tag in subsystem
    Rx_Msg = categories(categorical(tmpCell));
    for n = 1:length(Rx_Msg)
        if strcmp(char(Rx_Msg(n)),'NONE')
            continue
        end

        % Add inport
        BlockName = ['R_' char(Rx_Msg(n))];
        block_x = original_x - 500;
        block_y = original_y - 500 +50*n;
        block_w = block_x + 30;
        block_h = block_y + 13;
        srcT = 'simulink/Sources/In1';
        dstT = [TargetModel '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x,block_y,block_w,block_h]);

        % Add goto and connect line
        sourceport = get_param([TargetModel '/' BlockName],'PortHandles');
        targetpos = get_param(sourceport.Outport(1),'Position');
        BlockName = 'Goto';
        block_x = targetpos(1) + 100;
        block_y = targetpos(2) - 20;
        block_w = block_x + 220;
        block_h = block_y + 40;
        srcT = 'simulink/Signal Routing/Goto';
        dstT = [TargetModel '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'Gototag', ['R_' char(Rx_Msg(n))],'ShowName','off');
        targetport = get_param(h,'PortHandles');
        add_line(TargetModel, sourceport.Outport(1), targetport.Inport(1));
    end
end

%% Add goto tag and connect to subsystem
TargetModel = [new_model '/CGW'];

for i = 1:length(Port_SWC_CGW)

    if startsWith(Port_SWC_CGW(i),'R_')
        continue
    else
        ModuleH = get_param([TargetModel '/Sys_' char(Port_SWC_CGW(i))], 'Handle');
        portH = find_system(ModuleH, 'LookUnderMasks', 'on', 'FollowLinks', 'on', 'SearchDepth', 1, 'BlockType', 'Inport');
        PortNames = get_param(portH, 'Name');
        targetport = get_param([TargetModel '/Sys_' char(Port_SWC_CGW(i))],'PortHandles');
    end

    for k = 1:length(targetport.Inport)

        targetpos = get_param(targetport.Inport(k),'Position');
        if iscell(PortNames)
            PortName = char(PortNames(k));
        else
            PortName = PortNames;
        end

        BlockName = 'From';
        block_x = targetpos(1) - 300;
        block_y = targetpos(2) - 20;
        block_w = block_x + 220;
        block_h = block_y + 40;
        srcT = 'simulink/Signal Routing/From';
        dstT = [TargetModel '/' BlockName];
        h = add_block(srcT,dstT,'MakeNameUnique','on');
        set_param(h,'position',[block_x,block_y,block_w,block_h]);
        set_param(h,'Gototag', PortName ,'ShowName', 'off');
        sourceport = get_param(h,'PortHandles');
        add_line(TargetModel,sourceport.Outport(1),targetport.Inport(k));
    end
end