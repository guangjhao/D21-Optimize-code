function Gen_SWC_CGW(Channel_list,RoutingTable,Channel_list_LIN,MsgLinkFileName)
project_path = pwd;
ScriptVersion = '2024.06.05';

%% Read messageLink
cd([project_path '/documents/MessageLink']);
MessageLink_Rx = readcell(MsgLinkFileName,'Sheet','InputSignal');
MessageLink_Tx = readcell(MsgLinkFileName,'Sheet','OutputSignal');

% Change channel name from CAN_Dr1 to CANDr1 for Rx
for i = 1:length(MessageLink_Rx(:,2))
    MessageLink_Rx(i,2) = cellstr(erase(char(MessageLink_Rx(i,2)),'_'));
end

% Change channel name from CAN_Dr1 to CANDr1 for Tx
for i = 1:length(MessageLink_Tx(1,:))
    MessageLink_Tx(1,i) = cellstr(erase(char(MessageLink_Tx(1,i)),'_'));
end

%% Get APP related messages

Tx_Messages_APP = {};
Rx_Messages_APP = {};
cntR = 0;
cntT = 0;
for k = 1:length(Channel_list)
    Channel = char(Channel_list(k));
    tmpCell = MessageLink_Rx(strcmp(MessageLink_Rx(:,strcmp(MessageLink_Rx(1,:),'CANChannel')),Channel),strcmp(MessageLink_Rx(1,:),'MessageName'));
    Rx_MsgLink = categories(categorical(tmpCell));
    for i = 1:length(Rx_MsgLink)
        cntR = cntR + 1;
        Rx_Messages_APP{cntR,1} = [Channel '_' char(Rx_MsgLink(i))];
    end

    tmpCell = MessageLink_Tx(2:end,strcmp(MessageLink_Tx(1,:),Channel));
    tmpCell(cellfun(@(x) all(ismissing(x)), tmpCell)) = [];
    Tx_MsgLink = categories(categorical(tmpCell));
    for i = 1:length(Tx_MsgLink)
        cntT = cntT + 1;
        Tx_Messages_APP{cntT,1} = [Channel '_' char(Tx_MsgLink(i))];
    end
end

for k = 1:length(Channel_list_LIN)
    Channel = char(Channel_list_LIN(k));
    tmpCell = MessageLink_Rx(strcmp(MessageLink_Rx(:,strcmp(MessageLink_Rx(1,:),'CANChannel')),Channel),strcmp(MessageLink_Rx(1,:),'MessageName'));
    Rx_MsgLink = categories(categorical(tmpCell));
    for i = 1:length(Rx_MsgLink)
        cntR = cntR + 1;
        Rx_Messages_APP{cntR,1} = [Channel '_' char(Rx_MsgLink(i))];
    end

    tmpCell = MessageLink_Tx(2:end,strcmp(MessageLink_Tx(1,:),Channel));
    tmpCell(cellfun(@(x) all(ismissing(x)), tmpCell)) = [];
    Tx_MsgLink = categories(categorical(tmpCell));
    for i = 1:length(Tx_MsgLink)
        cntT = cntT + 1;
        Tx_Messages_APP{cntT,1} = [Channel '_' char(Tx_MsgLink(i))];
    end
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
                else
                    SourceMsgName = RoutingTable(k,2);
                end

                SignalRouting{cnt,1} = [Channel_source '_' char(SourceMsgName)]; % source CAN4_VCU1
                SignalRouting{cnt,2} = [Channel '_' char(RoutingTable(k,5))]; % target CAN4_VCU1

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
                else
                    SourceMsgName = RoutingTable(k,2);
                end

                SignalRouting{cnt,1} = [Channel_source '_' char(SourceMsgName)]; % source CAN4_VCU1
                SignalRouting{cnt,2} = [Channel '_' char(RoutingTable(k,5))]; % target CAN4_VCU1
            else
                continue
            end
        end
    end
end

