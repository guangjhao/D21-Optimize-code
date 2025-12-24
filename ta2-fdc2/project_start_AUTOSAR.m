function project_start_AUTOSAR
%% Initial settings
TargetECU_Abb = 'FDC';
code_generate = boolean(1);
ModelCreate = boolean(0);
ModelUpdate = boolean(0);
project_path = pwd;

%% License check and add path
if code_generate && ~license('checkout','Matlab_Coder')
    error('Error: No Matlab_Coder license'); 
end

if ~license('checkout','Simulink')
    error('Error: No Simulink license');
end

if ~license('checkout','Stateflow')
    error('Error: No Stateflow license');
end

cd(project_path);
addpath(project_path);
addpath([project_path '/Scripts']);
addpath([project_path '/library']);
addpath([project_path '/documents/A2L_Head']);
addpath([project_path '/documents/FVT_API']);
arch_path = [project_path '/software/sw_development/arch'];
addpath(arch_path);
cd(arch_path);
swcTypes = {'SWC_HALIN'; 'SWC_HALIN_CDD'; 'SWC_INP'; 'SWC_FDC'; 'SWC_OUTP'; 'SWC_HALOUT'; 'SWC_SCP'; 'SWC_CDD'; 'SWC_VES'; 'SWC_UDS'; 'SWC_IMU'; 'SWC_UART'; ...
            'SWC_DID'; 'SWC_APS'; 'SWC_CGW'; 'SWC_DKC'; 'SWC_IOEXP'; 'SWC_LOG';'Comp_FDC_main'};
%% load arxml and vcu_local
if ModelCreate
    cd ([project_path '/documents/ARXML_output']);
    A = dir;
    cnt = 0;
    [indx, q] = listdlg('PromptString',{'Select the SWC you want to update/create.'},'ListSize',[250,500],'ListString',swcTypes);
    if q == 0; return; end
    for i = 1:length(indx)
        swcTypes(i,1) = swcTypes(indx(i),1);
    end
    swcTypes((length(indx)+1):end) = [];
    for i = 1:length(A)
        if contains(A(i).name,'.arxml')
            cnt = cnt+1;
            k{cnt} = A(i).name;
        else
            continue
        end
    end

    ar = arxml.importer(k);
    cd(arch_path);
    Simulink.data.dictionary.closeAll;
    cleanupObj = onCleanup(@() cleanupSldd());
    for i =1:length(swcTypes(:,1))
        if ModelUpdate
            ModelName = [char(swcTypes(i)) '_type'];
            if contains(swcTypes(i),'Comp_FDC_main')
                ModelName = char(swcTypes(i));
            end
            open_system(ModelName)
            updateModel(ar, ModelName)
            Modify_APPType_sldd()
        else
            evalin( 'base', 'clear B*_outputs')
            ModelName = char(swcTypes(i));
            if contains(swcTypes(i),'Comp_FDC_main')
                createCompositionAsModel(ar, ['/Comp_' TargetECU_Abb '_ARPkg/Comp_' TargetECU_Abb '_main'], ...
                'ModelPeriodicRunnablesAs', 'FunctionCallSubsystem', 'DataDictionary', 'APPTypes.sldd');
            else
                createComponentAsModel(ar, ['/' ModelName '_ARPkg/' ModelName '_type'], ...
                'ModelPeriodicRunnablesAs', 'FunctionCallSubsystem', 'DataDictionary', 'APPTypes.sldd');
            end
            Modify_APPType_sldd
        end
    end
    if ~ModelUpdate
        % SWC_FDC_type Autobuild
        cd(project_path)
        FVT_SWC_Autobuild()
    end
    DictionaryObj = Simulink.data.dictionary.open('APPTypes.sldd');
    hDesignData = DictionaryObj.getSection('Global');
    childNamesList = hDesignData.evalin('who');
    for n = 1:numel(childNamesList)
        if strcmp(childNamesList{n},'AppModeRequestType')
            continue
        elseif startsWith(childNamesList{n},'B') && endsWith(childNamesList{n},'_outputs')
            deleteEntry(hDesignData, [childNamesList{n}]);
        end
    end
    saveChanges(DictionaryObj);
    Simulink.data.dictionary.closeAll;
end

evalin('base', 'run vcu_local_hdr');
evalin('base', 'run vcu_local_hdrTA2');

% in arch_path (inp, outp, util)
load_var_cal_buses

% in hal_path
cd([arch_path filesep 'hal'])
load_var_cal_buses

% in inp_path
cd([arch_path filesep 'inp'])
load_var_cal_buses

