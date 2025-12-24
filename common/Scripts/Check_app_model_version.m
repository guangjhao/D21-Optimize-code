function Check_app_model_version
    %% Initial settings
    Common_Scripts_path = pwd;
    if ~contains(Common_Scripts_path, 'common\Scripts'), error('current folder is not under common\Scripts'), end
    
    ref_car_model = {'d31f-fdc2', 'd21awd-fdc2', 'd21rwd-fdc2', 'd31hrwd-fdc2', 'd31hawd-fdc2'};
    
    Common_Models_path = [Common_Scripts_path '\..\Models'];
    addpath(Common_Models_path);
    % Clarify used car models
    app_dir = char([Common_Scripts_path '\..\..\']);
    pro_app_dir = dir(app_dir);
    pro_app_dir = struct2table(pro_app_dir);
    pro_app_dir = table2cell(pro_app_dir);
    num_pro_app_dir = length(pro_app_dir(:,1));
    app_models = {''};
    app_model_cnt=0;
    for i = 1:num_pro_app_dir
        model_str = pro_app_dir(i,1);
        if contains(model_str, ref_car_model) && ~contains(model_str, 'app')
            app_model_cnt = app_model_cnt + 1;
            app_models(app_model_cnt,1) = model_str;
        end
    end 


    % Update APP Model Version to app_ds_version.h
    file_path = fullfile([Common_Scripts_path '\..\..\..\source\fvt_cdd\common\io'], 'app_model_version.h');
    fid = fopen(file_path, 'r+');
    file_content = textscan(fid, '%s', 'delimiter', '\n', 'whitespace', '');
    file_content = file_content{1};
    fclose(fid);


    % Update #define RUN_TEST_APP_MODEL_VERSION
    search_text = '#define RUN_TEST_APP_MODEL_VERSION';
    search_idx = find(contains(file_content, search_text));
    runTestDef = '#define RUN_TEST_APP_MODEL_VERSION 1';
    insert_text = runTestDef;
    if ~isempty(search_idx)
        file_content(search_idx, 1) = {insert_text};
    end


    for app_model_idx = 1:length(app_models)
        
        car_model_folder = char(app_models(app_model_idx));
        project_path = char(strcat(Common_Scripts_path, '\..\..\', car_model_folder));
        car_model = upper(strrep(car_model_folder, '-', '_'));
        
        
        % Clarify used common models
        common_dir = char([project_path '\..\common\Models']);
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
            if ~contains(model_str, 'app') && num_model_str >= 3
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
            commonModelVersion = get_param(modelName, 'ModelVersion');
    

            % Get xxx.c and xxx.h source code version
            file_type = '.h';
            if strcmp(modelName, 'halin')
                sourcemodelName = 'hal_in';
            elseif strcmp(modelName, 'halout')
                sourcemodelName = 'hal_out';
            else
                sourcemodelName = modelName;
            end
            source_code_file_path = fullfile(strcat(Common_Scripts_path, '\..\..\..\source\fvt_app\', ...
                car_model_folder, '\SWC_FDC_type_autosar_rtw\', strcat(sourcemodelName, file_type)));
            fid = fopen(source_code_file_path, 'r+');
            source_code_content = textscan(fid, '%s', 'delimiter', '\n', 'whitespace', '');
            source_code_content = source_code_content{1};
            fclose(fid);
            search_text = char(' * Model version                  : ');
            search_idx = find(contains(source_code_content, search_text));
            sourceCodeVersionDef = source_code_content{search_idx};
            pattern = '(?<=: )\d+(\.\d+)?';
            modelVersion = string(regexp(sourceCodeVersionDef, pattern, 'match'));
    
            % Update #define COMMON_xxx_MODEL_VERSION
            search_text = char(strcat('#define COMMON_', upper(modelName), '_MODEL_VERSION'));
            search_idx = find(contains(file_content, search_text));
            modelVersionDef = strcat('#define COMMON_', upper(modelName), '_MODEL_VERSION', ' "', commonModelVersion, '"');
            insert_text = char(sprintf(modelVersionDef));
            if ~isempty(search_idx)
                file_content(search_idx, 1) = {insert_text};
            end
    
            % Update #define xxx_xxx_xxx_SOURCE_CODE_VERSION
            search_text = char(strcat(['#define ', car_model], '_', upper(modelName), '_SOURCE_CODE_VERSION'));
            search_idx = find(contains(file_content, search_text));
            sourceCodeVersionDef = strcat(['#define ', car_model], '_', upper(modelName), '_SOURCE_CODE_VERSION', ' "', modelVersion, '"');
            insert_text = char(sprintf(sourceCodeVersionDef));
            if ~isempty(search_idx)
                file_content(search_idx, 1) = {insert_text};
            end
    
        end
    end

    % Overwrite app_model_version.h
    fid = fopen(file_path, 'w');
    for i = 1:length(file_content(:,1))
        fprintf(fid,'%s\n',char(file_content(i,1)));
    end
    fclose(fid);

end