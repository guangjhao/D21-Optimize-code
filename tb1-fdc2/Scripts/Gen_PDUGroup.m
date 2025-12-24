function Gen_PDUGroup(Channel_list,MsgLinkFileName,TargetECU,DBCSet,Channel_list_LIN,LDFSet)
project_path = pwd;
ScriptVersion = '2024.07.02';
%% Get all CAN PDUs from source arxml
Icnt = 0;
Channel_IPDUCell = {};
Ncnt = 0;
Channel_NPDUCell = {};
for i = 1:length(Channel_list)
    Channel = char(Channel_list(i));
    cd([project_path '/documents/ARXML_output'])
    fileID = fopen([Channel '.arxml']);
    Source_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
    tmpCell = cell(length(Source_arxml{1,1}),1);
    for j = 1:length(Source_arxml{1,1})
        tmpCell{j,1} = Source_arxml{1,1}{j,1};
    end
    Source_arxml = tmpCell;

    for k = 1:length(Source_arxml)
        if contains(Source_arxml(k),'<I-SIGNAL-I-PDU>')
            Icnt = Icnt + 1;
            Channel_IPDUCell(Icnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>','</SHORT-NAME>');
        elseif contains(Source_arxml(k),'<N-PDU>')
            Ncnt = Ncnt + 1;
            Channel_NPDUCell(Ncnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>','</SHORT-NAME>');
        else
            continue
        end
    end
    fclose(fileID);
    cd(project_path);
end

%% Edit admin data
% get Template
fileID = fopen('PDUGroups_Template.arxml');
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
h = contains(Target_arxml(:,1),'<SD GID="InputFile_Msglink">');
tmpCell = Target_arxml(h);
OldString = char(extractBetween(tmpCell,'>','<'));
NewString = MsgLinkFileName;
Target_arxml(h) = strrep(tmpCell,OldString,NewString); % <SD GID="InputFile">CAN_MessageLinkOut</SD>

%% Modify I-SIGNAL-I-PDU-GROUP for CAN
Raw_start = find(contains(Target_arxml,'<I-SIGNAL-I-PDU-GROUP>'),1,'first');
Raw_end = find(contains(Target_arxml,'</I-SIGNAL-I-PDU-GROUP>'),1,'last');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1:length(Channel_list)
    Channel = char(Channel_list(i));
    DBC = DBCSet(i);

    Tx_Messages = {};
    Rx_Messages = {};
    cntR = 0;
    cntT = 0;
    for n = 1:length(DBC.Messages)
        MsgName = char(DBC.MessageInfo(n).Name);

        if all(~strcmp([Channel '_' MsgName],Channel_IPDUCell))
            continue
        elseif strcmp(DBC.MessageInfo(n).TxNodes,TargetECU)
            cntT = cntT + 1;
            Tx_Messages{cntT,1} = MsgName;
        else
            cntR = cntR + 1;
            Rx_Messages{cntR,1} = MsgName;
        end
    end

    tmpCell = Template; % initialize tmpCell

    % Modify Tx part for this channel
    Raw_start = find(contains(Template,'<I-SIGNAL-I-PDU-GROUP>'),1,'first');
    Raw_end = find(contains(Template,'</I-SIGNAL-I-PDU-GROUP>'),1,'first');
    tmpCell2 = Template(Raw_start:Raw_end); % initialize tmpCell2

    h = contains(tmpCell2,'<SHORT-NAME>PDUGroupName_Tx</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell2(h),'>','<'));
    NewString = [TargetECU '_' Channel '_Tx'];
    tmpCell2 = strrep(tmpCell2,OldString,NewString); % <SHORT-NAME>FUSION_CAN1_Tx</SHORT-NAME>

    Raw_start = find(contains(tmpCell2,'<I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'first');
    Raw_end = find(contains(tmpCell2,'</I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'last');
    tmpCell3 = tmpCell2(Raw_start:Raw_end);

    for k = 1:length(Tx_Messages)
        MsgName = char(Tx_Messages(k));

        h = find(contains(tmpCell3,'<I-SIGNAL-I-PDU-REF DEST="I-SIGNAL-I-PDU">'));
        OldString = char(extractBetween(tmpCell3(h),'>','<'));
        NewString = ['/' Channel '/PDU/' Channel '_' MsgName];
        tmpCell3(h) = strrep(tmpCell3(h),OldString,NewString); % /CAN1/PDU/CAN1_FD_VCU2

        if k == 1 % to replace original part
            Raw_start = find(contains(tmpCell2,'<I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'last');
            Raw_end = find(contains(tmpCell2,'</I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'last');
            tmpCell2 = [tmpCell2(1:Raw_start-1);tmpCell3(1:end);tmpCell2(Raw_end+1:end)];
        else % to add new part
            Raw_start = find(contains(tmpCell2,'</I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell2 = [tmpCell2(1:Raw_start);tmpCell3(1:end);tmpCell2(Raw_end:end)];
        end
    end

    Raw_end = find(contains(tmpCell,'</I-SIGNAL-I-PDU-GROUP>'),1,'first');
    tmpCell = [tmpCell2(1:end);tmpCell(Raw_end+1:end)];

    % Modify Rx part for this channel
    Raw_start = find(contains(Template,'<I-SIGNAL-I-PDU-GROUP>'),1,'last');
    Raw_end = find(contains(Template,'</I-SIGNAL-I-PDU-GROUP>'),1,'last');
    tmpCell2 = Template(Raw_start:Raw_end); % initialize tmpCell2

    h = contains(tmpCell2,'<SHORT-NAME>PDUGroupName_Rx</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell2(h),'>','<'));
    NewString = [TargetECU '_' Channel '_Rx'];
    tmpCell2 = strrep(tmpCell2,OldString,NewString); % <SHORT-NAME>FUSION_CAN1_Tx</SHORT-NAME>

    Raw_start = find(contains(tmpCell2,'<I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'first');
    Raw_end = find(contains(tmpCell2,'</I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'last');
    tmpCell3 = tmpCell2(Raw_start:Raw_end);

    for k = 1:length(Rx_Messages)
        MsgName = char(Rx_Messages(k));

        h = find(contains(tmpCell3,'<I-SIGNAL-I-PDU-REF DEST="I-SIGNAL-I-PDU">'));
        OldString = char(extractBetween(tmpCell3(h),'>','<'));
        NewString = ['/' Channel '/PDU/' Channel '_' MsgName];
        tmpCell3(h) = strrep(tmpCell3(h),OldString,NewString); % /CAN1/PDU/CAN1_FD_VCU2

        if k == 1 % to replace original part
            Raw_start = find(contains(tmpCell2,'<I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'last');
            Raw_end = find(contains(tmpCell2,'</I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'last');
            tmpCell2 = [tmpCell2(1:Raw_start-1);tmpCell3(1:end);tmpCell2(Raw_end+1:end)];
        else % to add new part
            Raw_start = find(contains(tmpCell2,'</I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell2 = [tmpCell2(1:Raw_start);tmpCell3(1:end);tmpCell2(Raw_end:end)];
        end
    end

    Raw_start = find(contains(tmpCell,'<I-SIGNAL-I-PDU-GROUP>'),1,'last');
    tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end)];

    % If any channel has empty Tx or Rx message
    if isempty(Tx_Messages)
        Raw_start = find(contains(tmpCell,'<I-SIGNAL-I-PDU-GROUP>'),1,'first');
        Raw_end = find(contains(tmpCell,'</I-SIGNAL-I-PDU-GROUP>'),1,'first');
        tmpCell(Raw_start:Raw_end) = [];
    end

    if isempty(Rx_Messages)
        Raw_start = find(contains(tmpCell,'<I-SIGNAL-I-PDU-GROUP>'),1,'last');
        Raw_end = find(contains(tmpCell,'</I-SIGNAL-I-PDU-GROUP>'),1,'last');
        tmpCell(Raw_start:Raw_end) = [];
    end

    if i == 1 % to replace original part
        Raw_start = find(contains(Target_arxml,'<I-SIGNAL-I-PDU-GROUP>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</I-SIGNAL-I-PDU-GROUP>'),1,'last');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
    else

        Raw_start = find(contains(Target_arxml,'</I-SIGNAL-I-PDU-GROUP>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

%% Modify I-SIGNAL-I-PDU-GROUP for LIN
Raw_start = find(contains(Template,'<I-SIGNAL-I-PDU-GROUP>'),1,'first');
Raw_end = find(contains(Template,'</I-SIGNAL-I-PDU-GROUP>'),1,'first');
Template = Template(Raw_start:Raw_end);


for i = 1:length(Channel_list_LIN)
    Channel = char(Channel_list_LIN(i));
    LDF = LDFSet{i};

    Tx_Messages = {};
    Rx_Messages = {};
    cntR = 0;
    cntT = 0;

    for n = 1:length(LDF.Messages)
        MsgName = char(LDF.MessageInfo(n).Name);

        if strcmp(LDF.MessageInfo(n).TxNodes,TargetECU)
            cntT = cntT + 1;
            Tx_Messages{cntT,1} = MsgName;
        else
            cntR = cntR + 1;
            Rx_Messages{cntR,1} = MsgName;
        end
    end

    tmpCell = Template; % initialize tmpCell

    % Modify Tx part for this channel
    h = contains(tmpCell,'<SHORT-NAME>PDUGroupName_Tx</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = [TargetECU '_' Channel '_Tx'];
    tmpCell = strrep(tmpCell,OldString,NewString); % <SHORT-NAME>ZONE_DR_LINDr1_Tx</SHORT-NAME>

    h = contains(tmpCell,'<COMMUNICATION-DIRECTION>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = 'OUT';
    tmpCell = strrep(tmpCell,OldString,NewString); % <COMMUNICATION-DIRECTION>IN</COMMUNICATION-DIRECTION>

    h = contains(tmpCell,'<COMMUNICATION-MODE>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = 'Transmit_All';
    tmpCell = strrep(tmpCell,OldString,NewString); % <COMMUNICATION-MODE>Transmit_All</COMMUNICATION-MODE>

    Raw_start = find(contains(tmpCell,'<I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'first');
    Raw_end = find(contains(tmpCell,'</I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'first');
    tmpCell2 = tmpCell(Raw_start:Raw_end);

    for k = 1:length(Tx_Messages)
        MsgName = char(Tx_Messages(k));

        h = find(contains(tmpCell2,'<I-SIGNAL-I-PDU-REF DEST="I-SIGNAL-I-PDU">'));
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = ['/' Channel '/PDU/' Channel '_' MsgName];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/PDU/CAN1_FD_VCU2

        if k == 1 % to replace original part
            Raw_start = find(contains(tmpCell,'<I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'first');
            Raw_end = find(contains(tmpCell,'</I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'first');
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
        else % to add new part
            Raw_start = find(contains(tmpCell,'</I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    % If any channel has empty Tx message
    if isempty(Tx_Messages)
        Raw_start = find(contains(tmpCell,'<I-SIGNAL-I-PDU-GROUP>'),1,'first');
        Raw_end = find(contains(tmpCell,'</I-SIGNAL-I-PDU-GROUP>'),1,'first');
        tmpCell(Raw_start:Raw_end) = [];
    end

    Raw_start = find(contains(Target_arxml,'</I-SIGNAL-I-PDU-GROUP>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];

    
    % Modify Rx part for this channel
    tmpCell = Template; % initialize tmpCell

    h = contains(tmpCell,'<SHORT-NAME>PDUGroupName_Tx</SHORT-NAME>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = [TargetECU '_' Channel '_Rx'];
    tmpCell = strrep(tmpCell,OldString,NewString); % <SHORT-NAME>ZONE_DR_LINDr1_Rx</SHORT-NAME>

    h = contains(tmpCell,'<COMMUNICATION-DIRECTION>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = 'IN';
    tmpCell = strrep(tmpCell,OldString,NewString); % <COMMUNICATION-DIRECTION>IN</COMMUNICATION-DIRECTION>

    h = contains(tmpCell,'<COMMUNICATION-MODE>');
    OldString = char(extractBetween(tmpCell(h),'>','<'));
    NewString = 'Receive_All';
    tmpCell = strrep(tmpCell,OldString,NewString); % <COMMUNICATION-MODE>Receive_All</COMMUNICATION-MODE>

    Raw_start = find(contains(tmpCell,'<I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'first');
    Raw_end = find(contains(tmpCell,'</I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'first');
    tmpCell2 = tmpCell(Raw_start:Raw_end);

    for k = 1:length(Rx_Messages)
        MsgName = char(Rx_Messages(k));

        h = find(contains(tmpCell2,'<I-SIGNAL-I-PDU-REF DEST="I-SIGNAL-I-PDU">'));
        OldString = char(extractBetween(tmpCell2(h),'>','<'));
        NewString = ['/' Channel '/PDU/' Channel '_' MsgName];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/PDU/CAN1_FD_VCU2

        if k == 1 % to replace original part
            Raw_start = find(contains(tmpCell,'<I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'first');
            Raw_end = find(contains(tmpCell,'</I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'first');
            tmpCell = [tmpCell(1:Raw_start-1);tmpCell2(1:end);tmpCell(Raw_end+1:end)];
        else % to add new part
            Raw_start = find(contains(tmpCell,'</I-SIGNAL-I-PDU-REF-CONDITIONAL>'),1,'last');
            Raw_end = Raw_start + 1;
            tmpCell = [tmpCell(1:Raw_start);tmpCell2(1:end);tmpCell(Raw_end:end)];
        end
    end

    % If any channel has empty Rx message
    if isempty(Rx_Messages)
        Raw_start = find(contains(tmpCell,'<I-SIGNAL-I-PDU-GROUP>'),1,'last');
        Raw_end = find(contains(tmpCell,'</I-SIGNAL-I-PDU-GROUP>'),1,'last');
        tmpCell(Raw_start:Raw_end) = [];
    end

    Raw_start = find(contains(Target_arxml,'</I-SIGNAL-I-PDU-GROUP>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
end


%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen( 'PDUGroup.arxml','w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);

end