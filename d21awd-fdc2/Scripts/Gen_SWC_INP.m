function Gen_SWC_INP()
%% Initial settings
project_path = pwd;
arch_Path = [project_path '/software/sw_development/arch'];
channel_list = {'CAN1','CAN2','CAN3','CAN4','CAN5','CAN6'};
is_Calibration_Data_From_Another_File = boolean(0);
Num_CANChn = length(channel_list);

for i = 1:Num_CANChn
    CANChannel = erase(char(channel_list(i)),'_');
    cd([arch_Path '\hal\hal_' lower(CANChannel)]);       
    data = readtable(['DD_HAL_' upper(CANChannel)],'sheet','Signals','PreserveVariableNames',true);
    [data_m,~] = size(data);
    cd([arch_Path '\inp']);

    if contains(CANChannel,'LIN')
        IsLINMessage = boolean(1);
    else
        IsLINMessage = boolean(0);
    end    

    %% inside message model
    %Data restore 
    Arry_data = table2cell(data);
    Arry_CAN = ["" "" "" "" "" "" ""];
    Numb_CAN = 0; 
    Arry_CANValid = ["" "" "" "" "" ""];
    Numb_CANValid = 0; 
    Arry_Digital = ["" "" "" "" "" ""];
    Numb_Digital = 0;
    Arry_LLSD = ["" "" "" "" "" ""];
    Numb_LLSD = 0;
    Arry_Analog = ["" "" "" "" "" ""];
    Numb_Analog = 0;
    for k = 1:data_m
        str_dir = Arry_data(k,2);
        str_source = Arry_data(k,13); 
        if (string(str_dir) == ("output") && string(str_source) == ("CAN"))
            str = Arry_data(k,1);
            tmp = find(contains(str,"CANMsgInvalid"));
            if isempty(string(tmp))
                Numb_CAN = Numb_CAN+1;        
                Arry_CAN(Numb_CAN,1) = Arry_data(k,1);
                Arry_CAN(Numb_CAN,2) = Arry_data(k,3);
                Arry_CAN(Numb_CAN,3) = Arry_data(k,4);
                Arry_CAN(Numb_CAN,4) = Arry_data(k,5);
                Arry_CAN(Numb_CAN,5) = Arry_data(k,6);
                Arry_CAN(Numb_CAN,6) = Arry_data(k,12);
                Arry_CAN(Numb_CAN,7) = Arry_data(k,14);
            elseif (tmp == 1)
                Numb_CANValid = Numb_CANValid+1;
                Arry_CANValid(Numb_CANValid,1) = Arry_data(k,1);
                Arry_CANValid(Numb_CANValid,2) = Arry_data(k,3);
                Arry_CANValid(Numb_CANValid,3) = Arry_data(k,4);
                Arry_CANValid(Numb_CANValid,4) = Arry_data(k,5);
                Arry_CANValid(Numb_CANValid,5) = Arry_data(k,6);
                Arry_CANValid(Numb_CANValid,6) = Arry_data(k,12);
            end
        elseif (string(str_dir) == ("output") && string(str_source) == ("LIN"))
            str = Arry_data(k,1);
            tmp = find(contains(str,"LINMsgInvalid"));
            if isempty(string(tmp))
                Numb_CAN = Numb_CAN+1;        
                Arry_CAN(Numb_CAN,1) = Arry_data(k,1);
                Arry_CAN(Numb_CAN,2) = Arry_data(k,3);
                Arry_CAN(Numb_CAN,3) = Arry_data(k,4);
                Arry_CAN(Numb_CAN,4) = Arry_data(k,5);
                Arry_CAN(Numb_CAN,5) = Arry_data(k,6);
                Arry_CAN(Numb_CAN,6) = Arry_data(k,12);
                Arry_CAN(Numb_CAN,7) = Arry_data(k,14);
            elseif (tmp == 1)
                Numb_CANValid = Numb_CANValid+1;
                Arry_CANValid(Numb_CANValid,1) = Arry_data(k,1);
                Arry_CANValid(Numb_CANValid,2) = Arry_data(k,3);
                Arry_CANValid(Numb_CANValid,3) = Arry_data(k,4);
                Arry_CANValid(Numb_CANValid,4) = Arry_data(k,5);
                Arry_CANValid(Numb_CANValid,5) = Arry_data(k,6);
                Arry_CANValid(Numb_CANValid,6) = Arry_data(k,12);
            end
        elseif (string(str_dir) == ("output") && string(str_source) == ("digital"))
            Numb_Digital = Numb_Digital+1;
            Arry_Digital(Numb_Digital,1) = Arry_data(k,1);
            Arry_Digital(Numb_Digital,2) = Arry_data(k,3);
            Arry_Digital(Numb_Digital,3) = Arry_data(k,4);
            Arry_Digital(Numb_Digital,4) = Arry_data(k,5);
            Arry_Digital(Numb_Digital,5) = Arry_data(k,6);
            Arry_Digital(Numb_Digital,6) = Arry_data(k,13);
        elseif (string(str_dir) == ("output") && string(str_source) == ("analog"))
            Numb_Analog = Numb_Analog+1;
            Arry_Analog(Numb_Analog,1) = Arry_data(k,1);
            Arry_Analog(Numb_Analog,2) = Arry_data(k,3);
            Arry_Analog(Numb_Analog,3) = Arry_data(k,4);
            Arry_Analog(Numb_Analog,4) = Arry_data(k,5);
            Arry_Analog(Numb_Analog,5) = Arry_data(k,6);
            Arry_Analog(Numb_Analog,6) = Arry_data(k,13);
        elseif (string(str_dir) == ("output") && string(str_source) == ("LLSD"))        
            Numb_LLSD = Numb_LLSD+1;
            Arry_LLSD(Numb_LLSD,1) = Arry_data(k,1);
            Arry_LLSD(Numb_LLSD,2) = Arry_data(k,3);
            Arry_LLSD(Numb_LLSD,3) = Arry_data(k,4);
            Arry_LLSD(Numb_LLSD,4) = Arry_data(k,5);
            Arry_LLSD(Numb_LLSD,5) = Arry_data(k,6);
            Arry_LLSD(Numb_LLSD,6) = Arry_data(k,13);       
        end
    end
 
    %% CANMsgValid
    Numb_TotalCal = 0;
    Numb_Outputs = 0;
    if Numb_CANValid ~= 0
        Cal_CANValid = {'_ovrdflg','_ovrdval'};

        sigoutputs = "";
        for k=1:Numb_CANValid
            str = char(Arry_CANValid(k,1));
            if (k==1)
                sigoutputs = str;
            else
                sigoutputs = strcat(sigoutputs,',',str);
            end
        end 


        for k=1:Numb_CANValid
            
            ModuleName = char(Arry_CANValid(k,1));
            ModuleName = erase(ModuleName,"VHAL_");
            ModuleName = erase(ModuleName,"_flg");
            str = char(Arry_CANValid(k,1));      
            newstr=strrep(str,'VHAL','KINP'); 
            for j=1:length(Cal_CANValid)
                 Cal_str = Cal_CANValid(j);
                 str = strcat(newstr,Cal_str); 
                 kblock_value = char(str);
                 Numb_TotalCal = Numb_TotalCal + 1;
                 Arry_Cal(Numb_TotalCal,1) = cellstr(kblock_value);
                 switch j 
                     case {1,2}
                         Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                         Arry_Cal(Numb_TotalCal,3) = cellstr('boolean');                 
                         Arry_Cal(Numb_TotalCal,4) = num2cell(0);
                         Arry_Cal(Numb_TotalCal,5) = num2cell(1);
                         Arry_Cal(Numb_TotalCal,6) = cellstr('flg');
                         Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                         Arry_Cal(Numb_TotalCal,8) = num2cell(0);