% in app_path	(app/*)
cd([arch_path filesep 'app'])
load_var_cal_buses
cd(arch_path)

if code_generate

    % Delete .slxc and _rtw
    delete_slxc_and_rtw(arch_path, swcTypes);

    %% Build models
    [indx, q] = listdlg('PromptString',{'Select the SWC you want to gen.'},'ListSize',[200,500],'ListString',swcTypes);
    if q == 0
        return
    end
    for i = 1:length(indx)
        swcTypes(i,1) = swcTypes(indx(i),1);
    end
    swcTypes((length(indx)+1):end) = [];
    evalin( 'base', 'clear DT_*' )
    for i = 1:length(swcTypes)
        cd(arch_path)
        target_swc = char(swcTypes(i,1));
        buildmodel([swcTypes{i}, '_type'], arch_path);
        if strcmp(target_swc,'SWC_FDC')
        cd(project_path)
        copyfile([project_path '/documents/FVT_API/FVT_API.h'], [arch_path '/SWC_FDC_type_autosar_rtw'])
        end
    end

    %% Copy files to fvt_app_path
    RAW_CODE_path = copy_files_to_fvt_app(project_path, arch_path, swcTypes);
    
    %% .A2l merge & rework
    cd(project_path)
    Gen_A2L()
    run A2L_rework

    %% Modify SWC_FDC_type.c SWC_XXX_type.h
    Modify_c_and_h(RAW_CODE_path, swcTypes);

    % Modify SWC_DID_type.c
    cd(project_path)
    if any(contains(swcTypes,'SWC_DID'))
        Modify_SWC_DID_type(RAW_CODE_path);
    end
    cd(arch_path);

    %% Check Model Version
    if any(contains(swcTypes,{'SWC_HALIN';'SWC_INP';'SWC_OUTP';'SWC_HALOUT';'SWC_FDC'}))
%         Check_Model_Version(project_path, RAW_CODE_path,swcTypes);    
    end
end

end
%% END of main

%% run xxx_var.m, xxx_cal.m and BXXX_outputs.m
function load_var_cal_buses

    names = dir;

    for i = 1:length(names)

        if names(i).isdir == 0; continue; end
        if ~isempty(strfind(names(i).name, '.')); continue; end
        if ~isempty(strfind(names(i).name, 'Test')); continue; end
        if ~isempty(strfind(names(i).name, 'test')); continue; end
        if ~isempty(strfind(names(i).name, 'MINT')); continue; end
        if ~isempty(strfind(names(i).name, 'slprj')); continue; end
        if ~isempty(strfind(names(i).name, 'sfprj')); continue; end
        if ~isempty(strfind(names(i).name, '_grt_rtw')); continue; end
        if ~isempty(strfind(names(i).name, '_ert_rtw')); continue; end
        if ~isempty(strfind(names(i).name, '_dev')); continue; end
        if ~isempty(strfind(names(i).name, '+PccuCALFLASH')); continue; end

        % % Set path % %
        pathname = [pwd filesep names(i).name];
        addpath(pathname, '-begin');

        % % Run Calibration % %

        var_name = [names(i).name '_var'];

        if 2 == exist(var_name, 'file')
            evalin('base', ['run ' var_name]);
        end

        cal_name = [names(i).name '_cal'];

        if 2 == exist(cal_name, 'file')
            evalin('base', ['run ' cal_name]);
        end

        % % Run Bus defination % %

        bus_name = ['B' upper(names(i).name) '_outputs'];

        if 1 == evalin('base', ['exist(''' bus_name ''' , ''var'')'])
            evalin('base', ['clear ' bus_name]);
        end

        if 2 == exist(bus_name, 'file')
            evalin('base', ['run ' bus_name]);
            busObj = evalin('base', bus_name);
            busObj.HeaderFile = 'Rte_Type.h';
            assignin('base', bus_name, busObj)
        end

        % % Run Array declaration % %

        array_name = [names(i).name '_array'];

        if 2 == exist(array_name, 'file')
            evalin('base', ['run ' array_name]);
        end

    end

end

function ModelConfig(model)
    cs = getActiveConfigSet(model);
    set_param(cs, 'GenerateASAP2', 'on');
    % set_param(cs, 'TargetLongLongMode','on');
    set_param(cs, 'SuppressUnreachableDefaultCases', 'off');
    set_param(cs, 'ConvertIfToSwitch', 'off');
    set_param(cs, 'BooleanTrueId', 'true_MatlabRTW');
    set_param(cs, 'BooleanFalseId', 'false_MatlabRTW');
    set_param(cs, 'ProdHWDeviceType', 'ARM Compatible->ARM Cortex-M'); % Production device vendor and type
    set_param(cs, 'ProdLongLongMode', 'on'); % Support long long
    set_param(cs, 'ProdEqTarget', 'on'); % Test hardware is the same as production hardware
    set_param(cs, 'PortableWordSizes', 'on'); % Enable portable word sizes
end

function buildmodel(model, arch_path)
    open_system(model)
    ModelConfig(model)
    slbuild(model)
    save_system(model)
    close_system(model)
    cd(arch_path)
end

function code_path = CopyFilestofvt_app_path(SWC_trw, arch_path, RAW_CODE_path)
    code_path = [arch_path '\' SWC_trw];
    mkdir(RAW_CODE_path, SWC_trw);

    files = dir([code_path '\*.c']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name], [RAW_CODE_path '\' SWC_trw '\' files(i).name])
    end

    files = dir([code_path '\*.h']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name], [RAW_CODE_path '\' SWC_trw '\' files(i).name])
    end

end

function delete_slxc_and_rtw(arch_path, swcTypes)
    filePaths = fullfile(arch_path, strcat(swcTypes, '_type.slxc'));
    folderPaths = fullfile(arch_path, [{'slprj'}; strcat(swcTypes, '_type_autosar_rtw')]);
    for i = 1:length(filePaths)
        if exist(filePaths{i}, 'file')
            delete(filePaths{i});
        end
    end
    for i = 1:length(folderPaths)
        if exist(folderPaths{i}, 'dir')
            rmdir(folderPaths{i}, 's');
        end
    end
end

function RAW_CODE_path = copy_files_to_fvt_app(project_path, arch_path, swcTypes)
    fclose('all');
    Clone_path = extractBefore(project_path,'\fdc-bsp-m7-autosar');
    last_slash_index = find(project_path == '\', 1, 'last');
    car_model_folder = project_path(last_slash_index+1:end);
    RAW_CODE_folder = ['RAW_CODE_' car_model_folder];
    RAW_CODE_path = [Clone_path '\' RAW_CODE_folder];
    mkdir(Clone_path, RAW_CODE_folder);
    RAW_CODE_path = [Clone_path '\' RAW_CODE_folder];
    [~, Car_Model] = fileparts(project_path);
    fvt_app_path = [Clone_path '\fdc-bsp-m7-autosar\source\fvt_app\' Car_Model];
    document_path = [project_path '\documents'];

    codePaths = struct();

    for i = 1:length(swcTypes)
        type = swcTypes{i,1};
        fieldName = [type '_code_path'];
        if exist([RAW_CODE_path '\' type, '_type_autosar_rtw'], 'dir') == 7
            rmdir([RAW_CODE_path '\' type, '_type_autosar_rtw'], 's');
        end
        codePaths.(fieldName) = CopyFilestofvt_app_path([type, '_type_autosar_rtw'], arch_path, RAW_CODE_path);
        SWC_code_path = codePaths.(fieldName);
        % a2l
        files = dir([SWC_code_path '\*.a2l']);
        if ~isempty(files)
            for k = 1:length(files)
                % copyfile([files(k).folder '\' files(k).name],[RAW_CODE_path '\\' files(k).name])
                copyfile([files(k).folder '\' files(k).name],[project_path '/documents/A2L_Files'])
            end
        end
    end
    
    slprj_path = [arch_path '\slprj\autosar\_sharedutils'];
    
    mkdir(RAW_CODE_path,'_sharedutils');
    
    % sharedutils
    files = dir([slprj_path '\**\*.c']);
    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\_sharedutils\' files(i).name])
    end
    files = dir([slprj_path '\**\*.h']);
    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\_sharedutils\' files(i).name])
    end
end

function Modify_c_and_h(RAW_CODE_path, swcTypes)
    % add Watchdog
    if any(strcmp(swcTypes(:,1),'SWC_HALIN'))
        file_path = fullfile([RAW_CODE_path '\SWC_HALIN_type_autosar_rtw'], 'SWC_HALIN_type.c');
        fid = fopen(file_path, 'r+');
        file_content = fread(fid,'*char')';
        fclose(fid);    
        
        pattern2 = 'void run_SWC_HALIN_AppCallWDG_StartUp\(void\)\s*{\s*\/\*\s*\(no output\/update code required\) \*\/\s*}';
        newContent2 = 'void run_SWC_HALIN_AppCallWDG_StartUp(void)\n{\n  ApiWdgM_WdgMMode_NormalOperation();\n}';
        
        pattern3 = 'void run_SWC_HALIN_AppCallWDG\(void\)\s*{\s*\/\*\s*\(no output\/update code required\) \*\/\s*}';
        newContent3 = 'void run_SWC_HALIN_AppCallWDG(void)\n{\n  ApiWdgM_AliveSupervision_0();\n}';      
        new_file_content = regexprep(file_content, {pattern2, pattern3}, {newContent2, newContent3});  
        fid = fopen(file_path, 'w');
        fwrite(fid, new_file_content , 'char');
        fclose(fid);

        % modify SWC_HALIN_type.h for include "FVT_API.h"
        file_path = fullfile([RAW_CODE_path '\SWC_HALIN_type_autosar_rtw'], 'SWC_HALIN_type.h');
        fid = fopen(file_path, 'r+');
        file_content = fread(fid, '*char')';
        fclose(fid);
        search_text = '#include "SWC_HALIN_type_types.h"';
        search_idx = strfind(file_content, search_text);
        insert_text = '#include "FVT_API.h"';
        if ~contains(file_content, insert_text)
            if ~isempty(search_idx)
         
            file_content = [file_content(1:search_idx + length(search_text) - 1) newline insert_text newline newline ...
                                newline file_content(search_idx + length(search_text):end)];
        
            fid = fopen(file_path, 'w');
            fwrite(fid, file_content, 'char');
            fclose(fid);
            end
        end
    end

    if any(contains(swcTypes(:,1),'SWC_HALOUT'))
        file_path = fullfile([RAW_CODE_path '\SWC_HALOUT_type_autosar_rtw'], 'SWC_HALOUT_type.c');
        fid = fopen(file_path, 'r+');
        file_content = fread(fid,'*char')';
        fclose(fid);
        pattern1 = 'void run_SWC_HALOUT_AppCallWDG_End\(void\)\s*{\s*\/\*\s*\(no output\/update code required\) \*\/\s*}';
        newContent1 = 'void run_SWC_HALOUT_AppCallWDG_End(void)\n{\n  ApiWdgM_WdgMMode_Shutdown();\n}';
        new_file_content = regexprep(file_content, {pattern1}, {newContent1});
        fid = fopen(file_path, 'w');
        fwrite(fid, new_file_content , 'char');
        fclose(fid);

        % remove function content
        fid = fopen(file_path, 'r+');
        file_content = fread(fid, '*char')';
        fclose(fid);
        function_name = 'SWC_HALOUT_type_Init';
        pattern = ['void\s+' function_name '\s*\([^)]*\)\s*{'];
        start_idx = regexp(file_content, pattern, 'once');
        if ~isempty(start_idx)
        stack = 0;
        for i = start_idx:length(file_content)
            if file_content(i) == '{'
                stack = stack + 1;
            elseif file_content(i) == '}'
                stack = stack - 1;
                if stack == 0
                    end_idx = i;
                    break;
                end
            end
        end
    
        new_file_content = [file_content(1:start_idx-1) file_content(end_idx+1:end)];
        
        fid = fopen(file_path, 'w');
        fwrite(fid, new_file_content, 'char');
        fclose(fid);
        end
    
        % modify SWC_HALOUT_type.h for include "FVT_API.h"
        file_path = fullfile([RAW_CODE_path '\SWC_HALOUT_type_autosar_rtw'], 'SWC_HALOUT_type.h');
        fid = fopen(file_path, 'r+');
        file_content = fread(fid, '*char')';
        fclose(fid);
        search_text = '#include "SWC_HALOUT_type_types.h"';
        search_idx = strfind(file_content, search_text);
        insert_text = '#include "FVT_API.h"';

        if ~contains(file_content, insert_text)
            if ~isempty(search_idx)
         
            file_content = [file_content(1:search_idx + length(search_text) - 1) newline insert_text newline newline ...
                                file_content(search_idx + length(search_text):end)];
        
            fid = fopen(file_path, 'w');
            fwrite(fid, file_content, 'char');
            fclose(fid);
            end
        end
    end

    if any(contains(swcTypes(:,1),'SWC_CDD'))
        file_path = fullfile([RAW_CODE_path '\SWC_CDD_type_autosar_rtw'], 'SWC_CDD_type.h');
        fid = fopen(file_path, 'r+');
        file_content = fread(fid, '*char')';
        fclose(fid);
        search_text = '#include "SWC_CDD_type_types.h"';
        search_idx = strfind(file_content, search_text);
        insert_text = '#include "FVT_API.h"';
        if ~contains(file_content, insert_text)
            if ~isempty(search_idx)
         
            file_content = [file_content(1:search_idx + length(search_text) - 1) newline insert_text newline file_content(search_idx + length(search_text):end)];
        
            fid = fopen(file_path, 'w');
            fwrite(fid, file_content, 'char');
            fclose(fid);
            end
        end
    end

    % Modify SWC_DID_type.h
    if any(contains(swcTypes(:,1),'SWC_DID'))
        file_path = fullfile([RAW_CODE_path '\SWC_DID_type_autosar_rtw'], 'SWC_DID_type.h');
        fid = fopen(file_path, 'r+');
        file_content = fread(fid, '*char')';
        fclose(fid);
        search_text = '#include "SWC_DID_type_types.h"';
        search_idx = strfind(file_content, search_text);
        insert_text = '#include "FVT_API.h"';
        if ~contains(file_content, insert_text)
            if ~isempty(search_idx)
         
            file_content = [file_content(1:search_idx + length(search_text) - 1) newline insert_text newline file_content(search_idx + length(search_text):end)];
        
            fid = fopen(file_path, 'w');
            fwrite(fid, file_content, 'char');
            fclose(fid);
            end
        end
    end

    if any(contains(swcTypes(:,1),'SWC_DKC'))
        % Modify SWC_DKC_type.h
        file_path = fullfile([RAW_CODE_path '\SWC_DKC_type_autosar_rtw'], 'SWC_DKC_type.h');
        fid = fopen(file_path, 'r+');
        file_content = fread(fid, '*char')';
        fclose(fid);
        search_text = '#include "SWC_DKC_type_types.h"';
        search_idx = strfind(file_content, search_text);
        insert_text = '#include "FVT_API.h"';
        insert_text2 = '#include <string.h>';
        if ~contains(file_content, insert_text)
            if ~isempty(search_idx)
            
            file_content = [file_content(1:search_idx+length(search_text)-1) newline insert_text newline insert_text2 newline file_content(search_idx+length(search_text):end)];
        
            fid = fopen(file_path, 'w');
            fwrite(fid, file_content, 'char');
            fclose(fid);
            end
        end
    end

    if any(contains(swcTypes(:,1),'SWC_UDS'))
        % Modify SWC_UDS_type.h
        file_path = fullfile([RAW_CODE_path '\SWC_UDS_type_autosar_rtw'], 'SWC_UDS_type.h');
        fid = fopen(file_path, 'r+');
        file_content = fread(fid, '*char')';
        fclose(fid);
        search_text = '#include "SWC_UDS_type_types.h"';
        search_idx = strfind(file_content, search_text);
        insert_text = '#include "FVT_API.h"';
        insert_text2 = '#include "uds_dem.h"';
        if ~contains(file_content, insert_text)
            if ~isempty(search_idx)
            
            file_content = [file_content(1:search_idx+length(search_text)-1) newline insert_text newline insert_text2 newline file_content(search_idx+length(search_text):end)];
        
            fid = fopen(file_path, 'w');
            fwrite(fid, file_content, 'char');
            fclose(fid);
            end
        end
    end

    if any(contains(swcTypes(:,1),'SWC_VES'))
        % Modify SWC_UDS_type.h
        file_path = fullfile([RAW_CODE_path '\SWC_VES_type_autosar_rtw'], 'SWC_VES_type.h');
        fid = fopen(file_path, 'r+');
        file_content = fread(fid, '*char')';
        fclose(fid);
        search_text = '#include "SWC_VES_type_types.h"';
        search_idx = strfind(file_content, search_text);
        insert_text = '#include "FVT_API.h"';
        if ~contains(file_content, insert_text)
            if ~isempty(search_idx)
            
            file_content = [file_content(1:search_idx+length(search_text)-1) newline insert_text newline file_content(search_idx+length(search_text):end)];
        
            fid = fopen(file_path, 'w');
            fwrite(fid, file_content, 'char');
            fclose(fid);
            end
        end
    end
end

function cleanupSldd()
dictObj = Simulink.data.dictionary.open('APPTypes.sldd');
saveChanges(dictObj);
close(dictObj);
end

function Modify_APPType_sldd()
% Remove Bxxx_outputs in APPType.sldd
dictObj = Simulink.data.dictionary.open('APPTypes.sldd');
hDesignData = dictObj.getSection('Global');
childNamesList = hDesignData.evalin('who');
for n = 1:numel(childNamesList)
    if strcmp(childNamesList{n},'AppModeRequestType')
        continue
    elseif startsWith(childNamesList{n},'B') && endsWith(childNamesList{n},'_outputs')
        deleteEntry(hDesignData, [childNamesList{n}]);
    end
end
saveChanges(dictObj);
Simulink.data.dictionary.closeAll;
end