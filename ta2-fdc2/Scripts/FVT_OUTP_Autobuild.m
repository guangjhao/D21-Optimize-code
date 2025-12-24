function FVT_OUTP_Autobuild()
%% Initial settings
ref_car_model = {'ta2-fdc2'};
car_model = ref_car_model{1};

arch_Path = pwd;
if ~contains(arch_Path, 'arch'), error('current folder is not under arch'), end
project_path = extractBefore(arch_Path,'\software');
library_path = [project_path '/library'];
Scripts_path = [project_path '/Scripts'];

addpath(library_path);
addpath(Scripts_path)
addpath([project_path '/documents/FVT_API']);
addpath(arch_Path);

q = questdlg({'Check the following conditions:', '1. Current folder arch?', ...
    '2. All app layer DD files finished?'}, 'Initial check', 'Yes','No','Yes');
if ~contains(q, 'Yes')
    return
end
% arch_Path = pwd;
app_dir = [arch_Path '\app'];
app_dir = char(app_dir);
pro_app_dir = dir(app_dir);
pro_app_dir = struct2table(pro_app_dir);
pro_app_dir = table2cell(pro_app_dir);
num_pro_app_dir = length(pro_app_dir(:,1));
ref_module = {''};
k=0;
for i = 1:num_pro_app_dir
    str = pro_app_dir(i,1); 
    num_str = strlength(str); 
    if ((num_str==3)||(num_str==4))
        k =k+1;
        ref_module(k,1) = str;
    end 
end 
[indx, ~] = listdlg('PromptString',{'Select the module.'},'ListSize',[200,150],'ListString',ref_module);

target_module = cell(length(indx));
for i = 1:length(indx)
    target_module(i) = ref_module(indx(i));
end

