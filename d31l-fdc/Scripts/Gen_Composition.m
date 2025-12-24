function Gen_Composition(Channel_list,MsgLinkFileName,RoutingTable,DBCSet)
project_path = pwd;
ScriptVersion = '2024.05.15';

%% Read messageLink
cd([project_path '/documents/MessageLink']);
MessageLink_Rx = readcell(MsgLinkFileName,'Sheet','InputSignal');
MessageLink_Tx = readcell(MsgLinkFileName,'Sheet','OutputSignal');

%% Get Tx signal routing messages
tmpCell = {};
cnt = 0;
for n = 1:length(Channel_list)
    Channel = char(Channel_list(n));

    if strcmp(Channel,'CANDr1')
        Raw_start = find(contains(RoutingTable(:,4),'distributed messages, target:CAN_Dr1')) + 2;
    else
        Raw_start = find(contains(RoutingTable(:,4),['distributed messages, target:' Channel])) + 2;
    end

    for i = 1:length(Raw_start)
        Raw_end = Raw_start(i) + find(contains(RoutingTable(Raw_start(i):end,4),'distributed messages, target'),1,'first') - 2;
        if isempty(Raw_end); Raw_end = length(RoutingTable(:,1));end

        for k = Raw_start(i):Raw_end
            if ~strcmp(RoutingTable(k,4),'Invalid')
                cnt = cnt + 1;
                tmpCell(cnt,1) = cellstr([Channel '_SG_' char(RoutingTable(k,5))]);
            else
                continue
            end
        end
    end
end
tmpCell = categories(categorical(tmpCell));
tmpCell(contains(tmpCell,'Invalid')) = [];
Tx_MsgSignalGW = tmpCell;

%% Get Rx signal routing messages
tmpCell = {};
cnt = 0;
for n = 1:length(Channel_list)
    Channel = char(Channel_list(n));
    if strcmp(Channel,'CANDr1')
        Raw_start = find(contains(RoutingTable(:,1),'requested signals, source:CAN_Dr1')) + 2;
    else
        Raw_start = find(contains(RoutingTable(:,1),['requested signals, source:' Channel])) + 2;
    end

    for i = 1:length(Raw_start)
        Raw_end = Raw_start(i) + find(contains(RoutingTable(Raw_start(i):end,1),'requested signals, source'),1,'first') - 2;
        if isempty(Raw_end); Raw_end = length(RoutingTable(:,1));end

        for k = Raw_start(i):Raw_end
            if ~strcmp(RoutingTable(k,1),'Invalid')
                cnt = cnt + 1;
                tmpCell(cnt,1) = cellstr([Channel '_SG_' char(RoutingTable(k,2))]);
            else
                continue
            end
        end
    end
end
tmpCell = categories(categorical(tmpCell));
tmpCell(contains(tmpCell,'Invalid')) = [];
Rx_MsgSignalGW = tmpCell;

%% Get APP related messages
% Signal routing Rx messages will be defined in MsgLink, but Tx not.

P_SG = {};
R_SG = {};
cntR = 0;
cntT = 0;
for k = 1:length(Channel_list)
    Channel = char(Channel_list(k));
    tmpCell = MessageLink_Rx(strcmp(MessageLink_Rx(:,strcmp(MessageLink_Rx(1,:),'CANChannel')),Channel),strcmp(MessageLink_Rx(1,:),'MessageName'));
    Rx_MsgLink = categories(categorical(tmpCell));
    for i = 1:length(Rx_MsgLink)
        cntR = cntR + 1;
        R_SG{cntR,1} = [Channel '_SG_' char(Rx_MsgLink(i))];
    end

    tmpCell = MessageLink_Tx(2:end,strcmp(MessageLink_Tx(1,:),Channel));
    tmpCell(cellfun(@(x) all(ismissing(x)), tmpCell)) = [];
    Tx_MsgLink = categories(categorical(tmpCell));
    for i = 1:length(Tx_MsgLink)
        cntT = cntT + 1;
        P_SG{cntT,1} = [Channel '_SG_' char(Tx_MsgLink(i))];
    end
end

R_SG = union(R_SG,Rx_MsgSignalGW);
P_SG = union(P_SG,Tx_MsgSignalGW);
TargetECU = 'FDC';

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

