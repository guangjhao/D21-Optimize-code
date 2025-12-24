function A2L_rework

project_path = pwd;
arch_path = [project_path '/software/sw_development/arch'];
%% read original a2l and head file
cd ([project_path '/documents'])
fileID = fopen('SWC_FDC_type.a2l');
Target_A2L = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Target_A2L{1,1}),1);
for i = 1:length(Target_A2L{1,1})
    tmpCell{i,1} = Target_A2L{1,1}{i,1};
end
Target_A2L = tmpCell;
fclose(fileID);

cd([project_path '/documents/A2L_Head']);
fileID = fopen('A2L_Head.a2l','r');
Header_A2L = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(Header_A2L{1,1}),1);
for i = 1:length(Header_A2L{1,1})
    tmpCell{i,1} = Header_A2L{1,1}{i,1};
end
Header_A2L = tmpCell;
fclose(fileID);

%% header modify
EndofHeader = max(find(contains(Target_A2L(:,1),'/end MOD_PAR')),...
                  find(contains(Target_A2L(:,1),'/end MOD_COMMON')));

for i = EndofHeader:-1:1
    Target_A2L(i,:) = [];
end
Target_A2L = [Header_A2L;Target_A2L];

%% ENUM table update
fileID = fopen('vcu_local_hdr.m','r');
ENUM_Table = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
tmpCell = cell(length(ENUM_Table{1,1}),1);
for i = 1:length(ENUM_Table{1,1})
    tmpCell{i,1} = ENUM_Table{1,1}{i,1};
end
ENUM_Table = tmpCell;
VarIndex = find(contains(ENUM_Table,'_enum'));

for i = 1: length(VarIndex)
    VarName = deblank(extractAfter(char(ENUM_Table(VarIndex(i))),'% '));
    VarIdx_a2l = find(contains(Target_A2L,VarName), 1);
    if isempty(VarIdx_a2l)
        continue
    end

    % update conversion method
    ConversionName = ['COMPU_METHOD_ENUM_' char(upper(extractBetween(VarName,'_','_')))];
    if startsWith(VarName,'K')
        ConversionIdx_a2l = VarIdx_a2l + find(contains(Target_A2L(VarIdx_a2l:end),'Conversion Method'), 1)-1;
    else
        ConversionIdx_a2l = VarIdx_a2l + find(contains(Target_A2L(VarIdx_a2l:end),'Conversion method'), 1)-1;
    end
    Target_A2L(ConversionIdx_a2l) = {['          /* Conversion method      */      ' ConversionName]};


    StartIdx = VarIndex(i) + find(contains(ENUM_Table(VarIndex(i):end),'ENUM'),1)-1;
    cnt = 0;
    VarENUM = {};

    for k = StartIdx:1:length(ENUM_Table)
        if ~isempty(char(deblank(ENUM_Table(k))))
            cnt = cnt+1;
            Num = str2double(extractBetween(ENUM_Table(k),'(',');'));
            Disp = extractAfter(deblank(extractBetween(ENUM_Table(k),'_','=')),'_');
            VarENUM{cnt,1} = ['          ' num2str(Num) ' ' '"' char(Disp) '"'];
        else
            break
        end
    end

    COMPU_METHOD_idx = find(contains(Target_A2L(:,1),'/begin GROUP'),1)-2;
    COMPU_METHOD = {'';['        /begin COMPU_METHOD ' ConversionName];'          ""';...
                    '           TAB_VERB "%0.2" ""';...
                    ['           COMPU_TAB_REF VTAB_' ConversionName];...
                    '        /end COMPU_METHOD';''};

    COMPU_VTAB = {['        /begin COMPU_VTAB VTAB_' ConversionName ' "" ' 'TAB_VERB ' num2str(length(VarENUM))];...
                    '        /end COMPU_VTAB';''};
    COMPU_VTAB = [COMPU_VTAB(1);VarENUM;COMPU_VTAB(2:3)];
    Target_A2L = [Target_A2L(1:COMPU_METHOD_idx);COMPU_METHOD;COMPU_VTAB;Target_A2L(COMPU_METHOD_idx+2:end)];

end

%% write new a2l file
cd ([project_path '/documents'])
delete SWC_FDC_type.a2l

fileID = fopen('NewA2L.a2l','w');
for i = 1:length(Target_A2L(:,1))
    fprintf(fileID,'%s\n',char(Target_A2L(i,1)));
end
fclose(fileID);

movefile('NewA2L.a2l','SWC_FDC_type.a2l');
cd (arch_path)
disp('a2l rework done!')

end