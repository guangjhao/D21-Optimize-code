% ===== $Id: FVT_export_businfo.m v2.0 2021-11-02 16:45:16 $ =====
% Outputs: XXX_var.m/XXX_cal.m/XXX_outputs.m/XXX_array.m
% ==================================================

function FVT_export_businfo_modified()
verctrl = 'FVT_export_businfo_v2.0 2021-11-02';
disp(verctrl);
%% Read DD.xlsx
try
    [FileName,PathName] = uigetfile({'*.xls;*.xlsx;', 'Excel Files (*.xls, *.xlsx)'; '*.*', 'All Files (*.*)'}, 'Select DD.xls');
    signal_table = readtable([PathName FileName],'sheet','Signals','PreserveVariableNames',true);
    calibration_table = readtable([PathName FileName],'sheet','Calibrations','PreserveVariableNames',true);
    buildbus(FileName,PathName,signal_table,calibration_table,verctrl)
    disp([FileName ' Done!']);
catch ErrorInfo
    if FileName == 0
        disp('You must selcect the DD.xlsx file.');
    else
        disp(ErrorInfo.message)
    end
end
end

function buildbus(FileName,PathName,signal_table,calibration_table,verctrl)
%% Get sheets name & number
cd (PathName);
[~,sheets] = xlsfinfo(FileName);
numSheets = length(sheets);
%% Get module name
module_name = extractAfter(FileName,"_"); 
module_name = extractBefore(module_name,"."); 
%% Get sig & cal size
[num_signal, ~] = size(signal_table);
[num_calibration, ~] = size(calibration_table);
%% Get cal array/table name & number
if contains(module_name,'_')
    m_str = ['M' extractBefore(module_name,'_')];
    a_str = ['A' extractBefore(module_name,'_') '_'];
    A_str = ['A' extractBefore(module_name,'_')];
else
    m_str = ['M' module_name];
    a_str = ['A' module_name '_'];
    A_str = ['A' module_name];
end
k = 0; l = 0; 
calarry = cell(numSheets, 1);
caltable = cell(numSheets, 1);
for i = 1: numSheets
    Sheets_Names = sheets(i); 
    sheet_name = string(Sheets_Names); 
    chk = extractBefore(sheet_name,"_"); 
    ychk = extractAfter(sheet_name,"_");
    ychk = extractAfter(ychk,"_"); 
    ychk = extractBefore(ychk,"_");    
    if (chk==m_str)&&(ychk=='Y')
        l = l+1; 
        calarry(l,1) = cellstr(sheet_name) ; 
    elseif (chk==m_str)
        k = k+1; 
        caltable(k,1) = cellstr(sheet_name) ; 
    end     
end 
num_caltable = k ; num_calarry = l ; 
%% Get signal internal/output data & number
num_sig_internal = 0; 
num_sig_outputs = 0; 
internal_arry = cell(num_signal, 5);
output_arry = cell(num_signal, 5);
for i = 1:num_signal
    str = table2cell(signal_table(i,1)); 
    str = char(str); 
    str_dir = table2cell(signal_table(i,2)); 
    str_dir = char(str_dir); 
    type = table2cell(signal_table(i,3)); 
    type = char(type);     
    unit = extractAfter(str,"_");
    unit = extractAfter(unit,"_");   
    
    min = table2cell(signal_table(i,4)); 
    max = table2cell(signal_table(i,5)); 
    
    internal_flg = strcmp(str_dir,'internal'); 
    outputs_flg = strcmp(str_dir,'output');
    
    if (isempty(type)==0)&&(internal_flg==1)
        num_sig_internal = num_sig_internal +1;
        internal_arry(num_sig_internal,1) = cellstr(str); 
        internal_arry(num_sig_internal,2) = cellstr(type);
        internal_arry(num_sig_internal,3) = cellstr(unit);        
        internal_arry(num_sig_internal,4) = (min);       
        internal_arry(num_sig_internal,5) = (max);    
    elseif (isempty(type)==0)&&(outputs_flg==1)
        num_sig_outputs = num_sig_outputs +1; 
        output_arry(num_sig_outputs,1) = cellstr(str); 
        output_arry(num_sig_outputs,2) = cellstr(type);
        output_arry(num_sig_outputs,3) = cellstr(unit);           
        output_arry(num_sig_outputs,4) = (min);       
        output_arry(num_sig_outputs,5) = (max);  
    end 
