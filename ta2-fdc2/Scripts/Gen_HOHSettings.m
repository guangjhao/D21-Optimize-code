function Gen_HOHSettings(Channel_list,MsgLinkFileName,Channel_list_LIN,LDFSet,DBCSet,TargetECU,RoutingTable)
project_path = pwd;
ScriptVersion = '2024.08.12';

%% Get ECUC original arxml
cd([project_path '/documents/ARXML_splitconfig'])
fileID = fopen('HOHSettings.arxml');
HOH_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(HOH_arxml{1,1}),1);
for i = 1:length(HOH_arxml{1,1})
    tmpCell{i,1} = HOH_arxml{1,1}{i,1};
end
HOH_arxml = tmpCell;
fclose(fileID);
cd(project_path);

%% Get System arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen('System.arxml');
System_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(System_arxml{1,1}),1);
for i = 1:length(System_arxml{1,1})
    tmpCell{i,1} = System_arxml{1,1}{i,1};
end
System_arxml = tmpCell;
fclose(fileID);
cd(project_path);

%% Get HOHSettings template arxml
fileID = fopen('HOHSettings_template.arxml');
Template_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Template_arxml{1,1}),1);
for i = 1:length(Template_arxml{1,1})
    tmpCell{i,1} = Template_arxml{1,1}{i,1};
end
Template_arxml = tmpCell;
fclose(fileID);
cd(project_path);

%% Read messageLink
cd([project_path '/../common/documents']);
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
P_SG_APP = {};
R_SG_HOST = {};
cntR = 0;
cntT = 0;

% Get FD Rx PDU
% for k = 1:length(System_arxml)
%     if contains(strip(char(System_arxml(k)),'left'),'<SHORT-NAME>MAP_R_CAN')
%         Channel = cellstr(extractBetween(System_arxml(k),'<SHORT-NAME>MAP_R_','_'));
%         MsgName = cellstr(extractBetween(System_arxml(k),['<SHORT-NAME>MAP_R_' char(Channel) '_'],'</SHORT-NAME>'));
%         cntR = cntR + 1;
%         R_SG_HOST(cntR,1) = MsgName;
%         R_SG_HOST(cntR,2) = Channel;
%     end
% end

% Get CAN messages
% for k = 1:length(Channel_list)
%     Channel = char(Channel_list(k));
%     tmpCell = MessageLink_Rx(strcmp(MessageLink_Rx(:,strcmp(MessageLink_Rx(1,:),'CANChannel')),Channel),strcmp(MessageLink_Rx(1,:),'MessageName'));
%     Rx_MsgLink = categories(categorical(tmpCell));
%     for i = 1:length(Rx_MsgLink)
%         cntR = cntR + 1;
%         R_SG_HOST{cntR,1} = char(Rx_MsgLink(i));
%         R_SG_HOST{cntR,2} = Channel;
%     end
% 
%     tmpCell = MessageLink_Tx(2:end,strcmp(MessageLink_Tx(1,:),Channel));
%     tmpCell(cellfun(@(x) all(ismissing(x)), tmpCell)) = [];
%     Tx_MsgLink = categories(categorical(tmpCell));
%     for i = 1:length(Tx_MsgLink)
%         cntT = cntT + 1;
%         P_SG_APP{cntT,1} = char(Tx_MsgLink(i));
%     end
% end
% 
% % Get LIN messages
% for k = 1:length(Channel_list_LIN)
%     Channel = char(Channel_list_LIN(k));
%     tmpCell = MessageLink_Rx(strcmp(MessageLink_Rx(:,strcmp(MessageLink_Rx(1,:),'CANChannel')),Channel),strcmp(MessageLink_Rx(1,:),'MessageName'));
%     Rx_MsgLink = categories(categorical(tmpCell));
%     for i = 1:length(Rx_MsgLink)
%         cntR = cntR + 1;
%         R_SG_HOST{cntR,1} = char(Rx_MsgLink(i));
%         R_SG_HOST{cntR,2} = Channel;
%     end
% 
%     tmpCell = MessageLink_Tx(2:end,strcmp(MessageLink_Tx(1,:),Channel));
%     tmpCell(cellfun(@(x) all(ismissing(x)), tmpCell)) = [];
%     Tx_MsgLink = categories(categorical(tmpCell));
%     for i = 1:length(Tx_MsgLink)
%         cntT = cntT + 1;
%         P_SG_APP{cntT,1} = char(Tx_MsgLink(i));
%     end
% end

