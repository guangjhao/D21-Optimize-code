function FVT_MessesgeLink()
%% Initial settings
ref_car_model = {'d21awd-fdc2','d21rwd-fdc2', 'd31hawd-fdc2'};
car_model = ref_car_model{1};

Common_Scripts_path = pwd;
if ~contains(Common_Scripts_path, 'common\Scripts'), error('current folder is not under common\Scripts'), end
project_path = char(strcat(Common_Scripts_path, '/../../', car_model));

ECU_list = {'ZONE_DR','ZONE_FR', 'ZONE_RR_TA2', 'ZONE_FR_TA2', 'FUSION'};
q = listdlg('PromptString','Select target ECU:','ListString', ECU_list, ...
            'Name', 'Select target ECU', ...
			'ListSize', [250 150],'SelectionMode','single');
switch q
    case 1
        TargetNode = 'ZONE_DR';
        TargetNode_temp = 'zone-dr';
        CarModel = {'d21x-zone3-dr/app_dr','d31f25-zone3-dr/app_dr','d31h-zone3-dr/app_dr'};
    case 2
        TargetNode = 'ZONE_FR';
        TargetNode_temp = 'zone-fr';
        CarModel = {'d21x-zone3-fr/app_fr','d31f25-zone3-fr/app_fr','d31h-zone3-fr/app_fr'};
    case 3
        TargetNode = 'ZONE_RR';
        TargetNode_temp = 'zone-rr-ta2';
        CarModel = {'ta2-zone3-rr/app_rr'};
    case 4
        TargetNode = 'ZONE_FR';
        TargetNode_temp = 'zone-fr-ta2';
        CarModel = {'ta2-zone3-fr/app_fr'};
    case 5
        TargetNode = 'FUSION';
        TargetNode_temp = 'fusion';
        CarModel = {'d21rwd-fdc2'};
end