%                      case {2}
%                          Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
%                          Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
%                          Arry_Cal(Numb_TotalCal,4) = num2cell(0);
%                          Arry_Cal(Numb_TotalCal,5) = num2cell(255);
%                          Arry_Cal(Numb_TotalCal,6) = cellstr('cnt'); 
%                          Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');                
%                          Arry_Cal(Numb_TotalCal,8) = num2cell(100);
%                      case {3}
%                          Arry_Cal(Numb_TotalCal,2) = cellstr('internal');                 
%                          Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
%                          Arry_Cal(Numb_TotalCal,4) = num2cell(0);
%                          Arry_Cal(Numb_TotalCal,5) = num2cell(255);
%                          Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
%                          Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');  
%                          Arry_Cal(Numb_TotalCal,8) = num2cell(100);  
%                      case {4}
%                          Arry_Cal(Numb_TotalCal,2) = cellstr('internal');   
%                          Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
%                          Arry_Cal(Numb_TotalCal,4) = num2cell(0);
%                          Arry_Cal(Numb_TotalCal,5) = num2cell(255);
%                          Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
%                          Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');  
%                          Arry_Cal(Numb_TotalCal,8) = num2cell(100);
                 end
            end   

            str = char(Arry_CANValid(k,1));
            newstr = strrep(str,'VHAL','VINP'); 
            newstr = strrep(newstr,'Invalid','Valid'); 
        
            Numb_Outputs = Numb_Outputs+1;    
            Arry_outputs(Numb_Outputs,1) = cellstr(newstr);
            Arry_outputs(Numb_Outputs,2) = cellstr('output');
            Arry_outputs(Numb_Outputs,3) = cellstr('boolean');
            Arry_outputs(Numb_Outputs,4) = num2cell(0);
            Arry_outputs(Numb_Outputs,5) = num2cell(1);
            Arry_outputs(Numb_Outputs,6) = cellstr('flg');
        end
    end

    %% CAN

    if ~(strcmp(string(CANChannel),"CAN99"))
    categ = categorical(Arry_CAN(:,6));
    categty = categories(categ);
    countcats_A = countcats(categ);
    Numb_categty = length(categty);
    Cal_CAN ={'_defval','_ovrdflg','_ovrdval'};
    for k = 1:Numb_categty
        SignalPlace = find(contains(Arry_CAN(1:end,6),categty(k)));
        m = SignalPlace(1);
        n = m + countcats_A(k) - 1;
        
        j_in = 0;
        clear Arry_temp; 
        Arry_temp = {'','',''};
        Numb_outport = 0;
        tmp_cnt =0;
        for j = m:n
            j_in = j_in+1; 
            tmp_cnt = tmp_cnt +1;
            str = Arry_CAN(j,1); 
            str_unit = erase(str,'VHAL_'); 
    
            for s = 1:length(Cal_CAN) 
                cal = char(Cal_CAN(s));       
                Cal_value = strcat('KINP_',str_unit,cal);               
                Numb_TotalCal = Numb_TotalCal + 1;
                Arry_Cal(Numb_TotalCal,1) = cellstr(Cal_value);

                switch s
                    case {1}
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                        Arry_Cal(Numb_TotalCal,3) = cellstr(Arry_CAN(j,2));
                        Arry_Cal(Numb_TotalCal,4) = num2cell(str2double(Arry_CAN(j,3)));
                        Arry_Cal(Numb_TotalCal,5) = num2cell(str2double(Arry_CAN(j,4)));
                        Arry_Cal(Numb_TotalCal,6) = cellstr(Arry_CAN(j,5));
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        if (0<str2double(Arry_CAN(j,3)))
                            Arry_Cal(Numb_TotalCal,8) = num2cell(str2double(Arry_CAN(j,3)));
                        else
                            Arry_Cal(Numb_TotalCal,8) = num2cell(0);
                        end