%% Read DBC info

ValueTable = {};
cnt = 0;
for i = 1:length(Channel_list)
    
    DBC = DBCSet(i);
    for k = 1:length(DBC.Messages)
        % Add Diag Rx PDU in R_SG_HOST
        if ~strcmp(DBC.MessageInfo(k).TxNodes,TargetECU) && ...
                (strcmp(DBC.MessageInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(k).Attributes(:,1),'DiagRequest')).Value,'Yes') ||...
                strcmp(DBC.MessageInfo(k).AttributeInfo(strcmp(DBC.MessageInfo(k).Attributes(:,1),'DiagResponse')).Value,'Yes') ||...
                startsWith(DBC.MessageInfo(k).Name,'Diag')) || ...
                (~strcmp(DBC.MessageInfo(k).TxNodes,TargetECU) && ~startsWith(DBC.MessageInfo(k).Name,'NMm_'))

            R_SG_HOST(end+1,1) = cellstr(DBC.MessageInfo(k).Name);
            R_SG_HOST(end,2) = Channel_list(i);
        end

        MsgName = char(DBC.MessageInfo(k).Name);
        if any(strcmp(DBC.MessageInfo(k).TxNodes,TargetECU)) ||...
                startsWith(MsgName,'NMm_')
            continue
        end
        cnt = cnt + 1;
        ValueTable{cnt,1} = char(DBC.MessageInfo(k).Name);
        ValueTable{cnt,2} = num2str(DBC.MessageInfo(k).ID);

    end
end

%% Get Rx frame routing messages

tmpCell = {};


Raw_start = find(contains(RoutingTable(:,1),['requested signals, source:' ])) + 2;

cnt = 0;
for i = 1:length(Raw_start)
    Raw_end = Raw_start(i) + find(contains(RoutingTable(Raw_start(i):end,1),'requested signals, source'),1,'first') - 2;
    Tx_Channel =  extractAfter(RoutingTable(Raw_start(i)-2,4),'distributed messages, target:');
    Rx_Channel =  extractAfter(RoutingTable(Raw_start(i)-2,2),'requested signals, source:');
    if isempty(Raw_end); Raw_end = length(RoutingTable(:,1));end

    for k = Raw_start(i):Raw_end
        if strcmp(RoutingTable(k,1),'Invalid')
            cnt = cnt + 1;
            tmpCell(cnt,1) = RoutingTable(k,2);
            tmpCell(cnt,2) = Rx_Channel;
            tmpCell(cnt,3) = Tx_Channel;
        else
            continue
        end
    end
end

% tmpCell = categories(categorical(tmpCell));
h = find(contains(tmpCell(:,1),'Invalid'));
tmpCell(h,:) = [];
Rx_MsgFrameGW = tmpCell;

numValues = cellfun(@str2double, erase(Rx_MsgFrameGW(:, 3),'CAN'));
[~, sortedIdx] = sort(numValues);
Rx_MsgFrameGW = Rx_MsgFrameGW(sortedIdx, :);

% Sort FrameGW Can LLCE Advanced Feature Reference

Delet_array = [];
cnt = 0;

for i = 1:length(Rx_MsgFrameGW)
    
    Rx_MsgFrameGW(i,4) = cellstr('/Llce_Af/Llce_Af/LlceAfGeneral/AF_ToCan' + string(erase(Rx_MsgFrameGW(i,3),'CAN')));
    h = find(strcmp(Rx_MsgFrameGW(:,1),Rx_MsgFrameGW(i,1)));

    if length(h) >= 2 &&  i == h(1)
        for k = 2:length(h)            
            Rx_MsgFrameGW(h(1),4) =  cellstr(string(Rx_MsgFrameGW(h(1),4)) + "_" + string(erase(Rx_MsgFrameGW(h(k),3),'CAN')));
            cnt = cnt +1;
            Delet_array(cnt) = h(k);
        end
    end
end

Rx_MsgFrameGW(Delet_array,:) = [];

%% %% Get HOHSettings.ARXML info

