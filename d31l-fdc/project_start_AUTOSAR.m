function project_start_AUTOSAR
%% Initial settings
TargetECU_Abb = 'FDC';
code_generate = boolean (1);
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

%% load arxml and vcu_local
if ModelCreate
    
%     filePaths = fullfile(arch_path, {'APPTypes.sldd', 'Comp_FDC_main.slx', 'SWC_FDC_type.slx', 'SWC_CDD_type.slx', 'SWC_VES_type.slx',...
%         'SWC_UDS_type.slx', 'SWC_IMU_type.slx', 'SWC_UART_type.slx','SWC_DID_type.slx'});
%     for i = 1:length(filePaths)
%         if exist(filePaths{i}, 'file')
%             delete(filePaths{i});
%         end
%     end
    
    cd ([project_path '/documents/ARXML_output']);
    A = dir;
    cnt = 0;

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
    if ModelUpdate
        model = ['Comp_' TargetECU_Abb '_main'];
        open_system(model)
        updateModel(ar, model)
    else
        createCompositionAsModel(ar, ['/Comp_' TargetECU_Abb '_ARPkg/Comp_' TargetECU_Abb '_main'], ...
            'ModelPeriodicRunnablesAs', 'FunctionCallSubsystem', 'DataDictionary', 'APPTypes.sldd');
    end
    DictionaryObj = Simulink.data.dictionary.open('APPTypes.sldd');
    saveChanges(DictionaryObj);

end