%                      case {2}
%                         Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
%                         Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
%                         Arry_Cal(Numb_TotalCal,4) = num2cell(0);
%                         Arry_Cal(Numb_TotalCal,5) = num2cell(255);
%                         Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
%                         Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
%                         Arry_Cal(Numb_TotalCal,8) = num2cell(100);
%                      case {3}
%                         Arry_Cal(Numb_TotalCal,2) = cellstr('internal'); 
%                         Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
%                         Arry_Cal(Numb_TotalCal,4) = num2cell(0);
%                         Arry_Cal(Numb_TotalCal,5) = num2cell(255);
%                         Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
%                         Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
%                         Arry_Cal(Numb_TotalCal,8) = num2cell(5);  
%                      case {4}
%                         Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
%                         Arry_Cal(Numb_TotalCal,3) = cellstr('uint8');
%                         Arry_Cal(Numb_TotalCal,4) = num2cell(0);
%                         Arry_Cal(Numb_TotalCal,5) = num2cell(255);
%                         Arry_Cal(Numb_TotalCal,6) = cellstr('cnt');
%                         Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
%                         Arry_Cal(Numb_TotalCal,8) = num2cell(10);
                     case {2}
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal');
                        Arry_Cal(Numb_TotalCal,3) = cellstr('boolean');
                        Arry_Cal(Numb_TotalCal,4) = num2cell(0);
                        Arry_Cal(Numb_TotalCal,5) = num2cell(1);
                        Arry_Cal(Numb_TotalCal,6) = cellstr('flg');
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        Arry_Cal(Numb_TotalCal,8) = num2cell(0);
                     case {3}
                        Arry_Cal(Numb_TotalCal,2) = cellstr('internal'); 
                        Arry_Cal(Numb_TotalCal,3) = cellstr(Arry_CAN(j,2));
                        Arry_Cal(Numb_TotalCal,4) = num2cell(str2double(Arry_CAN(j,3)));
                        Arry_Cal(Numb_TotalCal,5) = num2cell(str2double(Arry_CAN(j,4)));
                        Arry_Cal(Numb_TotalCal,6) = cellstr(Arry_CAN(j,5));
                        Arry_Cal(Numb_TotalCal,7) = cellstr('N/A');
                        if (0<str2double(Arry_CAN(j,3)))
                            Arry_Cal(Numb_TotalCal,8) = num2cell(str2double(Arry_CAN(j,3)));
                        else
                            Arry_Cal(Numb_TotalCal,8) = num2cell(0);
                        end
                end
            end          
            
            str_out = erase(str,'VHAL');
            str_out = ['VINP',char(str_out)];
            

            Numb_outport = Numb_outport + 1;
            Arry_temp(Numb_outport,1) = cellstr(str_out);
            Arry_temp(Numb_outport,2) = cellstr('x'); 
            sig_valid = Arry_CAN(j,7);
            Numb_Outputs = Numb_Outputs+1;
            Arry_outputs(Numb_Outputs,1) = cellstr(str_out);
            Arry_outputs(Numb_Outputs,2) = cellstr('output');
            Arry_outputs(Numb_Outputs,3) = cellstr(Arry_CAN(j,2));
            Arry_outputs(Numb_Outputs,4) = num2cell(str2double(Arry_CAN(j,3)));
            Arry_outputs(Numb_Outputs,5) = num2cell(str2double(Arry_CAN(j,4)));
            Arry_outputs(Numb_Outputs,6) = cellstr(Arry_CAN(j,5));
            if (sig_valid=='V')
                str_out = erase(str,'VHAL_');
                str_out = extractBefore(str_out,'_');
                str_out = ['VINP_' char(str_out) 'Valid' '_flg'];
                Numb_outport = Numb_outport + 1;
                Arry_temp(Numb_outport,1) = cellstr(str_out);
                Arry_temp(Numb_outport,2) = cellstr('v');               
                
                Numb_Outputs = Numb_Outputs+1;
                Arry_outputs(Numb_Outputs,1) = cellstr(str_out);
                Arry_outputs(Numb_Outputs,2) = cellstr('output');
                Arry_outputs(Numb_Outputs,3) = cellstr('boolean');
                Arry_outputs(Numb_Outputs,4) = num2cell(0);
                Arry_outputs(Numb_Outputs,5) = num2cell(1);
                Arry_outputs(Numb_Outputs,6) = cellstr('flg');               
            end                         
        end
    end
 end
    %% Write DD
    DD_path = [arch_Path '\inp\inp_' lower(CANChannel)];
    cd (DD_path);
    disp('Writing DD file...');
    Table_output = cell2table(Arry_outputs);
    Table_output.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units'};
    
    Table_cal = cell2table(Arry_Cal);
    Table_cal.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units' 'Enum Table' 'Default during Running'};
    File_name = ['DD_INP_' upper(CANChannel) '_temp.xlsx'];
    writetable(Table_output,File_name,'Sheet',1);
    writetable(Table_cal,File_name,'Sheet',2);

    File_pos = [DD_path '\' File_name];
    xlsApp = actxserver('Excel.Application');
    ewb = xlsApp.Workbooks.Open(File_pos);
    ewb.Worksheets.Item(1).name = 'Signals'; 
    ewb.Worksheets.Item(1).Range('A1').Interior.ColorIndex = 4;
    ewb.Worksheets.Item(1).Range('B1').Interior.ColorIndex = 4;
    ewb.Worksheets.Item(1).Range('C1').Interior.ColorIndex = 4;
    ewb.Worksheets.Item(1).Range('D1').Interior.ColorIndex = 4;
    ewb.Worksheets.Item(1).Range('E1').Interior.ColorIndex = 4;
    ewb.Worksheets.Item(1).Range('F1').Interior.ColorIndex = 4;
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
%     disp('Write DD finish');
    
    if is_Calibration_Data_From_Another_File
        choice = {'Yes','No'};
        s = listdlg('ListString', choice, ...
		            'Name', 'Copy calibration data from another file?', ...
		            'ListSize', [400 50], ...
			        'SelectionMode', 'single' ...
			        );
        if (isempty(s)==1) 
            disp('no select');
        elseif (s == 1)
            disp('comparing ...');
            [FileName_Old,PathName_old] = uigetfile({'*.xls;*.xlsx;', 'Excel Files (*.xls, *.xlsx)'; '*.*', 'All Files (*.*)'}, 'Select Old file(.xls)');
            data_o=readtable([PathName_old FileName_Old],'sheet','Calibrations','PreserveVariableNames',true);
            [data_o_m,~]=size(data_o);
            data_o_Varialbe = data_o.Properties.VariableNames;
            row_default = find(strcmp(data_o_Varialbe,"Default during Running"));
            %data_n_arry = table2cell(tot_calibration_table);
            %[n_arry_y ~] = size(tot_calibration_table);
            data_o_arry = table2cell(data_o);
            data_n_arry_var = Arry_Cal(:,1);
            
            num_color = 0;
    %         num_cal_arry = 0;
            for k = 1:data_o_m
                str = char(data_o_arry(k,1));
    %             cal_val = data_o_arry(k,row_default);
                re = find(strcmp(str,data_n_arry_var));
                if (isempty(re)==0)
                    cal_val = data_o_arry(k,row_default);
                    cal_val_new = Arry_Cal(re,row_default);
                    if (cell2mat(cal_val) ~= (cell2mat(cal_val_new)))
                        Arry_Cal(re,row_default) = cal_val;
                        re = re+1;
                        num_color = num_color+1;
                        color_val(num_color,1) = cellstr(['H' num2str(re)]);
                    end 
                end 
            end
            data_new = cell2table(Arry_Cal); 
            data_new.Properties.VariableNames = {'Calibrations Name' 'Direction' 'Data Type' 'Min' 'Max' 'Units' 'Enum Table' 'Default during Running'};
            writetable(data_new,File_pos,'Sheet',2);
        
        
            File_pos = [DD_path '\' File_name];
            xlsApp = actxserver('Excel.Application');
            ewb = xlsApp.Workbooks.Open(File_pos);
            if (num_color~=0)
                for k = 1:length(color_val)
                    str = char(color_val(k,1));
                    ewb.Worksheets.Item(2).Range(str).Interior.ColorIndex = 5;
                end
            end
    %         cal_ref = ['A','B','C','D','E','F','G','H','I','J'];
        
            % Save Workbook
            ewb.Save();
            % Close Workbook
            ewb.Close();
            % Quit Excel Excel.Quit();
            disp('New DD.xls of INP updated from old file');
        else
            disp('New DD.xls finished');
        end
    end

DD_file = ['DD_INP_' upper(CANChannel) '.xlsx'];
delete(['DD_INP_' upper(CANChannel) '.xlsx']);
movefile(File_name,DD_file);

%% run FVT_businfo
signal_table = readtable(DD_file,'sheet','Signals','PreserveVariableNames',true);
calibration_table = readtable(DD_file,'sheet','Calibrations','PreserveVariableNames',true);
verctrl = 'FVT_export_businfo_v3.0 2022-09-06';
% disp('running FVT BUS info...');
buildbus(DD_file,DD_path,signal_table,calibration_table,verctrl);

%% run Build_SWC_APP
Module = ['INP_' CANChannel];
Build_SWC_APP(Module,Arry_outputs,project_path)

% clear old arrays
Arry_outputs = {};
Arry_Cal = {};
end

disp('FVT_INP.arxml Done!');
end

function Build_SWC_APP(Module,Arry_outputs,project_path)
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
h = find(contains(FVTAPP_arxml(:,1),['<SHORT-NAME>DT_B' Module  '_outputs</SHORT-NAME>']));
ECUC_start_array = find(contains(FVTAPP_arxml(:,1),'<IMPLEMENTATION-DATA-TYPE-ELEMENT>'));
ECUC_end_array = find(contains(FVTAPP_arxml(:,1),'</IMPLEMENTATION-DATA-TYPE-ELEMENT>'));

ECUC_start = min(ECUC_start_array(ECUC_start_array>h));
ECUC_end = min(ECUC_end_array(ECUC_end_array>h));

% 
for i = 1:length(Arry_outputs(:,1))
    tmpCell = FVTAPP_arxml(ECUC_start:ECUC_end);
    SignalName = Arry_outputs(i,1);
    DataType = Arry_outputs(i,3);
    Arrayflg = boolean(0);

    if strcmp(DataType,'single')
        DataType = cellstr('float32');
    elseif strcmp(DataType,'int16')
        DataType = cellstr('sint16'); 
    elseif strcmp(DataType,'Array16') || strcmp(DataType,'u8Array16')
        DataType = cellstr('u8_Array16_type');
        Arrayflg = boolean(1);
    elseif strcmp(DataType,'Array8') || strcmp(DataType,'u8Array8')
        DataType = cellstr('u8_Array8_type');
        Arrayflg = boolean(1);
    elseif strcmp(DataType,'u16Array8')
        DataType = cellstr('u16_Array8_type');
        Arrayflg = boolean(1);
    elseif strcmp(DataType,'u32Array8')
        DataType = cellstr('u32_Array8_type');
        Arrayflg = boolean(1);
    elseif strcmp(DataType,'u8Array17')
        DataType = cellstr('u8_Array17_type');
        Arrayflg = boolean(1);
    elseif strcmp(DataType,'u8Array20')
        DataType = cellstr('u8_Array20_type');
        Arrayflg = boolean(1);
    elseif strcmp(DataType,'u8Array12')
        DataType = cellstr('u8_Array12_type');
        Arrayflg = boolean(1);
    end

    % Signal Name
    h = find(contains(tmpCell,'<SHORT-NAME>V'));
    OldString = extractBetween(tmpCell(h),'<SHORT-NAME>','</SHORT-NAME>');
    NewString = SignalName;
    tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    
    % DataType
    h = find(contains(tmpCell,'<IMPLEMENTATION-DATA-TYPE-REF DEST="'));
    if ~Arrayflg
        OldString = extractBetween(tmpCell(h),'/ImplementationDataTypes/','</IMPLEMENTATION-DATA-TYPE-REF>');
        NewString = DataType;
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    else
        OldString = extractBetween(tmpCell(h),'DEST="IMPLEMENTATION-DATA-TYPE">','</IMPLEMENTATION-DATA-TYPE-REF>');
        NewString = ['/Impl_Type_APP_ARPkg/' char(DataType)];
        tmpCell(h) = strrep(tmpCell(h),OldString,NewString);
    end
    if i == 1
        tmpCell2 = tmpCell;
    else 
        tmpCell2 = [tmpCell2;tmpCell];
    end
end

% Replace original CanIfInitHohCfg(CanIfHrhCfg & CanIfHthCfg) part
h = find(contains(FVTAPP_arxml(:,1),['<SHORT-NAME>DT_B' Module  '_outputs</SHORT-NAME>']));
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
str_firstcali = (string(table2cell(calibration_table(1,1))));
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
    sens = strcat("{","'", str ,"' ", " ,1, ", " '", type ,"' ", " ,-1" , ", 'real'", " ,'Sample'};...");
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
        sens = strcat("a2l_mon('", str, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
        fprintf(fileID,[ char(sens)  '\n'...
                       ]);
    end   
end 

% Close the file.
fclose(fileID);
% Open the file in the editor.
% save(varfile);
end


% function Copy_DD_to_other_car_models(car_model, Common_Scripts_path, arch_Path)
%     project_path = char(strcat(Common_Scripts_path, '/../../', car_model));
%     source_dd_Path = [arch_Path '/inp'];
%     target_dd_Path = [project_path '/software/sw_development/arch/inp'];
% 
%     allItems = dir(source_dd_Path);
%     for i = 1:length(allItems)
%         if allItems(i).isdir && contains(allItems(i).name, 'can')
%             sourcePath = fullfile(source_dd_Path, allItems(i).name);
%             destinationPath = fullfile(target_dd_Path, allItems(i).name);
%             copyfile(sourcePath, destinationPath);
%         end
%     end
% end
