function Gen_SWC_HALIN(MsgLinkFileName)
%% Initial settings
project_path = pwd;
arch_Path = [project_path '/software/sw_development/arch'];
TargetNode = 'FUSION';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUS list is real CAN channel in BSP. It depends on hardware layout and
% vehicle side cable.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

channel_list = {'CAN1','CAN2','CAN3','CAN4','CAN5','CAN6'};
busList =      {'1','2','3','4','6','7'};
NUN_CHANNEL = length(channel_list);

%% Read MessageLink
MessageLink = readcell(MsgLinkFileName,'Sheet','InputSignal');

%% Working for seperate channel
for i = 1:NUN_CHANNEL
    
    % read DBC or LIN message map
    cd(arch_Path);
    Channel = char(channel_list(i));
    busID = char(busList(i));
    % num_routing = 0;
 
    if contains(Channel,'CAN')
        IsLINMessage = boolean(0);
        path = [project_path '\..\common\documents\MessageMap\'];
        filenames = dir(path);
        filenames = string({filenames.name});
        FileName = string(filenames(contains(filenames,Channel)));
        FileName = char(FileName(contains(FileName,'.dbc')));
        DBC= canDatabase([path FileName]);
    else
        Filepath = [project_path '\..\common\documents\MessageMap\'];
        filenames = dir(Filepath);
        filenames = string({filenames.name});
        FileName = string(filenames(contains(filenames,Channel)));
        FileName = char(FileName(contains(FileName,'.xlsx')));
        DBC = LinDatabase(Filepath,FileName,Channel,password);
        IsLINMessage = boolean(1);
    end
    Channel = erase(Channel, '_');

    %% Detect APP siganl for each CAN   
    Numb_restore = 0;

    if find(ismissing(string(MessageLink)))
        msg = 'Error: Input Signal not match between Messagelink and DBC, checkout signal name is correct';
        error(msg);
    end

    MessageLink(:,2) = erase(MessageLink(:,2),'_');
    Detect_APP_signal_array_can = strcmp(MessageLink(:,2),Channel);
    Detect_APP_signal_can = find(Detect_APP_signal_array_can == 1);
    Numb_array = length(Detect_APP_signal_can);
    
    % Creat APP siganl table for each CAN
    if ~isempty(Detect_APP_signal_can)
        APP_CANSignal = cell(Numb_array,3);
        for p = 1:Numb_array    
               Numb_restore = Numb_restore + 1;
               APP_CANSignal(Numb_restore,1) = cellstr(Channel);
               APP_CANSignal(Numb_restore,2) = MessageLink((Detect_APP_signal_can(p,1)),1);
               APP_CANSignal(Numb_restore,3) = MessageLink((Detect_APP_signal_can(p,1)),3);
        end
    end

    %% generate RxMsgTable and define CAN filter
    RxMsgTable = cell(length(DBC.Messages),8);
    filter = '[';
    MsgCnt = 0;
    SignalCnt = 0;

    for j = 1:length(DBC.Messages)
        if ~contains(DBC.MessageInfo(j).Name,'CCP')...
                && ~contains(DBC.MessageInfo(j).Name,'XCP')...
                && ~contains(DBC.MessageInfo(j).Name,'Diag')...
                && (any(strcmp(APP_CANSignal(:,3),DBC.MessageInfo(j).Name)))...
                && (~startsWith(DBC.MessageInfo(j).Name,'NMm_')|| ~startsWith(DBC.MessageInfo(j).Name,'XNMm_'))...
                && ~contains(DBC.MessageInfo(j).TxNodes,TargetNode)... 
                && ~isempty(DBC.MessageInfo(j).Signals)    
              % && ~contains(DBC.MessageInfo(j).Name,'NMm')...

            RxMsgTable(j,1) = num2cell(j); % DBC index
            RxMsgTable(j,2) = num2cell(DBC.MessageInfo(j).ID); % Message ID in dec
            RxMsgTable(j,3) = num2cell(DBC.MessageInfo(j).Length); % Data length
            RxMsgTable(j,4) = cellstr(DBC.MessageInfo(j).Name); % Message name
            RxMsgTable(j,5) = cellstr(erase(DBC.MessageInfo(j).Name,'_')); % Message name for DD
            RxMsgTable(j,6) = cellstr(DBC.MessageInfo(j).TxNodes); % Message Tx node
            if IsLINMessage
                RxMsgTable(j,2) = num2cell(DBC.MessageInfo(j).PID); % LIN message use PID
                RxMsgTable(j,7) = cellstr(DBC.MessageInfo(j).MsgCycleTime); % LIN message cycle time
                RxMsgTable(j,8) = cellstr(DBC.MessageInfo(j).Delay); % LIN message delay time
                filter = [filter ' 0x' num2str(dec2hex(DBC.MessageInfo(j).PID))];
            else
                RxMsgTable(j,7) = num2cell(DBC.MessageInfo(j).AttributeInfo(strcmp(DBC.MessageInfo(j).Attributes(:,1),'GenMsgCycleTime')).Value);
                RxMsgTable(j,8) = cellstr('0');
                filter = [filter ' 0x' num2str(dec2hex(DBC.MessageInfo(j).ID))];
            end
            MsgCnt = MsgCnt + 1;
            
            SignalCnt = SignalCnt + length(DBC.MessageInfo(j).Signals);
        end   
    end
    filter = [filter ']'];

    for j = length(RxMsgTable(:,1)):-1:1
        if cellfun(@isempty,RxMsgTable(j,1))
            RxMsgTable(j,:) = [];
        end
    end
    RxMsgTable = [{'DBCidx','ID/PID(dec)','DLC','MsgName','MsgName_DD','TxNode','MsgCycleTime','LIN Delay time'};RxMsgTable]; 
    
    DD_cell = cell(MsgCnt + Numb_array + 20,16);
    DD_cell2 = cell(2*MsgCnt + Numb_array, 8);

    %% Generate channel model
    
    for j = 2: MsgCnt+1
        % read Rx message infos
        MsgName = char(RxMsgTable(j,strcmp(RxMsgTable(1,:),'MsgName')));
        MsgName_DD = char(RxMsgTable(j,strcmp(RxMsgTable(1,:),'MsgName_DD')));
        TxNode = char(RxMsgTable(j,strcmp(RxMsgTable(1,:),'TxNode')));
        ID = cell2mat(RxMsgTable(j,strcmp(RxMsgTable(1,:),'ID/PID(dec)')));
        MsgID_hex = ['0x' char(dec2hex(ID))];
        DLC = string(RxMsgTable(j,strcmp(RxMsgTable(1,:),'DLC')));
 
        %% Detcet message match APP signals
        if ~isempty(Detect_APP_signal_can)
        Msg_check = strcmp((string(APP_CANSignal(:,3))),string(MsgName));
        Detect_AppMsg = find(Msg_check == 1);
        Numb_Msg_Matchsignal = length(Detect_AppMsg);

            if ~isempty(Detect_AppMsg)
            Signal_match_array = zeros((Numb_Msg_Matchsignal),1);
    
            % Detcet each match signal in DBC table row positon       
               for kkk = 1:length(Detect_AppMsg)            
                Match_Signal = string(APP_CANSignal((Detect_AppMsg(kkk)),2));   
                Signal_match = strcmp(DBC.MessageInfo(cell2mat(RxMsgTable(j,strcmp(RxMsgTable(1,:),'DBCidx')))).Signals,(Match_Signal)');
                Signal_match_array_pos = find(Signal_match == 1);

                if isempty(Signal_match_array_pos)
                msg = ['Error: Input Signal: ' char(Match_Signal) ' not match between Messagelink and DBC, checkout signal name is correct'];
                error(msg);
                end

                   if ~isempty(Signal_match_array_pos)
                      Signal_match_array(kkk,1) = Signal_match_array_pos;  
                   end  
               end    
    
                % Creat SignalName_raw for APP singal
                Signal_match_array = sort(Signal_match_array);
                SignalName_app = cell(length(Signal_match_array),1);  

                for bbb = 1:length(Signal_match_array)
                    Index_signal = find(cellfun(@isempty,SignalName_app(1:end,1)));
                    SignalName_app(Index_signal(1),1) = DBC.MessageInfo(cell2mat(RxMsgTable(j,strcmp(RxMsgTable(1,:),'DBCidx')))).Signals(Signal_match_array(bbb),1);
                end
            end        
        end

     %%
        if IsLINMessage
            MsgCycleTime = string(RxMsgTable(j,strcmp(RxMsgTable(1,:),'MsgCycleTime')));
            FirstDelay = string(RxMsgTable(j,strcmp(RxMsgTable(1,:),'LIN Delay time')));
            TimeoutSet = {'3'};
        elseif contains(MsgName,'NMm')
            TimeoutSet = {num2str(1), num2str(700)};   
        else
            MsgCycleTime = string(RxMsgTable(j,strcmp(RxMsgTable(1,:),'MsgCycleTime')));
            TimeoutSet = {num2str(2.5), num2str(MsgCycleTime)};
        end


        %************** Setup message invalid and byte goto***************%
        % write DD file
        if IsLINMessage
            MsgTimeoutflg = ['VHAL_LINMsgInvalid' MsgName_DD '_flg'];
        % elseif strcmp(Channel,'CAN6')
        %   MsgTimeoutflg = ['VHAL_CAN6CANMsgInvalid' MsgName_DD '_flg'];
        else
            MsgTimeoutflg = ['VHAL_CANMsgInvalid' MsgName_DD '_flg'];
        end
        MsgTimeoutflgUnit = 'flg';
        MsgTimeoutflgDataType = 'boolean';             
        DD_Index_Msg = find(cellfun(@isempty,DD_cell(1:end,1)));
        DD_cell(DD_Index_Msg(1),1) = {MsgTimeoutflg}; % HAL signal name
        DD_cell(DD_Index_Msg(1),2) = {'output'}; % Direction
        DD_cell(DD_Index_Msg(1),3) = {MsgTimeoutflgDataType}; % data type
        DD_cell(DD_Index_Msg(1),4) = {'0'}; % Minimum
        DD_cell(DD_Index_Msg(1),5) = {'1'}; % Maximun
        DD_cell(DD_Index_Msg(1),6) = {MsgTimeoutflgUnit}; % Unit
        DD_cell(DD_Index_Msg(1),7) = {'N/A'}; % Enum table
        DD_cell(DD_Index_Msg(1),8) = {'N/A'}; % Default before and during POWER-UP
        DD_cell(DD_Index_Msg(1),9) = {'N/A'}; % DDefault before and during POWER-DOWN
        DD_cell(DD_Index_Msg(1),10) = {'N/A'}; % Description
        DD_cell(DD_Index_Msg(1),11) = {TxNode}; % CAN transmitter
        DD_cell(DD_Index_Msg(1),12) = {MsgName}; % Message
        if IsLINMessage
            DD_cell(DD_Index_Msg(1),13) = {'LIN'}; % Data source
        else
            DD_cell(DD_Index_Msg(1),13) = {'CAN'};
        end
        

        %%%%%%%%%%%%%%%%% Setup Checksum & Rollingcount %%%%%%%%%%%%%%%%%%%

        % write DD file
        if contains(MsgName, {'ESC1', 'ESC5', 'ESC7'}) || contains(MsgName, {'FCM2', 'FCM4', 'ABM1', 'BMS1', 'BMS6', 'CCU1', 'CCU2', 'Shifter', 'MCU_N_R1', 'MCU_N_F1', 'EPS1', 'EPB1'}) 
              
            MsgCSErrflg = ['VHAL_' MsgName_DD 'CSErr_flg'];
            MsgCSErrflgUnit = 'flg';
            MsgCSErrflgDataType = 'boolean';
            DD_Index_Msg = find(cellfun(@isempty, DD_cell(1:end, 1)));
            DD_cell(DD_Index_Msg(1), 1) = {MsgCSErrflg}; % HAL signal name
            DD_cell(DD_Index_Msg(1), 2) = {'output'}; % Direction
            DD_cell(DD_Index_Msg(1), 3) = {MsgCSErrflgDataType}; % data type
            DD_cell(DD_Index_Msg(1), 4) = {'0'}; % Minimum
            DD_cell(DD_Index_Msg(1), 5) = {'1'}; % Maximun
            DD_cell(DD_Index_Msg(1), 6) = {MsgCSErrflgUnit}; % Unit
            DD_cell(DD_Index_Msg(1), 7) = {'N/A'}; % Enum table
            DD_cell(DD_Index_Msg(1), 8) = {'N/A'}; % Default before and during POWER-UP
            DD_cell(DD_Index_Msg(1), 9) = {'N/A'}; % DDefault before and during POWER-DOWN
            DD_cell(DD_Index_Msg(1), 10) = {'N/A'}; % Description
            DD_cell(DD_Index_Msg(1), 11) = {TxNode}; % CAN transmitter
            DD_cell(DD_Index_Msg(1), 12) = {MsgName}; % Message
            DD_cell(DD_Index_Msg(1), 13) = {'CAN'};

            if true % ~contains(MsgName, {'FCM4'})
                MsgRCErrflg = ['VHAL_' MsgName_DD 'RCErr_flg'];
                MsgRCErrflgUnit = 'flg';
                MsgRCErrflgDataType = 'boolean';
                DD_Index_Msg = find(cellfun(@isempty, DD_cell(1:end, 1)));
                DD_cell(DD_Index_Msg(1), 1) = {MsgRCErrflg}; % HAL signal name
                DD_cell(DD_Index_Msg(1), 2) = {'output'}; % Direction
                DD_cell(DD_Index_Msg(1), 3) = {MsgRCErrflgDataType}; % data type
                DD_cell(DD_Index_Msg(1), 4) = {'0'}; % Minimum
                DD_cell(DD_Index_Msg(1), 5) = {'1'}; % Maximun
                DD_cell(DD_Index_Msg(1), 6) = {MsgRCErrflgUnit}; % Unit
                DD_cell(DD_Index_Msg(1), 7) = {'N/A'}; % Enum table
                DD_cell(DD_Index_Msg(1), 8) = {'N/A'}; % Default before and during POWER-UP
                DD_cell(DD_Index_Msg(1), 9) = {'N/A'}; % DDefault before and during POWER-DOWN
                DD_cell(DD_Index_Msg(1), 10) = {'N/A'}; % Description
                DD_cell(DD_Index_Msg(1), 11) = {TxNode}; % CAN transmitter
                DD_cell(DD_Index_Msg(1), 12) = {MsgName}; % Message
                DD_cell(DD_Index_Msg(1), 13) = {'CAN'};
            end
                            
            % write DD file for KHAL_E2E_flg
            DD_Index2 = find(cellfun(@isempty, DD_cell2(1:end, 1)));
            DD_cell2(DD_Index2(1), 1) = {['KHAL_' Channel MsgName_DD 'E2E_flg']}; % Signal name
            DD_cell2(DD_Index2(1), 2) = {'internal'}; % Direction
            DD_cell2(DD_Index2(1), 3) = {'boolean'}; % data type
            DD_cell2(DD_Index2(1), 4) = {'0'}; % Minimum
            DD_cell2(DD_Index2(1), 5) = {'1'}; % Maximun
            DD_cell2(DD_Index2(1), 6) = {'flg'}; % Unit
            DD_cell2(DD_Index2(1), 7) = {'N/A'}; % Enum table
            if contains(MsgName_DD, {'MCUNR1', 'MCUNF1'})
                DD_cell2(DD_Index2(1), 8) = {'0'}; % Default during Running
            else
                DD_cell2(DD_Index2(1), 8) = {'1'}; % Default during Running
            end
        end        
                    

        for k  = 1:length(Signal_match_array)
            SignalSize = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).SignalSize;
            SignalMin = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Minimum;
            SignalMax = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Maximum;
            Startbit = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).StartBit;
            SignalUnit_raw = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Units;
            SignalUnit_modify = char(UnitChange(SignalUnit_raw));
            SignalName = char(erase(DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Name, '_'));
            Autosar_SignalName = char(DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Name);
            SignalResolution = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Factor;
            SignalOffset = DBC.MessageInfo(cell2mat(RxMsgTable(j,1))).SignalInfo(Signal_match_array(k)).Offset;
            SignalConvert = {num2str(SignalResolution), num2str(SignalOffset)};
                 
            % define VHAL signal name and type   
            if SignalSize == 1
                SignalUnit = 'flg';
                SignalDataType = 'boolean';
            elseif contains(SignalName,'Diag')
                SignalUnit = 'Diag';
                SignalDataType = 'uint64';
            elseif isempty(SignalUnit_modify) && SignalOffset ==0 && SignalResolution == 1
                SignalUnit = 'enum';
                if SignalSize <= 8; SignalDataType = 'uint8'; end
                if (8 < SignalSize) && (SignalSize <= 16); SignalDataType = 'uint16'; end
                if (16 < SignalSize) && (SignalSize <= 32); SignalDataType = 'uint32'; end
                if SignalSize > 32 ; SignalDataType = 'uint64'; end
            elseif isempty(SignalUnit_modify) && (SignalOffset ~=0 || SignalResolution ~= 1)
                SignalUnit = 'cnt';
                SignalDataType = 'single';
            else
                SignalUnit = SignalUnit_modify;
                SignalDataType = 'single';
            end
            
            % Modify signal maximum if out of range
            if startsWith(SignalDataType,'uint') && SignalMax > intmax(SignalDataType)
                SignalMax = intmax(SignalDataType);
%                 disp([SignalName char(9) 'maximum value has been modified']);
            end

            SignalName_HAL = ['VHAL_' SignalName '_' SignalUnit];
            % write DD file
            DD_Index = find(cellfun(@isempty,DD_cell(1:end,1)));
            DD_cell(DD_Index(1),1) = {SignalName_HAL}; % HAL signal name
            DD_cell(DD_Index(1),2) = {'output'}; % Direction
            DD_cell(DD_Index(1),3) = {SignalDataType}; % data type
            DD_cell(DD_Index(1),4) = {num2str(SignalMin)}; % Minimum
            DD_cell(DD_Index(1),5) = {num2str(SignalMax)}; % Maximun
            DD_cell(DD_Index(1),6) = {SignalUnit}; % Unit
            DD_cell(DD_Index(1),7) = {'N/A'}; % Enum table
            DD_cell(DD_Index(1),8) = {'N/A'}; % Default before and during POWER-UP
            DD_cell(DD_Index(1),9) = {'N/A'}; % DDefault before and during POWER-DOWN
            DD_cell(DD_Index(1),10) = {'N/A'}; % Description
            DD_cell(DD_Index(1),11) = {TxNode}; % CAN transmitter
            DD_cell(DD_Index(1),12) = {MsgName}; % Message
            DD_cell(DD_Index(1),13) = {'CAN'}; % Data source
        end
    end
    % Delete empty DD_cell cell
    for h = length(DD_cell(:,1)):-1:1
        if cellfun(@isempty,DD_cell(h,1))
            DD_cell(h,:) = [];
        end
    end

    % Delete empty DD_cell2 cell
    for p = length(DD_cell2(:, 1)):-1:1

        if cellfun(@isempty, DD_cell2(p, 1))

            if p == 1
                % write DD file
                DD_cell2(1, 1:8) = {'0'};
            else
                DD_cell2(p, :) = [];
            end
        end
    end    
     % create DD file
     DD_path = [arch_Path '\hal\hal_' lower(Channel)];
     cd(DD_path);
     if isfile(['DD_HAL_' upper(Channel) '.xlsx'])
        delete (['DD_HAL_' upper(Channel) '.xlsx']);
     end
     DD_table = cell2table(DD_cell);
     DD_table.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units' 'Enum table' 'Default before and during POWER-UP' 'Default before and during POWER-DOWN' 'Description' 'TxNodes' 'TxMessagge' 'DataSource' 'Signals valid require' 'Signal process In NewInpProcess require' 'New Signal Name'};
     File_name = ['DD_HAL_' upper(Channel) '.xlsx'];
     DD_table_cal = cell2table(DD_cell2);
     DD_table_cal.Properties.VariableNames = {'Signal Name' 'Direction' 'Data type' 'Min' 'Max' 'Units' 'Enum table' 'Default during Running'};
     
     writetable(DD_table,File_name,'Sheet',1);
     writetable(DD_table_cal,File_name,'Sheet',2);
     
     xlsApp = actxserver('Excel.Application');
     ewb = xlsApp.Workbooks.Open([DD_path '\' File_name]);
     ewb.Worksheets.Item(1).name = 'Signals'; 
     ewb.Worksheets.Item(2).name = 'Calibrations'; 
     ewb.Save();
     ewb.Close(true);
     verctrl = 'FVT_export_businfo_v3.0 2022-09-06';
     disp('Writing DD file...');
     buildbus(File_name,DD_path,DD_table,DD_table_cal,verctrl);
     cd(arch_Path);
     Module = ['HAL_' Channel];
     Build_SWC_APP(Module,DD_cell,project_path)
end
disp('FVT_HALIN.arxml Done!');
% Copy DD to other car models
% for car_model_indx = 2:length(ref_car_model)
%     car_model = ref_car_model{car_model_indx};
%     Copy_DD_to_other_car_models(car_model, Common_Scripts_path, arch_Path);
% end

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

function Unit_modify = UnitChange(Rx_Signal_unit)

Unit_modify = Rx_Signal_unit;

    switch Rx_Signal_unit
        case {'Percent','Percent0-100%','%','percent (%)','percent^%^'}
            Unit_modify = cellstr('pct');   
        case {'km/h'}
            Unit_modify = cellstr('kph');
        case {'RPM','Rpm'}
             Unit_modify = cellstr('rpm');
        case {'Volt','voltage','Voltage'}
             Unit_modify = cellstr('V');
        case {'KW','kw','k-Watt'}
             Unit_modify = cellstr('kW');
        case {'watt.hour'}
             Unit_modify = cellstr('Wh');
        case {'Watt'}
             Unit_modify = cellstr('W');     
        case {'KWh','kwh'}
             Unit_modify = cellstr('kWh');
        case {'wh/km'}
             Unit_modify = cellstr('Whpkm');
        case {'m/s2','m/s^2','m/s 2','m/s?'}
             Unit_modify = cellstr('mps2');
        case {'m/s^3'}
             Unit_modify = cellstr('mps3');
        case {'m/s'}
             Unit_modify = cellstr('mps');
        case {'kg/m^2'}
             Unit_modify = cellstr('kgpm2');
        case {'Wphr'}
             Unit_modify = cellstr('Wph');
        case {'Amp','Ampere'}
             Unit_modify = cellstr('A');
        case {'degC','DegC','Deg C','Deg^C'}
             Unit_modify = cellstr('C');
        case {'deg/s','Deg/s'}
             Unit_modify = cellstr("degps");
        case {'L/100km'}
             Unit_modify = cellstr("Lp100km");
        case {'S','Sec','SECOND'}
            Unit_modify = cellstr('s');
        case {'HOUR'}
            Unit_modify = cellstr('hr');
        case {'MINUTE'}
            Unit_modify = cellstr('min');
        case {"G's"}
            Unit_modify = cellstr('Gps');
        case {'L/min'}
            Unit_modify = cellstr('Lpmin');
        case {'KM'}
            Unit_modify = cellstr('km');
        case {'cycle','cycle(s)'}
            Unit_modify = cellstr('cyc');
        case {'^'}
            Unit_modify = cellstr('enum');
        case {'m^(-1)','1/meter','1/meter^2'}
            Unit_modify = cellstr('raw32');
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
    str_m = table2cell(signal_table(i,1)); 
    str_m = char(str_m); 
    str_dir = table2cell(signal_table(i,2)); 
    str_dir = char(str_dir); 
    type = table2cell(signal_table(i,3)); 
    type = char(type);     
    unit = extractAfter(str_m,"_");
    unit = extractAfter(unit,"_");   
    
    min = table2cell(signal_table(i,4)); 
    max = table2cell(signal_table(i,5)); 
    
    internal_flg = strcmp(str_dir,'internal'); 
    outputs_flg = strcmp(str_dir,'output');
    
    if (isempty(type)==0)&&(internal_flg==1)
        num_sig_internal = num_sig_internal +1;
        internal_arry(num_sig_internal,1) = cellstr(str_m); 
        internal_arry(num_sig_internal,2) = cellstr(type);
        internal_arry(num_sig_internal,3) = cellstr(unit);        
        internal_arry(num_sig_internal,4) = (min);       
        internal_arry(num_sig_internal,5) = (max);    
    elseif (isempty(type)==0)&&(outputs_flg==1)
        num_sig_outputs = num_sig_outputs +1; 
        output_arry(num_sig_outputs,1) = cellstr(str_m); 
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
    str_m = table2cell(calibration_table(i,1));
    str_tablechk = extractBefore(str_m,"_"); 
    if (str_tablechk~=string(A_str))&&(str_tablechk~=string(m_str))
    str_m = char(str_m); 
    defval = string(table2cell(calibration_table(i,8)));
        if (ismissing(defval)==1)
            defval = '0';
        end 
    sig = strcat("a2l_cal(","'",str_m,"',","     ", defval,")",";");
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
    str_m = output_arry(i,1) ;
    str_m = string(str_m); 
    type = output_arry(i,2) ;
    type = string(type); 
    sens = strcat("{","'", str_m ,"' ", " ,1, ", " '", type ,"' ", " ,-1" , ", 'real'", " ,'Sample'};...");
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
        str_m = table2cell(calibration_table(i,1)); 
        str_m = string(str_m); 
        unit = table2cell(calibration_table(i,6)); 
        unit = string(unit); 
        type = table2cell(calibration_table(i,3)); 
        type = string(type); 
        max = table2cell(calibration_table(i,5)); 
        max = string(max); 
        min = table2cell(calibration_table(i,4)); 
        min = string(min); 

        sens = strcat("a2l_par('", str_m, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
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
        str_m = string(internal_arry(i,1)); 
        unit = string(internal_arry(i,3));
        type = string(internal_arry(i,2));
        max = string(internal_arry(i,5));
        min = string(internal_arry(i,4));
        sens = strcat("a2l_mon('", str_m, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
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
        str_m = string(output_arry(i,1)); 
        unit = string(output_arry(i,3));
        type = string(output_arry(i,2));
        max = string(output_arry(i,5));
        min = string(output_arry(i,4));
        sens = strcat("a2l_mon('", str_m, "', 	'", unit,"',    ",min,",    ",max,",    ","'",type,"',    '');");
        fprintf(fileID,[ char(sens)  '\n'...
                       ]);
    end   
end 

% Close the file.
fclose(fileID);
% Open the file in the editor.
% save(varfile);
end

function database = LinDatabase(Filepath,FileName,Linchannel,password)
%% read excel file
xlsAPP = actxserver('excel.application');
xlsAPP.Visible = 1;
xlsWB = xlsAPP.Workbooks;
xlsFile = xlsWB.Open([Filepath FileName],[],false,[],password);
exlSheet1 = xlsFile.Sheets.Item(Linchannel);
dat_range = exlSheet1.UsedRange;
raw_data = dat_range.value;
exlSheet1 = xlsFile.Sheets.Item('Schedule');
dat_range = exlSheet1.UsedRange;
raw_data_schedule = dat_range.value;
Buf = find(strcmp(raw_data_schedule(:,1),'Slot ID'));
raw_data_schedule(1:Buf,:) = [];
data_schedule(:,1) = string(raw_data_schedule(:,2));
data_schedule(:,2) = string(raw_data_schedule(:,3));% ID(dec), delay time
xlsFile.Close(false);
xlsAPP.Quit;
%% create LIN DBC
raw_data{1,1} = [];
database = struct;
MsgIndex = find(cell2mat(cellfun(@(x)any(~isnan(x)),raw_data(:,1),'UniformOutput',false)));
MsgCnt = length(MsgIndex);
for i = 1:MsgCnt
    database.Messages(i,1) = raw_data(MsgIndex(i),1);
    database.MessageInfo(i).Name = char(raw_data(MsgIndex(i),1));
    database.MessageInfo(i).ID = hex2dec(char(raw_data(MsgIndex(i),2)));
    database.MessageInfo(i).PID = hex2dec(char(raw_data(MsgIndex(i),3)));
    database.MessageInfo(i).Length = raw_data(MsgIndex(i),6);
    database.MessageInfo(i).TxNodes = raw_data(1,strcmp(raw_data(MsgIndex(i),:),'Tx'));

    ScheduleIdx = find(strcmp(data_schedule(:,1),char(raw_data(MsgIndex(i),2))));
    if ScheduleIdx == 1
        database.MessageInfo(i).Delay = '0';
    else
        database.MessageInfo(i).Delay = num2str(sum(str2double(data_schedule(1:ScheduleIdx(1)-1,2))));
    end
     database.MessageInfo(i).MsgCycleTime = num2str(sum(str2double(data_schedule(1:end,2)))/length(ScheduleIdx));

    if i ~= MsgCnt
        Signallength = MsgIndex(i+1)-MsgIndex(i)-2;
        database.MessageInfo(i).Signals = raw_data(MsgIndex(i)+1:MsgIndex(i)+Signallength,7);
        for k = 1:Signallength
            database.MessageInfo(i).SignalInfo(k).Name = char(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Name')));

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Bit Length (Bit)')));
            % From ET_V09 CAN team changed LIN messagemap column name
            if isempty(Buf); Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Length (Bit)'))); end

            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).SignalSize = Buf; else; database.MessageInfo(i).SignalInfo(k).SignalSize = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Start Bit')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).StartBit = Buf; else; database.MessageInfo(i).SignalInfo(k).StartBit = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Resolution')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Factor = Buf; else; database.MessageInfo(i).SignalInfo(k).Factor = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Offset')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Offset = Buf; else; database.MessageInfo(i).SignalInfo(k).Offset = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Min. Value (phys)')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Minimum = Buf; else; database.MessageInfo(i).SignalInfo(k).Minimum = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Max. Value (phys)')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Maximum = Buf; else; database.MessageInfo(i).SignalInfo(k).Maximum = str2double(Buf); end
            
            Buf = raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Unit'));
            if ismissing(string(Buf)); database.MessageInfo(i).SignalInfo(k).Units = ""; else; database.MessageInfo(i).SignalInfo(k).Units = char(Buf); end

        end

    else
        Signallength = length(raw_data(:,1)) - MsgIndex(i);
        database.MessageInfo(i).Signals = raw_data(MsgIndex(i)+1:end,7);
        for k = 1:Signallength
            database.MessageInfo(i).SignalInfo(k).Name = char(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Name')));

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Bit Length (Bit)')));
            % From ET_V09 CAN team changed LIN messagemap column name
            if isempty(Buf); Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Length (Bit)'))); end

            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).SignalSize = Buf; else; database.MessageInfo(i).SignalInfo(k).SignalSize = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Start Bit')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).StartBit = Buf; else; database.MessageInfo(i).SignalInfo(k).StartBit = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Resolution')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Factor = Buf; else; database.MessageInfo(i).SignalInfo(k).Factor = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Offset')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Offset = Buf; else; database.MessageInfo(i).SignalInfo(k).Offset = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Min. Value (phys)')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Minimum = Buf; else; database.MessageInfo(i).SignalInfo(k).Minimum = str2double(Buf); end

            Buf = cell2mat(raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Signal Max. Value (phys)')));
            if isnumeric(Buf); database.MessageInfo(i).SignalInfo(k).Maximum = Buf; else; database.MessageInfo(i).SignalInfo(k).Maximum = str2double(Buf); end
            
            Buf = raw_data(MsgIndex(i)+k,strcmp(raw_data(1,:),'Unit'));
            if ismissing(string(Buf)); database.MessageInfo(i).SignalInfo(k).Units = ""; else; database.MessageInfo(i).SignalInfo(k).Units = char(Buf); end

        end
    end
end

end

% function Copy_DD_to_other_car_models(car_model, Common_Scripts_path, arch_Path)
%     project_path = char(strcat(Common_Scripts_path, '/../../', car_model));
%     source_dd_Path = [arch_Path '/hal'];
%     target_dd_Path = [project_path '/software/sw_development/arch/hal'];
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

