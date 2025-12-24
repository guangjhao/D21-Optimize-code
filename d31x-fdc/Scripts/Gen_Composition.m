function Gen_Composition(Channel_list,MsgLinkFileName,TargetECU,Channel_list_LIN,RoutingTable)
project_path = pwd;
ScriptVersion = '2024.06.05';

%% Define target ECU name
if strcmp(TargetECU,'FUSION'); TargetECU = 'FDC'; end

%% Read messageLink
cd([project_path '/documents']);
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
R_SG_APP = {};
cntR = 0;
cntT = 0;

% Get CAN messages
for k = 1:length(Channel_list)
    Channel = char(Channel_list(k));
    tmpCell = MessageLink_Rx(strcmp(MessageLink_Rx(:,strcmp(MessageLink_Rx(1,:),'CANChannel')),Channel),strcmp(MessageLink_Rx(1,:),'MessageName'));
    Rx_MsgLink = categories(categorical(tmpCell));
    for i = 1:length(Rx_MsgLink)
        cntR = cntR + 1;
        R_SG_APP{cntR,1} = [Channel '_SG_' char(Rx_MsgLink(i))];
    end

    tmpCell = MessageLink_Tx(2:end,strcmp(MessageLink_Tx(1,:),Channel));
    tmpCell(cellfun(@(x) all(ismissing(x)), tmpCell)) = [];
    Tx_MsgLink = categories(categorical(tmpCell));
    for i = 1:length(Tx_MsgLink)
        cntT = cntT + 1;
        P_SG_APP{cntT,1} = [Channel '_SG_' char(Tx_MsgLink(i))];
    end
end

% Get LIN messages
for k = 1:length(Channel_list_LIN)
    Channel = char(Channel_list_LIN(k));
    tmpCell = MessageLink_Rx(strcmp(MessageLink_Rx(:,strcmp(MessageLink_Rx(1,:),'CANChannel')),Channel),strcmp(MessageLink_Rx(1,:),'MessageName'));
    Rx_MsgLink = categories(categorical(tmpCell));
    for i = 1:length(Rx_MsgLink)
        cntR = cntR + 1;
        R_SG_APP{cntR,1} = [Channel '_SG_' char(Rx_MsgLink(i))];
    end

    tmpCell = MessageLink_Tx(2:end,strcmp(MessageLink_Tx(1,:),Channel));
    tmpCell(cellfun(@(x) all(ismissing(x)), tmpCell)) = [];
    Tx_MsgLink = categories(categorical(tmpCell));
    for i = 1:length(Tx_MsgLink)
        cntT = cntT + 1;
        P_SG_APP{cntT,1} = [Channel '_SG_' char(Tx_MsgLink(i))];
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

                SignalRouting{cnt,1} = [Channel_source '_SG_' char(SourceMsgName)]; % source CAN4_VCU1
                SignalRouting{cnt,2} = [Channel '_SG_' char(RoutingTable(k,5))]; % target CAN4_VCU1

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

                SignalRouting{cnt,1} = [Channel_source '_SG_' char(SourceMsgName)]; % source CAN4_VCU1
                SignalRouting{cnt,2} = [Channel '_SG_' char(RoutingTable(k,5))]; % target CAN4_VCU1
            else
                continue
            end
        end
    end
end

%% Get Rx and Tx signal routing messages
P_SG_CGW = categories(categorical(SignalRouting(:,2)));
R_SG_CGW = categories(categorical(SignalRouting(:,1)));

% Rework P_SG_CGW
P_SG_Mixed = intersect(P_SG_CGW,P_SG_APP);
for i = 1:length(P_SG_CGW)
    if any(strcmp(char(P_SG_CGW(i)),P_SG_Mixed))

        P_SG_CGW{i} = [extractBefore(char(P_SG_CGW(i)),'_SG_') '_SG_CGW_' extractAfter(char(P_SG_CGW(i)),'_SG_')];

    end
end

%% Edit admin data
% get Composition_Template
fileID = fopen('Composion_Template.arxml');
Template_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Template_arxml{1,1}),1);
for i = 1:length(Template_arxml{1,1})
    tmpCell{i,1} = Template_arxml{1,1}{i,1};
end
Template_arxml = tmpCell;
fclose(fileID);
cd(project_path);

% get Composition_ARXML
cd([project_path '/documents/ARXML_output'])
fileID = fopen('Composition.arxml');
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
h = contains(Target_arxml(:,1),'<SD GID="InputFile">');
tmpCell = Target_arxml(h);
OldString = char(extractBetween(tmpCell,'>','<'));
NewString = MsgLinkFileName;
Target_arxml(h) = strrep(tmpCell,OldString,NewString); % <SD GID="InputFile">CAN_MessageLinkOut</SD>

