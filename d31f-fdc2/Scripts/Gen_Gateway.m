function Gen_Gateway(Channel_list,TargetECU,RoutingTable,Channel_list_LIN,RoutingTableName)
project_path = pwd;
ScriptVersion = '2024.04.11';

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

                SignalRouting(cnt,1) = cellstr(Channel_source); % source signal channel
                SignalRouting(cnt,2) = RoutingTable(k,1); % source signal name
                SignalRouting(cnt,3) = SourceMsgName; % source message name
                SignalRouting(cnt,4) = cellstr(Channel); % target signal channel
                SignalRouting(cnt,5) = RoutingTable(k,4); % target signal name
                SignalRouting(cnt,6) = RoutingTable(k,10); % timeout value
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

                SignalRouting(cnt,1) = cellstr(Channel_source); % source signal channel
                SignalRouting(cnt,2) = RoutingTable(k,1); % source signal name
                SignalRouting(cnt,3) = SourceMsgName; % source message name
                SignalRouting(cnt,4) = cellstr(Channel); % target signal channel
                SignalRouting(cnt,5) = RoutingTable(k,4); % target signal name
                SignalRouting(cnt,6) = RoutingTable(k,10); % timeout value
            else
                continue
            end
        end
    end
end
%% Edit admin data
% get Gateway_Template
fileID = fopen('Gateway_Template.arxml');
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

% modify RoutingTable version
h = contains(Target_arxml(:,1),'<SD GID="InputFile_RoutingTable">');
OldString = char(extractBetween(Target_arxml(h),'>','<'));
NewString = RoutingTableName;
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString); % <SD GID="InputFile_RoutingTable">RoutingTable</SD>

%% Modify Gateway name
h = contains(Target_arxml(:,1),'<SHORT-NAME>Gateway_TargetECU</SHORT-NAME>');
OldString = char(extractBetween(Target_arxml(h),'>','<'));
NewString = ['Gateway_' TargetECU];
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString); % <SHORT-NAME>Gateway_ZONE_DR</SHORT-NAME>

%% Modify ECU instance reference
h = contains(Target_arxml(:,1),'<ECU-REF DEST="ECU-INSTANCE">');
OldString = char(extractBetween(Target_arxml(h),'>','<'));
NewString = ['/ECU/' TargetECU];
Target_arxml(h) = strrep(Target_arxml(h),OldString,NewString); % <SHORT-NAME>/ECU/ZONE_DR</SHORT-NAME>

%% Modify I-SIGNAL-MAPPING
Raw_start = find(contains(Target_arxml,'<I-SIGNAL-MAPPING>'),1,'first');
Raw_end = find(contains(Target_arxml,'</I-SIGNAL-MAPPING>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:length(SignalRouting(:,1))
    tmpCell = Template; % initialize tmpCell
    SChannel = char(SignalRouting(i,1)); % source channel
    SSignal = char(SignalRouting(i,2)); % source signal name
    TChannel = char(SignalRouting(i,4)); % target signal channel
    TSignal = char(SignalRouting(i,5)); % target signal name


    h = find(contains(tmpCell,'<SOURCE-SIGNAL-REF DEST="I-SIGNAL-TRIGGERING">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' SChannel '/Cluster/' SChannel '/' SChannel '/ST_' SChannel '_' SSignal];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN3/Cluster/CAN3/CAN3/ST_CAN3_PwrSta

    h = find(contains(tmpCell,'<TARGET-SIGNAL-REF DEST="I-SIGNAL-TRIGGERING">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' TChannel '/Cluster/' TChannel '/' TChannel '/ST_' TChannel '_' TSignal];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN3/Cluster/CAN3/CAN3/ST_CAN3_PwrSta

    if i == 1 % to replace original part
        Raw_start = find(contains(Target_arxml,'<I-SIGNAL-MAPPING>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</I-SIGNAL-MAPPING>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
    else % too add new part
        Raw_start = find(contains(Target_arxml,'</I-SIGNAL-MAPPING>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen('Gateway.arxml','w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);

end