%% Define Rx and Tx messages
Tx_Messages_CGW = categories(categorical(SignalRouting(:,2)));
Rx_Messages_CGW = categories(categorical(SignalRouting(:,1)));

Tx_Messages_Mixed = intersect(Tx_Messages_CGW,Tx_Messages_APP);
% Rework Tx_Messages_CGW
for i = 1:length(Tx_Messages_CGW)
    if any(strcmp(char(Tx_Messages_CGW(i)),Tx_Messages_Mixed))

        Tx_Messages_CGW{i} = [extractBefore(char(Tx_Messages_CGW(i)),'_') '_CGW_' extractAfter(char(Tx_Messages_CGW(i)),'_')];

    end
end

%% Edit admin data
% get Template
fileID = fopen('SWC_CGW_Template.arxml');
Target_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Target_arxml{1,1}),1);
for i = 1:length(Target_arxml{1,1})
    tmpCell{i,1} = Target_arxml{1,1}{i,1};
end
Target_arxml = tmpCell;
fclose(fileID);
cd(project_path);

% modify script version
h = contains(Target_arxml(:,1),'<SD GID="ScriptVersion">');
tmpCell = Target_arxml(h);
OldString = extractBetween(tmpCell,'>','<');
Target_arxml(h) = strrep(tmpCell,OldString,ScriptVersion); % <SD GID="ScriptVersion">0.0.1</SD>

% modify MessageLink version
h = contains(Target_arxml(:,1),'<SD GID="GenerateTime">');
tmpCell = Target_arxml(h);
OldString = char(extractBetween(tmpCell,'>','<'));
NewString = char(datetime);
Target_arxml(h) = strrep(tmpCell,OldString,NewString); % <SD GID="InputFile">CAN_MessageLinkOut</SD>

%% Modify ports

