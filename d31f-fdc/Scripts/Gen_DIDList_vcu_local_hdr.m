function Gen_DIDList_vcu_local_hdr(~)

%% Check
q = questdlg({'Check the following conditions:', 'Current folder is Scripts?'},...
    'Initial check','Yes','No','Yes');
if ~contains(q, 'Yes')
    return
end
cd ../documents/

%% Read DID List .xlsx File
FVT_DIDList = (readcell('FVT_DIDList.xlsx'));
DIDList_DIDNumHex = FVT_DIDList(3:end,1);
DIDList_ArgDatatype = FVT_DIDList(3:end,4);
DIDList_DIDSize = FVT_DIDList(3:end,5);
DIDList_RWMode = FVT_DIDList(3:end,6);
DIDList_SubDataName = FVT_DIDList(3:end,7);
DIDList_CSOPName = FVT_DIDList(3:end,8);
DIDList_DIDlen = FVT_DIDList(3:end,9);      % Input1
DIDList_DIDNum = FVT_DIDList(3:end,10);     % Input2
DIDList_DIDSta = FVT_DIDList(3:end,11);     % Output1
DIDList_VarNameIn = FVT_DIDList(3:end,12);  % Input3
DIDList_VarNameOut = FVT_DIDList(3:end,13); % Output2

%% Delete duplicated DID
j = 1;
for i = 1: length(DIDList_DIDNumHex)
    if ~ismissing(DIDList_DIDNumHex{i})
       DIDList_DIDNumHex_Valid{j} =  DIDList_DIDNumHex{i};
       DIDList_SubDataName_Valid{j} =  DIDList_SubDataName{i};
       DIDList_DIDSize_Valid{j} = DIDList_DIDSize{i};
       DIDList_RWMode_Valid{j} = DIDList_RWMode{i};
       j = j+1;
    end     
end

%% Generate vcu_local_hdr
for i = 1:size(DIDList_DIDNumHex_Valid, 2)
    
    % DIDNum_xxx    =   uint16(0xxxx);
    variable_name = sprintf('DIDNum_%s', DIDList_SubDataName_Valid{i});
    variable_value = sprintf('uint16(%s)', DIDList_DIDNumHex_Valid{i});
    fprintf('%-32s\t=\t%s;\n', variable_name, variable_value);

    % DIDLen_xxx    =   uint16(xxx);
    variable_name = sprintf('DIDLen_%s', DIDList_SubDataName_Valid{i});
    variable_value = sprintf('uint16(%d)', DIDList_DIDSize_Valid{i});
    fprintf('%-32s\t=\t%s;\n', variable_name, variable_value);

    % A2L resolving array variables
    if DIDList_DIDSize_Valid{i} > 1 && DIDList_RWMode_Valid{i} == 'W'
        variable_name = sprintf('VHAL_%s_raw', DIDList_SubDataName_Valid{i});
        fprintf('\n');
        fprintf('global %s;\n', variable_name);
        fprintf('%s = Simulink.Signal;\n', variable_name);
        fprintf('%s.CoderInfo.StorageClass = ''ExportedGlobal'';\n', variable_name);
        fprintf('%s.DataType = ''uint8'';\n', variable_name);
    end

    fprintf('\n');
end


end