end

for j = length(output_arry(:,1)):-1:1
    if cellfun(@isempty,output_arry(j,1))
        output_arry(j,:) = [];
    end
end

%% Filter Duplicated table definitions
num_M = num_calarry + num_caltable;
M_name = cell(num_M, 1);
extractBetween(str, '_', '_');
for i = 1:num_M
    if i <= num_calarry
        M_name(i, 1) = extractBetween(calarry(i, 1), '_', '_');
    else
        M_name(i, 1) = extractBetween(caltable(i - num_calarry, 1), '_', '_');
    end
end
[uniqueStrings, ~, idx] = unique(M_name);
counts = histcounts(idx, 1:(length(uniqueStrings)+1));
repeatedStrings = uniqueStrings(counts > 1);

if ~isempty(repeatedStrings)
    disp('Duplicated table definitions found.');
    disp(repeatedStrings);
end
%% build XXX_cal.m
cal_file = strcat(lower(module_name),"_cal.m");
fullFileName = char(cal_file) ;
fileID = fopen(fullFileName, 'w');
%% disp('Loading $Id: pmm_cal.m 198 2013-08-29 09:10:12Z haitec $')
%tile1 = 'disp(''Loading $Id:';
%tile2 = 'foxtron $'')';
datetime.setDefaultFormats('default','yyyy-MM-dd HH:mm:ss');

fprintf(fileID,'%%===========$Update Time :  %s $=========\n',datetime);
fprintf(fileID,'disp(''Loading $Id: %s  %s    foxtron $      %s'')',cal_file,datetime,verctrl); 
fprintf(fileID,'\n'); 
fprintf(fileID,'\n');            
%tot_sig = '';
if ~isempty(calibration_table)
str_firstcali = (string(table2cell(calibration_table(1,1))));
end
%% Judge have cali data or not
if (num_calibration~=0)&&(str_firstcali ~="0")
%% Write KXXX cal data
for i = 1:num_calibration
    str = table2cell(calibration_table(i,1));
    str_tablechk = extractBefore(str,"_"); 
    if (str_tablechk~=string(A_str))&&(str_tablechk~=string(m_str))
        str = char(str); 
        defval = string(table2cell(calibration_table(i,8)));
        if (ismissing(defval)==1)
            defval = '0';
        end
        sig = strcat("a2l_cal(","'",str,"',","     ", defval,")",";");
        fprintf(fileID,'%s \n',char(sig));
    elseif str_tablechk == string(A_str) 
        str = char(str);
        if any(strcmp(sheets, str))
            table_array = readtable([PathName FileName], 'sheet', str);
            array = table2array(table_array);
            if array(1) < calibration_table{i, 4}
                disp([str, ' is smaller than lower limit!'])
            elseif array(end) > calibration_table{i,5}
                disp([str, ' is larger than upper limit!'])
            end
            defval = strcat('[', strjoin(string(array), ' '), ']');
            if ~ismissing(defval)
                sig = strcat("a2l_cal(","'",str,"',","     ", defval,")",";");
                fprintf(fileID,'%s \n',char(sig));
            end
        end
    end
end
%% write caltable(XYZ) cal data
for i = 1:num_caltable
   str_var = char(caltable(i,1));