evalin('base', 'run vcu_local_hdr');

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

    cd(arch_path)

    filePaths = fullfile(arch_path, {'SWC_FDC_type.slxc', 'SWC_CDD_type.slxc', 'SWC_VES_type.slxc',...
        'SWC_UDS_type.slxc', 'SWC_IMU_type.slxc', 'SWC_UART_type.slxc','SWC_DID_type.slxc','SWC_APS_type.slxc'});
    folderPaths = fullfile(arch_path, {'slprj', 'SWC_CDD_type_autosar_rtw', 'SWC_FDC_type_autosar_rtw',...
        'SWC_UDS_type_autosar_rtw', 'SWC_VES_type_autosar_rtw', 'SWC_IMU_type_autosar_rtw', 'SWC_UART_type_autosar_rtw', 'SWC_DID_type_autosar_rtw', 'SWC_APS_type_autosar_rtw'});
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

    model = 'SWC_VES_type';
    open_system(model)
    ModelConfig(model)
    slbuild(model)
    save_system(model)
    close_system(model)
    cd(arch_path)

    model = 'SWC_FDC_type';
    open_system(model)
    ModelConfig(model)
    slbuild(model)
    save_system(model)
    close_system(model)
    cd(arch_path)

    model = 'SWC_CDD_type';
    open_system(model)
    ModelConfig(model)
    slbuild(model)
    save_system(model)
    close_system(model)
    cd(arch_path)

    model = 'SWC_UDS_type';
    open_system(model)
    ModelConfig(model)
    slbuild(model)
    save_system(model)
    close_system(model)
    cd(arch_path)

    model = 'SWC_IMU_type';
    open_system(model)
    ModelConfig(model)
    slbuild(model)
    save_system(model)
    close_system(model)
    cd(arch_path)
    
    model = 'SWC_UART_type';
    open_system(model)
    ModelConfig(model)
    slbuild(model)
    save_system(model)
    close_system(model)
    cd(arch_path)

    model = 'SWC_DID_type';
    open_system(model)
    ModelConfig(model)
    slbuild(model)
    save_system(model)
    close_system(model)
    cd(arch_path)

    model = 'SWC_APS_type';
    open_system(model)
    ModelConfig(model)
    slbuild(model)
    save_system(model)
    close_system(model)
    cd(arch_path)

    model = 'SWC_LOG_type';
    open_system(model)
    ModelConfig(model)
    slbuild(model)
    save_system(model)
    close_system(model)
    cd(arch_path)    

    cd(project_path)
    run A2L_rework
    copyfile([project_path '/documents/FVT_API/FVT_API.h'],[arch_path '/SWC_FDC_type_autosar_rtw'])

    %% Set path
    Clone_path = extractBefore(project_path,'\fdc-bsp-m7-autosar');
    RAW_CODE_path = [Clone_path '\RAW_CODE'];
    [~, Car_Model] = fileparts(project_path);
    FDC_code_path = [arch_path '\SWC_FDC_type_autosar_rtw'];
    CDD_code_path = [arch_path '\SWC_CDD_type_autosar_rtw'];
    VES_code_path = [arch_path '\SWC_VES_type_autosar_rtw'];
    IMU_code_path = [arch_path '\SWC_IMU_type_autosar_rtw'];
    UART_code_path = [arch_path '\SWC_UART_type_autosar_rtw'];
    DID_code_path = [arch_path '\SWC_DID_type_autosar_rtw'];
    APS_code_path = [arch_path '\SWC_APS_type_autosar_rtw'];
    LOG_code_path = [arch_path '\SWC_LOG_type_autosar_rtw'];
    slprj_path    = [arch_path '\slprj\autosar\_sharedutils'];
    fvt_app_path  = [Clone_path '\fdc-bsp-m7-autosar\source\fvt_app\' Car_Model];
    document_path = [project_path '\documents'];
    mkdir(Clone_path,'RAW_CODE');
    mkdir(RAW_CODE_path,'SWC_FDC_type_autosar_rtw');
    mkdir(RAW_CODE_path,'SWC_CDD_type_autosar_rtw');
    mkdir(RAW_CODE_path,'SWC_VES_type_autosar_rtw');
    mkdir(RAW_CODE_path,'SWC_IMU_type_autosar_rtw');
    mkdir(RAW_CODE_path,'SWC_UART_type_autosar_rtw');
    mkdir(RAW_CODE_path,'SWC_DID_type_autosar_rtw');
    mkdir(RAW_CODE_path,'SWC_APS_type_autosar_rtw');
    mkdir(RAW_CODE_path,'SWC_LOG_type_autosar_rtw');
    mkdir(RAW_CODE_path,'_sharedutils');
    
    %% Copy files to fvt_app_path

    % FDC
    files = dir([FDC_code_path '\*.c']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_FDC_type_autosar_rtw\' files(i).name])
    end

    files = dir([FDC_code_path '\*.h']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_FDC_type_autosar_rtw\' files(i).name])
    end

    files = dir([FDC_code_path '\*.a2l']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\\' files(i).name])
    end

    % CDD
    files = dir([CDD_code_path '\*.c']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_CDD_type_autosar_rtw\' files(i).name])
    end

    files = dir([CDD_code_path '\*.h']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_CDD_type_autosar_rtw\' files(i).name])
    end

    % VES
    files = dir([VES_code_path '\*.c']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_VES_type_autosar_rtw\' files(i).name])
    end

    files = dir([VES_code_path '\*.h']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_VES_type_autosar_rtw\' files(i).name])
    end

    % IMU
    files = dir([IMU_code_path '\*.c']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_IMU_type_autosar_rtw\' files(i).name])
    end

    files = dir([IMU_code_path '\*.h']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_IMU_type_autosar_rtw\' files(i).name])
    end

    % DID
    files = dir([DID_code_path '\*.c']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_DID_type_autosar_rtw\' files(i).name])
    end

    files = dir([DID_code_path '\*.h']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_DID_type_autosar_rtw\' files(i).name])
    end
    
    % UART
    files = dir([UART_code_path '\*.c']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_UART_type_autosar_rtw\' files(i).name])
    end

    files = dir([UART_code_path '\*.h']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_UART_type_autosar_rtw\' files(i).name])
    end
	
	% APS
    files = dir([APS_code_path '\*.c']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_APS_type_autosar_rtw\' files(i).name])
    end

    files = dir([APS_code_path '\*.h']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_APS_type_autosar_rtw\' files(i).name])
    end

    % LOG
    files = dir([LOG_code_path '\*.c']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_LOG_type_autosar_rtw\' files(i).name])
    end

    files = dir([LOG_code_path '\*.h']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\SWC_LOG_type_autosar_rtw\' files(i).name])
    end

    files = dir([slprj_path '\**\*.c']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\_sharedutils\' files(i).name])
    end

    files = dir([slprj_path '\**\*.h']);

    for i = 1:length(files)
        copyfile([files(i).folder '\' files(i).name],[RAW_CODE_path '\_sharedutils\' files(i).name])
    end

    %% Modify SWC_FDC_type.c .h
    % add Watchdog
    file_path = fullfile([RAW_CODE_path '\SWC_FDC_type_autosar_rtw'], 'SWC_FDC_type.c');
    fid = fopen(file_path, 'r+');
    file_content = fread(fid,'*char')';
    fclose(fid);
    pattern1 = 'void run_SWC_FDC_AppCallWDG_End\(void\)\s*{\s*\/\*\s*\(no output\/update code required\) \*\/\s*}';
    newContent1 = 'void run_SWC_FDC_AppCallWDG_End(void)\n{\n  ApiWdgM_WdgMMode_Shutdown();\n}';
    
    pattern2 = 'void run_SWC_FDC_AppCallWDG_StartUp\(void\)\s*{\s*\/\*\s*\(no output\/update code required\) \*\/\s*}';
    newContent2 = 'void run_SWC_FDC_AppCallWDG_StartUp(void)\n{\n  ApiWdgM_WdgMMode_NormalOperation();\n}';
    
    pattern3 = 'void run_SWC_FDC_AppCallWDG\(void\)\s*{\s*\/\*\s*\(no output\/update code required\) \*\/\s*}';
    newContent3 = 'void run_SWC_FDC_AppCallWDG(void)\n{\n  ApiWdgM_AliveSupervision_0();\n}';
    
    new_file_content = regexprep(file_content, {pattern1, pattern2, pattern3}, {newContent1, newContent2, newContent3});
    
    fid = fopen(file_path, 'w');
    fwrite(fid, new_file_content , 'char');
    fclose(fid);

    % remove function content
    file_path = fullfile([RAW_CODE_path '\SWC_FDC_type_autosar_rtw'], 'SWC_FDC_type.c');
    fid = fopen(file_path, 'r+');
    file_content = fread(fid, '*char')';
    fclose(fid);
    function_name = 'SWC_FDC_type_Init';
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

    % modify SWC_FDC_type.h and SWC_CDD_type.h for include "FVT_API.h"
    file_path = fullfile([RAW_CODE_path '\SWC_FDC_type_autosar_rtw'], 'SWC_FDC_type.h');
    fid = fopen(file_path, 'r+');
    file_content = fread(fid, '*char')';
    fclose(fid);
    search_text = '#include "SWC_FDC_type_types.h"';
    search_idx = strfind(file_content, search_text);
    insert_text = '#include "FVT_API.h"';
    if ~contains(file_content, insert_text)
        if ~isempty(search_idx)
     
        file_content = [file_content(1:search_idx+length(search_text)-1) char(10) insert_text char(10) file_content(search_idx+length(search_text):end)];
    
        fid = fopen(file_path, 'w');
        fwrite(fid, file_content, 'char');
        fclose(fid);
        end
    end

    file_path = fullfile([RAW_CODE_path '\SWC_CDD_type_autosar_rtw'], 'SWC_CDD_type.h');
    fid = fopen(file_path, 'r+');
    file_content = fread(fid, '*char')';
    fclose(fid);
    search_text = '#include "SWC_CDD_type_types.h"';
    search_idx = strfind(file_content, search_text);
    insert_text = '#include "FVT_API.h"';
    if ~contains(file_content, insert_text)
        if ~isempty(search_idx)
     
        file_content = [file_content(1:search_idx+length(search_text)-1) char(10) insert_text char(10) file_content(search_idx+length(search_text):end)];
    
        fid = fopen(file_path, 'w');
        fwrite(fid, file_content, 'char');
        fclose(fid);
        end
    end
    
    %% Modify SWC_DID_type.c & SWC_DID_type.h
    % Modify SWC_DID_type.h
    file_path = fullfile([RAW_CODE_path '\SWC_DID_type_autosar_rtw'], 'SWC_DID_type.h');
    fid = fopen(file_path, 'r+');
    file_content = fread(fid, '*char')';
    fclose(fid);
    search_text = '#include "SWC_DID_type_types.h"';
    search_idx = strfind(file_content, search_text);
    insert_text = '#include "FVT_API.h"';
    if ~contains(file_content, insert_text)
        if ~isempty(search_idx)
     
        file_content = [file_content(1:search_idx+length(search_text)-1) char(10) insert_text char(10) file_content(search_idx+length(search_text):end)];
    
        fid = fopen(file_path, 'w');
        fwrite(fid, file_content, 'char');
        fclose(fid);
        end
    end

    % Modify SWC_DID_type.c
    cd(project_path)
    Modify_SWC_DID_type(RAW_CODE_path);
    cd(arch_path);
    
end

end
%% END of main


%% run xxx_var.m, xxx_cal.m and BXXX_outputs.m
function load_var_cal_buses

names = dir;
for i=1:length(names)

    if names(i).isdir == 0							;	continue;	end
    if ~isempty(strfind(names(i).name, '.'))		;	continue;	end
    if ~isempty(strfind(names(i).name, 'Test'))     ;	continue;	end
    if ~isempty(strfind(names(i).name, 'test'))     ;	continue;	end
    if ~isempty(strfind(names(i).name, 'MINT'))     ;	continue;	end
    if ~isempty(strfind(names(i).name, 'slprj'))    ;	continue;	end
    if ~isempty(strfind(names(i).name, 'sfprj'))    ;	continue;	end
    if ~isempty(strfind(names(i).name, '_grt_rtw')) ;	continue;	end
    if ~isempty(strfind(names(i).name, '_ert_rtw')) ;	continue;	end
    if ~isempty(strfind(names(i).name, '_dev'))		;	continue;	end
    if ~isempty(strfind(names(i).name, '+PccuCALFLASH'))		;	continue;	end

    % % Set path % %
    pathname = [pwd filesep names(i).name];
    addpath(pathname);

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
    set_param(cs, 'GenerateASAP2','on');
    % set_param(cs, 'TargetLongLongMode','on');
    set_param(cs,'SuppressUnreachableDefaultCases', 'off');
    set_param(cs,'ConvertIfToSwitch', 'off');
    set_param(cs,'BooleanTrueId','true_MatlabRTW');
    set_param(cs,'BooleanFalseId','false_MatlabRTW');
    set_param(cs,'ProdHWDeviceType', 'ARM Compatible->ARM Cortex-M');   % Production device vendor and type
    set_param(cs,'ProdLongLongMode', 'on');   % Support long long
    set_param(cs,'ProdEqTarget', 'on'); % Test hardware is the same as production hardware
    set_param(cs,'PortableWordSizes', 'on');   % Enable portable word sizes
end
