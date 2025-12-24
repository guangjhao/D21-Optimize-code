function code_generation

ModelName = 'hcu_main';
open_system(ModelName);
disp('hcu_main model opened');

if isfolder('hcu_main_ert_rtw')
    rmdir('hcu_main_ert_rtw', 's');
end

disp('generating code...')
% rtwbuild(ModelName);
slbuild(ModelName);
close_system(ModelName);
end