% h = find(contains(HOH_arxml,'<SHORT-NAME>HOH_'));
% HOH_Array = cell(length(h),3);
% HOH_Array(:,1) = extractBetween(HOH_arxml(h),'<SHORT-NAME>','</SHORT-NAME>');
% 
% h = find(contains(HOH_arxml,'CanHwFilterCode</DEFINITION-REF>'));
% HOH_Array(:,3) = extractBetween(HOH_arxml(h+1),'<VALUE>','</VALUE>');
% 
% numValues = cellfun(@str2double, HOH_Array(:, 3));
% [~, sortedIdx] = sort(numValues);
% HOH_Array = HOH_Array(sortedIdx, :);

% Remove old HOH

h1 = find(contains(HOH_arxml,'<SHORT-NAME>HOH_'));
ECUC_start_array = find(contains(HOH_arxml(:,1),'<ECUC-CONTAINER-VALUE>'));
ECUC_end_array = find(contains(HOH_arxml(:,1),'</SUB-CONTAINERS>'));

HOH_Array = {};
cnt = 0;

for i = 1:length(h1)
    ECUC_start = max(ECUC_start_array(ECUC_start_array<h1(i)));
    ECUC_end = min(ECUC_end_array(ECUC_end_array>h1(i)))+1;

    % HOH name
    h = find(contains(HOH_arxml(ECUC_start:ECUC_end),'<SHORT-NAME>HOH_')) + ECUC_start -1;
    HOH_Name = extractBetween(HOH_arxml(h),'<SHORT-NAME>','</SHORT-NAME>');
    
    if startsWith(HOH_Name,'HOH_TX') || endsWith(HOH_Name,'_Xcp')
        continue
    end
    cnt = cnt +1;
    HOH_Array(cnt,1) = HOH_Name;

    % HOH message ID
    h = find(contains(HOH_arxml(ECUC_start:ECUC_end),'CanHwFilterCode</DEFINITION-REF>')) + ECUC_start -1;
    HOH_Array(cnt,3) = extractBetween(HOH_arxml(h+1),'<VALUE>','</VALUE>');

    % HOH CanHwObjectCount
    h = find(contains(HOH_arxml(ECUC_start:ECUC_end),'/CanHwObjectCount</DEFINITION-REF>')) + ECUC_start -1;
    HOH_Array(cnt,5) = extractBetween(HOH_arxml(h+1),'<VALUE>','</VALUE>');
    
    % HOH CanObjectType
    h = find(contains(HOH_arxml(ECUC_start:ECUC_end),'/CanObjectType</DEFINITION-REF>')) + ECUC_start -1;
    HOH_Array(cnt,6) = extractBetween(HOH_arxml(h+1),'<VALUE>','</VALUE>');

    HOH_arxml(ECUC_start:ECUC_end) = {'XXX'};
end

numValues = cellfun(@str2double, HOH_Array(:, 3));
[~, sortedIdx] = sort(numValues);
HOH_Array = HOH_Array(sortedIdx, :);

h = strcmp(HOH_arxml(:,1),'XXX');
HOH_arxml(h) = [];

%% Get all HOH message name

Delete_array = [];
cnt = 0;

for i =1:length(HOH_Array)
    TargetID = HOH_Array(i,3);

    if cell2mat(TargetID) == '0'
        continue
    end

    TargetMsg = ValueTable(strcmp(ValueTable(:,2),TargetID));

    if isempty(TargetMsg)

        if ~contains(HOH_Array(i,1),'Xcp')
            cnt = cnt+1;
            Delete_array(cnt) = i;
        end

        continue
    end
    HOH_Array(i,2) = TargetMsg;
    HOH_Array(i,4) = cellstr('/Llce_Af/Llce_Af/LlceAfGeneral/AF_Host');
end

HOH_Array(Delete_array,:) = [];

%% Create Frame routing HOH 

for i = 1:length(Rx_MsgFrameGW(:,1))
    
    h = find(strcmp(HOH_Array(:,2),Rx_MsgFrameGW(i,1)));

    if ~isempty(h) % Old Frame routing
        HOH_Array(h,4) = Rx_MsgFrameGW(i,4);

    else % New Frame routing
        disp(['CAUTION: ' char(Rx_MsgFrameGW(i,2)) '::' char(Rx_MsgFrameGW(i,1)) ' is new Frame routing PDU.']);
        HOH_Array(end+1,1) = cellstr(['HOH_999_' char(Rx_MsgFrameGW(i,2))]);
        HOH_Array(end,2) = Rx_MsgFrameGW(i,1);
        HOH_Array(end,3) = ValueTable(strcmp(ValueTable(:,1),Rx_MsgFrameGW(i,1)),2); % New Frame routing PDU ID
        HOH_Array(end,4) = Rx_MsgFrameGW(i,4);
        HOH_Array(end,5) = {'12'}; % Frame routing PDU CanHwObjectCount
        HOH_Array(end,6) = {'RECEIVE'}; % Frame routing PDU CanObjectType
    end
