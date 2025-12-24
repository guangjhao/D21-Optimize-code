function Check_vcu_local_hdr_Definition()
% Check if the definition in vcu_local_hdr.m matches the definition in .dbc files 

%% Initial settings
Common_Scripts_path = pwd;
if ~contains(Common_Scripts_path, 'common\Scripts'), error('current folder is not under common\Scripts'), end

TargetNode = 'FUSION';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUS list is real CAN channel in BSP. It depends on hardware layout and
% vehicle side cable.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(TargetNode,'FUSION')
    channel_list = {'CAN1','CAN2','CAN3','CAN4','CAN5','CAN6'};
    busList =      {'1','2','3','4','6','7'};
    NUM_CAN_CHANNEL = '6';
    NUM_LIN_CHANNEL = '0';
elseif strcmp(TargetNode,'ZONE_DR')
    channel_list = {'CAN_Dr1','CAN4','LIN_Dr1','LIN_Dr2','LIN_Dr3','LIN_Dr4'};
    busList =      {'1','0','0','1','2','3'};
    NUM_CAN_CHANNEL = '2';
    NUM_LIN_CHANNEL = '4';
elseif strcmp(TargetNode,'ZONE_FR')
    channel_list = {'CAN_Fr1','CAN4','LIN_Fr1','LIN_Fr2'};
    busList =      {'1','0','0','1'};
    NUM_CAN_CHANNEL = '2';
    NUM_LIN_CHANNEL = '2';
else
    error('Undefined target ECU');
end

q = [1, 2, 3, 4, 5, 6];

NUN_CHANNEL = length(q);

%% Load vcu_local_hdr.m
evalin('base', 'run vcu_local_hdr');
baseVars = evalin('base', 'who');
ENUMStruct = struct();
enumVars = baseVars(~cellfun('isempty', regexp(baseVars, '^ENUM_')));

for i = 1:length(enumVars)
    ENUMName = enumVars{i};
    ENUMValue = evalin('base', ENUMName);
    underscorePositions = strfind(ENUMName, '_');
    if length(underscorePositions) ~= 2
        continue
    end
    SigNametokens = regexp(ENUMName, '_(.*?)_', 'tokens');
    ENUMSigName = SigNametokens{1}{1};
    Texttokens = regexp(ENUMName, '_([^_]*)$', 'tokens');
    ENUMText = Texttokens{1}{1};

    ENUMStruct(end+1).ENUMName = ENUMName;
    ENUMStruct(end).Value = ENUMValue;
    ENUMStruct(end).SigName = ENUMSigName;
    ENUMStruct(end).Text = ENUMText;
end
ENUMStruct = ENUMStruct(2:end);

SigTable = [{'Name', 'Text', 'Value'}];

SigStruct = struct();
SigStruct.Name = '';
DisMatchStruct = struct();
DisMatchStruct.Match = cell(1);

