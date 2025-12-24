function Update_CMM()

MessageLinkOut_Autobuild = boolean (1);

%% Initial settings
project_path = pwd;
Scripts_path = [project_path '/Scripts'];
arch_path = [project_path '/software/sw_development/arch'];
MessageLink_path = [project_path '\documents\MessageLink\'];

%% dbc_AutoWorkAround
cd(Scripts_path);
run_py('dbc_AutoWorkAround.py')


%% Modify_MessageLink
cd(arch_path);
disp('Modify_MessageLink.m running...')
Modify_MessageLink()
disp('Modify_MessageLink.m Done.')


%% MessageLinkOut_Autobuild
desktopPath = fullfile(getenv('USERPROFILE'), 'Desktop');
if MessageLinkOut_Autobuild
    cd(Scripts_path);
    run_py('MessageLinkOut_Autobuild.py')


%% Clone MessageLinkOut to origin folder
Linkout_file = dir([desktopPath '\zzz_MessageLinkout_Create\CAN_MessageLinkOut_*']);
delete([MessageLink_path '\CAN_MessageLinkOut_*']);
copyfile([Linkout_file.folder '\' Linkout_file.name],[MessageLink_path Linkout_file.name]);
end


%% FVT_ARXML_Generator
cd(project_path);
disp('FVT_ARXML_Generator.m running...')
FVT_ARXML_Generator()


%% Remove zzz_MessageLinkout_Create
rmdir([desktopPath '\zzz_MessageLinkout_Create'], 's');

fprintf('\n<strong>%s</strong>\n\n', 'CMM Updated and ARXML outputs Done!');
disp('Press any key to continue Check_vcu_local_hdr_Definition...');
pause;


%% Check_vcu_local_hdr_Definition
cd(arch_path);
disp('Check_vcu_local_hdr_Definition.m running...')
Check_vcu_local_hdr_Definition()

end



function run_py(file_name)

    Path = pwd;
    pythonScript = [Path '\' file_name];
    disp([file_name ' running...']);
    
    status = system(['python ', pythonScript]);
    
    if status == 0
        disp([file_name ' Done.']);
    else
        disp([file_name ' Failed.']);
    end

end