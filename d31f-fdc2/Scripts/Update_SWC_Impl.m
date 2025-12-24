function Update_SWC_Impl()
project_path = pwd;

q = questdlg({'Check the following conditions:','1. Run project_start?',...
    '2. Current folder arch?','3. All app layer DD files finished?'}, ...
	'Initial check', 'Yes','No','Yes');
if ~contains(q, 'Yes')
    return
end

%% Select SWC_APP
arch_Path = [project_path '\software\sw_development\arch'];
app_dir = [arch_Path '\app'];
app_dir = char(app_dir);
pro_app_dir = dir(app_dir);
pro_app_dir = struct2table(pro_app_dir);
pro_app_dir = table2cell(pro_app_dir);
num_pro_app_dir = length(pro_app_dir(:,1));

hal_dir = [arch_Path '\hal'];
hal_dir = char(hal_dir);
pro_hal_dir = dir(hal_dir);
pro_hal_dir = struct2table(pro_hal_dir);
pro_hal_dir = table2cell(pro_hal_dir);
num_pro_hal_dir = length(pro_hal_dir(:,1));

inp_dir = [arch_Path '\inp'];
inp_dir = char(inp_dir);
pro_inp_dir = dir(inp_dir);
pro_inp_dir = struct2table(pro_inp_dir);
pro_inp_dir = table2cell(pro_inp_dir);
num_pro_inp_dir = length(pro_inp_dir(:,1));

outp_dir = arch_Path;
outp_dir = char(outp_dir);
pro_outp_dir = dir(outp_dir);
pro_outp_dir = struct2table(pro_outp_dir);
pro_outp_dir = table2cell(pro_outp_dir);
num_pro_outp_dir= length(pro_outp_dir(:,1));

for i = 1:num_pro_outp_dir
    str = pro_outp_dir(i,1);
    if ~strcmp(str,'outp')
        pro_outp_dir(i,1) = {'.'};
    end
end

pro_all_dir = [pro_app_dir;pro_hal_dir;pro_inp_dir;pro_outp_dir];
num_pro_all_dir = num_pro_app_dir + num_pro_hal_dir + num_pro_inp_dir + num_pro_outp_dir;

ref_module = {''};
k=0;
for i = 1:num_pro_all_dir
    str = pro_all_dir(i,1);
    isdir = cell2mat(pro_all_dir(i,5));
    if isdir && ~contains(str,'.') && ~contains(str,'halout') && ~contains(str,'can')
        k =k+1;
        ref_module(k,1) = str;
    end 
end 
[indx, q] = listdlg('PromptString',{'Select the module.'},'ListSize',[200,500],'ListString',ref_module);
if q == 0
    return
end

target_module = cell(length(indx));
for i = 1:length(indx)
    target_module(i) = ref_module(indx(i));
end