% P-Ports
Raw_start = find(contains(Target_arxml,'<P-PORT-PROTOTYPE>'),1,'first');
Raw_end = find(contains(Target_arxml,'</P-PORT-PROTOTYPE>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for k = 1:length(Tx_Messages_CGW)
    tmpCell = Template; % initialize tmpCell
    Channel = char(extractBefore(Tx_Messages_CGW(k),'_'));
    MsgName = char(extractAfter(Tx_Messages_CGW(k),'_'));

    h = contains(tmpCell(:,1),'<SHORT-NAME>PPortPrototype</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['P_' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>P_CAN1_FD_APS1</SHORT-NAME>

    h = contains(tmpCell(:,1),'<PROVIDED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['/CANInterface_ARPkg/IF_' Channel '_SG_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_FD_APS1

    if k == 1 % to replace original part
        Raw_start = find(contains(Target_arxml,'<P-PORT-PROTOTYPE>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</P-PORT-PROTOTYPE>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
    else
        % Write P-PORTS into target arxml
        Raw_start = find(contains(Target_arxml,'</P-PORT-PROTOTYPE>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end

end

% R-Ports
Raw_start = find(contains(Target_arxml,'<R-PORT-PROTOTYPE>'),1,'first');
Raw_end = find(contains(Target_arxml,'</R-PORT-PROTOTYPE>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for k = 1:length(Rx_Messages_CGW)
    tmpCell = Template; % initialize tmpCell
    Channel = char(extractBefore(Rx_Messages_CGW(k),'_'));
    MsgName = char(extractAfter(Rx_Messages_CGW(k),'_'));

    h = contains(tmpCell(:,1),'<SHORT-NAME>RPortPrototype</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['R_' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>R_CAN1_FCM3</SHORT-NAME>

    h = contains(tmpCell(:,1),'<REQUIRED-INTERFACE-TREF DEST="CLIENT-SERVER-INTERFACE">');
    OldString = char(extractBetween(tmpCell(h),'REQUIRED-INTERFACE-TREF DEST="','">'));
    NewString = 'SENDER-RECEIVER-INTERFACE';
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <REQUIRED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['/CANInterface_ARPkg/IF_' Channel '_SG_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_FCM3


    % Write R-PORTS into target arxml
    if k == 1 % to replace original part
        Raw_start = find(contains(Target_arxml,'<R-PORT-PROTOTYPE>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</R-PORT-PROTOTYPE>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
    else
        % Write P-PORTS into target arxml
        Raw_start = find(contains(Target_arxml,'</R-PORT-PROTOTYPE>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

%% Modify application SW component type: internal behaviors

% Data read access
Raw_start = find(contains(Target_arxml,'<DATA-READ-ACCESSS>'),1,'first')+1;
Raw_end = find(contains(Target_arxml,'</DATA-READ-ACCESSS>'),1,'first')-1;
Template = Target_arxml(Raw_start:Raw_end);

for k = 1:length(Rx_Messages_CGW)
    tmpCell = Template; % initialize tmpCell
    Channel = char(extractBefore(Rx_Messages_CGW(k),'_'));
    MsgName = char(extractAfter(Rx_Messages_CGW(k),'_'));

    h = contains(tmpCell(:,1),'<SHORT-NAME>DataReadAccessName</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['DA_R_' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>DA_R_CAN1_FCM3</SHORT-NAME>

    h = contains(tmpCell(:,1),'<PORT-PROTOTYPE-REF DEST="R-PORT-PROTOTYPE">');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['/SWC_CGW_ARPkg/SWC_CGW_type/R_' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_CGW_ARPkg/SWC_CGW_type/R_CAN1_FCM3

    h = contains(tmpCell(:,1),'<TARGET-DATA-PROTOTYPE-REF DEST="VARIABLE-DATA-PROTOTYPE">');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['/CANInterface_ARPkg/IF_' Channel '_SG_' MsgName '/' Channel '_SG_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_FCM3/CAN1_SG_FCM3

    if k == 1 % to replace original part
        Raw_start = find(contains(Target_arxml,'<DATA-READ-ACCESSS>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</DATA-READ-ACCESSS>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    else
        Raw_start = find(contains(Target_arxml,'</DATA-READ-ACCESSS>'),1,'last')-1;
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

% Data write access
Raw_start = find(contains(Target_arxml,'<DATA-WRITE-ACCESSS>'),1,'first')+1;
Raw_end = find(contains(Target_arxml,'</DATA-WRITE-ACCESSS>'),1,'first')-1;
Template = Target_arxml(Raw_start:Raw_end);

for k = 1:length(Tx_Messages_CGW)
    tmpCell = Template; % initialize tmpCell
    Channel = char(extractBefore(Tx_Messages_CGW(k),'_'));
    MsgName = char(extractAfter(Tx_Messages_CGW(k),'_'));

    h = contains(tmpCell(:,1),'<SHORT-NAME>DataWriteAccessName</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['DA_P_' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>DA_P_CAN1_FD_APS1</SHORT-NAME>

    h = contains(tmpCell(:,1),'<PORT-PROTOTYPE-REF DEST="P-PORT-PROTOTYPE">');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['/SWC_CGW_ARPkg/SWC_CGW_type/P_' Channel '_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_CGW_ARPkg/SWC_CGW_type/P_CAN1_FD_APS1

    h = contains(tmpCell(:,1),'<TARGET-DATA-PROTOTYPE-REF DEST="VARIABLE-DATA-PROTOTYPE">');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = ['/CANInterface_ARPkg/IF_' Channel '_SG_' MsgName '/' Channel '_SG_' MsgName];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_FD_APS1/CAN1_SG_FD_APS1

    if k == 1 % to replace original part
        Raw_start = find(contains(Target_arxml,'<DATA-WRITE-ACCESSS>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</DATA-WRITE-ACCESSS>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    else
        Raw_start = find(contains(Target_arxml,'</DATA-WRITE-ACCESSS>'),1,'last')-1;
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen( 'SWC_CGW.arxml','w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);

end