end

%% Find new Rx PDU in messageLink, create it

for i = 1:length(R_SG_HOST)
    h = find(strcmp(HOH_Array(:,2),R_SG_HOST(i,1)));
    % Find PDU in HOH array, if not, create HOH
    if any(h)
        
        if ~endsWith(HOH_Array(h,4),'AF_Host') % Frame routing and APP Rx PDU
            HOH_Array(h,4) = cellstr(string(HOH_Array(h,4)) + '_Host');
        end

        continue
    else
        disp(['CAUTION: ' char(R_SG_HOST(i,2)) '::' char(R_SG_HOST(i,1)) ' is new Rx PDU.']);
        HOH_Array(end+1,1) = cellstr(['HOH_999_' char(R_SG_HOST(i,2))]);
        HOH_Array(end,2) = R_SG_HOST(i,1);
        HOH_Array(end,3) = ValueTable(strcmp(ValueTable(:,1),R_SG_HOST(i,1)),2); % New Rx PDU ID
        HOH_Array(end,4) = cellstr('/Llce_Af/Llce_Af/LlceAfGeneral/AF_Host');
        HOH_Array(end,5) = cellstr('12'); % Rx PDU CanHwObjectCount
        HOH_Array(end,6) = {'RECEIVE'}; % Rx PDU CanObjectType
    end
end

%% Delete don't need Rx PDU

idx = cellfun(@ischar,HOH_Array) ; 
HOH_Array(~idx) = {'NA'};

Delete_array = [];
cnt = 0;
for i = 1:length(HOH_Array)
    if ~strcmp(HOH_Array(i,3),'0') && endsWith(string(HOH_Array(i,4)),'/AF_Host') && ~any(strcmp(R_SG_HOST(:,1),HOH_Array(i,2))) % Not Frame routing, have ID, didn't exist in Messagelink input 
       cnt = cnt+1;
        Delete_array(cnt,1) = i;
        disp(['CAUTION: ' char(HOH_Array(i,2)) ' is not use Rx PDU now,  will delete it.'])
    end
end

HOH_Array(Delete_array,:) = [];

%% Sort HOH_array

Final_HOH_Array = {};

for i = 1:length(Channel_list)
    Channel = char(Channel_list(i));
    % Sort CANx HOH (HOH_x_CANx)

    cnt = 0;
    HOH_Array_CAN = {};
    % Delete_array = [];
    for j = 1:length(HOH_Array(:,1))
        if endsWith(HOH_Array(j,1),Channel) && strcmp(HOH_Array(j,6),'RECEIVE') && ~startsWith(HOH_Array(j,1),'HOH_TX_LOGGING_')
            cnt =cnt +1;
            HOH_Array_CAN(cnt,:) = HOH_Array(j,1:end);
            % Delete_array(cnt) = j;
        else
            continue 
        end
    end
    
    if isempty(HOH_Array_CAN)
        continue
    end
    h = extractBetween(HOH_Array_CAN(:,1),'_','_');
    h = find(~isnan(cellfun(@str2double, h))); % Rx HOH
    
    % New number of HOH_X_CAN
    for k = 1:length(h)
        HOH_Array_CAN(h(k)) = cellstr(['HOH_' num2str(k) '_' Channel]);

    end

    if i == 1
        Final_HOH_Array(1:length(HOH_Array_CAN),:) = HOH_Array_CAN(1:end,:);

    else % Replace original description
        Final_HOH_Array(end+1 : end+length(HOH_Array_CAN(:,1)),:) = HOH_Array_CAN(1:end,:);
    end

end

% Add else HOH
% Final_HOH_Array(end+1 : end + length(HOH_Array(:,1)),:) = HOH_Array(1:end,:);


%% Add all HOH in ARXMl
Raw_start = find(contains(Template_arxml(:,1),'<ECUC-CONTAINER-VALUE>'),1,'first');
Raw_end = find(contains(Template_arxml(:,1),'</ECUC-CONTAINER-VALUE>'),1,'last');
template = Template_arxml(Raw_start:Raw_end,1);
tmpCell = template;
tmpCell2 = {};