num_module = length(target_module); 
n=0;
for i = 1:num_module
    str = char(target_module(i));
    upper_str = upper(str); 
    file = strcat('DD_',upper_str); 
    path = char(pro_all_dir(strcmp(pro_all_dir(:,1),str),2));
    path = strcat([path '\' str '\']);
    data = readtable([path file],'sheet','Signals','PreserveVariableNames',true);
    [data_m,~] = size(data);
    data_cell = table2cell(data);
    k =0;
    restore_data = {};
    for j = 1:data_m
        str = data_cell(j,1);
        str_dir = data_cell(j,2);
        if contains(str_dir, 'output')
            k = k+1; 
            restore_data(k,1) = str;
            restore_data(k,2) = str_dir;
            restore_data(k,3) = data_cell(j,3);
            restore_data(k,4) = data_cell(j,4);            
            restore_data(k,5) = data_cell(j,5);
            restore_data(k,6) = data_cell(j,6);
            restore_data(k,7) = cellstr(upper_str);
        end
    end
    Module = char(extractAfter(file,'DD_'));
    ARXML_Name = Build_SWC_APP(Module,restore_data,project_path);
%     Modify_sldd(ARXML_Name,Module,project_path)
end

%%
function ARXML_Name = Build_SWC_APP(Module,Arry_outputs,project_path)
%% Get FVT_APP arxml
cd([project_path '/documents/ARXML_output'])
if contains(Module,'HAL_CAN')
    ARXML_Name = 'HALIN';
elseif contains(Module,'INP_')
    ARXML_Name = 'INP';
elseif contains(Module,'HAL_')
    ARXML_Name = 'HALIN_CDD';
elseif strcmp(Module,'OUTP') || strcmp(Module,'HALOUT')
    ARXML_Name = Module;
else
    ARXML_Name = 'APP';
end
fileID = fopen(['FVT_' ARXML_Name '.arxml']);
FVTAPP_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(FVTAPP_arxml{1,1}),1);
for i = 1:length(FVTAPP_arxml{1,1})
    tmpCell{i,1} = FVTAPP_arxml{1,1}{i,1};
end
FVTAPP_arxml = tmpCell;
fclose(fileID);
cd(project_path);

%% Modify <IMPLEMENTATION-DATA-TYPE-ELEMENT>
h = find(contains(FVTAPP_arxml(:,1),['<SHORT-NAME>B' Module  '_outputs</SHORT-NAME>']),1,'first');
ECUC_start_array = find(contains(FVTAPP_arxml(:,1),'<IMPLEMENTATION-DATA-TYPE-ELEMENT>'));
ECUC_end_array = find(contains(FVTAPP_arxml(:,1),'</IMPLEMENTATION-DATA-TYPE-ELEMENT>'));

ECUC_start = min(ECUC_start_array(ECUC_start_array>h));
ECUC_end = min(ECUC_end_array(ECUC_end_array>h));

% 
for i = 1:length(Arry_outputs(:,1))
    tmpCell = FVTAPP_arxml(ECUC_start:ECUC_end);
    SignalName = Arry_outputs(i,1);
    DataType = Arry_outputs(i,3);

    if strcmp(DataType,'single')
        DataType = cellstr('float32');
    elseif startsWith(DataType,'int')
        DataType = cellstr(['sint' char(extractAfter(DataType,'int'))]); 
    elseif strcmp(DataType,'Array16') || strcmp(DataType,'u8Array16')
        DataType = cellstr('u8_Array16_type');
    elseif strcmp(DataType,'Array8') || strcmp(DataType,'u8Array8')
        DataType = cellstr('u8_Array8_type');
    elseif strcmp(DataType,'u16Array8')
        DataType = cellstr('u16_Array8_type');
    elseif strcmp(DataType,'u32Array8')
        DataType = cellstr('u32_Array8_type');
    elseif strcmp(DataType,'u8Array17')
        DataType = cellstr('u8_Array17_type');
    elseif strcmp(DataType,'u8Array20')
        DataType = cellstr('u8_Array20_type');
    elseif strcmp(DataType,'u8Array12')
        DataType = cellstr('u8_Array12_type');
    end

    % Signal Name
    h = find(contains(tmpCell,'<SHORT-NAME>V'));
    OldString = extractBetween(tmpCell(h),'<SHORT-NAME>','</SHORT-NAME>');
    NewString = SignalName;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % DataType
    h = find(contains(tmpCell,'<IMPLEMENTATION-DATA-TYPE-REF DEST="'));
    OldString = extractBetween(tmpCell(h),'/ImplementationDataTypes/','</IMPLEMENTATION-DATA-TYPE-REF>');
    NewString = DataType;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);

    if i == 1
        tmpCell2 = tmpCell;
    else 
        tmpCell2 = [tmpCell2;tmpCell];
    end
end

% Replace original CanIfInitHohCfg(CanIfHrhCfg & CanIfHthCfg) part
h = find(contains(FVTAPP_arxml(:,1),['<SHORT-NAME>B' Module  '_outputs</SHORT-NAME>']),1,'first');
ECUC_start_array = find(contains(FVTAPP_arxml(:,1),'<SUB-ELEMENTS>'));
ECUC_end_array = find(contains(FVTAPP_arxml(:,1),'</SUB-ELEMENTS>'));

ECUC_start = min(ECUC_start_array(ECUC_start_array>h));
ECUC_end = min(ECUC_end_array(ECUC_end_array>h));

FVTAPP_arxml = [FVTAPP_arxml(1:ECUC_start);tmpCell2;FVTAPP_arxml(ECUC_end:end)];

