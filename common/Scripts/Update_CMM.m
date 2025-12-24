function Update_CMM()
    %% Initial settings
    isVcuLocalHdrDefNeedChecking = boolean(0);

    Common_Scripts_path = pwd;
    if ~contains(Common_Scripts_path, 'common\Scripts'), error('current folder is not under common\Scripts'), end

    ref_car_model = {'d31f-fdc', 'd31f-fdc2', 'd31hrwd-fdc2', 'd31hawd-fdc2', 'd21awd-fdc2', 'd21rwd-fdc2', 'd31x-fdc'};
    [indx, ~] = listdlg('PromptString',{'Select the car model.'},'ListSize',[200,150],'ListString',ref_car_model);

    if isempty(indx)
        error('Error: At least ONE car model should be selected');  
    end

    target_car_model = ref_car_model(indx(1));
    car_model = target_car_model{1};

    project_path = char(strcat(Common_Scripts_path, '\..\..\', car_model));
    Scripts_path = [project_path '/Scripts'];
    arch_path = [project_path '/software/sw_development/arch'];
    MessageLink_path = [project_path '\..\common\documents'];

    addpath(Common_Scripts_path, '-begin')
    addpath(Scripts_path, '-end')
    addpath(MessageLink_path)

    %% Temporary folder cleanup setup
    desktopPath = fullfile(getenv('USERPROFILE'), 'Desktop');
    tempFolder = [desktopPath '\zzz_MessageLinkout_Create'];
    cleanupObj = onCleanup(@() cleanupTempFolder(tempFolder));

    try
        %% dbc_AutoWorkAround
        cd(Common_Scripts_path);
        run_py('dbc_AutoWorkAround.py', car_model)

        %% Modify_MessageLink
        cd(Common_Scripts_path);
        FVT_MessesgeLink();

        %% FVT_ARXML_Generator
        for car_model_indx = 1:length(indx)
            target_car_model = ref_car_model(indx(car_model_indx));
            car_model = target_car_model{1};
            project_path = char(strcat(Common_Scripts_path, '\..\..\', car_model));
            cd(project_path);
            disp('FVT_ARXML_Generator.m running...')
            FVT_ARXML_Generator()

            fprintf('\n<strong>%s %s</strong>\n\n', car_model, ' CMM Updated and ARXML outputs Done!');
        end

        %% Check_vcu_local_hdr_Definition
        if isVcuLocalHdrDefNeedChecking
            disp('Press any key to continue Check_vcu_local_hdr_Definition...');
            pause;
            cd(Common_Scripts_path);
            disp('Check_vcu_local_hdr_Definition.m running...')
            Check_vcu_local_hdr_Definition()
        end

    catch ME
        fprintf('Error occurred: %s\n', ME.message);
        rethrow(ME);
    end
end

function run_py(file_name, args)
    Path = pwd;
    pythonScript = [Path '\' file_name];
    disp([file_name ' running...']);

    if isempty(args)
        status = system(['python ', pythonScript]);
    else
        command = sprintf('"%s" "%s" %s', 'python', pythonScript, args);
        status = system(command);
    end

    if status == 0
        disp([file_name ' Done.']);
    else
        disp([file_name ' Failed.']);
    end
end

function cleanupTempFolder(folderPath)
    if isfolder(folderPath)
        disp(['Cleaning up temporary folder: ' folderPath]);
        rmdir(folderPath, 's');
    end
end
