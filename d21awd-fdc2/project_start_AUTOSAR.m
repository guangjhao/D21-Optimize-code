function project_start_AUTOSAR
%% Initial settings
targetEcuAbb = 'FDC';
codeGenerate = boolean(0);
modelCreate  = boolean(0);
modelUpdate  = boolean(0);
projectPath  = pwd;

%% License check
if codeGenerate && ~license('checkout','Matlab_Coder')
    error('Error: No Matlab_Coder license'); 
end
    
if ~license('checkout','Simulink')
    error('Error: No Simulink license');
end

if ~license('checkout','Stateflow')
    error('Error: No Stateflow license');
end

%% Add path
cd(projectPath);
addpath(projectPath);
addpath([projectPath '/../common/Models'], '-end');
addpath([projectPath '/../common/Scripts']);
addpath([projectPath '/Scripts']);
addpath([projectPath '/../common/library']);
addpath([projectPath '/documents/A2L_Head']);
addpath([projectPath '/documents/FVT_API']);
arch_path = [projectPath '/software/sw_development/arch'];
source_sharedutils_path = [projectPath '/../../source/fvt_app/' extractAfter(projectPath,'app\') '/_sharedutils'];
addpath(arch_path);
cd(arch_path);

files = dir(fullfile(arch_path, '*.slx'));
swcTypes = {};
for i = 1:length(files)
    fileName = files(i).name;
    if contains(fileName, '_type.slx')
        modelName = strrep(fileName, '_type.slx', '');
    else
        modelName = strrep(fileName, '.slx', '');
    end    
    swcTypes{end+1, 1} = modelName;
end

%% Load vcu_local and var_cal_buses
evalin('base', 'run vcu_local_hdr');
evalin('base', 'run DTC_Constant_Definition');

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

%% Create or update model
if modelCreate || modelUpdate
    cd ([projectPath '/documents/ARXML_output']);
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
        if modelUpdate
            cd(arch_path);
            ModelName = [char(swcTypes(i)) '_type'];
            open_system(ModelName);
            updateModel(ar, ModelName);
            cd(arch_path);
            FVT_SWC_DID_Autobuild(ModelName);    
            Modify_APPType_sldd();
	    else
            evalin( 'base', 'clear B*_outputs');
            ModelName = char(swcTypes(i));
            if contains(swcTypes(i),'Comp_FDC_main')
	            createCompositionAsModel(ar, ['/Comp_' targetEcuAbb '_ARPkg/Comp_' targetEcuAbb '_main'], ...
	            'ModelPeriodicRunnablesAs', 'FunctionCallSubsystem', 'DataDictionary', 'APPTypes.sldd');
            else
                createComponentAsModel(ar, ['/' ModelName '_ARPkg/' ModelName '_type'], ...
                'ModelPeriodicRunnablesAs', 'FunctionCallSubsystem', 'DataDictionary', 'APPTypes.sldd');
            end
            Modify_APPType_sldd();
	    end
    end
    if ~modelUpdate
        % SWC_FDC_type Autobuild
        cd(projectPath)
        FVT_SWC_Autobuild()
    end
    Modify_APPType_sldd()
end

%% Generate code
if codeGenerate
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
        cd(projectPath)
        copyfile([projectPath '/documents/FVT_API/FVT_API.h'], [arch_path '/SWC_FDC_type_autosar_rtw'])
        end
    end

    %% Copy files to fvt_app_path
    RAW_CODE_path = copy_files_to_fvt_app(projectPath, arch_path, swcTypes, source_sharedutils_path);
    
    %% .A2l merge & rework
    cd(projectPath)
    Gen_A2L()
    run A2L_rework

    %% Modify SWC_FDC_type.c SWC_XXX_type.h
    Modify_c_and_h(RAW_CODE_path, swcTypes);

    % Modify SWC_DID_type.c
    cd(projectPath)
    if any(contains(swcTypes,'SWC_DID'))
        Modify_SWC_DID_type(RAW_CODE_path);
    end
    cd(arch_path);

    %% Check Model Version
    if any(contains(swcTypes,{'SWC_HALIN';'SWC_INP';'SWC_OUTP';'SWC_HALOUT';'SWC_FDC'}))
        Check_Model_Version(projectPath, RAW_CODE_path,swcTypes);    
    end
end

cd(arch_path)
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
    set_param(cs, 'UtilityFuncGeneration','Shared location');
    set_param(cs, 'GenerateSharedConstants','off');
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

function RAW_CODE_path = copy_files_to_fvt_app(projectPath, arch_path, swcTypes, source_sharedutils_path)
    fclose('all');
    Clone_path = extractBefore(projectPath,'\fdc-bsp-m7-autosar');
    last_slash_index = find(projectPath == '\', 1, 'last');
    car_model_folder = projectPath(last_slash_index+1:end);
    RAW_CODE_folder = ['RAW_CODE_' car_model_folder];
    RAW_CODE_path = [Clone_path '\' RAW_CODE_folder];
    mkdir(Clone_path, RAW_CODE_folder);
    RAW_CODE_path = [Clone_path '\' RAW_CODE_folder];
    [~, Car_Model] = fileparts(projectPath);
    fvt_app_path = [Clone_path '\fdc-bsp-m7-autosar\source\fvt_app\' Car_Model];
    document_path = [projectPath '\documents'];

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
                copyfile([files(k).folder '\' files(k).name],[projectPath '/documents/A2L_Files'])
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
    files = dir(fullfile([RAW_CODE_path '\_sharedutils\*.c']));
    sharedutils_files = transpose({files.name});
    files= dir(fullfile([source_sharedutils_path '\*.c']));
    source_sharedutils_files = transpose({files.name});
    for i = 1:length(sharedutils_files)
        warning_flg = ~any(strcmp(source_sharedutils_files,sharedutils_files(i)));
        if warning_flg
            file_name = extractBefore(char(sharedutils_files(i)),'.');
            msgbox(['There are new shared functions in sharedutils,' newline '' ...
                    'please copy the' newline newline...
                    file_name '.c' newline...
                    file_name '.h' newline newline...
                    'files in the "_sharedutils" folder under the source path.' newline...
                    'And add the "' file_name '.o" to mpu_regions.'],"Warning",'help');
        end
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

function Check_Model_Version(projectPath, RAW_CODE_path,swcTypes)
    
    if any(contains(swcTypes(:,1),{'SWC_HALIN';'SWC_INP';'SWC_FDC';'SWC_OUTP';'SWC_HALOUT'}))
        % Remove SWC_HALIN_CDD
        idx = strcmp(swcTypes(:,1),'SWC_HALIN_CDD');
        if any(idx)
            swcTypes(idx) = [];
        end
        if ~isempty(swcTypes)
            idx = ~contains(swcTypes(:,1),{'SWC_HALIN';'SWC_INP';'SWC_FDC';'SWC_V2L';'SWC_DDM';'SWC_CARB';'SWC_OUTP';'SWC_HALOUT'});
            if any(idx)
                swcTypes(idx) = [];
            end
            % Clarify used common models
            common_dir = char([projectPath '\..\common\Models']);
            pro_common_app_dir = dir(common_dir);
            pro_common_app_dir = struct2table(pro_common_app_dir);
            pro_common_app_dir = table2cell(pro_common_app_dir);
            num_pro_common_app_dir = length(pro_common_app_dir(:,1));
            common_models = {''};
            common_model_cnt=0;
            for i = 1:num_pro_common_app_dir
                str = pro_common_app_dir(i,1);
                model_str = strrep(str, '.slx', '');
                num_model_str = strlength(model_str); 
                if num_model_str >= 3 && ~any(strcmp(model_str, {'app'}))
                    common_model_cnt = common_model_cnt + 1;
                    common_models(common_model_cnt,1) = model_str;
                end 
            end 
    
            for common_model_idx = 1:length(common_models)
                % Get common model version
                modelName = string(common_models(common_model_idx));
                if ~bdIsLoaded(modelName)
                    load_system(modelName);
                end
                modelVersion = get_param(modelName, 'ModelVersion');
                
                % Filter model if no gen
                if any(contains(swcTypes(:,1), 'SWC_CARB'))
                    target_swc = 'SWC_CARB';
                elseif any(contains(swcTypes(:,1), upper(modelName)))
                    target_swc = ['SWC_' char(upper(modelName))];
                elseif any(contains(swcTypes(:,1), 'SWC_FDC')) && ~contains(modelName, {'halin';'inp';'outp';'halout'})
                    target_swc = 'SWC_FDC';
                else
                    continue
                end
                
                % Update xxx.c and xxx.h source code version in RAW_CODE
                file_types = {'.c', '.h'};
                for file_type_idx = 1:length(file_types)
                    if strcmp(modelName, 'halin')
                        sourcemodelName = 'hal_in';
                    elseif strcmp(modelName, 'halout')
                        sourcemodelName = 'hal_out';
                    else
                        sourcemodelName = modelName;
                    end
                    file_type = string(file_types(file_type_idx));
                    source_code_file_path = fullfile([RAW_CODE_path '\' target_swc '_type_autosar_rtw'], strcat(sourcemodelName, file_type));
                    fid = fopen(source_code_file_path, 'r+');
                    source_code_content = textscan(fid, '%s', 'delimiter', '\n', 'whitespace', '');
                    source_code_content = source_code_content{1};
                    fclose(fid);
                    search_text = char(' * Model version                  : ');
                    search_idx = find(contains(source_code_content, search_text));
                    sourceCodeVersionDef = strcat([' * Model version                  : ', modelVersion]);
                    insert_text = char(sprintf(sourceCodeVersionDef));
                    if ~isempty(search_idx)
                        source_code_content(search_idx, 1) = {insert_text};
                    end
            
                    % Overwrite xxx.c and xxx.h
                    fid = fopen(source_code_file_path, 'w');
                    for i = 1:length(source_code_content(:,1))
                        fprintf(fid,'%s\n',char(source_code_content(i,1)));
                    end
                    fclose(fid);
                end
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
    elseif startsWith(childNamesList{n},'B') && endsWith(childNamesList{n},'_outputs') && ~strcmp(childNamesList{n},'BOUTP2_outputs')
        deleteEntry(hDesignData, [childNamesList{n}]);
    end
end
saveChanges(dictObj);
Simulink.data.dictionary.closeAll;
end
