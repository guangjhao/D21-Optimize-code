function Gen_A2L()
project_path = pwd;

% q = questdlg({'1. All a2l files finished?'}, ...
% 	'Initial check', 'Yes','No','Yes');
% if ~contains(q, 'Yes')
%     return
% end

%% Select SWC_APP
a2l_dir = [project_path '/documents/A2L_Files'];
a2l_dir = char(a2l_dir);
pro_a2l_dir = dir(a2l_dir);
pro_a2l_dir = struct2table(pro_a2l_dir);
pro_a2l_dir = table2cell(pro_a2l_dir);
num_pro_a2l_dir = length(pro_a2l_dir(:,1));

ref_a2l = {''};
k=0;
for i = 1:num_pro_a2l_dir
    str = pro_a2l_dir(i,1);
    if contains(str,'.a2l')
        k =k+1;
        target_a2l_array(k,1) = str;
    end 
end 
% [indx, ~] = listdlg('PromptString',{'Select the a2l you want to merge.'},'ListSize',[200,200],'ListString',ref_a2l);
% 
% target_a2l_array = {};
% for i = 1:length(indx)
%     target_a2l_array(i,1) = ref_a2l(indx(i));
% end
cd([project_path '/documents/A2L_Files']);

%% Get a2l file
for k = 1:length(target_a2l_array)
    target_a2l = char(target_a2l_array(k));
    fileID = fopen(target_a2l);
    
    A2L_tmpCell = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
    tmpCell = cell(length(A2L_tmpCell{1,1}),1);
    for i = 1:length(A2L_tmpCell{1,1})
        tmpCell{i,1} = A2L_tmpCell{1,1}{i,1};
    end
    A2L_tmpCell = tmpCell;
    fclose(fileID);
    
    %% Search CHARACTERISTIC
    CHARCT_start = find(contains(A2L_tmpCell(:,1),'/begin CHARACTERISTIC'),1,'first');
    CHARCT_end = find(contains(A2L_tmpCell(:,1),'/end CHARACTERISTIC'),1,'last');
    
    CHARCT_tmpCell = A2L_tmpCell(CHARCT_start:CHARCT_end);
    
    %% Search MEASUREMENT
    MEASUREMENT_start = find(contains(A2L_tmpCell(:,1),'/begin MEASUREMENT'),1,'first');
    MEASUREMENT_end = find(contains(A2L_tmpCell(:,1),'/end MEASUREMENT'),1,'last');
    
    MEASUREMENT_tmpCell = A2L_tmpCell(MEASUREMENT_start:MEASUREMENT_end);
    
	%% Search COMPU_METHOD_part1
	COMPU_METHOD_part1_start = find(contains(A2L_tmpCell(:,1),'/begin COMPU_METHOD'),1,'first');
    COMPU_METHOD_part1_end = find(contains(A2L_tmpCell(:,1),'/end COMPU_METHOD'),1,'last');
    
    COMPU_METHOD_part1_tmpCell = A2L_tmpCell(COMPU_METHOD_part1_start:COMPU_METHOD_part1_end);
	
    if k ==1
        ALL_CHARCT_tmpCell = CHARCT_tmpCell;
        ALL_MEASUREMENT_tmpCell = MEASUREMENT_tmpCell;
		ALL_COMPU_METHOD_part1_tmpCell = COMPU_METHOD_part1_tmpCell;
    else
        ALL_CHARCT_tmpCell = [ALL_CHARCT_tmpCell;char(0x0);char(0x0);CHARCT_tmpCell];
        ALL_MEASUREMENT_tmpCell = [ALL_MEASUREMENT_tmpCell;char(0x0);char(0x0);MEASUREMENT_tmpCell];
		ALL_COMPU_METHOD_part1_tmpCell = [ALL_COMPU_METHOD_part1_tmpCell;char(0x0);char(0x0);COMPU_METHOD_part1_tmpCell];
    end

    % Replace COMPU_METHOD
    h = find(contains(ALL_CHARCT_tmpCell(:,1),erase(target_a2l,'.a2l')));
    OldString = erase(target_a2l,'.a2l');
    NewString = 'SWC_FDC_type';
    ALL_CHARCT_tmpCell(h) = strrep(ALL_CHARCT_tmpCell(h),OldString,NewString);

    h = find(contains(ALL_MEASUREMENT_tmpCell(:,1),erase(target_a2l,'.a2l')));
    OldString = erase(target_a2l,'.a2l');
    NewString = 'SWC_FDC_type';
    ALL_MEASUREMENT_tmpCell(h) = strrep(ALL_MEASUREMENT_tmpCell(h),OldString,NewString);
	
	h = find(contains(ALL_COMPU_METHOD_part1_tmpCell(:,1),erase(target_a2l,'.a2l')));
    OldString = erase(target_a2l,'.a2l');
    NewString = 'SWC_FDC_type';
    ALL_COMPU_METHOD_part1_tmpCell(h) = strrep(ALL_COMPU_METHOD_part1_tmpCell(h),OldString,NewString);