for i = 1:length(R_SG)
    if i ==1
        Raw_start = find(contains(Target_arxml,'<R-PORT-PROTOTYPE>'));
        Raw_end = find(contains(Target_arxml,'</R-PORT-PROTOTYPE>'));
        tmpCell = Target_arxml(Raw_start:Raw_end); % extract R port description part

        h = find(contains(tmpCell,'<R-PORT-PROTOTYPE>'))+1;
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['HALR_' erase(char(R_SG(i)),'_SG')];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>HALR_CAN3_BMS1</SHORT-NAME>

        h = find(contains(tmpCell,'<NONQUEUED-RECEIVER-COM-SPEC>'))+1;
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = [ '/CANInterface_ARPkg/IF_' char(R_SG(i)) '/' char(R_SG(i))];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_ABM1/CAN1_SG_ABM1

        h = find(contains(tmpCell,'<CONSTANT-REFERENCE>'))+1;
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/' char(extractBefore(R_SG(i),'_')) '/ConstantSpecification/Init_' char(R_SG(i))];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/ConstantSpecification/Init_CAN1_SG_VCU1

        h = contains(tmpCell,'<REQUIRED-INTERFACE-TREF');
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/CANInterface_ARPkg/IF_' char(R_SG(i))];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_ABM1/CAN1_SG_ABM1
        tmpCell2 = tmpCell;
    else
        h = find(contains(tmpCell2,'<R-PORT-PROTOTYPE>'))+1;
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['HALR_' erase(char(R_SG(i)),'_SG')];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>HALR_CAN3_BMS1</SHORT-NAME>

        h = find(contains(tmpCell2,'<NONQUEUED-RECEIVER-COM-SPEC>'))+1;
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = [ '/CANInterface_ARPkg/IF_' char(R_SG(i)) '/' char(R_SG(i))];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_ABM1/CAN1_SG_ABM1

        h = find(contains(tmpCell2,'<CONSTANT-REFERENCE>'))+1;
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' char(extractBefore(R_SG(i),'_')) '/ConstantSpecification/Init_' char(R_SG(i))];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/ConstantSpecification/Init_CAN1_SG_VCU1

        h = contains(tmpCell2,'<REQUIRED-INTERFACE-TREF');
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = [ '/CANInterface_ARPkg/IF_' char(R_SG(i))];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_ABM1/CAN1_SG_ABM1

        tmpCell = [tmpCell(1:end);tmpCell2(1:end)];
    end
end

Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];

%% Modify P_Ports for Target_arxml
% Erase previous P_Ports
Raw_start = find(contains(Target_arxml,'</P-PORT-PROTOTYPE>'),1,'first') + 1;
Raw_end = find(contains(Target_arxml,'</P-PORT-PROTOTYPE>'),1,'last');
Target_arxml(Raw_start:Raw_end) = [];

for i = 1:length(P_SG)
    if i ==1
        Raw_start = find(contains(Target_arxml,'<P-PORT-PROTOTYPE>'));
        Raw_end = find(contains(Target_arxml,'</P-PORT-PROTOTYPE>'));
        tmpCell = Target_arxml(Raw_start:Raw_end); % extract R port description part

        h = find(contains(tmpCell,'<P-PORT-PROTOTYPE>'))+1;
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['HALP_' erase(char(P_SG(i)),'_SG')];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>HALP_CAN3_FD_VCU1</SHORT-NAME>

        h = find(contains(tmpCell,'<NONQUEUED-SENDER-COM-SPEC>'))+1;
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = [ '/CANInterface_ARPkg/IF_' char(P_SG(i)) '/' char(P_SG(i))];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_FD_VCU1/CAN1_SG_FD_VCU1

        h = find(contains(tmpCell,'<CONSTANT-REFERENCE>'))+1;
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/' char(extractBefore(P_SG(i),'_')) '/ConstantSpecification/Init_' char(P_SG(i))];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN1/ConstantSpecification/Init_CAN1_SG_VCU1

        h = contains(tmpCell,'<PROVIDED-INTERFACE-TREF');
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = [ '/CANInterface_ARPkg/IF_' char(P_SG(i))];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_FD_VCU1
        tmpCell2 = tmpCell;
    else
        h = find(contains(tmpCell2,'<P-PORT-PROTOTYPE>'))+1;
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['HALP_' erase(char(P_SG(i)),'_SG')];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % <SHORT-NAME>HALP_CAN3_FD_VCU1</SHORT-NAME>

        h = find(contains(tmpCell2,'<NONQUEUED-SENDER-COM-SPEC>'))+1;
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = [ '/CANInterface_ARPkg/IF_' char(P_SG(i)) '/' char(P_SG(i))];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_FD_VCU1/CAN1_SG_FD_VCU1

        h = find(contains(tmpCell2,'<CONSTANT-REFERENCE>'))+1;
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = ['/' char(extractBefore(P_SG(i),'_')) '/ConstantSpecification/Init_' char(P_SG(i))];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CAN1/ConstantSpecification/Init_CAN1_SG_VCU1

        h = contains(tmpCell2,'<PROVIDED-INTERFACE-TREF');
        OldString = extractBetween(tmpCell2(h),'>','<');
        NewString = [ '/CANInterface_ARPkg/IF_' char(P_SG(i))];
        tmpCell2(h) = strrep(tmpCell2(h),OldString,NewString); % /CANInterface_ARPkg/IF_CAN1_SG_FD_VCU1

        tmpCell = [tmpCell(1:end);tmpCell2(1:end)];
    end
end

Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];

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

