load_system('SWC_FDC_type');
Subsystem_FirsyLayer = find_system('SWC_FDC_type','SearchDepth',2,'IncludeCommented','on','Commented','on','BlockType','SubSystem');
 
for i = 1:length(Subsystem_FirsyLayer)
 
   temp_sub_path = char(Subsystem_FirsyLayer(i));
 
   temp_comment_ind = get_param(temp_sub_path,'commented');
 
   if strcmp(temp_comment_ind,'on')
 
       set_param(temp_sub_path,'commented','off');
 
   end
 
end