%    if ~contains(str_var,'_Z_'), continue, end
   
   str_var_chk = extractAfter(str_var,"_"); 
   str_var_chk = extractBefore(str_var_chk,"_"); 
   str_var_x = strcat(a_str,str_var_chk,"_X");
   str_var_y = strcat(a_str,str_var_chk,"_Y"); 
   
   table_var = readtable([PathName FileName],'sheet', str_var); 

   arry_var = table2cell(table_var(:,1)); 
   var_y = arry_var(any(cellfun(@(x)any(~isnan(x)),arry_var),2),1);
   arry_var = table2cell(table_var(1,:)); 
   arry_var = transpose(arry_var);
   var_x = arry_var(any(cellfun(@(x)any(~isnan(x)),arry_var),2),1);
   num_x = length(var_x); 
   num_y = length(var_y);
   var_z = table_var(2:num_y+1,2:num_x+1); 
   var_z = table2cell(var_z);
   
   al2_x = strjoin(string(cell2mat((var_x)')));
   al2_y = strjoin(string(cell2mat((var_y)')));
   join_z = join(string(cell2mat(var_z)));
   al2_z = '';
    for j = 1:num_y
        al2_z = strcat(al2_z,";",join_z(j));
    end 
    al2_z = extractAfter(al2_z,";");
      
   sig_z = strcat("a2l_cal(","'",str_var,"',","     ", "[", al2_z,"]",")",";");
   
       for j = 1:num_calibration
        str_mod = table2cell(calibration_table(j,1));
        str_mod = char(str_mod);    
        chk_flg = strncmp(str_var_x, str_mod, length(char(str_var_x)));
         if (chk_flg==1)
              sig_x = strcat("a2l_cal(","'",str_mod,"',","     ","[", al2_x,"]",")",";");
              fprintf(fileID,[char(sig_x)  '\n']);
         end 
       end
       
       for j = 1:num_calibration
        str_mod = table2cell(calibration_table(j,1));
        str_mod = char(str_mod);    
        chk_flg = strncmp(str_var_y, str_mod, length(char(str_var_x)));
         if (chk_flg==1)
              sig_y = strcat("a2l_cal(","'",str_mod,"',","     ","[", al2_y,"]",")",";");
              fprintf(fileID,[char(sig_y)  '\n']);
         end 
       end
       
   fprintf(fileID,[char(sig_z) '\n']); 
end
%%  write calarray(XY) cal data
for i = 1:num_calarry
   str_var = char(calarry(i,1)); 
   str_var_chk = extractAfter(str_var,"_"); 
   str_var_chk = extractBefore(str_var_chk,"_"); 
   str_var_x = strcat(a_str,str_var_chk,"_X");

   table_var = readtable([PathName FileName],'sheet', str_var); 

   var_x = table2cell(table_var(1,2:end)); 
   var_y = table2cell(table_var(2,2:end)); 
   %num_x = length(var_x); 
   %num_y = length(var_y);
   
   al2_x = strjoin(string(cell2mat((var_x)')));
   al2_y = strjoin(string(cell2mat((var_y)')));

   
   sig_z = strcat("a2l_cal(","'",str_var,"',","     ", "[", al2_y,"]",")",";");
       for j = 1:num_calibration
        str_mod = table2cell(calibration_table(j,1));
        str_mod = char(str_mod);    
        chk_flg = strncmp(str_var_x, str_mod, length(char(str_var_x)));
         if (chk_flg==1)
              sig_x = strcat("a2l_cal(","'",str_mod,"',","     ","[", al2_x,"]",")",";");
              fprintf(fileID,[char(sig_x) '\n']);
         end 
       end
   fprintf(fileID,[char(sig_z)  '\n']);
   
end
end
%% Close the file.
fclose(fileID);
% Open the file in the editor.
% save(fullFileName);


%% build XXX_outputs.m
outputsfile = strcat("B",module_name,"_outputs.m"); 
output_filename =char(outputsfile);
outputs = strcat("B",module_name,"_outputs"); 
%couputs = char(outputs);
spe_couputs = strcat("'",outputs,"'");
fileID = fopen(output_filename, 'w');
datetime.setDefaultFormats('default','yyyy-MM-dd HH:mm:ss');
second = strcat("function ",outputs,"(varargin)"); 
%second = strcat("function cellInfo = ",outputs,"(varargin)"); 
datetime.setDefaultFormats('default','yyyy-MM-dd HH:mm:ss');

fprintf(fileID,[char(second) '\n']);
fprintf(fileID,'%%===========$Update Time :  %s $=========\n',datetime);
fprintf(fileID,'disp(''Loading $Id: %s  %s    foxtron $ %s'')\n',outputsfile,datetime,verctrl); 

%tile = ['%%===========$Update Time : ' date '$========='];
fprintf(fileID,'%%===========$Update Time :  %s $=========\n',datetime); 
fprintf(fileID,['%% BXXX_outputs returns a cell array containing bus object information' '\n'...
                '%% Optional Input: ''false'' will suppress a call to Simulink.Bus.cellToObject' '\n'...
                '%% when the m-file is executed.' '\n'...
                '%% The order of bus element attributes is as follows:' '\n'...
                '%% ElementName, Dimensions, DataType, SampleTime, Complexity, SamplingMode' '\n'...
                '\n'...
                'suppressObject = false;' '\n'...
                'if nargin == 1 && islogical(varargin{1}) && varargin{1} == false' '\n'...
                    'suppressObject = true;' '\n'...
                'elseif nargin > 1' '\n'...
                    'error(''Invalid input argument(s) encountered'');' '\n'...
                'end' '\n'...
                '\n'...
                'cellInfo = { ... ' '\n'...
                   '           {... ' '\n'...
                        '    '     char(spe_couputs) ',...'  '\n'...
                        '       '''', ...'  '\n'...
                        '       sprintf(''''), { ... ' '\n'...
                ]);
for i = 1:num_sig_outputs 
    str = output_arry(i,1) ;
    str = string(str); 
    type = output_arry(i,2) ;
    type = string(type); 
    if contains(type, 'Array')
        array_dims = extractAfter(type, 'Array');
        if strcmp(extractBefore(type, 'Array'),'u16')
            sens = strcat("{","'", str ,"' ", " ,", array_dims, ",  'uint16' " , " ,-1" , ", 'real'", " ,'Sample'};...");
        elseif strcmp(extractBefore(type, 'Array'),'u32')
            sens = strcat("{","'", str ,"' ", " ,", array_dims, ",  'uint32' " , " ,-1" , ", 'real'", " ,'Sample'};...");
        elseif strcmp(extractBefore(type, 'Array'),'bool')
            sens = strcat("{","'", str ,"' ", " ,", array_dims, ",  'boolean' " , " ,-1" , ", 'real'", " ,'Sample'};...");
        else
            sens = strcat("{","'", str ,"' ", " ,", array_dims, ",  'uint8' " , " ,-1" , ", 'real'", " ,'Sample'};...");
        end
    else % ~contains(type, 'Array')
        sens = strcat("{","'", str ,"' ", " ,1, ", " '", type ,"' ", " ,-1" , ", 'real'", " ,'Sample'};...");
    end
    fprintf(fileID,[
               '         '  char(sens) '\n'...
            ]);        
end
   
fprintf(fileID,[ '      } ... ' '\n'...
                 '    } ...' '\n'...
                 '  }''; ' '\n'...
                 'if ~suppressObject'  '\n'...
                 '    %% Create bus objects in the MATLAB base workspace' '\n'...
                 '    Simulink.Bus.cellToObject(cellInfo)' '\n'...
                'end' '\n'...
         'end' '\n'...
         ]); 
    
    
% Close the file.
fclose(fileID);
% Open the file in the editor.
% save(output_filename);


%% build xxx_var.m

varfile = strcat(lower(module_name),"_var.m"); 
varfile =char(varfile);
fileID = fopen(varfile, 'w');
datetime.setDefaultFormats('default','yyyy-MM-dd HH:mm:ss');

fprintf(fileID,'%%===========$Update Time :  %s $=========\n',datetime);
fprintf(fileID,'disp(''Loading $Id: %s  %s    foxtron $      %s'')',varfile,datetime,verctrl); 
fprintf(fileID,['\n'...
                '%%%% Calibration Name, Units, Min, Max, Data Type, Comment' '\n'...
                ]); 
str_firstcali = (string(table2cell(calibration_table(1,1))));
if (num_calibration~=0)&&(str_firstcali ~="0")
    for i = 1:num_calibration 
        str = table2cell(calibration_table(i,1)); 
        str = string(str); 
        unit = table2cell(calibration_table(i,6)); 
        unit = string(unit); 
        type = table2cell(calibration_table(i,3)); 
        type = string(type); 
        max = table2cell(calibration_table(i,5)); 
        max = string(max); 
        min = table2cell(calibration_table(i,4)); 
        min = string(min); 

        if contains(type, 'Array')
            continue;
        end

        sens = strcat("a2l_par('", str, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
        fprintf(fileID,[ char(sens)  '\n'...
                     ]);
    end
    
    
        fprintf(fileID,['\n'...
                        '%%%% Monitored Signals'  '\n'...
                        '%% Internal Signals %%' '\n'...
                       ]);
end
if (num_sig_internal~=0)
    for i = 1:num_sig_internal
        str = string(internal_arry(i,1)); 
        unit = string(internal_arry(i,3));
        type = string(internal_arry(i,2));
        max = string(internal_arry(i,5));
        min = string(internal_arry(i,4));

        if contains(type, 'Array')
            continue;
        end

        sens = strcat("a2l_mon('", str, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
        fprintf(fileID,[ char(sens)  '\n'...
                       ]);
    end   
end


fprintf(fileID,['\n'...
                '%%%% Outputs Signals'  '\n'...
                '%% Outputs Signals %%' '\n'...
               ]);    
if (num_sig_outputs~=0)
    for i = 1:num_sig_outputs
        str = string(output_arry(i,1)); 
        unit = string(output_arry(i,3));
        type = string(output_arry(i,2));
        max = string(output_arry(i,5));
        min = string(output_arry(i,4));

        if contains(type, 'Array')
            continue;
        end

        sens = strcat("a2l_mon('", str, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
        fprintf(fileID,[ char(sens)  '\n'...
                       ]);
    end   
end 

% Close the file.
fclose(fileID);
% Open the file in the editor.
% save(varfile);



%% build xxx_array.m

arrayfile = strcat(lower(module_name),"_array.m"); 
arrayfile = char(arrayfile);
fileID = fopen(arrayfile, 'w');
datetime.setDefaultFormats('default','yyyy-MM-dd HH:mm:ss');

fprintf(fileID,'%%===========$Update Time :  %s $=========\n',datetime);
fprintf(fileID,'disp(''Loading $Id: %s  %s    foxtron $      %s'')',arrayfile,datetime,verctrl); 
fprintf(fileID,['\n'...
                '%%%% Array declaration' '\n'...
                ]); 
str_firstcali = (string(table2cell(calibration_table(1,1))));
if (num_calibration~=0)&&(str_firstcali ~="0")
    for i = 1:num_calibration 
        str = table2cell(calibration_table(i,1)); 
        str = string(str); 
        unit = table2cell(calibration_table(i,6)); 
        unit = string(unit); 
        type = table2cell(calibration_table(i,3)); 
        type = string(type); 
        max = table2cell(calibration_table(i,5)); 
        max = string(max); 
        min = table2cell(calibration_table(i,4)); 
        min = string(min); 

        if contains(type, 'Array')
            variable_name = str;
            fprintf(fileID, '\nglobal %s;\n', variable_name);
            fprintf(fileID, '%s = Simulink.Signal;\n', variable_name);
            fprintf(fileID, '%s.CoderInfo.StorageClass = ''ExportedGlobal'';\n', variable_name);
            if strcmp(extractBefore(type, 'Array'),'u16')
                fprintf(fileID, '%s.DataType = ''uint16'';\n', variable_name);
            elseif strcmp(extractBefore(type, 'Array'),'u32')
                fprintf(fileID, '%s.DataType = ''uint32'';\n', variable_name);
            elseif strcmp(extractBefore(type, 'Array'),'bool')
                fprintf(fileID, '%s.DataType = ''boolean'';\n', variable_name);
            else
                fprintf(fileID, '%s.DataType = ''uint8'';\n', variable_name);
            end
        end
    end
    
    
end

if (num_sig_internal~=0)
    for i = 1:num_sig_internal
        str = string(internal_arry(i,1)); 
        unit = string(internal_arry(i,3));
        type = string(internal_arry(i,2));
        max = string(internal_arry(i,5));
        min = string(internal_arry(i,4));

        if contains(type, 'Array')
            variable_name = str;
            fprintf(fileID, '\nglobal %s;\n', variable_name);
            fprintf(fileID, '%s = Simulink.Signal;\n', variable_name);
            fprintf(fileID, '%s.CoderInfo.StorageClass = ''ExportedGlobal'';\n', variable_name);
            if strcmp(extractBefore(type, 'Array'),'u16')
                fprintf(fileID, '%s.DataType = ''uint16'';\n', variable_name);
            elseif strcmp(extractBefore(type, 'Array'),'u32')
                fprintf(fileID, '%s.DataType = ''uint32'';\n', variable_name);
            elseif strcmp(extractBefore(type, 'Array'),'bool')
                fprintf(fileID, '%s.DataType = ''boolean'';\n', variable_name);
            else
                fprintf(fileID, '%s.DataType = ''uint8'';\n', variable_name);
            end
        end        
    end
end

if (num_sig_outputs~=0)
    for i = 1:num_sig_outputs
        str = string(output_arry(i,1)); 
        unit = string(output_arry(i,3));
        type = string(output_arry(i,2));
        max = string(output_arry(i,5));
        min = string(output_arry(i,4));

        if contains(type, 'Array')
            variable_name = str;
            fprintf(fileID, '\nglobal %s;\n', variable_name);
            fprintf(fileID, '%s = Simulink.Signal;\n', variable_name);
            fprintf(fileID, '%s.CoderInfo.StorageClass = ''ExportedGlobal'';\n', variable_name);
            if strcmp(extractBefore(type, 'Array'),'u16')
                fprintf(fileID, '%s.DataType = ''uint16'';\n', variable_name);
            elseif strcmp(extractBefore(type, 'Array'),'u32')
                fprintf(fileID, '%s.DataType = ''uint32'';\n', variable_name);
            elseif strcmp(extractBefore(type, 'Array'),'bool')
                fprintf(fileID, '%s.DataType = ''boolean'';\n', variable_name);
            else
                fprintf(fileID, '%s.DataType = ''uint8'';\n', variable_name);
            end
        end        
    end
end


% Close the file.
fclose(fileID);
% Open the file in the editor.
% save(arrayfile);

% Modify ARXML & APPType.Sldd
project_path = extractBefore(pwd,'\software');
ARXML_Name = Build_SWC_APP(module_name,output_arry,project_path);
% Modify_sldd(ARXML_Name,module_name,project_path);
end

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
    DataType = Arry_outputs(i,2);

    if strcmp(DataType, 'single')
        DataType = cellstr('float32');
    elseif startsWith(DataType, 'int')
        DataType = cellstr(['sint' char(extractAfter(DataType, 'int'))]);
    elseif contains(DataType, 'Array')
        match = regexp(DataType, '^(u8|u16|u32|bool)Array(\d+)$', 'tokens');
        if ~isempty(match)
            DataType = cellstr([match{1,1}{1}{1} '_Array' match{1,1}{1}{2} '_type']);
        end
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
    if contains(Signal_type,'Array') && contains(Signal_type,'bool')
        Signal_type = cellstr('boolean');
    elseif contains(Signal_type,'Array')
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