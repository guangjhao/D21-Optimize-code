function Modify_SWC_DID_type(RAW_CODE_path)

    %% Set paths
    project_path = pwd;
    RAW_CODE_DID_path = [RAW_CODE_path '\SWC_DID_type_autosar_rtw'];

    %% Read FVT_DIDList
    FVT_DIDListFileName = 'FVT_DIDList.xlsx';   
    cd([project_path '/documents']);
    FVT_DIDList = (readcell(FVT_DIDListFileName));
    DIDList_Module = FVT_DIDList(3:end,3);
    DIDList_ArgDatatype = FVT_DIDList(3:end,4);
    DIDList_RWMode = FVT_DIDList(3:end,6);
    DIDList_SubDataName = FVT_DIDList(3:end,7);
    DIDList_CSOPName = FVT_DIDList(3:end,8);
    DIDList_DIDlen = FVT_DIDList(3:end,9);  % Input1
    DIDList_DIDNum = FVT_DIDList(3:end,10); % Input2
    DIDList_DIDSta = FVT_DIDList(3:end,11); % Output1
    DIDList_VarNameIn = FVT_DIDList(3:end,12);% Input3
    DIDList_VarNameOut = FVT_DIDList(3:end,13);% Output2


    %% Get original SWC_DID_type.c
    cd(RAW_CODE_DID_path);
    fileID = fopen('SWC_DID_type.c');
    Target_Ccode = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
    tmpCell = cell(length(Target_Ccode{1,1}),1);
    for i = 1:length(Target_Ccode{1,1})
        tmpCell{i,1} = Target_Ccode{1,1}{i,1};
    end
    Target_Ccode = tmpCell;
    fclose(fileID);


    %% Modify Target_Ccode
    % Find void fun(){}
    Raw_fun_start = find(contains(Target_Ccode,'void '));
    Raw_par_start = find(strcmp(Target_Ccode,'{'));
    Raw_par_end = find(strcmp(Target_Ccode,'}'));
    Raw_index = [];
    Raw_index(1,:) = Raw_fun_start;
    Raw_index(2,:) = Raw_par_start;
    Raw_index(3,:) = Raw_par_end;

    % Delete the content in the {}
    for i = 1:length(Raw_index)   
        Target_Ccode(Raw_index(2,i)+1:Raw_index(3,i)-1) = {''};
    end

    % Merge empty cells
    Merged_Ccode = {};
    current_empty = false;
    for i = 1:numel(Target_Ccode)
        if isempty(Target_Ccode{i})
            if ~current_empty
                Merged_Ccode{end+1,1} = '';
                current_empty = true;
            end
        else
            Merged_Ccode{end+1,1} = Target_Ccode{i};
            current_empty = false;
        end
    end
    Target_Ccode = Merged_Ccode;

    % Refind void fun(){}
    Raw_fun_start = find(contains(Target_Ccode,'void '));
    Raw_par_start = find(strcmp(Target_Ccode,'{'));
    Raw_par_end = find(strcmp(Target_Ccode,'}'));
    Raw_index = [];
    Raw_index(1,:) = Raw_fun_start;
    Raw_index(2,:) = Raw_par_start;
    Raw_index(3,:) = Raw_par_end;

    % Recognize SubDataName & RWMode
    pattern_SubDataName = '_([^_\(]*)\(';
    str = Target_Ccode(Raw_index(1,:));
    SubDataName_cell = regexp(str, pattern_SubDataName, 'tokens');
    pattern_RWMode = '_([^_]*)_[^_]*';
    RWMode_cell = regexp(str, pattern_RWMode, 'tokens'); % R: DIDSet; W: DIDGet

    % Insert API function into {}
    for i=1:length(SubDataName_cell)-1 % Ignore SWC_DID_type_Init()
        SubDataName = cell2mat(SubDataName_cell{i,1}{1});
        RWMode = cell2mat(RWMode_cell{i,1}{1});
        
        if strcmp(RWMode,'DIDGet')
            DIDList_index = find(strcmp(DIDList_RWMode,'W') & strcmp(DIDList_SubDataName,SubDataName));
            NewString = strjoin(['  *' DIDList_DIDSta(DIDList_index) ' = ApiSys_' DIDList_Module(DIDList_index) 'GetDIDdata(' DIDList_DIDNum(DIDList_index) ...
                ', ' DIDList_VarNameOut(DIDList_index) ', ' DIDList_DIDlen(DIDList_index) ');'],'');
        else % strcmp(RWMode,'DIDSet')
            DIDList_index = find(strcmp(DIDList_RWMode,'R') & strcmp(DIDList_SubDataName,SubDataName));
            if contains(DIDList_VarNameIn(DIDList_index),'Array')
                NewString = strjoin(['  ApiSys_' DIDList_Module(DIDList_index) 'SetDIDdata(' DIDList_DIDNum(DIDList_index) ...
                    ', ' DIDList_VarNameIn(DIDList_index) ', ' DIDList_DIDlen(DIDList_index) ');'],'');
            else % ~contains(DIDList_VarNameIn(DIDList_index),'Array')
                NewString = strjoin(['  ApiSys_' DIDList_Module(DIDList_index) 'SetDIDdata(' DIDList_DIDNum(DIDList_index) ...
                    ', &' DIDList_VarNameIn(DIDList_index) ', ' DIDList_DIDlen(DIDList_index) ');'],'');
            end      
        end

        Target_Ccode{Raw_index(2,i)+1,1} = NewString;
    end


    %% Save modified SWC_DID_type.c
    cd(RAW_CODE_DID_path);
    fileID = fopen( 'SWC_DID_type.c','w');
    for i = 1:length(Target_Ccode(:,1))
        fprintf(fileID,'%s\n',char(Target_Ccode(i,1)));
    end
    fclose(fileID);

end