for i = 1: length(R_SG)
    tmpCell = Template; % initialize tmpCell

    h = find(contains(tmpCell,'<SHORT-NAME>RPortDeligationConnectorName</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['DELConn_' erase(char(R_SG(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>DELConn_CAN3_FD_VCU1</SHORT-NAME>

    h = find(contains(tmpCell,'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/SWC_' TargetECU];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_FDC

    h = find(contains(tmpCell,'<TARGET-R-PORT-REF DEST="R-PORT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/SWC_' TargetECU '_ARPkg/SWC_' TargetECU '_type/R_' erase(char(R_SG(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_FDC_ARPkg/SWC_FDC_type/R_CAN1_FCM3

    h = find(contains(tmpCell,'<OUTER-PORT-REF DEST="R-PORT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/HALR_' erase(char(R_SG(i)),'_SG')];
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

%% Modify P_Port CONNECTORS
Raw_start = find(contains(Target_arxml,'<DELEGATION-SW-CONNECTOR>'),1,'last');
Raw_end = find(contains(Target_arxml,'</DELEGATION-SW-CONNECTOR>'),1,'last');
Template = Target_arxml(Raw_start:Raw_end);

for i = 1: length(P_SG)
    tmpCell = Template; % initialize tmpCell
    SGName = char(P_SG(i));

    h = find(contains(tmpCell,'<SHORT-NAME>PPortDeligationConnectorName</SHORT-NAME>'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['DELConn_' erase(char(P_SG(i)),'_SG')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>DELConn_CAN3_FD_VCU1</SHORT-NAME>

    if contains(SGName,'_OTA1')
        h = find(contains(tmpCell,'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/SWC_VES'];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_VES

        h = find(contains(tmpCell,'<TARGET-P-PORT-REF DEST="P-PORT-PROTOTYPE">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/SWC_VES_ARPkg/SWC_VES_type/P_' erase(char(P_SG(i)),'_SG')];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_VES_ARPkg/SWC_VES_type/P_CAN2_FD_OTA1

    else
        h = find(contains(tmpCell,'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/SWC_' TargetECU];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_FDC

        h = find(contains(tmpCell,'<TARGET-P-PORT-REF DEST="P-PORT-PROTOTYPE">'));
        OldString = extractBetween(tmpCell(h),'>','<');
        NewString = ['/SWC_' TargetECU '_ARPkg/SWC_' TargetECU '_type/P_' erase(char(P_SG(i)),'_SG')];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_FDC_ARPkg/SWC_FDC_type/P_CAN3_FD_VCU1
    end

    h = find(contains(tmpCell,'<OUTER-PORT-REF DEST="P-PORT-PROTOTYPE">'));
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/HALP_' erase(char(P_SG(i)),'_SG')];
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

%% Modify assembly sw connector
% Raw_start = find(contains(Target_arxml,'<? Halin assembly connector start ?>'),1,'first')+1;
% Raw_end = find(contains(Target_arxml,'<? Halin assembly connector end ?>'),1,'first')-1;
% tmpCell = Target_arxml(Raw_start:Raw_end);
%
% h = contains(tmpCell(:,1),'<SHORT-NAME>HalinAssemblyConnectorName</SHORT-NAME>');
% OldString = char(extractBetween(tmpCell(h),'>','<'));
% NewString = 'ASBConn_HALINCDD';
% tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>SWC_HALINCDD</SHORT-NAME>
%
% h = find(contains(tmpCell(:,1),'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'),1,"first");
% OldString = char(extractBetween(tmpCell(h),'>','<'));
% NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/SWC_HALINCDD'];
% tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_HALINCDD
%
% h = find(contains(tmpCell(:,1),'<TARGET-P-PORT-REF DEST="P-PORT-PROTOTYPE">'),1,"first");
% OldString = char(extractBetween(tmpCell(h),'>','<'));
% NewString = '/SWC_HALINCDD_ARPkg/SWC_HALINCDD_type/P_HALINCDD';
% tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_HALINCDD_ARPkg/SWC_HALINCDD_type/P_HALINCDD
%
% h = find(contains(tmpCell(:,1),'<CONTEXT-COMPONENT-REF DEST="SW-COMPONENT-PROTOTYPE">'),1,"last");
% OldString = char(extractBetween(tmpCell(h),'>','<'));
% NewString = ['/Comp_' TargetECU '_ARPkg/Comp_' TargetECU '_main/SWC_' TargetECU];
% tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /Comp_FDC_ARPkg/Comp_FDC_main/SWC_FDC
%
% h = find(contains(tmpCell(:,1),'<TARGET-R-PORT-REF DEST="R-PORT-PROTOTYPE">'),1,"last");
% OldString = char(extractBetween(tmpCell(h),'>','<'));
% NewString = '/SWC_FDC_ARPkg/SWC_FDC_type/R_HALINCDD';
% tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /SWC_FDC_ARPkg/SWC_FDC_type/R_HALINCDD
%
% Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];

%% Remove <? raws
% RedundantRows = find(contains(Target_arxml,'<?'));
% for i = length(RedundantRows):-1:2
%     Target_arxml(RedundantRows(i)) = [];
% end

%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen('Composition.arxml','w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);

end