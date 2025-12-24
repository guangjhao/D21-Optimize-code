function Modify_MessageLink()
%% Loading excel
arch_Path = pwd;
if ~contains(arch_Path, 'arch'), error('current folder is not under arch'), end
project_path = extractBefore(arch_Path,'\software');

TargetNode = {'FUSION'};

% % Select routing table
% path = [project_path '\documents\MessageMap\'];
% filenames = dir(path);
% filenames = string({filenames.name});
% RoutingTableName = char(filenames(contains(filenames,['RoutingTable_' char(TargetNode)])));
% password = filenames(contains(filenames,'to@'));
% password = extractBefore(password,'.txt');
% 
% xlsAPP = actxserver('excel.application');
% xlsAPP.Visible = 1;
% xlsWB = xlsAPP.Workbooks;
% xlsFile = xlsWB.Open([path RoutingTableName],[],false,[],password);
% exlSheet1 = xlsFile.Sheets.Item('RoutingTable');
% dat_range = exlSheet1.UsedRange;
% raw_data = dat_range.value;
% xlsFile.Close(false);
% xlsAPP.Quit;
% 
% %% Data filter
% [data_m , ~] = size(raw_data);
% Numb_restore = 0;
% Restore_array = cell(1,1);
% raw_data(cellfun(@(x) all(ismissing(x)), raw_data)) = {'Invalid'};
% raw_data(end+1,:) = {'Invalid'};
% for i = 1:data_m
%     SignalName = raw_data(i,1);
%     Rx_MessageName = raw_data(i,2);
%     Tx_MessageName = raw_data(i,5);
%     str_s = string(SignalName);
%     
%     if ~strcmp(raw_data(i,1),'Invalid')
%         % Here is use for save parameter from raw_data to Restore_array       
%         Array_space = isspace(str_s);
%         Numb_space = sum(Array_space);
% 
%         if strcmp(SignalName,'Signal Name')
%             CAN_chn = extractAfter(raw_data(i-1,1),'source:');
%             CAN_chn_res = char(CAN_chn);
%             CAN_chn = extractAfter(raw_data(i-1,4),'target:');
%             CAN_chn_out = char(erase(CAN_chn,'_'));
%         end
%         if (Numb_space==0)
%             Numb_restore = Numb_restore+1;
%             Restore_array(Numb_restore,1) = cellstr(CAN_chn_res);
%             Restore_array(Numb_restore,2) = SignalName;
% 
%             if ~strcmp(Rx_MessageName,'Invalid')
%                 Restore_array(Numb_restore,3) = Rx_MessageName;
%             else
%                 Restore_array(Numb_restore,3) = Restore_array(Numb_restore-1,3);
%             end
% 
%             Restore_array(Numb_restore,4) = cellstr(CAN_chn_out);
%             Restore_array(Numb_restore,5) = raw_data(i,4);
% 
%             if ~strcmp(Tx_MessageName,'Invalid')
%                 Restore_array(Numb_restore,6) = Tx_MessageName;
%             else
%                 Restore_array(Numb_restore,6) = Restore_array(Numb_restore-1,6);
%             end
% 
%             Restore_array(Numb_restore,7) = raw_data(i,10);
%         end
%     end
% end
% 
% Restore_array = sortrows(Restore_array,1);
% target_channel_array = unique(Restore_array(:,1)); 
% 
% % Numb_categty is total CAN channel found in Restore_array
% if strcmp(TargetNode,'FUSION')
% categty = {'CAN1';'CAN2';'CAN3';'CAN4';'CAN5';'CAN6'};
% Numb_categty = length(categty);
% elseif strcmp(TargetNode,'ZONE_DR')
% categty = {'CAN4';'CANDr1';'LINDr1';'LINDr2';'LINDr3';'LINDr4'};
% Numb_categty = length(categty);
% elseif strcmp(TargetNode,'ZONE_FR')
% categty = {'CAN4';'CANFr1';'LINFr1';'LINFr2'};
% Numb_categty = length(categty);
% end
% 
% %% Modify MessageLink for new input signal
% cd([project_path '/documents/MessageLink'])
% MessageLink_data = string(readcell('CAN_MessageLink.xlsx','Sheet','InputSignal'));
% MessageLink_inport = MessageLink_data(2:end,1);
% last_row = find(~cellfun(@isempty, MessageLink_inport), 1, 'last')+2;
% str_array = ['A' string(last_row)];
% xlRange = strjoin(str_array, '');
% Input_signal = string(cellfun(@(x) strrep(x, '''', ''), Restore_array(:, 2), 'UniformOutput', false));
% Input_unique = unique(Input_signal);
% j=1;
% for i = 1:length(Input_unique)
%     if ~ismember(Input_unique(i),MessageLink_inport)
%         New_inport(j,1) =Input_unique(i);
%         j = j+1;
%     end
% end
% if j ~= 1
%     xlswrite('CAN_MessageLink.xlsx',New_inport,'InputSignal',xlRange)
% end

% Clone Message Map and MessageLink to new folder on desktop

desktopPath = fullfile(getenv('USERPROFILE'), 'Desktop');
mkdir(desktopPath,'zzz_MessageLinkout_Create');
MSGCreate_path = [desktopPath '\zzz_MessageLinkout_Create\'];
MessageMap_path = [project_path '\documents\MessageMap\'];
MessageLink_path = [project_path '\documents\'];
Map_files = dir([MessageMap_path '*.dbc']);
Routing_file = dir([MessageMap_path '*RoutingTable*']);
for i = 1:length(Map_files)
        copyfile([Map_files(i).folder '\' Map_files(i).name],[MSGCreate_path Map_files(i).name]);
end
copyfile([Routing_file.folder '\' Routing_file.name],[MSGCreate_path Routing_file.name]);
copyfile([Map_files(i).folder '\' Map_files(i).name],[MSGCreate_path Map_files(i).name]);
Link_files = dir([MessageLink_path 'CAN_MessageLink.xlsx']);
copyfile([Link_files.folder '\' Link_files.name],[MSGCreate_path Link_files.name]);

end

