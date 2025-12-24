function FVT_SWC_Autobuild()
%% Select SWC for Autobuild
project_path = pwd;
addpath(project_path);
addpath([project_path '/Scripts']);
SWC_list = {'SWC_HALIN';'SWC_HALIN_CDD';'SWC_INP';'SWC_FDC';'SWC_OUTP';'SWC_HALOUT'};
[indx, ~] = listdlg('PromptString',{'Select the module.'},'ListSize',[200,150],'ListString',SWC_list);
indx = transpose(indx);
for i = 1:length(indx)
    Target_SWC = char(SWC_list(indx(i)));
    if any(strcmp(Target_SWC,{'SWC_HALIN';'SWC_INP';'SWC_FDC';'SWC_OUTP'}))
        FVT_SWC_Else_Autobuild(Target_SWC);
    else
        feval(['FVT_' Target_SWC '_Autobuild'])
    end
    cd(project_path);
end
end