model = 'SWC_HALCDD_type';
open_system(model)
cs = getActiveConfigSet(model);
set_param(cs, 'GenerateASAP2','on');
slbuild(model)