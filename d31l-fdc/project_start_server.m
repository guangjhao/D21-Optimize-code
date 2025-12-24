function project_start_server
%% Initial settings
code_generate = boolean (0);
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
%% load everything
evalin('base', 'run vcu_local_hdr');

% in arch_path	(inp, outp, util)
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

% load model configuration
cd(arch_path)
hcu_main_ModelConfig = ModelConfig_FUSION;
assignin('base', 'hcu_main_ModelConfig', hcu_main_ModelConfig);

if code_generate
    run code_generation
    disp('code generated, starting a2l rework')
    cd(project_path)
    run A2L_rework
    copyfile([project_path '/documents/FVT_API/FVT_API.h'],[arch_path '/hcu_main_ert_rtw'])
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

end