end

% Remove /begin IF_DATA XCP (B1XF-2113)
h = find(strcmp(ALL_MEASUREMENT_tmpCell(:,1),'      /begin IF_DATA XCP '));
if ~isempty(h)
    h1 = find(strcmp(ALL_MEASUREMENT_tmpCell(:,1),'      /begin IF_DATA CANAPE_EXT')) + 3;
    for i = 1:length(h)
    ALL_MEASUREMENT_tmpCell(h(i):h1(i)) = {'XXX'};
    end
    delete_idx = strcmp(ALL_MEASUREMENT_tmpCell,{'XXX'});
    ALL_MEASUREMENT_tmpCell(delete_idx) = [];
end

% Modify COMPU_METHOD_part1
h = find(contains(ALL_COMPU_METHOD_part1_tmpCell,'SWC_FDC_type'));
Array(:,1) = erase(extractAfter(ALL_COMPU_METHOD_part1_tmpCell(h),'*/'),' ');
Array(:,2) = num2cell(h(1:end));
for j = 1:length(Array(:,1))
    clear h
    target_method = Array(j,1);
    if strcmp(target_method,'XXX')
        continue
    end
	h = find(strcmp(Array(:,1),target_method));
	if length(h) > 1
        Array(h,1) = {'XXX'};
		for k = 2:length(h)
            start_idx = cell2mat(Array(h(k),2))-1;
            end_idx = cell2mat(Array(h(k),2))+7;
            ALL_COMPU_METHOD_part1_tmpCell(start_idx:end_idx) = {'XXX'};
		end
	end
end
Delete_idx = strcmp(ALL_COMPU_METHOD_part1_tmpCell,'XXX');
ALL_COMPU_METHOD_part1_tmpCell(Delete_idx) = [];

Final_a2l = 'SWC_FDC_type.a2l';
fileID = fopen(Final_a2l);

Final_a2l_tmpCell = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Final_a2l_tmpCell{1,1}),1);
for i = 1:length(Final_a2l_tmpCell{1,1})
    tmpCell{i,1} = Final_a2l_tmpCell{1,1}{i,1};
end
Final_a2l_tmpCell = tmpCell;
fclose(fileID);

% Replace oringal part 
CHARCT_start = find(contains(Final_a2l_tmpCell(:,1),'/begin CHARACTERISTIC'),1,'first');
CHARCT_end = find(contains(Final_a2l_tmpCell(:,1),'/end CHARACTERISTIC'),1,'last');

Final_a2l_tmpCell = [Final_a2l_tmpCell(1:CHARCT_start-1);ALL_CHARCT_tmpCell;Final_a2l_tmpCell(CHARCT_end+1:end)];

MEASUREMENT_start = find(contains(Final_a2l_tmpCell(:,1),'/begin MEASUREMENT'),1,'first');
MEASUREMENT_end = find(contains(Final_a2l_tmpCell(:,1),'/end MEASUREMENT'),1,'last');

Final_a2l_tmpCell = [Final_a2l_tmpCell(1:MEASUREMENT_start-1);ALL_MEASUREMENT_tmpCell;Final_a2l_tmpCell(MEASUREMENT_end+1:end)];

COMPU_METHOD_part1_start = find(contains(Final_a2l_tmpCell(:,1),'/begin COMPU_METHOD'),1,'first');
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
COMPU_METHOD_part1_end = find(contains(Final_a2l_tmpCell(:,1),'/begin COMPU_METHOD'),1,'last');
=======
COMPU_METHOD_part1_end = find(contains(Final_a2l_tmpCell(:,1),'/end COMPU_METHOD'),1,'last');
>>>>>>> 3e28ed96fb (dev-TA2: Modify Gen_A2L and SWC_FDC_type.a2l)
=======
COMPU_METHOD_part1_end = find(contains(Final_a2l_tmpCell(:,1),'/end COMPU_METHOD'),1,'last');
>>>>>>> b014a821e8 (dev-TA2: Update source code)
=======
COMPU_METHOD_part1_end = find(contains(Final_a2l_tmpCell(:,1),'/end COMPU_METHOD'),1,'last');
>>>>>>> 239ebbc89580a9342d80e09bacc21f780fff453d

Final_a2l_tmpCell = [Final_a2l_tmpCell(1:COMPU_METHOD_part1_start-1);ALL_COMPU_METHOD_part1_tmpCell;Final_a2l_tmpCell(COMPU_METHOD_part1_end+1:end)];

%% Output FVT_APP_arxml
cd([project_path '/documents']);
fileID = fopen('SWC_FDC_type.a2l','w');
for i = 1:length(Final_a2l_tmpCell(:,1))
    fprintf(fileID,'%s\n',char(Final_a2l_tmpCell(i,1)));
end
fclose(fileID);
cd(project_path);
end