%% Working for seperate channel
for i = 1:NUN_CHANNEL
    
    % read DBC or LIN message map
    Channel = char(channel_list(q(i)));
    busID = char(busList(q(i)));
 
    if contains(Channel,'CAN')
        IsLINMessage = boolean(0);
        path = [Common_Scripts_path '\..\documents\MessageMap\'];
        filenames = dir(path);
        filenames = string({filenames.name});
        FileName = string(filenames(contains(filenames,Channel)));
        FileName = char(FileName(contains(FileName,'.dbc')));
        DBC= canDatabase([path FileName]);
    else
        Filepath = [Common_Scripts_path '\..\documents\MessageMap\'];
        filenames = dir(Filepath);
        filenames = string({filenames.name});
        FileName = string(filenames(contains(filenames,Channel)));
        FileName = char(FileName(contains(FileName,'.xlsx')));
        DBC = LinDatabase(Filepath,FileName,Channel,password);
        IsLINMessage = boolean(1);
    end
    Channel = erase(Channel, '_');

    %% generate MsgTable and define CAN filter
    MsgTable = cell(length(DBC.Messages),9); 
    filter = '[';

    for j = 1:length(DBC.Messages)  
        MsgTable(j,1) = num2cell(j); % DBC index
        MsgTable(j,2) = num2cell(DBC.MessageInfo(j).ID); % Message ID in dec
        MsgTable(j,3) = num2cell(DBC.MessageInfo(j).Length); % Data length
        MsgTable(j,4) = cellstr(DBC.MessageInfo(j).Name); % Message name
        MsgTable(j,5) = cellstr(erase(DBC.MessageInfo(j).Name,'_')); % Message name for DD
        MsgTable(j,6) = cellstr(DBC.MessageInfo(j).TxNodes); % Message Tx node
        MsgTable(j,9) = cellstr(DBC.MessageInfo(j).Comment); % Message Comment

        if IsLINMessage
            MsgTable(j,2) = num2cell(DBC.MessageInfo(j).PID); % LIN message use PID
            MsgTable(j,7) = cellstr(DBC.MessageInfo(j).MsgCycleTime); % LIN message cycle time
            MsgTable(j,8) = cellstr(DBC.MessageInfo(j).Delay); % LIN message delay time
            filter = [filter ' 0x' num2str(dec2hex(DBC.MessageInfo(j).PID))];
        else
            MsgTable(j,7) = num2cell(DBC.MessageInfo(j).AttributeInfo(strcmp(DBC.MessageInfo(j).Attributes(:,1),'GenMsgCycleTime')).Value);
            MsgTable(j,8) = cellstr('0');
            filter = [filter ' 0x' num2str(dec2hex(DBC.MessageInfo(j).ID))];
        end
        
        %% Process useful infos and save into SigStruct
        for k = 1:length(DBC.MessageInfo(j).Signals)
            SigTable(end+1,1) = cellstr(DBC.MessageInfo(j).SignalInfo(k).Name);
            
            if ~isempty(DBC.MessageInfo(j).SignalInfo(k).ValueTable)
                SigName = DBC.MessageInfo(j).SignalInfo(k).Name;
                LocalSigName = upper(strrep(SigName, '_', ''));
                if any(strcmp({SigStruct.Name}, SigName))
                    continue
                end
                SigStruct(end+1).Name = SigName;
                SigStruct(end).LocalName = LocalSigName;
                SigStruct(end).Text = {DBC.MessageInfo(j).SignalInfo(k).ValueTable.Text};
                SigStruct(end).Value = {DBC.MessageInfo(j).SignalInfo(k).ValueTable.Value};
                
                ENUM_cell = {};
                ENUMText_cell = {};
                ENUMValue_cell = {};
                for l = 1:length(ENUMStruct)
                    if strcmp(ENUMStruct(l).SigName, LocalSigName)
                        ENUM_cell{end+1} = ENUMStruct(l).ENUMName;
                        ENUMText_cell{end+1} = ENUMStruct(l).Text;
                        ENUMValue_cell{end+1} = evalin('base', ENUMStruct(l).ENUMName);
                    end
                end

                SigStruct(end).ENUM = ENUM_cell;
                SigStruct(end).ENUMText = ENUMText_cell;
                SigStruct(end).ENUMValue = ENUMValue_cell;
            end
        end
    end
    filter = [filter ']'];
    
    SigStruct = SigStruct(2:end);
    
    for j = length(MsgTable(:,1)):-1:1
        if cellfun(@isempty,MsgTable(j,1))
            MsgTable(j,:) = [];
        end
    end

    for j = length(SigTable(:,1)):-1:1
        if cellfun(@isempty,SigTable(j,1))
            SigTable(j,:) = [];
        end
    end

    MsgTable = [{'DBCidx','ID/PID(dec)','DLC','MsgName','MsgName_DD','TxNode','MsgCycleTime','LIN Delay time','Comment'};MsgTable]; 
end

%% Display results
NotCompletelyDefinedSigName = {};
NotCompletelyDefinedENUMNum = {};
NotCompletelyDefinedDBCNum = {};
fprintf('\n<strong>%s</strong>\n', 'Definition in dbc and vcu_local_hdr :');
fprintf('=============================================================================')
for i = 1:length(SigStruct)
    if ~isempty(SigStruct(i).ENUM)
        
        if length(SigStruct(i).ENUM) < length(SigStruct(i).Value)
            NotCompletelyDefinedSigName{end+1} = SigStruct(i).Name;
            NotCompletelyDefinedENUMNum{end+1} = length(SigStruct(i).ENUM);
            NotCompletelyDefinedDBCNum{end+1} = length(SigStruct(i).Value);
        end

        Text_Compared = upper(strrep(SigStruct(i).Text, ' ', ''));
        Text_Compared = strrep(Text_Compared, ' ', '');
        Text_Compared = strrep(Text_Compared, '+', 'PLUS');
        Text_Compared = strrep(Text_Compared, '-', 'MINUS');
        Text_Compared = strrep(Text_Compared, 'KM/H', 'KPH');
        
        Value_Compared = SigStruct(i).Value;
        
        ENUM_Compared = SigStruct(i).ENUMText;

        ENUMValue_Compared = SigStruct(i).ENUMValue;
        
        % Initialize the variables to store all matches and distances
        allMatches = [];
        distances = [];

        % Calculate all possible matches and their distances
        for j = 1:length(Text_Compared)
            str1 = Text_Compared{j};
            for k = 1:length(ENUM_Compared)
                str2 = ENUM_Compared{k};
                dist = editDistance(str1, str2);
                allMatches = [allMatches; {j, k, dist}];
            end
        end

        % Sort the matches by distance
        allMatches = sortrows(allMatches, 3);

        % Initialize the variables to store the results
        bestMatches = cell(length(Text_Compared), 2); % Use cell array to store strings
        matchedENUM_Compared = false(length(ENUM_Compared), 1);

        % Find the best matches without duplication
        for k = 1:size(allMatches, 1)
            m = allMatches{k, 1};
            n = allMatches{k, 2};
            dist = allMatches{k, 3};
            if isempty(bestMatches{m, 2}) && ~matchedENUM_Compared(n)
                bestMatches{m, 1} = Text_Compared{m};
                bestMatches{m, 2} = Value_Compared{m};
                bestMatches{m, 3} = ENUM_Compared{n};
                bestMatches{m, 4} = ENUMValue_Compared{n};
                if Value_Compared{m} ~= ENUMValue_Compared{n}
                    bestMatches{m, 5} = 'Definition Dismatched !!!';
                else
                    bestMatches{m, 5} = '';
                end
                matchedENUM_Compared(n) = true;
            end
        end

        
        if any(~cellfun(@isempty, bestMatches(:, 5)))
            DisMatchStruct.Match(end+1) = {bestMatches};
        end

        fprintf('\n<strong>%s</strong>\n', SigStruct(i).Name);
        for k = 1:height(bestMatches)
            if ~any(cellfun(@isempty, bestMatches(k, 1:4)))
                fprintf('DBC: %-25s = %-3s >>  ENUM: %-25s = %-3s   %-10s \n', ...
                    string(bestMatches(k,1)), string(bestMatches(k,2)), string(bestMatches(k,3)), string(bestMatches(k,4)), string(bestMatches(k,5)))
            end
        end
        
    end
end



if ~isempty(NotCompletelyDefinedSigName)
    fprintf('\n\n<strong>%s</strong>\n', 'Not Completely Defined Signals Name :');
    disp('=============================================================================')
    for i = 1:length(NotCompletelyDefinedSigName)
        fprintf('%-25s DBC: %-3s >>  ENUM: %-3s \n', ...
            string(NotCompletelyDefinedSigName(i)), string(NotCompletelyDefinedDBCNum(i)), string(NotCompletelyDefinedENUMNum(i)))
    end
else % isempty(NotCompletelyDefinedSigName)
    fprintf('\n<strong>%s</strong>\n', 'All  SignalsCompletely Defined.');
end

end
% main end



%% Function to calculate edit distance
function dist = editDistance(str1, str2)
    len1 = length(str1);
    len2 = length(str2);
    % Create a distance matrix
    D = zeros(len1+1, len2+1);
    % Initialize the first row and column
    for i = 1:len1+1
        D(i, 1) = i-1;
    end
    for j = 1:len2+1
        D(1, j) = j-1;
    end
    % Fill in the distance matrix
    for i = 2:len1+1
        for j = 2:len2+1
            cost = (str1(i-1) ~= str2(j-1));
            D(i, j) = min([D(i-1, j) + 1, D(i, j-1) + 1, D(i-1, j-1) + cost]);
        end
    end
    % The edit distance is the value in the bottom-right corner of the matrix
    dist = D(len1+1, len2+1);
end