%% Modify ARPACKAGE name
% Return Composition name
h = contains(Target_arxml(:,1),'_ARPkg</SHORT-NAME>');
tmpCell = Target_arxml(h);
OldString = char(extractBetween(tmpCell,'>','<'));
NewString = 'CompositionARPkgName';
Target_arxml(h) = strrep(tmpCell,OldString,NewString); % <SHORT-NAME>Comp_FDC_ARPkg</SHORT-NAME>

h = contains(Target_arxml(:,1),'_main</SHORT-NAME>');
tmpCell = Target_arxml(h);
OldString = char(extractBetween(tmpCell,'>','<'));
NewString = 'CompositionName';
Target_arxml(h) = strrep(tmpCell,OldString,NewString); % <SHORT-NAME>Comp_FDC_ARPkg</SHORT-NAME>

h = contains(Target_arxml(:,1),'<SHORT-NAME>CompositionARPkgName</SHORT-NAME>');
tmpCell = Target_arxml(h);
OldString = char(extractBetween(tmpCell,'>','<'));
NewString = ['Comp_' TargetECU '_ARPkg'];
Target_arxml(h) = strrep(tmpCell,OldString,NewString); % <SHORT-NAME>Comp_FDC_ARPkg</SHORT-NAME>

h = contains(Target_arxml(:,1),'<SHORT-NAME>CompositionName</SHORT-NAME>');
tmpCell = Target_arxml(h);
OldString = char(extractBetween(tmpCell,'>','<'));
NewString = ['Comp_' TargetECU '_main'];
Target_arxml(h) = strrep(tmpCell,OldString,NewString); % <SHORT-NAME>Comp_FDC_main</SHORT-NAME>

%% Modify R_Ports for Target_arxml
% Erase previous R_Ports
Raw_start = find(contains(Target_arxml,'</R-PORT-PROTOTYPE>'),1,'first') + 1;
Raw_end = find(contains(Target_arxml,'</R-PORT-PROTOTYPE>'),1,'last');
Target_arxml(Raw_start:Raw_end) = [];

Raw_start = find(contains(Target_arxml,'<R-PORT-PROTOTYPE>'));
Raw_end = find(contains(Target_arxml,'</R-PORT-PROTOTYPE>'));
Template = Target_arxml(Raw_start:Raw_end);
R_SG_ALL = union(R_SG_APP,R_SG_CGW);