%% Output FVT_APP_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen(['FVT_' ARXML_Name '.arxml'],'w');
for i = 1:length(FVTAPP_arxml(:,1))
    fprintf(fileID,'%s\n',char(FVTAPP_arxml(i,1)));
end
fclose(fileID);
end

function Modify_sldd(ARXML_Name,Module,project_path)
evalin( 'base', 'clear DT_*' )
% Select ARXML
fileID = fopen(['FVT_' ARXML_Name '.arxml']);
FVTAPP_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(FVTAPP_arxml{1,1}),1);
for i = 1:length(FVTAPP_arxml{1,1})
    tmpCell{i,1} = FVTAPP_arxml{1,1}{i,1};
end
FVTAPP_arxml = tmpCell;
fclose(fileID);
cd(project_path);

% Select <IMPLEMENTATION-DATA-TYPE-ELEMENT>
h = find(contains(FVTAPP_arxml(:,1),['<SHORT-NAME>DT_B' Module  '_outputs</SHORT-NAME>']));
ECUC_start_array = find(contains(FVTAPP_arxml(:,1),'<SUB-ELEMENTS>'));
ECUC_end_array = find(contains(FVTAPP_arxml(:,1),'</SUB-ELEMENTS>'));

ECUC_start = min(ECUC_start_array(ECUC_start_array>h));
ECUC_end = min(ECUC_end_array(ECUC_end_array>h));

tmpCell = FVTAPP_arxml(ECUC_start:ECUC_end);
h = find(contains(tmpCell,['<SHORT-NAME>V']));
h1 = find(contains(tmpCell,'DEST="IMPLEMENTATION-DATA-TYPE">'));

if length(h) ~= length(h1)
    error('ARXML error')
end

Signal_table = cell(length(h),3);
for i = 1:length(h)
    Signal_name = extractBetween(tmpCell(h(i)),'>','<');
    Signal_type = extractBetween(tmpCell(h1(i)),'/ImplementationDataTypes/','</IMPLEMENTATION-DATA-TYPE-REF>');
    Signal_dimension = {[1 1]};
    if contains(Signal_type,'Array')
        Signal_dimension = {str2double(extractBetween(Signal_type,'Array','_'))};
        date_type = extractBetween(Signal_type,'u','_Array');
        Signal_type = {['uint' char(date_type)]};
    elseif strcmp(Signal_type,'float32')
        Signal_type = cellstr('single');
    elseif startsWith(Signal_type,'sint')
        Signal_type = cellstr(['int' char(extractAfter(Signal_type,'sint'))]);
    end
    Signal_table(i,1) = Signal_name;
    Signal_table(i,2) = Signal_type;
    Signal_table(i,3) = Signal_dimension;
end

cd([project_path '\software\sw_development\arch']);
Simulink.data.dictionary.closeAll
dictObj = Simulink.data.dictionary.open('APPTypes.sldd');
dataSec = dictObj.getSection('Design Data');
entryObj = find(dataSec, 'Name', ['DT_B' Module  '_outputs']);
busObj = getValue(entryObj);
elems = busObj.Elements;

% Delete all signal in Buselement
% elems(1:end) = [];

% Create new BusElement
% newElem = Simulink.BusElement;

for n = 1:length(Signal_table(:,1))
    elems(n).Name = char(Signal_table(n,1));
    elems(n).DataType = char(Signal_table(n,2));
    elems(n).Dimensions = cell2mat(Signal_table(n,3));
end
if length(Signal_table(:,1))<length(elems)
    elems(length(Signal_table(:,1))+1:end) = [];
end
busObj.Elements = elems;

setValue(entryObj, busObj);
saveChanges(dictObj);
close(dictObj);

dictObj = Simulink.data.dictionary.open('APPTypes.sldd');
hDesignData = dictObj.getSection('Global');
childNamesList = hDesignData.evalin('who');
for n = 1:numel(childNamesList)
    if strcmp(childNamesList{n},'AppModeRequestType')
        continue
    end
    hEntry = hDesignData.getEntry(childNamesList{n});
    assignin('base', hEntry.Name, hEntry.getValue);
end
Simulink.data.dictionary.closeAll
end
cd(project_path);
end