for i = 1:length(Final_HOH_Array)
    tmpCell = template;
    NmPDU_flg = boolean(0);

    HOH_Name = Final_HOH_Array(i,1);
    HOH_CanHwObjCnt = Final_HOH_Array(i,5);
    HOH_CanObjType = Final_HOH_Array(i,6);
    HOH_CanHwFilterCode = Final_HOH_Array(i,3);
    HOH_CanHandleType = cellstr('BASIC');
    HOH_CanAdvFeatureRef = Final_HOH_Array(i,4);
    idx = strfind(string(Final_HOH_Array(i,1)),'_');
    Channel = upper(extractAfter(Final_HOH_Array(i,1),idx(end)));
    
    if contains(Final_HOH_Array(i,1),'Can8_Xcp')
        Channel = cellstr(['CAN_' char(Channel)]);
    end
    

    if strcmp(Final_HOH_Array(i,3),'0') && strcmp(Final_HOH_Array(i,4),'NA')  && strcmp(Final_HOH_Array(i,6),'RECEIVE')
        % Nm PDU
        NmPDU_flg = boolean(1);
        CanIdType = cellstr('STANDARD');
        HOH_CanHwFilterMask = cellstr('0');
        HOH_RangeStart = cellstr('1281'); % 0x501
        HOH_RangeEnd = cellstr('1408'); % 0x580
    elseif str2double(Final_HOH_Array(i,3)) > 4095
        CanIdType = cellstr('EXTENDED');
        HOH_CanHwFilterMask = cellstr('4294967295');
    else
        CanIdType = cellstr('STANDARD');
        HOH_CanHwFilterMask = cellstr('2047');
    end

    % HOH Name
    h = find(contains(tmpCell,'<SHORT-NAME>HOH_'));
    OldString = extractBetween(tmpCell(h),'<SHORT-NAME>','</SHORT-NAME>');
    NewString = HOH_Name;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % HOH CanHandleType
    h = find(contains(tmpCell,'/CanHandleType</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = HOH_CanHandleType;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % HOH CanHwObjectCount
    h = find(contains(tmpCell,'/CanHwObjectCount</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = HOH_CanHwObjCnt;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % HOH CanIdType
    h = find(contains(tmpCell,'/CanIdType</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = CanIdType;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % HOH CanObjectType
    h = find(contains(tmpCell,'/CanObjectType</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = HOH_CanObjType;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % HOH CanHwFilterCode
    h = find(contains(tmpCell,'/CanHwFilterCode</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = HOH_CanHwFilterCode;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % HOH CanHwFilterMask
    h = find(contains(tmpCell,'/CanHwFilterMask</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = HOH_CanHwFilterMask;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % HOH CanConfigSet
    h = find(contains(tmpCell,'<VALUE-REF DEST="ECUC-CONTAINER-VALUE">/Can/Can/CanConfigSet/'));
    OldString = extractBetween(tmpCell(h),'CanConfigSet/','</VALUE-REF>');
    NewString = Channel;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % HOH CanObjectId
    h = find(contains(tmpCell,'/CanObjectId</DEFINITION-REF>')) + 1;
    OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
    NewString = mat2str(i-1);
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    if i == 1
        tmpCell_CanObjectId = tmpCell(h-2:h+1);
    end

    if NmPDU_flg
        % RangeFilter
        h = find(contains(tmpCell,'/RangeEnd</DEFINITION-REF>')) + 1;
        OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
        NewString = HOH_RangeEnd;
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

        h = find(contains(tmpCell,'/RangeStart</DEFINITION-REF>')) + 1;
        OldString = extractBetween(tmpCell(h),'<VALUE>','</VALUE>');
        NewString = HOH_RangeStart;
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
        
        % Delete CanAdvancedFeature part
        h1 = find(contains(tmpCell,'<SHORT-NAME>CanAdvancedFeature</SHORT-NAME>'));
        ECUC_start_array = find(contains(tmpCell(:,1),'<ECUC-CONTAINER-VALUE>'));
        ECUC_end_array = find(contains(tmpCell(:,1),'</ECUC-CONTAINER-VALUE>'));
        ECUC_start = max(ECUC_start_array(ECUC_start_array<h1));
        ECUC_end = min(ECUC_end_array(ECUC_end_array>h1));        
        tmpCell(ECUC_start:ECUC_end) = [];

    else % Rx PDU
        % Delete RangeFilter part
        h1 = find(contains(tmpCell,'<SHORT-NAME>RangeFilter</SHORT-NAME>'));
        ECUC_start_array = find(contains(tmpCell(:,1),'<ECUC-CONTAINER-VALUE>'));
        ECUC_end_array = find(contains(tmpCell(:,1),'</ECUC-CONTAINER-VALUE>'));
        ECUC_start = max(ECUC_start_array(ECUC_start_array<h1));
        ECUC_end = min(ECUC_end_array(ECUC_end_array>h1));        
        tmpCell(ECUC_start:ECUC_end) = [];

        % HOH CanAdvancedFeatureRef
        h = find(contains(tmpCell,'/CanAdvancedFeatureRef</DEFINITION-REF>')) + 1;
        OldString = extractBetween(tmpCell(h),'ECUC-CONTAINER-VALUE">','</VALUE-REF>');
        NewString = HOH_CanAdvFeatureRef;
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    end
    

    if i == 1
        tmpCell2 = tmpCell;
    else 
        tmpCell2 = [tmpCell2;tmpCell];
    end

    % Add in HOH arxml
%     idx = find(contains(HOH_arxml,'</ECUC-CONTAINER-VALUE>'));
%     Raw_start = idx(end-2);
% 
%     HOH_arxml = [HOH_arxml(1:Raw_start);tmpCell;HOH_arxml(Raw_start + 1:end)];

end

%% Add orignal HOH CanObjectId
% Find CanObjectId part
h = contains(HOH_arxml(:,1),'<SHORT-NAME>HOH_');
Else_HOH_cell(:,1) = extractBetween(HOH_arxml(h),'<SHORT-NAME>','</SHORT-NAME>');
h = find(contains(HOH_arxml,'/CanHardwareObject/CanObjectType</DEFINITION-REF>')) + 1;
Else_HOH_cell(:,2) = extractBetween(HOH_arxml(h),'<VALUE>','</VALUE>');

[~, sortedIdx] = sort(Else_HOH_cell(:,2));
Else_HOH_cell = Else_HOH_cell(sortedIdx, :);

for i = 1:length(Else_HOH_cell)

    h = find(contains(HOH_arxml(:,1),Else_HOH_cell(i)));
    ECUC_start_array = find(contains(HOH_arxml(:,1),'<PARAMETER-VALUES>'));
    ECUC_end_array = find(contains(HOH_arxml(:,1),'</PARAMETER-VALUES>'));

    ECUC_start = min(ECUC_start_array(ECUC_start_array>h)); % <PARAMETER-VALUES>
    ECUC_end = min(ECUC_end_array(ECUC_end_array>h)); % </PARAMETER-VALUES>
    h = find(contains(HOH_arxml(ECUC_start:ECUC_end),'/CanObjectId</DEFINITION-REF>'));

    if ~any(h) % Add new CanObjectId part
        HOH_arxml = [HOH_arxml(1:ECUC_end-1);tmpCell_CanObjectId;HOH_arxml(ECUC_end:end)];
        ECUC_end = ECUC_end + length(tmpCell_CanObjectId);
        h = find(contains(HOH_arxml(ECUC_start:ECUC_end),'/CanObjectId</DEFINITION-REF>'));
    end

    % Update CanObjectId
    OldString = extractBetween(HOH_arxml(ECUC_start + h),'<VALUE>','</VALUE>');
    NewString = mat2str(length(Final_HOH_Array)+i -1);
    HOH_arxml(ECUC_start + h) = strrep(HOH_arxml(ECUC_start + h),OldString,NewString);

end

% Add in HOH arxml
h = find(contains(HOH_arxml,'<SHORT-NAME>CanErrorReporting</SHORT-NAME>'));
ECUC_end_array = find(contains(HOH_arxml(:,1),'</ECUC-CONTAINER-VALUE>'));
ECUC_end = min(ECUC_end_array(ECUC_end_array>h));
HOH_arxml = [HOH_arxml(1:ECUC_end);tmpCell2;HOH_arxml(ECUC_end+1:end)];

%% Output COM_arxml
cd([project_path '/documents/ARXML_splitconfig'])
fileID = fopen('HOHSettings.arxml','w');
for i = 1:length(HOH_arxml(:,1))
    fprintf(fileID,'%s\n',char(HOH_arxml(i,1)));
end
fclose(fileID);
end