for i = 1:length(R_SG_ALL)
    tmpCell = Template; % initialize tmpCell

    h = find(contains(tmpCell,'<R-PORT-PROTOTYPE>'))+1;
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['HALR_' erase(char(R_SG_ALL(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>HALR_CAN3_BMS1</SHORT-NAME>

    h = find(contains(tmpCell,'<DATA-ELEMENT-REF DEST="VARIABLE-DATA-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [ '/CANInterface_ARPkg/IF_' char(R_SG_ALL(i)) '/' char(R_SG_ALL(i))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_ABM1/CAN1_SG_ABM1

    h = find(contains(tmpCell,'<CONSTANT-REF DEST="CONSTANT-SPECIFICATION">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' char(extractBefore(R_SG_ALL(i),'_')) '/ConstantSpecification/Init_' char(R_SG_ALL(i))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/ConstantSpecification/Init_CAN1_SG_VCU1

    h = contains(tmpCell,'<REQUIRED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/CANInterface_ARPkg/IF_' char(R_SG_ALL(i))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_ABM1/CAN1_SG_ABM1

    if i == 1 % replace original part
        Raw_start = find(contains(Target_arxml,'<R-PORT-PROTOTYPE>'));
        Raw_end = find(contains(Target_arxml,'</R-PORT-PROTOTYPE>'));
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
    else
        Raw_start = find(contains(Target_arxml,'</R-PORT-PROTOTYPE>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

%% Modify P_Ports for Target_arxml
% Erase previous P_Ports
Raw_start = find(contains(Target_arxml,'</P-PORT-PROTOTYPE>'),1,'first') + 1;
Raw_end = find(contains(Target_arxml,'</P-PORT-PROTOTYPE>'),1,'last');
Target_arxml(Raw_start:Raw_end) = [];

Raw_start = find(contains(Target_arxml,'<P-PORT-PROTOTYPE>'));
Raw_end = find(contains(Target_arxml,'</P-PORT-PROTOTYPE>'));
Template = Target_arxml(Raw_start:Raw_end);
P_SG_ALL = union(P_SG_APP,P_SG_CGW);

for i = 1:length(P_SG_ALL)
    tmpCell = Template; % initialize
    if contains(char(P_SG_ALL(i)),'_CONN1')
        continue
    end
    h = find(contains(tmpCell,'<P-PORT-PROTOTYPE>'))+1;
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['HALP_' erase(char(P_SG_ALL(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>HALP_CAN3_FD_VCU1</SHORT-NAME>

    h = find(contains(tmpCell,'<DATA-ELEMENT-REF DEST="VARIABLE-DATA-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [ '/CANInterface_ARPkg/IF_' char(P_SG_ALL(i)) '/' char(P_SG_ALL(i))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_FD_VCU1/CAN1_SG_FD_VCU1

    h = find(contains(tmpCell,'<CONSTANT-REF DEST="CONSTANT-SPECIFICATION">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/' char(extractBefore(P_SG_ALL(i),'_')) '/ConstantSpecification/Init_' char(P_SG_ALL(i))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/ConstantSpecification/Init_CAN1_SG_VCU1

    h = contains(tmpCell,'<PROVIDED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [ '/CANInterface_ARPkg/IF_' char(P_SG_ALL(i))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_FD_VCU1

    if i == 1 % replace original part
        Raw_start = find(contains(Target_arxml,'<P-PORT-PROTOTYPE>'));
        Raw_end = find(contains(Target_arxml,'</P-PORT-PROTOTYPE>'));
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
    else
        Raw_start = find(contains(Target_arxml,'</P-PORT-PROTOTYPE>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end


%% Modify COMPONENTS
% Components will not change with CMM, maintain in
% Composition_Template.arxml

%% Modify R_Port CONNECTORS
% Replace to template
Raw_start = find(contains(Target_arxml,'<DELEGATION-SW-CONNECTOR>'),1,'first')+1;
Raw_end = find(contains(Target_arxml,'</DELEGATION-SW-CONNECTOR>'),1,'last')-1;
Target_arxml(Raw_start:Raw_end) =[];
Raw_start = find(contains(Target_arxml,'<DELEGATION-SW-CONNECTOR>'),1,'first');
Raw_end = find(contains(Target_arxml,'</DELEGATION-SW-CONNECTOR>'),1,'last');

template_Raw_start = find(contains(Template_arxml,'<DELEGATION-SW-CONNECTOR>'),1,'first') + 1;
template_Raw_end = find(contains(Template_arxml,'</DELEGATION-SW-CONNECTOR>'),1,'last') - 1;
Target_arxml = [Target_arxml(1:Raw_start);Template_arxml(template_Raw_start:template_Raw_end);Target_arxml(Raw_end:end)];


Raw_start = find(contains(Target_arxml,'<DELEGATION-SW-CONNECTOR>'),1,'first');
Raw_end = find(contains(Target_arxml,'</DELEGATION-SW-CONNECTOR>'),1,'first');
Template = Target_arxml(Raw_start:Raw_end);

% Connectors for APP
for i = 1: length(R_SG_APP)
    tmpCell = Template; % initialize tmpCell

    h = find(contains(tmpCell,'<SHORT-NAME>RPortDeligationConnectorName</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['DELConn_' erase(char(R_SG_APP(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>DELConn_CAN3_FD_VCU1</SHORT-NAME>

    h = find(contains(tmpCell,'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/SWC_' TargetECU];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_FDC

    h = find(contains(tmpCell,'<TARGET-R-PORT-REF DEST="R-PORT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/SWC_' TargetECU '_ARPkg/SWC_' TargetECU '_type/R_' erase(char(R_SG_APP(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_FDC_ARPkg/SWC_FDC_type/R_CAN1_FCM3

    h = find(contains(tmpCell,'<OUTER-PORT-REF DEST="R-PORT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/HALR_' erase(char(R_SG_APP(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/HALR_CAN1_FCM3

    if i == 1 % to replace original part
        Raw_start = find(contains(Target_arxml,'<DELEGATION-SW-CONNECTOR>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</DELEGATION-SW-CONNECTOR>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
    else % to add new part
        Raw_start = find(contains(Target_arxml,'<DELEGATION-SW-CONNECTOR>'),1,'last')-1;
        Raw_end = find(contains(Target_arxml,'<DELEGATION-SW-CONNECTOR>'),1,'last');
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

% Connectors for CGW
for i = 1: length(R_SG_CGW)
    tmpCell = Template; % initialize tmpCell

    h = find(contains(tmpCell,'<SHORT-NAME>RPortDeligationConnectorName</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['DELConn_CGW_' erase(char(R_SG_CGW(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>DELConn_CGW_CAN3_FD_VCU1</SHORT-NAME>

    h = find(contains(tmpCell,'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/SWC_CGW'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_CGW

    h = find(contains(tmpCell,'<TARGET-R-PORT-REF DEST="R-PORT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/SWC_CGW_ARPkg/SWC_CGW_type/R_' erase(char(R_SG_CGW(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_FDC_ARPkg/SWC_FDC_type/R_CAN1_FCM3

    h = find(contains(tmpCell,'<OUTER-PORT-REF DEST="R-PORT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/HALR_' erase(char(R_SG_CGW(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/HALR_CAN1_FCM3

    % Update arxml
    Raw_start = find(contains(Target_arxml,'<DELEGATION-SW-CONNECTOR>'),1,'last')-1;
    Raw_end = find(contains(Target_arxml,'<DELEGATION-SW-CONNECTOR>'),1,'last');
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];

end
%% Modify P_Port CONNECTORS
Raw_start = find(contains(Target_arxml,'<DELEGATION-SW-CONNECTOR>'),1,'last');
Raw_end = find(contains(Target_arxml,'</DELEGATION-SW-CONNECTOR>'),1,'last');
Template = Target_arxml(Raw_start:Raw_end);

% Connectors for APP
for i = 1: length(P_SG_APP)
    tmpCell = Template; % initialize tmpCell
    SGName = char(P_SG_APP(i));

    h = find(contains(tmpCell,'<SHORT-NAME>PPortDeligationConnectorName</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['DELConn_' erase(char(P_SG_APP(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>DELConn_CAN3_FD_VCU1</SHORT-NAME>

    if contains(SGName,'_OTA1')
        h = find(contains(tmpCell,'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/SWC_VES'];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_VES

        h = find(contains(tmpCell,'<TARGET-P-PORT-REF DEST="P-PORT-PROTOTYPE">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/SWC_VES_ARPkg/SWC_VES_type/P_' erase(char(P_SG_APP(i)),'_SG')];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_VES_ARPkg/SWC_VES_type/P_CAN2_FD_OTA1
	elseif contains(SGName,'_CONN1')
	 	continue
    else
	    h = find(contains(tmpCell,'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'));
	    OldString = extractBetween(tmpCell(h),'>','<');
	    NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/SWC_' TargetECU];
	    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_FDC
	
	    h = find(contains(tmpCell,'<TARGET-P-PORT-REF DEST="P-PORT-PROTOTYPE">'));
	    OldString = extractBetween(tmpCell(h),'>','<');
	    NewString = ['/SWC_' TargetECU '_ARPkg/SWC_' TargetECU '_type/P_' erase(char(P_SG_APP(i)),'_SG')];
	    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_FDC_ARPkg/SWC_FDC_type/P_CAN3_FD_VCU1
    end

    h = find(contains(tmpCell,'<OUTER-PORT-REF DEST="P-PORT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/HALP_' erase(char(P_SG_APP(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/HALP_CAN3_FD_VCU1

    if i == 1 % to replace original part
        Raw_start = find(contains(Target_arxml,'<DELEGATION-SW-CONNECTOR>'),1,'last');
        Raw_end = find(contains(Target_arxml,'</DELEGATION-SW-CONNECTOR>'),1,'last');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
    else % to add new part
        Raw_start = find(contains(Target_arxml,'</DELEGATION-SW-CONNECTOR>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

% Connectors for CGW
for i = 1: length(P_SG_CGW)
    tmpCell = Template; % initialize tmpCell

    h = find(contains(tmpCell,'<SHORT-NAME>PPortDeligationConnectorName</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['DELConn_CGW_' erase(char(P_SG_CGW(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>DELConn_CAN3_FD_VCU1</SHORT-NAME>

    h = find(contains(tmpCell,'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/SWC_CGW'];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_FDC

    h = find(contains(tmpCell,'<TARGET-P-PORT-REF DEST="P-PORT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/SWC_CGW_ARPkg/SWC_CGW_type/P_' erase(char(P_SG_CGW(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_FDC_ARPkg/SWC_FDC_type/P_CAN3_FD_VCU1

    h = find(contains(tmpCell,'<OUTER-PORT-REF DEST="P-PORT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/HALP_' erase(char(P_SG_CGW(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/HALP_CAN3_FD_VCU1

    % Update arxml
    Raw_start = find(contains(Target_arxml,'</DELEGATION-SW-CONNECTOR>'),1,'last');
    Raw_end = Raw_start + 1;
    Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];

end

%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen('Composition.arxml','w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);

end