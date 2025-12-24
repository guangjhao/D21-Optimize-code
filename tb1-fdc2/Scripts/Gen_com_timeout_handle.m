function Gen_com_timeout_handle
project_path = pwd;
ScriptVersion = '2024.07.08';

%% Get composition R port
% For main SWC
cnt = 0;
Port_SWC = {};

cd([project_path '/documents/ARXML_output'])
fileID = fopen('Composition.arxml');
Source_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Source_arxml{1,1}),1);
for j = 1:length(Source_arxml{1,1})
    tmpCell{j,1} = Source_arxml{1,1}{j,1};
end

% Remove Admin data
Source_arxml = tmpCell;
if any(find(contains(Source_arxml,'<ADMIN-DATA>')))
    h = find(contains(Source_arxml,'<ADMIN-DATA>'));
    for i = 1:length(h)
        Raw_start = find(contains(Source_arxml,'<ADMIN-DATA>'),1,'first');
        Raw_end = find(contains(Source_arxml,'</ADMIN-DATA>'),1,'first');
        Source_arxml(Raw_start:Raw_end) = [];
    end
end


for k = 1:length(Source_arxml)
    if strcmp(strip(char(Source_arxml(k)),'left'),'<R-PORT-PROTOTYPE>')&& contains(Source_arxml(k+4),'CANInterface_ARPkg')
        cnt = cnt + 1;
        Port_SWC(cnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>' ,'</SHORT-NAME>');
    end
end

%% Get SWC_FDC R port
% For main SWC
cnt = 0;
Port_SWCFDC = {};

cd([project_path '/documents/ARXML_output'])
fileID = fopen('SWC_FDC.arxml');
Source_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Source_arxml{1,1}),1);
for j = 1:length(Source_arxml{1,1})
    tmpCell{j,1} = Source_arxml{1,1}{j,1};
end

% Remove Admin data
Source_arxml = tmpCell;
if any(find(contains(Source_arxml,'<ADMIN-DATA>')))
    h = find(contains(Source_arxml,'<ADMIN-DATA>'));
    for i = 1:length(h)
        Raw_start = find(contains(Source_arxml,'<ADMIN-DATA>'),1,'first');
        Raw_end = find(contains(Source_arxml,'</ADMIN-DATA>'),1,'first');
        Source_arxml(Raw_start:Raw_end) = [];
    end
end


for k = 1:length(Source_arxml)
    if strcmp(strip(char(Source_arxml(k)),'left'),'<R-PORT-PROTOTYPE>') && contains(Source_arxml(k+2),'CANInterface_ARPkg')
        cnt = cnt + 1;
        Port_SWCFDC(cnt,1) = extractBetween(Source_arxml(k+1),'<SHORT-NAME>R_' ,'</SHORT-NAME>');
    end
end

%% For com_timeout_Template.c
cd([project_path '/documents/Templates'])
fileID = fopen('com_timeout_Template.c');
Template_c = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Template_c{1,1}),1);
for j = 1:length(Template_c{1,1})
    tmpCell{j,1} = Template_c{1,1}{j,1};
end

% FUNC(void, COM_APPL_CODE)
Target_c = tmpCell;
Raw_start = find(contains(tmpCell,'_ComNotification(void)'),1,'last')-1;
Raw_end = find(contains(tmpCell,' = true'),1,'last') + 1;
tmpCell = tmpCell(Raw_start:Raw_end);
Firstport = boolean(1);

