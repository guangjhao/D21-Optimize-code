function Gen_CANInterface(Channel_list,Channel_list_LIN)
project_path = pwd;
ScriptVersion = '2024.06.05';

%% Get informations from source arxml

cnt = 0;
DTCell = {};

% Get CAN related info
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

    % Get all ImplementationDataTypes
    for k = 1:length(Source_arxml)
        if contains(Source_arxml(k),['<SHORT-NAME>DT_' Channel '_'])
            cnt = cnt + 1;
            DTCell(cnt,1) = extractBetween(Source_arxml(k),'>','<');
        end
    end
    fclose(fileID);
    cd(project_path);
end

% Get LIN related info
for i = 1:length(Channel_list_LIN)
    Channel = char(Channel_list_LIN(i));
    cd([project_path '/documents/ARXML_output'])
    fileID = fopen([Channel '.arxml']);
    Source_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
    tmpCell = cell(length(Source_arxml{1,1}),1);
    for j = 1:length(Source_arxml{1,1})
        tmpCell{j,1} = Source_arxml{1,1}{j,1};
    end
    Source_arxml = tmpCell;

    % Get all frame ports
    for k = 1:length(Source_arxml)
        if contains(Source_arxml(k),['<SHORT-NAME>DT_' Channel '_'])
            cnt = cnt + 1;
            DTCell(cnt,1) = extractBetween(Source_arxml(k),'>','<');
        end
    end
    fclose(fileID);
    cd(project_path);
end

%% Edit admin data
% get APPInterface_Template
fileID = fopen('CANInterface_Template.arxml');
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
Target_arxml(h) = [];

%% Modify S-R interface
Raw_start = find(contains(Target_arxml,'<SENDER-RECEIVER-INTERFACE>'));
Raw_end = find(contains(Target_arxml,'</SENDER-RECEIVER-INTERFACE>'));
Template = Target_arxml(Raw_start:Raw_end); % extract interface description part
FirstMessage = boolean(1);

for i = 1:length(DTCell)
    tmpCell = Template; % initialize temCell
    Channel = extractBetween(char(DTCell(i)),'DT_','_');
    Channel = char(Channel);

    h = find(contains(tmpCell,'<SENDER-RECEIVER-INTERFACE>'))+1;
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = ['IF_' extractAfter(char(DTCell(i)),'DT_')];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>IF_CAN3_BMS1</SHORT-NAME

    h = find(contains(tmpCell,'<VARIABLE-DATA-PROTOTYPE>'))+1;
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = extractAfter(char(DTCell(i)),'DT_');
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % <SHORT-NAME>CAN3_SG_BMS1</SHORT-NAME>

    h = contains(tmpCell,'<TYPE-TREF DEST');
    OldString = extractBetween(tmpCell(h),'>','<');
    NewString = [ '/' Channel '/ImplementationDataTypes/' char(DTCell(i))];
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString); % /CAN4/ImplementationDataTypes/DT_CAN4_SG_BMS6

    if FirstMessage % to replace original part
        Raw_start = find(contains(Target_arxml,'<SENDER-RECEIVER-INTERFACE>'),1,'first');
        Raw_end = find(contains(Target_arxml,'</SENDER-RECEIVER-INTERFACE>'),1,'first');
        Target_arxml = [Target_arxml(1:Raw_start-1);tmpCell(1:end);Target_arxml(Raw_end+1:end)];
        FirstMessage = boolean(0);
    else % to add new part
        Raw_start = find(contains(Target_arxml,'</SENDER-RECEIVER-INTERFACE>'),1,'last');
        Raw_end = Raw_start + 1;
        Target_arxml = [Target_arxml(1:Raw_start);tmpCell(1:end);Target_arxml(Raw_end:end)];
    end
end

%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen( 'CANInterface.arxml','w');
for i = 1:length(Target_arxml(:,1))
    fprintf(fileID,'%s\n',char(Target_arxml(i,1)));
end
fclose(fileID);

%%
end