% select CAN MAP version
RoutingFolder = [project_path '\..\common\documents\MessageMap\'];
CMM_list = transpose(string({dir(RoutingFolder).name}));
CMM_list = CMM_list(contains(CMM_list, "FP"));
q = listdlg('PromptString','Select CMM version:','ListString', CMM_list, ...
            'Name', 'Select CMM version', ...
			'ListSize', [250 150],'SelectionMode','single');
% RoutingFolder = char(fullfile(RoutingFolder, CMM_list(q)));
[RoutingTable,CMMVersion] = FVT_ReadRoutingTable(RoutingFolder,TargetNode);

MsgLinkFolder = [project_path '\..\common\documents\'];
MsgLinkFileName = 'CAN_MessageLink.xlsx';
MsgLink_Folder = findFilesWithName(MsgLinkFolder, MsgLinkFileName);


MsgLinkOutTable = readtable(char(MsgLink_Folder),'Sheet','OutputSignal','VariableNamingRule','preserve');
MsgLinkInTable = readtable(char(MsgLink_Folder),'Sheet','InputSignal','VariableNamingRule','preserve');
MsgLinkOutArray = table2array(MsgLinkOutTable(:,1:2));
MsgLinkInArray = table2array(MsgLinkInTable(:,1));

containerInfolder = dir(RoutingFolder); Numb_TxSig = 0; Numb_RxSig = 0; Numb_Node = 0;
clear TxArry; clear RxArry; clear NodeArry; 
NodeArry = {zeros(1,1)}; TxArry = {zeros(1,1)};  RxArry= {zeros(1,1)};
dataStruct = struct();
for i = 1:length(containerInfolder)
    
    str = containerInfolder(i).name;
    if contains(str,'dbc') && contains(str,CMM_list(:))
        n = 0;
        temp_Arry = {zeros(1,1)};
        temp_DBC = canDatabase([containerInfolder(i).folder '/' containerInfolder(i).name]);
        DB_Name = temp_DBC.AttributeInfo(3).Value;
        Numb_Node = Numb_Node+1;
        NodeArry(Numb_Node,1) = cellstr(DB_Name);
        
        for j = 1:length(temp_DBC.MessageInfo)
            temp_struct = temp_DBC.MessageInfo(j);
            str_msg = temp_struct.Name;
            str_TxNode = temp_struct.TxNodes;
            
            if strcmp(char(str_TxNode),TargetNode)&&~contains(str_msg,'NMm')&&~contains(str_msg,'Diag')               
                for k = 1:length(temp_struct.Signals)     
                    n = n+1;
                    Numb_TxSig = Numb_TxSig+1;
                    str_sig = temp_struct.Signals(k);
                    str_data = temp_struct.SignalInfo.Class;
                    str_factor = temp_struct.SignalInfo(k).Factor;
                    str_offset = temp_struct.SignalInfo(k).Offset;
                    str_min = temp_struct.SignalInfo(k).Minimum;
                    str_max = temp_struct.SignalInfo(k).Maximum;
                    TxArry(Numb_TxSig,1) = cellstr(DB_Name);
                    TxArry(Numb_TxSig,2) = cellstr(str_msg);
                    TxArry(Numb_TxSig,3) = cellstr(str_sig);
                    TxArry(Numb_TxSig,4) = cellstr(str_data);
                    TxArry(Numb_TxSig,5) = num2cell(str_factor);
                    TxArry(Numb_TxSig,6) = num2cell(str_offset);
                    TxArry(Numb_TxSig,7) = num2cell(str_min);
                    TxArry(Numb_TxSig,8) = num2cell(str_max);
                    temp_Arry(n,1) = cellstr(str_sig);                    
                end
            else
                for k = 1:length(temp_struct.Signals)
                    Numb_RxSig = Numb_RxSig+1;
                    str_sig = temp_struct.Signals(k);
                    str_data = temp_struct.SignalInfo.Class;
                    str_factor = temp_struct.SignalInfo.Factor;
                    str_offset = temp_struct.SignalInfo.Offset;
                    RxArry(Numb_RxSig,1) = cellstr(DB_Name);
                    RxArry(Numb_RxSig,2) = cellstr(str_msg);
                    RxArry(Numb_RxSig,3) = cellstr(str_sig);
                    RxArry(Numb_RxSig,4) = cellstr(str_data);
                    RxArry(Numb_RxSig,5) = num2cell(str_factor);
                    RxArry(Numb_RxSig,6) = num2cell(str_offset);
                end
            end

        end
        for j =1:length(MsgLinkOutArray)
            str = MsgLinkOutArray(j,1);
            sig_index =  find(strcmp(temp_Arry(:,1),char(str)));
            if ~isempty(sig_index)
                temp_Arry(sig_index,2) = MsgLinkOutArray(j,2);
            elseif isempty(sig_index)
                %error(['InputSignal: "'  char(9) char(str) char(9)   '" dont found from database.'])
            end
        end
        dataStruct.(DB_Name) = temp_Arry;
        %tempoutput_Arry = temp_Arry;
    end
    LinSigTag_flg = 0; FrameTag_flg = 0; 
    if contains(str,'ldf') && contains(str,char(CMM_list(q)))
        ldf_string = fileread([containerInfolder(i).folder '/' containerInfolder(i).name]);
        ldf_string_Arry = textscan(ldf_string,'%s', 'delimiter', '\n', 'whitespace', '');
        ldf_arry = ldf_string_Arry{1};
        ldf_name = strsplit(containerInfolder(i).name,'_');
        for j = 1:length(ldf_name)
            temp_index = find(strcmp(ldf_name(1,:),'LIN'));
        end
        ldf_name = [char(ldf_name(temp_index)),'_',char(ldf_name(temp_index+1))];
        
        Numb_TxSig_tag_b = Numb_TxSig;
        %Numb_RxSig_tag_b = Numb_RxSig;
        Numb_Node = Numb_Node+1;
        NodeArry(Numb_Node,1) = cellstr(ldf_name);
        n = 0; clear temp_Arry;
        for j = 1:length(ldf_string_Arry{1})
            str = char(ldf_string_Arry{1}(j));           
            if contains(str,'Signals {')
                LinSigTag_flg = 1;
            end
            if LinSigTag_flg&&contains(str,'}')
                LinSigTag_flg = 0;
            end
            if LinSigTag_flg&&contains(str,':')
               str_sig = extractBefore(str,":");
               str_sig = regexprep(str_sig,'\s+','');
               str_arry = strsplit(str,',');
               str_node = char(str_arry(3));
               if contains(str_node,TargetNode)
                   n =n+1;
                   Numb_TxSig = Numb_TxSig+1;
                   TxArry(Numb_TxSig,1) = cellstr(ldf_name);
                   TxArry(Numb_TxSig,3) = cellstr(str_sig);
                   temp_Arry(n,1) = cellstr(str_sig);
               else 
                   Numb_RxSig = Numb_RxSig+1;
                   RxArry(Numb_RxSig,1) = cellstr(ldf_name);
                   RxArry(Numb_RxSig,3) = cellstr(str_sig);
               end               
            end
            if contains(str,'Frames {')
                FrameTag_flg = 1;        
            elseif (FrameTag_flg&&contains(str,';'))
                signame = extractBefore(str,',');
                signame = regexprep(signame,'\s+','');
                if strcmp(NodeName,TargetNode)
                    str_index = find(strcmp(TxArry(:,3),signame));
                    if length(str_index)>1
                        for k=1:length(str_index)
                            TxArryNode = char(TxArry(str_index(k),1));
                            if (strcmp(TxArryNode,ldf_name))
                                str_index = str_index(k);
                                TxArry(str_index,2) = cellstr(msgname);
                            end
                        end
                    else
                        TxArry(str_index,2) = cellstr(msgname);
                    end
                else
                    str_index = find(strcmp(RxArry(:,3),signame));
                    if length(str_index)>1
                        for k=1:length(str_index)
                            RxArryNode = char(RxArry(str_index(k),1));
                            if (strcmp(RxArryNode,ldf_name))
                                str_index = str_index(k);
                                RxArry(str_index,2) = cellstr(msgname);
                            end
                        end
                    else
                        RxArry(str_index,2) = cellstr(msgname);
                    end
                end
                %sig_index = find(strcmp(TxArry(:,3),signame));
            end
            if FrameTag_flg&&contains(str,':')
                msgname = extractBefore(str,':');
                msgname = regexprep(msgname,'\s+','');
                NodeName = strsplit(str,',');
                NodeName = char(NodeName(2));
                NodeName = regexprep(NodeName,'\s+','');
            end
            if (FrameTag_flg && contains(str,'Diagnostic_frames {'))
                FrameTag_flg = 0;
            end
        end

        for j = 1:length(temp_Arry)
            str = char(temp_Arry(j,1));
            pattern = ['Enc_.*?_', str, ' {'];
            arry_chk = regexp(ldf_arry, pattern,'once');
            isEmptyCell = cellfun(@isempty, arry_chk);
            nonEmptyIndices = find(~isEmptyCell);
            if ~isempty(nonEmptyIndices)
                sig_datainfo = char(ldf_arry(nonEmptyIndices+1));
                sig_datainfo_arry = strsplit(sig_datainfo,',');

                value =  strrep(sig_datainfo_arry(2), ' ', '');
                sig_min =  strrep(value, ';', '');
                TxArry(Numb_TxSig_tag_b+j,7) = num2cell(str2double(sig_min));
                value =  strrep(sig_datainfo_arry(3), ' ', '');
                sig_max =  strrep(value, ';', '');
                TxArry(Numb_TxSig_tag_b+j,8) = num2cell(str2double(sig_max));              
                value =  strrep(sig_datainfo_arry(4), ' ', '');
                sig_factor =  strrep(value, ';', '');
                TxArry(Numb_TxSig_tag_b+j,5) = num2cell(str2double(sig_factor));
                value =  strrep(sig_datainfo_arry(5), ' ', '');
                sig_offset =  strrep(value, ';', '');
                TxArry(Numb_TxSig_tag_b+j,6) = num2cell(str2double(sig_offset));
                if (str2double(sig_factor)~=1)
                    sig_type = 'single';
                else
                    sig_type = 'uint8';
                end
                TxArry(Numb_TxSig_tag_b+j,4) = cellstr(sig_type);
            else
                error(['Could not find LIN Signal: ',str,' encoder rule.']);
            end
        end
        for j =1:length(MsgLinkOutArray)
            str = MsgLinkOutArray(j,1);
            sig_index =  find(strcmp(temp_Arry(:,1),char(str)));
            if ~isempty(sig_index)
                temp_Arry(sig_index,2) = MsgLinkOutArray(j,2);
            elseif isempty(sig_index)
                %error(['InputSignal: "'  char(9) char(str) char(9)   '" dont found from database.'])
            end
        end
        dataStruct.(ldf_name) = temp_Arry;
    end
end
[uniqueStrArray, ~, idx] = (unique(RxArry(:,3)));
counts = accumarray(idx, 1);
repeatedStrRx = uniqueStrArray(counts > 1);
if isempty(repeatedStrRx)
    %disp('No SAME Name Rx signal in CAN...')
else
    %disp(repeatedStrRx);
    %disp('Above signal(Rx) have two or more same name in CAN...')
end
[uniqueStrArray, ~, idx] = (unique(TxArry(:,3)));
counts = accumarray(idx, 1);
repeatedStrTx = uniqueStrArray(counts > 1);
if isempty(repeatedStrTx)
    %disp('No SAME Name Tx signal in CAN...')
else
    %disp(repeatedStrTx);
    %disp('Above signal(Tx) have two or more same name in CAN...')
end

%Fill MessageLinkOut Sheet 
for i = 1:length(MsgLinkOutArray)
    str = MsgLinkOutArray(i,1);
    sig_index =  find(strcmp(TxArry(:,3),char(str)));
    if isempty(sig_index)
        error(['OutputSignal: "' char(9) char(str) char(9) '" dont found from database. It will have error if run else scripts.']);
    end
    for j = 1:length(sig_index)
        sig_node = (TxArry(sig_index(j),1));
        MSG = (TxArry(sig_index(j),2));
        Colum_index = find(strcmp(NodeArry(:,1),char(sig_node)));
        MsgLinkOutArray(i,Colum_index+2) = MSG;        
    end
end
%Fill Message Not Used Sheet
MsgNotUsedArry = {zeros(1,1)}; n = 0;
for i = 1:length(TxArry)
    str = char(TxArry(i,3));
    sigMsgLink_index = find(strcmp(MsgLinkOutArray(:,1),char(str)), 1);
    sigRouting_index = find(strcmp(RoutingTable(:,7),char(str)), 1);
    if isempty(sigMsgLink_index) && isempty(sigRouting_index)
        n = n+1;
        MsgNotUsedArry(n,1) = (TxArry(i,3)); 
        MsgNotUsedArry(n,2) = (TxArry(i,2));
        MsgNotUsedArry(n,3) = (TxArry(i,1));
    end 
end 
for i = 1:length(MsgLinkInArray)
    str = MsgLinkInArray(i,1);
    sig_index =  find(strcmp(RxArry(:,3),char(str)));
    for j = 1:length(sig_index)
        sig_node = (RxArry(sig_index(j),1));
        MSG = (RxArry(sig_index(j),2));
        %Colum_index = find(strcmp(NodeArry(:,1),char(sig_node)));
        MsgLinkInArray(i,j+1) = sig_node;        
        MsgLinkInArray(i,j+2) = MSG;
        MsgLinkInArray(i,j+3) = table2cell(MsgLinkInTable(i,4)); 
    end
end

temp_table_in = array2table(MsgLinkInArray);
temp_table_in.Properties.VariableNames{1} = 'Signal Name in CAN BUS';
temp_table_in.Properties.VariableNames{2} = 'CANChannel';
temp_table_in.Properties.VariableNames{3} = 'MessageName';
temp_table_in.Properties.VariableNames{4} = 'TargetSWC';

if width(MsgLinkOutArray)<(length(NodeArry)+2)
    x = (length(NodeArry)+2)-width(MsgLinkOutArray);    
    MsgLinkOutArray = [MsgLinkOutArray, cell(length(MsgLinkOutArray), x)];
end
temp_table_out = array2table(MsgLinkOutArray);
temp_table_out.Properties.VariableNames{1} = 'Signal Name in CAN BUS';
temp_table_out.Properties.VariableNames{2} = 'Signal Name in AP';
for i = 1:length(NodeArry)
    q = ['' char(NodeArry(i)) ''];
    temp_table_out.Properties.VariableNames{i+2} = q;
end

cd ([project_path '\..\common\documents\']);
filenameshort = 'CAN_MessageLinkOut';
filename = [filenameshort '_' CMMVersion '.xlsx'];
if ~isempty(dir([filename ,'.xlsx']))
    delete CAN_MessageLinkOut.xlsx;
end 


writetable(temp_table_out, filename, 'Sheet', 'OutputSignal');
writetable(temp_table_in, filename, 'Sheet', 'InputSignal');

% Add sheet for each channel check result 
for i = 1:length(NodeArry)
    Field = char(NodeArry(i));
    tempoutput_Arry = dataStruct.(Field);
    [m, n] = size(tempoutput_Arry);
    if n==1
        tempoutput_Arry(:,2) = cell(m,1);
    end
    temp_table_out = array2table(tempoutput_Arry);

    temp_table_out.Properties.VariableNames{1} = 'Signal Name in CAN BUS';
    temp_table_out.Properties.VariableNames{2} = 'From';
    writetable(temp_table_out, filename, 'Sheet',Field );
end

temp_length = length(MsgNotUsedArry);
if temp_length>0
    MsgNotUsedTable = array2table(MsgNotUsedArry);
    MsgNotUsedTable.Properties.VariableNames{1} = 'TxSignalNotUsed';
    MsgNotUsedTable.Properties.VariableNames{2} = 'MessageName';
    MsgNotUsedTable.Properties.VariableNames{3} = 'Channel(CAN/LIN)';
    writetable(MsgNotUsedTable, filename, 'Sheet','TxSig_Not_Defined_Output' );
end

%Check 'ON CAN' signal upper and lower limitation on DBC definition
for numb_CarModel = 1:length(CarModel)
    CarModel_temp = CarModel{numb_CarModel};
    CarModel_temp_split = strsplit(CarModel_temp,'-');
    CarModel_short = char(CarModel_temp_split(1));
    OUTP_folder = [project_path '/software/sw_development/arch/outp'];
    DD_OUTP = 'DD_OUTP.xlsx';
    DD_OUTP_FilePos = findFilesWithName(OUTP_folder, DD_OUTP);
    if ~isempty(DD_OUTP_FilePos)
        k = 0; l = 0; DDChk_Arry = {zeros(1,1)}; DDChk_NoFindArry = {zeros(1,1)};
        OUTP_arry_Sig = readcell(char(DD_OUTP_FilePos),'Sheet','Signals');
        OUTP_arry_Cal = readcell(char(DD_OUTP_FilePos),'Sheet','Calibrations');
        %MsgLinkOutArry = table2array(MsgLinkOutTable);
        MsgLinkOutArray_temp = MsgLinkOutArray(:,1:2);
        for i = 2:length(OUTP_arry_Sig)
            str = char(OUTP_arry_Sig(i,1));
            str_sig = char(OUTP_arry_Sig(i,7));
            MsgLinkOut_index_temp = find(strcmp(MsgLinkOutArray_temp(:,2),char(str_sig)));
            if ~isempty(MsgLinkOut_index_temp)
                %MsgLinkOut_index_temp = find(strcmp(MsgLinkOutArray_temp(:, 2), char(str_sig)) & ...
                %           cellfun(@length, MsgLinkOutArray_temp(:, 2)) == length(char(str_sig)));
                for n = 1:length(MsgLinkOut_index_temp)
                    MsgLinkOut_index = MsgLinkOut_index_temp(n);
                    k_str_max = ['K',str(2:end),'_maxval'];
                    k_str_max_index = strcmp(OUTP_arry_Cal(:,1),char(k_str_max));
                    k_str_max_def = OUTP_arry_Cal(k_str_max_index,8);
                    k_str_min = ['K',str(2:end),'_minval'];
                    k_str_min_index = strcmp(OUTP_arry_Cal(:,1),char(k_str_min));
                    k_str_min_def = OUTP_arry_Cal(k_str_min_index,8);


                    data_sig = MsgLinkOutArray(MsgLinkOut_index,1);
                    TxArry_index = find(strcmp(TxArry(:,3),char(data_sig)));
                    if (length(TxArry_index)>1)
                        %warning(['This signal(',str,') be used in more than two files.']);
                    end
                    for j = 1:length(TxArry_index)
                        k = k+1;
                        Database_def_sig = TxArry(TxArry_index(j),3);
                        Database_def_node = TxArry(TxArry_index(j),2);
                        Database_def_max = cell2mat(TxArry(TxArry_index(j),8));
                        Database_def_min = cell2mat(TxArry(TxArry_index(j),7));
                        Database_def_ch = TxArry(TxArry_index(j),1);
                        DDChk_Arry(k,1) = Database_def_ch;
                        DDChk_Arry(k,2) = Database_def_sig;
                        DDChk_Arry(k,3) = Database_def_node;
                        DDChk_Arry(k,4) = TxArry(TxArry_index(j),7);
                        DDChk_Arry(k,5) = k_str_min_def;
                        DDChk_Arry(k,6) = TxArry(TxArry_index(j),8);
                        DDChk_Arry(k,7) = k_str_max_def;
                        if cell2mat(k_str_max_def)>=Database_def_max && cell2mat(k_str_min_def) <=Database_def_min
                            DDChk_Arry(k,8) = cellstr('PASS');
                        elseif cell2mat(k_str_max_def)<=Database_def_max && cell2mat(k_str_min_def) <=Database_def_min
                            DDChk_Arry(k,8) = cellstr(['Calibration default(MAX.) ',k_str_max,' is under database definition.']);
                        elseif cell2mat(k_str_max_def)>=Database_def_max && cell2mat(k_str_min_def) >=Database_def_min
                            DDChk_Arry(k,8) = cellstr(['Calibration default(MIN.) ',k_str_min,' is beyond database definition.']);
                        else
                            DDChk_Arry(k,8) = cellstr(['Both of calibration defualt(MAX./MIN.)(',k_str_max,'/',k_str_min,') do not meet database definition.']);
                        end
                    end

                end
            else
                l  =l+1;
                DDChk_NoFindArry(l,1) = (OUTP_arry_Sig(i,1));
                DDChk_NoFindArry(l,2) = (OUTP_arry_Sig(i,7));
                %warning(['This signal(',str,') cannot find in DBC or LDF.']);
            end
        end
    else
        disp(['No check DD_outp calibration because cannot find DD_outp.xlsx in this project: ' CarModel_temp '.']);
    end
    if ~isempty(DD_OUTP_FilePos)
        DDChk_Table = array2table(DDChk_Arry);
        DDChk_Table.Properties.VariableNames{1} = 'Node';
        DDChk_Table.Properties.VariableNames{2} = 'SignalName';
        DDChk_Table.Properties.VariableNames{3} = 'Message';
        DDChk_Table.Properties.VariableNames{4} = 'DataBase(Min.)';
        DDChk_Table.Properties.VariableNames{5} = 'Calibration(Min.)';
        DDChk_Table.Properties.VariableNames{6} = 'DataBase(Max.)';
        DDChk_Table.Properties.VariableNames{7} = 'Calibration(Max.)';
        DDChk_Table.Properties.VariableNames{8} = 'Check Result';
        writetable(DDChk_Table, filename, 'Sheet',['CALVar_Chk_' CarModel_short]);
        if length(DDChk_NoFindArry)==1
            DDChk_NoFindArry = {'0','0'};
            DDChkNoFind_Table = array2table(DDChk_NoFindArry);
            DDChkNoFind_Table.Properties.VariableNames{1} = 'OutputSig Not Used On CAN/LIN';
            DDChkNoFind_Table.Properties.VariableNames{2} = 'Application Signal Name';
            writetable(DDChkNoFind_Table, filename, 'Sheet',['OUTP_Sig_Not_OnCAN_' CarModel_short]);
        else
            DDChkNoFind_Table = array2table(DDChk_NoFindArry);
            DDChkNoFind_Table.Properties.VariableNames{1} = 'OutputSig Not Used On CAN/LIN';
            DDChkNoFind_Table.Properties.VariableNames{2} = 'Application Signal Name';
            writetable(DDChkNoFind_Table, filename, 'Sheet',['OUTP_Sig_Not_OnCAN_' CarModel_short]);
        end
    end
end

n = 0; RxSigNoUsedArray = {zeros(1,1)};
for i = 1:height(RxArry)
    str = char(RxArry(i,3));
    str_msg = char(RxArry(i,2));
    str_node = char(RxArry(i,1));
    sigMsgLink_index = find(strcmp(MsgLinkInArray(:,1),char(str)), 1);
    sigRouting_index = find(strcmp(RoutingTable(:,3),char(str)), 1);
    if isempty(sigMsgLink_index) && isempty(sigRouting_index)
        n = n+1;
        RxSigNoUsedArray(n,1) = cellstr(str);
        RxSigNoUsedArray(n,2) = cellstr(str_msg);
        RxSigNoUsedArray(n,3) = cellstr(str_node);
    end
end
if height(RxSigNoUsedArray)~=1
    RxSigNoUsedTable = array2table(RxSigNoUsedArray);
    RxSigNoUsedTable.Properties.VariableNames{1} = 'Signals Not Used by SWC and CGW';
    RxSigNoUsedTable.Properties.VariableNames{2} = 'Message';
    RxSigNoUsedTable.Properties.VariableNames{3} = 'Node';
    writetable(RxSigNoUsedTable, filename, 'Sheet','RxSig_NotUsed');
end

cd (MsgLinkFolder);
disp('MessegeLink Sctript finished.');

for i = 1:height(MsgLinkInArray)
    str = MsgLinkInArray{i,3};
    if isempty(str)
        str_sig = MsgLinkInArray{i,1};
        error(['InputSignal: "' char(9) str_sig char(9) '" dont found from database. It will have error if run else scripts.']);
    end
end 
end

function fileList = findFilesWithName(rootFolder, fileName)
fileList = '';
filesAndFolders = dir(rootFolder);

filesAndFolders = filesAndFolders(~ismember({filesAndFolders.name}, {'.', '..'}));
for i = 1:length(filesAndFolders)
    fullPath = fullfile(rootFolder, filesAndFolders(i).name);
    if filesAndFolders(i).isdir
        fileList = [fileList; findFilesWithName(fullPath, fileName)];
    elseif strcmp(filesAndFolders(i).name, fileName)
        fileList = [fileList; {fullPath}];
    end
end
end

function [RoutingTable,CMM_version] = FVT_ReadRoutingTable(pathx,TargetNodex)
TargetNode = TargetNodex;
path = pathx;
Path_dir = dir(path);
filenames = string({Path_dir.name});
RoutingTableName = filenames(contains(filenames,['RoutingTable_' char(TargetNode)]));
if isempty(RoutingTableName)
    RoutingTableName = '';
    dbc_files = dir(fullfile(path, '*.dbc'));
    can4_file = char(dbc_files(contains({dbc_files.name}, 'CAN4')).name);
    can4_file_split = strsplit(can4_file, '_');
    CMM_version = [char(can4_file_split(1)) '_' char(can4_file_split(2))];
else
    RoutingTableName = char(RoutingTableName);
    RoutingTableName_split = strsplit(char(RoutingTableName),'_');
    CMM_version = [char(RoutingTableName_split(1)) '_' char(RoutingTableName_split(2))];
end

if ~isempty(RoutingTableName)
    RoutingTableName = RoutingTableName(:,:,1);
    password = ':sUW@k~23w@SeE8c';
    %filenames(contains(filenames,'to@'));
    password = extractBefore(password,'.txt');
    if isempty(password)
        Passwordnote = char(filenames(contains(filenames,'password')));
        if isempty(Passwordnote)
            disp('CANNOT open routing table becasue no password.');
        else
            password = fileread([path '/' Passwordnote]);
        end        
    end
    if ~isempty (RoutingTableName) && ~isempty(password)        
        xlsAPP = actxserver('excel.application');
        xlsAPP.Visible = 1;
        xlsWB = xlsAPP.Workbooks;
        xlsFile = xlsWB.Open([path '\' RoutingTableName],[],false,[],password);
        exlSheet1 = xlsFile.Sheets.Item('RoutingTable');
        dat_range = exlSheet1.UsedRange;
        raw_data = dat_range.value;
        xlsFile.Close(false);
        xlsAPP.Quit;

        RoutingArry = {zeros(1,1)}; k=0;
        for i = 1:height(raw_data)
            str_source = raw_data(i,2);
            if ~ismissing(string(raw_data(i,2)))&&contains(char(str_source),'requested signals, source:')
                source_node = extractAfter(char(str_source),':');
            end
            str_targe = raw_data(i,5);
            if ~ismissing(string(raw_data(i,5)))&&contains(char(str_targe),'distributed messages, target:')
                target_node = extractAfter(char(str_targe),':');
            end

            if ismissing(string(raw_data(i,2)))
                continue;
            elseif contains(char(raw_data(i,2)), 'Diag')
                continue;
            elseif contains(char(raw_data(i,2)), ' ')
                continue;
            elseif contains(char(raw_data(i,7)), 'Direct Message Routing') && ~contains(char(raw_data(i,2)), 'Diag')
                k = k+1;
                RoutingArry(k,1) = cellstr(source_node);
                RoutingArry(k,2) = (raw_data(i,2));
                RoutingArry(k,3) = cellstr('-');
                RoutingArry(k,4) = (raw_data(i,3));
                RoutingArry(k,5) = cellstr(target_node);
                RoutingArry(k,6) = (raw_data(i,5));
                RoutingArry(k,7) = cellstr('-');
                RoutingArry(k,8) = (raw_data(i,6));
                RoutingArry(k,9) = cellstr('-');
            elseif contains(char(raw_data(i,7)), 'Direct Message Routing')
                continue;


            else
                k = k+1;
                RoutingArry(k,1) = cellstr(source_node);
                RoutingArry(k,2) = (raw_data(i,2));
                RoutingArry(k,3) = cellstr(strrep(char(raw_data(i,1)),'''',''));
                RoutingArry(k,4) = (raw_data(i,3));
                RoutingArry(k,5) = cellstr(target_node);
                RoutingArry(k,6) = (raw_data(i,5));
                RoutingArry(k,7) = (raw_data(i,4));
                RoutingArry(k,8) = (raw_data(i,6));
                RoutingArry(k,9) = (raw_data(i,10));
            end
        end
        RoutingTable = RoutingArry;
    else
        RoutingTable = {'0','0','0','0','0','0','0','0','0'};
        disp('No find RoutingTable.');
    end

    if isempty(password)
        disp('No find RoutingTable password(to@xxxxxxxx.txt)');
    end
else
    RoutingTable = {'0','0','0','0','0','0','0','0','0'};
end
end