for i =1:length(Port_SWC)
    MsgName = char(extractAfter(Port_SWC(i),'HALR_'));
    SG_MsgName = [extractBefore(MsgName,'_') '_SG_' extractAfter(MsgName,'_')];
    
    % FUNC(void, COM_APPL_CODE) CAN1_SG_ABM1_ComNotification(void)
    
    h = find(contains(tmpCell,'_ComNotification(void)'),1,'last');
    OldString = extractBetween(tmpCell(h),') ','_ComNotification(void)');
    NewString = SG_MsgName;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % fvt_rtsg_notification_handler(RTSG_CANx_xxx, __FUNCTION__);
    h = find(contains(tmpCell,'fvt_rtsg_notification_handler'),1,'last');
    OldString = extractBetween(tmpCell(h),'RTSG_',');');
    NewString = SG_MsgName;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % VHAL_CANMsgInvalidxxx_flg = false
    h = find(contains(tmpCell,' = false'),1,'last');
    OldString = extractBetween(tmpCell(h),'VHAL_CANMsgInvalid','_flg');
    NewString = erase(extractAfter(MsgName,'_'),'_');
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % FUNC(void, COM_APPL_CODE) CAN1_SG_ABM1_ComTimeoutNotification(void)
    h = find(contains(tmpCell,'_ComTimeoutNotification(void)'),1,'last');
    OldString = extractBetween(tmpCell(h),') ','_ComTimeoutNotification(void)');
    NewString = SG_MsgName;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    % fvt_rtsg_timeout_handler(RTSG_CANx_xxx, __FUNCTION__);
    h = find(contains(tmpCell,'fvt_rtsg_timeout_handler'),1,'last');
    OldString = extractBetween(tmpCell(h),'RTSG_',');');
    NewString = SG_MsgName;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % VHAL_CANMsgInvalidxxx_flg = false
    h = find(contains(tmpCell,' = true'),1,'last');
    OldString = extractBetween(tmpCell(h),'VHAL_CANMsgInvalid','_flg');
    NewString = erase(extractAfter(MsgName,'_'),'_');
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    if Firstport
        Target_c = [Target_c(1:Raw_start);tmpCell(1:end);Target_c(Raw_end+1:end)];
        Firstport = boolean(0);
    else
        Raw_start = find(contains(Target_c,';'),1,'last') + 1;
        Raw_end = Raw_start + 1;
        Target_c = [Target_c(1:Raw_start);tmpCell(1:end);Target_c(Raw_end:end)];
    end
    
    % Remove VHAL_CANMsgInvalidxxx_flg if only in SWC_CGW_type

    if ~any(strcmp(Port_SWCFDC,MsgName))
        h = contains(Target_c,['VHAL_CANMsgInvalid' erase(extractAfter(MsgName,'_'),'_') '_flg' ]);
        Target_c(h) = [];
    end
end

%% Output com_timeout_handle.c
cd([project_path '/documents/'])
fileID = fopen('com_timeout_handle.c','w');
for i = 1:length(Target_c(:,1))
    fprintf(fileID,'%s\n',char(Target_c(i,1)));
end
fclose(fileID);

%% For com_timeout_Template.h
cd([project_path '/documents/Templates'])
fileID = fopen('com_timeout_Template.h');
Template_c = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Template_c{1,1}),1);
for j = 1:length(Template_c{1,1})
    tmpCell{j,1} = Template_c{1,1}{j,1};
end
Target_h = tmpCell;

% RTSG_CAN1_SG_ABM1
h = find(contains(tmpCell,'RTSG_CAN1_SG_ABM1'));
MsgName = string(extractAfter(Port_SWC,'HALR_'));
SG_MsgName = extractBefore(MsgName,'_') +  '_SG_' + extractAfter(MsgName,'_');
tmpCell = cellstr('RTSG_' + string(SG_MsgName) + ',');

OldString = 'RTSG_CAN1_SG_ABM1';
NewString = tmpCell;
tmpCell = strrep(Target_h(h),OldString,NewString);

Target_h = [Target_h(1:h-1);tmpCell(1:end);Target_h(h+1:end)];
%% Output com_timeout_handle.h
cd([project_path '/documents/'])
fileID = fopen('com_timeout_handle.h','w');
for i = 1:length(Target_h(:,1))
    fprintf(fileID,'%s\n',char(Target_h(i,1)));
end
fclose(fileID);

end