num_module = length(target_module); 
n=0;
for i = 1:num_module
    k =0;
    for car_model_indx = 1:length(ref_car_model)
        str = char(target_module(i));
        upper_str = upper(str); 
        file = strcat('DD_',upper_str); 
        ddpath = strcat(app_dir,'\',str, '\');
        path = strrep(ddpath, ref_car_model{1}, ref_car_model{car_model_indx});
        data = readtable([path file],'sheet','Signals','PreserveVariableNames',true);
        [data_m,~] = size(data);
        data_cell = table2cell(data);
        NaNJudge = cellfun(@isnan, data_cell(1:end,7),'UniformOutput', false);
        
        for j = 1:data_m
            str = data_cell(j,1);
            str_dir = data_cell(j,2);
            if isempty(cell2mat(NaNJudge(j)))
                str_CAN = 'None';
            elseif cell2mat(NaNJudge(j)) == 1
                str_CAN = 'None';
            else
                str_CAN = data_cell(j,7);
            end

            if contains(str_dir, 'output') && contains(str_CAN,'V')
                k = k+1; 
                n = n+1; 
                if n > 1 && any(contains(restore_data(:,1),str))
                    n = n-1;
                    k = k-1;
                else
                    restore_data(n,1) = str;
                    restore_data(n,2) = str_dir;
                    restore_data(n,3) = data_cell(j,3);
                    restore_data(n,4) = data_cell(j,4);            
                    restore_data(n,5) = data_cell(j,5);
                    restore_data(n,6) = data_cell(j,6);
                    restore_data(n,7) = cellstr(upper_str);
                end
            end       
        end
    end
    group(i) = k; 
end

load_system simulink
load_system FVT_lib
new_model = ['OUTP_temp_' datestr(now,30)];
new_system(new_model);
open_system(new_model);
set_param(new_model,'LibraryLinkDisplay','all');
ModuleName = 'outpmodule';
original_x = 0; original_y = 0;
block_x=original_x+800;
block_y=original_y-100;
block_w=block_x+500;
block_h=block_y+30*n;
srcT = 'built-in/SubSystem';
dstT = [new_model '/' ModuleName];    
h = add_block(srcT,dstT);     
set_param(h,'position',[block_x,block_y,block_w,block_h],'ContentPreviewEnabled','off'); 

tail=0; 
color = {'yellow';'gray'};
k_value = {'_ovrdflg','_ovrdval','_maxval','_minval'};

clear Arry_cal; 
Numb_inputs = length(restore_data(1:end,1));
Module_last ='';
Numb_Cal = 0; 
for i  = 1:Numb_inputs
    if (i~=1)
        Module_last = string(restore_data(i-1,7));
    end
    Module =string(restore_data(i,7));
    if (i==1)||(string(color_s) == string(color(2)) && Module_last ~= Module)||(string(color_s) == string(color(1)) && Module_last == Module)
        color_s = color(1); 
    else
        color_s = color(2);
    end    
    str = char(restore_data(i,1));
    str_unit = char(restore_data(i,3)); 
    sign = extractAfter(str,"_");
    sign_unit = extractAfter(sign,"_");
    sign = extractBefore(sign,"_");               
    path_name = strcat(str,"_proc");
    out_name = extractAfter(str,"_");
    out_name = strcat("VOUTP_",out_name);            
     k_str = extractAfter(str,"_");
            
     Blockname = str;    
     srcT = 'simulink/Sources/In1';
     dstT = [new_model '/' ModuleName '/' Blockname]; 
     block_x=original_x;
     block_y=original_y+i*120;
     block_w=block_x+30;
     block_h=block_y+13;
     Hal = add_block(srcT,dstT);
     set_param(Hal,'position',[block_x,block_y,block_w,block_h]); 
            
     dstT = [new_model '/' ModuleName '/' Blockname];
     port = get_param(dstT,'PortHandles'); 
     port_pos  = get_param(port.Outport(1),'position'); 
            
     outp_block = [str , '_Inproc'];        
     srcT = 'FVT_lib/outp/OverrideAndLimit';
     dstT = [new_model '/' ModuleName '/' char(outp_block)]; 
     block_x=port_pos(1)+250;
     block_y=port_pos(2)-40;
     block_w=block_x+150;
     block_h=block_y+80;
     Hal = add_block(srcT,dstT);
     set_param(Hal,'position',[block_x,block_y,block_w,block_h],'BackgroundColor',char(color_s));

     dstT = [new_model '/' ModuleName '/' outp_block];
     port = get_param(dstT,'PortHandles'); 
     port_pos  = get_param(port.Outport(1),'position'); 
            
     Blockname = 'UnitConverter';
     srcT = 'simulink/Signal Attributes/Data Type Conversion';
     dstT = [new_model '/' ModuleName '/' Blockname num2str(i)]; 
     block_x=port_pos(1)+150;
     block_y=port_pos(2)-15;
     block_w=block_x+70;
     block_h=block_y+30;
     Hal = add_block(srcT,dstT);
     if contains(str_unit, 'Array')
        if strcmp(extractBefore(str_unit, 'Array'),'u16')
            data_unit = 'uint16';
        elseif strcmp(extractBefore(str_unit, 'Array'),'u32')
            data_unit = 'uint32';
        else
            data_unit = 'uint8';
        end
     else
        data_unit = str_unit;
     end
     set_param(Hal,'position',[block_x,block_y,block_w,block_h ],'showname','off','OutDataTypeStr',data_unit);
     
     dstT = [new_model '/' ModuleName '/' Blockname num2str(i)];
     port = get_param(dstT,'PortHandles'); 
     port_pos  = get_param(port.Outport(1),'position'); 
            
     Blockname = 'Out'; 
     srcT = 'simulink/Sinks/Out1';
     dstT = [new_model '/' ModuleName '/' Blockname num2str(i)]; 
     block_x=port_pos(1)+150;
     block_y=port_pos(2)-6.5;
     block_w=block_x+30;
     block_h=block_y+13;
     Hal = add_block(srcT,dstT);    
     set_param(Hal,'position',[block_x,block_y,block_w,block_h],'Port',num2str(i),'name',out_name); 
      
     dstT = [new_model '/' ModuleName]; 
     H1_line=add_line(dstT, [char(str), '/1'],[char(outp_block) ,'/1']);
     H2_line=add_line(dstT, [char(outp_block), '/1'],['UnitConverter' num2str(i)  ,'/1']);   
     H3_line=add_line(dstT, ['UnitConverter' num2str(i), '/1'],[char(out_name),'/1']);
     set_param(H1_line,'name',char(str));
     str_inProc = strcat("<",str,"_inProc",">");
     set_param(H2_line,'name',char(str_inProc));
     set_param(H3_line,'name',char(out_name));  
     set(H3_line,'MustResolveToSignalObject',1);
     for j = 1:length(k_value)
         if contains(str_unit, 'Array')
            if strcmp(extractBefore(str_unit, 'Array'),'u16')
                data_unit = 'uint16';
            elseif strcmp(extractBefore(str_unit, 'Array'),'u32')
                data_unit = 'uint32';
            else
                data_unit = 'uint8';
            end
         else
            data_unit = str_unit;
         end
         Numb_Cal = Numb_Cal+1;
         out_cal = erase(out_name,'VOUTP');
         out_cal = ['KOUTP' char(out_cal) char(k_value(j))];
         if (j <=2)
            dstT = [new_model '/' ModuleName '/' char(outp_block) '/' 'Signal_Override' '/' char(k_value(j))];
         else 
            dstT = [new_model '/' ModuleName '/' char(outp_block) '/' 'Signal_Limit' '/' char(k_value(j))];
         end
         set_param(dstT,'Value',char(out_cal));
         Arry_cal(Numb_Cal,1) = cellstr(out_cal);
         Arry_cal(Numb_Cal,2) = cellstr('internal');
         if (j == 1)
            Arry_cal(Numb_Cal,3) = cellstr('boolean');
            Arry_cal(Numb_Cal,4) = num2cell(0);
            Arry_cal(Numb_Cal,5) = num2cell(1);
            Arry_cal(Numb_Cal,6) = cellstr('flg');
            Arry_cal(Numb_Cal,7) = cellstr('N/A');
            Arry_cal(Numb_Cal,8) = num2cell(0);
            if strcmp(out_cal,'KOUTP_RgnAbnorSta_flg_ovrdflg') %FDC-1327
                Arry_cal(Numb_Cal,8) = num2cell(1);
            end
         elseif (j==2)
            Arry_cal(Numb_Cal,3) = cellstr(data_unit);
            if (data_unit == "single")
                if (cell2mat(restore_data(i,4))<-65535)
                    Arry_cal(Numb_Cal,4) = (restore_data(i,4));
                else
                    Arry_cal(Numb_Cal,4) = num2cell(-65535);
                end
            else
                Arry_cal(Numb_Cal,4) = num2cell(0);
            end
            if (data_unit == "uint8")
                Arry_cal(Numb_Cal,5) = num2cell(255);
                Arry_cal(Numb_Cal,6) = cellstr('enum');
                Arry_cal(Numb_Cal,7) = cellstr('N/A');
                Arry_cal(Numb_Cal,8) = num2cell(0);
            elseif (data_unit == "single")
                if (cell2mat(restore_data(i,5))>65535)
                    Arry_cal(Numb_Cal,5) = (restore_data(i,5));
                else
                    Arry_cal(Numb_Cal,5) = num2cell(65535);
                end
                Arry_cal(Numb_Cal,6) = cellstr(sign_unit);
                Arry_cal(Numb_Cal,7) = cellstr('N/A');
                Arry_cal(Numb_Cal,8) = num2cell(0);
            elseif (data_unit == "uint16")
                Arry_cal(Numb_Cal,5) = num2cell(65535);
                Arry_cal(Numb_Cal,6) = cellstr(sign_unit);
                Arry_cal(Numb_Cal,7) = cellstr('N/A');
                Arry_cal(Numb_Cal,8) = num2cell(0);
           elseif (data_unit == "uint32")
                Arry_cal(Numb_Cal,5) = num2cell(4294967295);
                Arry_cal(Numb_Cal,6) = cellstr(sign_unit);
                Arry_cal(Numb_Cal,7) = cellstr('N/A');
                Arry_cal(Numb_Cal,8) = num2cell(0);
            else 
                Arry_cal(Numb_Cal,5) = num2cell(1);
                Arry_cal(Numb_Cal,6) = cellstr(sign_unit);
                Arry_cal(Numb_Cal,7) = cellstr('N/A');
                Arry_cal(Numb_Cal,8) = num2cell(0);
            end
         elseif (j==3)
            Arry_cal(Numb_Cal,3) = cellstr(data_unit);
            if (data_unit == "single")
                if (cell2mat(restore_data(i,4))<-65535)
                    Arry_cal(Numb_Cal,4) = (restore_data(i,4));
                else
                    Arry_cal(Numb_Cal,4) = num2cell(-65535);
                end
            else
                Arry_cal(Numb_Cal,4) = num2cell(0);
            end
            if (data_unit == "single")
                if (cell2mat(restore_data(i,5))>65535)
                    Arry_cal(Numb_Cal,5) = (restore_data(i,5));
                else
                    Arry_cal(Numb_Cal,5) = num2cell(65535);
                end
            elseif (data_unit == "uint8")
                Arry_cal(Numb_Cal,5) = num2cell(255);
            elseif (data_unit == "uint16")
                Arry_cal(Numb_Cal,5) = num2cell(65535);
            elseif (data_unit == "uint32")
                Arry_cal(Numb_Cal,5) = num2cell(4294967295);                
            else 
                Arry_cal(Numb_Cal,5) = num2cell(1);
            end
            Arry_cal(Numb_Cal,6) = cellstr(restore_data(i,6));
            Arry_cal(Numb_Cal,7) = cellstr('N/A');
            Arry_cal(Numb_Cal,8) = (restore_data(i,5));  
         else
            Arry_cal(Numb_Cal,3) = cellstr(data_unit);
            if (data_unit == "single")
                if (cell2mat(restore_data(i,4))<-65535)
                    Arry_cal(Numb_Cal,4) = (restore_data(i,4));
                else
                    Arry_cal(Numb_Cal,4) = num2cell(-65535);
                end
            else
                Arry_cal(Numb_Cal,4) = num2cell(0);
            end
            if (data_unit == "single")
                if (cell2mat(restore_data(i,5))>65535)
                    Arry_cal(Numb_Cal,5) = (restore_data(i,5));
                else
                    Arry_cal(Numb_Cal,5) = num2cell(65535);
                end
            elseif (data_unit == "uint8")
                Arry_cal(Numb_Cal,5) = num2cell(255);
            elseif (data_unit == "uint16")
                Arry_cal(Numb_Cal,5) = num2cell(65535);
            elseif (data_unit == "uint32")
                Arry_cal(Numb_Cal,5) = num2cell(4294967295);                  
            else
                Arry_cal(Numb_Cal,5) = num2cell(1);
            end
            Arry_cal(Numb_Cal,6) = cellstr(restore_data(i,6));
            Arry_cal(Numb_Cal,7) = cellstr('N/A');
            Arry_cal(Numb_Cal,8) = (restore_data(i,4));   
         end            
     end
end
for i = 1:Numb_inputs 
    str = string(restore_data(i,1));
    sig_str = extractAfter(str,'_');
    sig_str = ['VOUTP_', char(sig_str)];
    Arry_sig(i,1) = cellstr(sig_str);
    Arry_sig(i,2) = cellstr('output');
    Arry_sig(i,3) = (restore_data(i,3));
    Arry_sig(i,4) = (restore_data(i,4));
    Arry_sig(i,5) = (restore_data(i,5));
    Arry_sig(i,6) = (restore_data(i,6));
    Arry_sig(i,7) = cellstr(str);
end
dstT = [new_model '/' ModuleName];
port = get_param(dstT,'PortHandles'); 
port_pos  = get_param(port.Inport(1),'position'); 
for i = 1:num_module
    if group(i)~=0
    if (i==1)
        ini =1; tail = group(1); sigslc_pos(4) = 0 ;block_offset =port_pos(2)-15;
    else
        ini = tail+1;tail = tail + group(i);block_offset =0;
    end
    sig_str = '';
    for j = ini:tail
        str = restore_data(j,1);
        sig_str = strcat(sig_str,',',str);  
    end
    sig_str = extractAfter(sig_str,","); 

    Ssrct_name='bus_selector'; 
    srcT = 'simulink/Signal Routing/Bus Selector';
    dstT = [new_model '/' Ssrct_name num2str(i)];
    block_x=original_x+500;
    block_y=original_y+block_offset+sigslc_pos(4);
    block_w=block_x+10;
    block_h=block_y+30*group(i);
    Hal = add_block(srcT,dstT);
    set_param(Hal,'position',[block_x,block_y,block_w,block_h],'outputsignals',char(sig_str))
    sigslc_pos = get_param([new_model '/' Ssrct_name num2str(i)],'position');
    q=0;
    for j = ini:tail
        q= q+1;
        dstT = [new_model];
        H = add_line(dstT,[Ssrct_name num2str(i), '/' num2str(q)],[ModuleName , '/' num2str(j)]);
    end
    type = target_module(i);    
    Bus_name = strcat("B",upper(type),"_outputs"); 
    block_x=original_x+200;
    block_y=(sigslc_pos(2)+sigslc_pos(4))/2-5;
    block_w=block_x+30;
    block_h=block_y+13;
    srcT = 'simulink/Sources/In1';
    dstT = [new_model '/' char(Bus_name)]; 
    Hal = add_block(srcT,dstT);
    set_param(Hal,'position',[block_x,block_y,block_w,block_h],'UseBusObject','on','BusObject',char(Bus_name)); 
    dstT = [new_model];
    H = add_line(dstT,[char(Bus_name), '/1'],[Ssrct_name num2str(i), '/1']);
    set_param(H,'name',strcat('<',Bus_name,'>'))
    end
end
%%
Ssrct_name='bus_creator'; 
srcT = 'simulink/Signal Routing/Bus Creator';
dstT = [new_model '/' Ssrct_name]; 
block_x=original_x+1500;
block_y=original_y+port_pos(2)-15;
block_w=block_x+10;
block_h=block_y+30*Numb_inputs;
Hal = add_block(srcT,dstT);
set_param(Hal,'position',[block_x,block_y,block_w,block_h],'ShowName','off','inputs',num2str(Numb_inputs)); 
set_param(Hal,'OutDataTypeStr','Bus:  BOUTP_outputs');
set_param(Hal,'NonVirtualBus','on');
for i = 1:Numb_inputs
    str = char(Arry_sig(i,1));
    dstT = [new_model];
    H_line = add_line(dstT,[ModuleName, '/' num2str(i)],[Ssrct_name, '/' num2str(i)]);
    set_param(H_line,'name',strcat('<',str,'>'));
end
sigslc_pos = get_param([new_model '/bus_creator'],'position');
Bus_name = 'BOUTP_outputs'; 
block_x=original_x+1800;
block_y=(sigslc_pos(2)+sigslc_pos(4))/2-6.5;
block_w=block_x+30;
block_h=block_y+13;
srcT = 'simulink/Sinks/Out1';
dstT = [new_model '/' char(Bus_name)]; 
Hal = add_block(srcT,dstT);
set_param(Hal,'position',[block_x,block_y,block_w,block_h],'UseBusObject','on','BusObject','BOUTP_outputs');  
dstT = [new_model];
H_line = add_line(dstT,[Ssrct_name, '/1'],[char(Bus_name), '/1']);
set_param(H_line,'name',strcat('<',Bus_name,'>'))

%%
outp_docs = strfind(app_dir,'\');
outp_dir = app_dir(1:outp_docs(end));
proj_DD = [outp_dir 'outp'];
cd (proj_DD);
disp('Writing DD file...');
Table_output = cell2table(Arry_sig);
Table_output.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units' 'Source Signal'};

Table_cal = cell2table(Arry_cal);
Table_cal.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units' 'Enum Table' 'Default during Running'};
File_name = strcat('DD_OUTP_',char(date),'.xlsx');
writetable(Table_output,File_name,'Sheet',1);
writetable(Table_cal,File_name,'Sheet',2);

File_pos = strcat(proj_DD,'\',File_name);
xlsApp = actxserver('Excel.Application');
ewb = xlsApp.Workbooks.Open(File_pos);
ewb.Worksheets.Item(1).name = 'Signals'; 
ewb.Worksheets.Item(1).Range('A1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('B1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('C1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('D1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('E1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('F1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(1).Range('G1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).name = 'Calibrations'; 
ewb.Worksheets.Item(2).Range('A1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('B1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('C1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('D1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('E1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('F1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('G1').Interior.ColorIndex = 4;
ewb.Worksheets.Item(2).Range('H1').Interior.ColorIndex = 4;
ewb.Save();
ewb.Close(true);
disp('Write DD finish, running FVT_export_businfo_modified');

DD_file = 'DD_OUTP.xlsx';
DD_path = [arch_Path '\outp'];
delete DD_OUTP.xlsx;
movefile(File_name,DD_file);
signal_table = readtable(DD_file,'sheet','Signals','PreserveVariableNames',true);
calibration_table = readtable(DD_file,'sheet','Calibrations','PreserveVariableNames',true);
verctrl = 'FVT_export_businfo_v3.0 2022-09-06';
buildbus(DD_file,DD_path,signal_table,calibration_table,verctrl);

cd(arch_Path);
disp('outp Done!');

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
project_path = char(extractBefore(pwd,'software'));
ARXML_Name = Build_SWC_APP(module_name,output_arry,project_path);
%     Modify_sldd(ARXML_Name,module_name,project_path);
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

    if strcmp(DataType,'single')
        DataType = cellstr('float32');
    elseif strcmp(DataType,'int16')
        DataType = cellstr('sint16'); 
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