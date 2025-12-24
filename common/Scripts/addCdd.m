% Function: addCdd
% Description: Generates AUTOSAR-compatible CDD ARXML files based on a given C-style API declaration. 
% Flowchart:
%   +---------------------------------------------------+
%   |   User inputs API declaration                     |
%   +---------------------------------------------------+
%                             v
%   +---------------------------------------------------+
%   |   Parse API to generate recommended CDD           |
%   |   declaration for user to edit                    |
%   +---------------------------------------------------+
%                             v
%   +---------------------------------------------------+
%   |   Re-parse edited CDD declaration to generate:    |
%   |   - Final CDD function name                       |
%   |   - Argument names and their directions           |
%   +---------------------------------------------------+
%                             v
%   +---------------------------------------------------+
%   |   Modify FVT_CDD.arxml:                           |
%   |   - Insert <CLIENT-SERVER-OPERATION>              |
%   |   - Insert <ARGUMENT-DATA-PROTOTYPE>              |
%   |   - For arrays: Insert <IMPLEMENTATION-DATA-TYPE> |
%   +---------------------------------------------------+
%                             v
%   +---------------------------------------------------+
%   |   Modify SWC_CDD.arxml:                           |
%   |   - Insert <OPERATION-INVOKED-EVENT>              |
%   |   - Insert <RUNNABLE-ENTITY>                      |
%   +---------------------------------------------------+
%                             v
%   +---------------------------------------------------+
%   |   Modify SWC_FDC.arxml or FVT_HALIN_CDD.arxml:    |
%   |   - Insert <SYNCHRONOUS-SERVER-CALL-POINT>        |
%   +---------------------------------------------------+


%% Add CDD based on the given API
function addCdd()
    
    %% Initialization
    commonScriptsPath = pwd;
    if ~contains(commonScriptsPath, 'common\Scripts'), error('current folder is not under common\Scripts'), end

    refCarModel = {'d31l-fdc', 'd31f-fdc', 'd31f-fdc2', 'd31hrwd-fdc2', 'd31hawd-fdc2', 'd21rwd-fdc2', 'd21awd-fdc2', 'd31x-fdc'};
    [selectedIdx, ~] = listdlg('PromptString', {'Select the car model.'}, 'ListSize', [200,150], 'ListString', refCarModel, 'SelectionMode', 'single');
    selectedCarModel = refCarModel{selectedIdx};

    projectPath = char(strcat(commonScriptsPath, '\..\..\', selectedCarModel));


    %% Api Info
    % Input: Api Declaration => Output: Cdd Declaration Recommendation
    prompt = {'Please enter the API declaration： (e.g.: int api_get_status(uint8 id) )'};
    dlgTitle = 'Enter the API declaration';
    numLines = [1, 100];
    apiDeclaration = inputdlg(prompt, dlgTitle, numLines);
    apiDeclaration = strtrim(apiDeclaration{1});
    disp(['Entered API Declaration:' char(9) apiDeclaration]);
    [~, ~, cddDeclaration] = parseApiDeclarationToCddArgs(apiDeclaration);
    

    %% Cdd Info
    % Input: Edited Cdd Declaration => Output: Generated Cdd Name & Arguments Info (cddArgName & cddArgDirection)
    prompt = {'Please edit the CDD declaration based on the following naming recommendation：'};
    dlgTitle = 'Edit the CDD declaration';
    numLines = [1, 100];
    defaultDeclaration = {cddDeclaration};
    editedDeclaration = inputdlg(prompt, dlgTitle, numLines, defaultDeclaration);
    cddDeclaration = strtrim(editedDeclaration{1});
    disp(['Edited CDD Declaration:' char(9) char(9) cddDeclaration]);
    [cddName, argsInfo, generatedCddDeclaration] = parseApiDeclarationToCddArgs(cddDeclaration);
    disp(['Generated CDD Declaration:' char(9) generatedCddDeclaration]);

    argumentsName = cellfun(@(a) a.cddArgName, argsInfo, 'UniformOutput', false);
    argumentsDirection  = cellfun(@(a) a.cddArgDirection, argsInfo, 'UniformOutput', false);
    numArguments = length(argumentsName);


    %% Modify FVT_CDD.arxml
    % Add <csopCell> and <argumentImplTypesCell> (if needed)
    % <csopCell> = <csopCellHeader> + <argumentsCell> + <csopCellFooter>
    cd([projectPath '\documents\ARXML_output']) 
    fileId = fopen('FVT_CDD.arxml');
    fvtCddArxml = textscan(fileId,'%s', 'delimiter', '\n', 'whitespace', '');
    fclose(fileId);
    fvtCddArxml = fvtCddArxml{1};

    % Select one of the CDD interfaces in FVT_CDD.arxml
    cddIfLines = find(contains(fvtCddArxml, '          <SHORT-NAME>IF_') & contains(fvtCddArxml, 'CDD'));
    cddIfsNested = regexp(fvtCddArxml(cddIfLines), '<SHORT-NAME>(.*?)</SHORT-NAME>', 'tokens')';
    cddIfs = cellfun(@(nestedCell) strtrim(nestedCell{1,1}{1,1}), cddIfsNested, 'UniformOutput', false);
    [selectedIdx, ~] = listdlg('ListString', cddIfs', 'ListSize', [200,150], 'SelectionMode', 'single', 'PromptString', 'Select the CDD interface.');
    selectedCddIf = cddIfs{selectedIdx};  
    selectedCddIfLine = cddIfLines(selectedIdx) + 2;
    cddImplTypesLine = find(contains(fvtCddArxml, '      <SHORT-NAME>Impl_Types_ARPkg')) + 1;

    csopCellHeader = {
    '            <CLIENT-SERVER-OPERATION>';
    sprintf('              <SHORT-NAME>CSOP_%s</SHORT-NAME>', cddName)
    '              <ADMIN-DATA><SDGS><SDG GID="_conversion"><SDG GID="DIAG-ARG-INTEGRITY"><SD GID="_mixed">false</SD></SDG><SD GID="_path">DIAG-ARG-INTEGRITY@3/</SD><SD GID="_target">org.artop.aal.autosar4480</SD></SDG><SDG GID="_conversion"><SDG GID="FIRE-AND-FORGET"><SD GID="_mixed">false</SD></SDG><SD GID="_path">FIRE-AND-FORGET@3/</SD><SD GID="_target">org.artop.aal.autosar4430</SD></SDG></SDGS></ADMIN-DATA><ARGUMENTS>';
    };
    
    argumentsCell = {};
    argumentImplTypesCell = {};
    for i = 1:numArguments
        argumentName = argumentsName{i};
        argumentTypeAbbr = subsref(split(argumentName, '_'), substruct('{}', {1}));  
        argumentType = strrep(strrep(argumentTypeAbbr, 'u', 'uint'), 's', 'sint');
        argumentDirection = argumentsDirection{i};

        if contains(argumentType, 'Array')
            argumentCell = {
            '                <ARGUMENT-DATA-PROTOTYPE>';
            sprintf('                  <SHORT-NAME>%s</SHORT-NAME>', argumentName);
            sprintf('                  <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">/Impl_Types_ARPkg/%s_type</TYPE-TREF>', argumentName);
            sprintf('                  <DIRECTION>%s</DIRECTION>', argumentDirection);
            '                  <SERVER-ARGUMENT-IMPL-POLICY>USE-ARGUMENT-TYPE</SERVER-ARGUMENT-IMPL-POLICY>';
            '                </ARGUMENT-DATA-PROTOTYPE>';
            };
            
            % Define argument implementation data type   
            argumentTypeMatch = regexp(argumentType, '[a-z]int\d+|\d+$', 'match');
            argumentBaseType = argumentTypeMatch{1};
            argumentArraySize = argumentTypeMatch{2};
            argumentBaseTypeAbbr = strrep(argumentBaseType, 'int', '');

            argumentImplTypeCell = {
                '        <IMPLEMENTATION-DATA-TYPE>';
                sprintf('          <SHORT-NAME>%s_type</SHORT-NAME>', argumentName);
                '          <CATEGORY>ARRAY</CATEGORY>';
                '          <ADMIN-DATA><SDGS><SDG GID="_conversion"><SDG GID="IS-STRUCT-WITH-OPTIONAL-ELEMENT"><SD GID="_mixed">false</SD></SDG>';
                '          <SD GID="_path">IS-STRUCT-WITH-OPTIONAL-ELEMENT@4/</SD><SD GID="_target">org.artop.aal.autosar4460</SD></SDG></SDGS></ADMIN-DATA><SW-DATA-DEF-PROPS>';
                '            <SW-DATA-DEF-PROPS-VARIANTS>';
                '              <SW-DATA-DEF-PROPS-CONDITIONAL></SW-DATA-DEF-PROPS-CONDITIONAL>';
                '            </SW-DATA-DEF-PROPS-VARIANTS>';
                '          </SW-DATA-DEF-PROPS>';
                '          <SUB-ELEMENTS>';
                '            <IMPLEMENTATION-DATA-TYPE-ELEMENT>';
                sprintf('              <SHORT-NAME>%s_Element</SHORT-NAME>', argumentBaseTypeAbbr);
                '              <CATEGORY>VALUE</CATEGORY>';
                '              <ADMIN-DATA><SDGS><SDG GID="_conversion"><SDG GID="IS-OPTIONAL"><SD GID="_mixed">false</SD></SDG>';
                sprintf('              <SD GID="_path">IS-OPTIONAL@5/</SD><SD GID="_target">org.artop.aal.autosar4460</SD></SDG></SDGS></ADMIN-DATA><ARRAY-SIZE>%s</ARRAY-SIZE>', argumentArraySize);
                '              <ARRAY-SIZE-SEMANTICS>FIXED-SIZE</ARRAY-SIZE-SEMANTICS>';
                '              <SW-DATA-DEF-PROPS>';
                '                <SW-DATA-DEF-PROPS-VARIANTS>';
                '                  <SW-DATA-DEF-PROPS-CONDITIONAL>';
                sprintf('                    <BASE-TYPE-REF DEST="SW-BASE-TYPE">/AUTOSAR_Platform/BaseTypes/%s</BASE-TYPE-REF>', argumentBaseType);
                '                  </SW-DATA-DEF-PROPS-CONDITIONAL>';
                '                </SW-DATA-DEF-PROPS-VARIANTS>';
                '              </SW-DATA-DEF-PROPS>';
                '            </IMPLEMENTATION-DATA-TYPE-ELEMENT>';
                '          </SUB-ELEMENTS>';
                '        </IMPLEMENTATION-DATA-TYPE>';
            };

            argumentImplTypesCell = [argumentImplTypesCell; argumentImplTypeCell];

        else % ~contains(argumentType, 'Array')
                    argumentCell = {
            '                <ARGUMENT-DATA-PROTOTYPE>';
            sprintf('                  <SHORT-NAME>%s</SHORT-NAME>', argumentName);
            sprintf('                  <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">/AUTOSAR_Platform/ImplementationDataTypes/%s</TYPE-TREF>', argumentType);
            sprintf('                  <DIRECTION>%s</DIRECTION>', argumentDirection);
            '                  <SERVER-ARGUMENT-IMPL-POLICY>USE-ARGUMENT-TYPE</SERVER-ARGUMENT-IMPL-POLICY>';
            '                </ARGUMENT-DATA-PROTOTYPE>';
            };
        end

        argumentsCell = [argumentsCell; argumentCell];
    end
    
    csopCellFooter = {
    '              </ARGUMENTS>';
    '            </CLIENT-SERVER-OPERATION>';
    };

    csopCell = [csopCellHeader; argumentsCell; csopCellFooter];
    fvtCddArxml = [
        fvtCddArxml(1: selectedCddIfLine); csopCell; fvtCddArxml(selectedCddIfLine + 1: cddImplTypesLine); argumentImplTypesCell; fvtCddArxml(cddImplTypesLine + 1: end)
        ];

    % Output arxml
    cd([projectPath '\documents\ARXML_output'])
    fileID = fopen( 'FVT_CDD.arxml','w');
    for i = 1:length(fvtCddArxml(:,1))
        fprintf(fileID,'%s\n',char(fvtCddArxml(i,1)));
    end
    fclose(fileID);


    %% Modify SWC_CDD.arxml
    % Add <oieCell> and <runnableCell>
    swcName = 'SWC_CDD';

    cd([projectPath '\documents\ARXML_output']) 
    fileId = fopen('SWC_CDD.arxml');
    swcCddArxml = textscan(fileId,'%s', 'delimiter', '\n', 'whitespace', '');
    fclose(fileId);
    swcCddArxml = swcCddArxml{1};

    cddInternalBehaviorLine = find(contains(swcCddArxml, '              <SHORT-NAME>SWC_CDD_type_IB')) + 1;
    selectedCdd = strrep(selectedCddIf, 'IF_', '');
    oieCell = {
        '                <OPERATION-INVOKED-EVENT>';
        sprintf('                  <SHORT-NAME>oie_P_%s_CSOP_%s</SHORT-NAME>', selectedCdd, cddName);
        sprintf('                  <START-ON-EVENT-REF DEST="RUNNABLE-ENTITY">/SWC_CDD_ARPkg/SWC_CDD_type/SWC_CDD_type_IB/run_%s_%s</START-ON-EVENT-REF>', selectedCdd, cddName);
        '                  <OPERATION-IREF>';
        sprintf('                    <CONTEXT-P-PORT-REF DEST="P-PORT-PROTOTYPE">/SWC_CDD_ARPkg/SWC_CDD_type/P_%s</CONTEXT-P-PORT-REF>', selectedCdd);
        sprintf('                    <TARGET-PROVIDED-OPERATION-REF DEST="CLIENT-SERVER-OPERATION">/FVT_CDD_Interface_ARPkg/%s/CSOP_%s</TARGET-PROVIDED-OPERATION-REF>', selectedCddIf, cddName);
        '                  </OPERATION-IREF>';
        '                </OPERATION-INVOKED-EVENT>';
    };
  
    cddRunnablesLine = find(contains(swcCddArxml, '              <RUNNABLES>'));
    runnableCell = {
        '                <RUNNABLE-ENTITY>';
        sprintf('                  <SHORT-NAME>run_%s_%s</SHORT-NAME>', selectedCdd, cddName);
        '                  <MINIMUM-START-INTERVAL>0.0</MINIMUM-START-INTERVAL>';
        '                  <CAN-BE-INVOKED-CONCURRENTLY>false</CAN-BE-INVOKED-CONCURRENTLY>';
        sprintf('                  <SYMBOL>run_%s_%s</SYMBOL>', selectedCdd, cddName);
        '                </RUNNABLE-ENTITY>';
    };

    swcCddArxml = [
        swcCddArxml(1: cddInternalBehaviorLine); oieCell; swcCddArxml(cddInternalBehaviorLine + 1: cddRunnablesLine); runnableCell; swcCddArxml(cddRunnablesLine + 1: end)
        ];

    % Output arxml
    cd([projectPath '\documents\ARXML_output'])
    fileID = fopen( 'SWC_CDD.arxml','w');
    for i = 1:length(swcCddArxml(:,1))
        fprintf(fileID,'%s\n',char(swcCddArxml(i,1)));
    end
    fclose(fileID);    

    
    if any(strcmp(selectedCarModel, {'d31l-fdc', 'd31f-fdc', 'd31x-fdc'}))
        %% Modify SWC_FDC.arxml
        % Add <scpCell>
        swcName = 'SWC_FDC';
    
        cd([projectPath '\documents\ARXML_output']) 
        fileId = fopen('SWC_FDC.arxml');
        swcFdcArxml = textscan(fileId,'%s', 'delimiter', '\n', 'whitespace', '');
        fclose(fileId);
        swcFdcArxml = swcFdcArxml{1};
        
        cddReLines = find(contains(swcFdcArxml, '<SHORT-NAME>run_SWC_FDC') & contains(swcFdcArxml, 'ms'));
        cddResNested = regexp(swcFdcArxml(cddReLines), '<SHORT-NAME>(.*?)</SHORT-NAME>', 'tokens')';
        cddRes = cellfun(@(nestedCell) strtrim(nestedCell{1,1}{1,1}), cddResNested, 'UniformOutput', false);
        [selectedIdx, ~] = listdlg('ListString', cddRes', 'ListSize', [200,150], 'SelectionMode', 'single', 'PromptString', 'Select the CDD runnable entity.');
        selectedCddRes = cddRes{selectedIdx};  
        selectedCddResLine = cddReLines(selectedIdx);
        nextSelectedCddResLine = cddReLines(min(selectedIdx + 1, length(cddReLines)));
        cddServerCallPointLines = find(contains(swcFdcArxml, '<SERVER-CALL-POINTS>'));
        cddServerCallPointLine = cddServerCallPointLines( ...
            find((cddServerCallPointLines > selectedCddResLine) & (cddServerCallPointLines < nextSelectedCddResLine), 1, 'first'));
    
        scpCell = {
            '                    <SYNCHRONOUS-SERVER-CALL-POINT>';
            sprintf('                      <SHORT-NAME>scp_CSOP_%s</SHORT-NAME>', cddName);
            '                      <OPERATION-IREF>';
            sprintf('                        <CONTEXT-R-PORT-REF DEST="R-PORT-PROTOTYPE">/SWC_FDC_ARPkg/SWC_FDC_type/R_%s</CONTEXT-R-PORT-REF>', selectedCdd);
            sprintf('                        <TARGET-REQUIRED-OPERATION-REF DEST="CLIENT-SERVER-OPERATION">/FVT_CDD_Interface_ARPkg/%s/CSOP_%s</TARGET-REQUIRED-OPERATION-REF>', selectedCddIf, cddName);
            '                      </OPERATION-IREF>';
            '                      <TIMEOUT>0.0</TIMEOUT>';
            '                    </SYNCHRONOUS-SERVER-CALL-POINT>';
        };
    
        swcFdcArxml = [
            swcFdcArxml(1: cddServerCallPointLine); scpCell; swcFdcArxml(cddServerCallPointLine + 1: end);
            ];
    
        % Output arxml
        cd([projectPath '\documents\ARXML_output'])
        fileID = fopen( 'SWC_FDC.arxml','w');
        for i = 1:length(swcFdcArxml(:,1))
            fprintf(fileID,'%s\n',char(swcFdcArxml(i,1)));
        end
        fclose(fileID);
        cd(commonScriptsPath);

    elseif any(strcmp(selectedCarModel, {'d31f-fdc2', 'd31hawd-fdc2', 'd31hrwd-fdc2', 'd21awd-fdc2', 'd21rwd-fdc2'}))
        %% Modify FVT_HALIN_CDD.arxml
        % Add <scpCell>
        swcName = 'FVT_HALIN_CDD';
    
        cd([projectPath '\documents\ARXML_output']) 
        fileId = fopen('FVT_HALIN_CDD.arxml');
        swcFdcArxml = textscan(fileId,'%s', 'delimiter', '\n', 'whitespace', '');
        fclose(fileId);
        swcFdcArxml = swcFdcArxml{1};
        
        cddReLines = find(contains(swcFdcArxml, '<SHORT-NAME>run_SWC_HALIN') & contains(swcFdcArxml, 'ms'));
        cddResNested = regexp(swcFdcArxml(cddReLines), '<SHORT-NAME>(.*?)</SHORT-NAME>', 'tokens')';
        cddRes = cellfun(@(nestedCell) strtrim(nestedCell{1,1}{1,1}), cddResNested, 'UniformOutput', false);
        [selectedIdx, ~] = listdlg('ListString', cddRes', 'ListSize', [200,150], 'SelectionMode', 'single', 'PromptString', 'Select the CDD runnable entity.');
        selectedCddRes = cddRes{selectedIdx};  
        selectedCddResLine = cddReLines(selectedIdx);
        nextSelectedCddResLine = cddReLines(min(selectedIdx + 1, length(cddReLines)));
        cddServerCallPointLines = find(contains(swcFdcArxml, '<SERVER-CALL-POINTS>'));
        cddServerCallPointLine = cddServerCallPointLines( ...
            find((cddServerCallPointLines > selectedCddResLine) & (cddServerCallPointLines < nextSelectedCddResLine), 1, 'first'));
    
        scpCell = {
            '                    <SYNCHRONOUS-SERVER-CALL-POINT>';
            sprintf('                      <SHORT-NAME>scp_CSOP_%s</SHORT-NAME>', cddName);
            '                      <OPERATION-IREF>';
            sprintf('                        <CONTEXT-R-PORT-REF DEST="R-PORT-PROTOTYPE">/SWC_HALIN_CDD_ARPkg/SWC_HALIN_CDD_type/R_%s</CONTEXT-R-PORT-REF>', selectedCdd);
            sprintf('                        <TARGET-REQUIRED-OPERATION-REF DEST="CLIENT-SERVER-OPERATION">/FVT_CDD_Interface_ARPkg/%s/CSOP_%s</TARGET-REQUIRED-OPERATION-REF>', selectedCddIf, cddName);
            '                      </OPERATION-IREF>';
            '                      <TIMEOUT>0.0</TIMEOUT>';
            '                    </SYNCHRONOUS-SERVER-CALL-POINT>';
        };
    
        swcFdcArxml = [
            swcFdcArxml(1: cddServerCallPointLine); scpCell; swcFdcArxml(cddServerCallPointLine + 1: end);
            ];
    
        % Output arxml
        cd([projectPath '\documents\ARXML_output'])
        fileID = fopen( 'FVT_HALIN_CDD.arxml','w');
        for i = 1:length(swcFdcArxml(:,1))
            fprintf(fileID,'%s\n',char(swcFdcArxml(i,1)));
        end
        fclose(fileID);
        cd(commonScriptsPath);
    end

end



%% Process Api Declaration
function [cddName, argsInfo, cddDeclaration] = parseApiDeclarationToCddArgs(apiDeclaration)
    
    % ===== cddName =====
    apiDeclaration = strtrim(strrep(apiDeclaration, ';', ''));
    tokens = regexp(apiDeclaration, '^\s*([a-zA-Z_][a-zA-Z0-9_*\s]+)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(', 'tokens', 'once');
    returnType = strtrim(tokens{1});
    apiName = strtrim(tokens{2});

    splittedParts = split(apiName, '_');
    capitalizedParts = cellfun(@(s) [upper(s(1)) s(2:end)], splittedParts, 'UniformOutput', false);
    splitByCaps = @(s) regexp(s, '[A-Z]{2,}[0-9]*(?=[A-Z][a-z]|$)|[A-Z][a-z]+\d*|[A-Z][0-9]+|[A-Z]', 'match');
    allParts = cellfun(splitByCaps, capitalizedParts, 'UniformOutput', false);
    apiNameCamelParts = [allParts{:}];
    if contains(apiNameCamelParts{1}, 'api', 'IgnoreCase', true)
        apiNameCamelParts = apiNameCamelParts(2:end);        
    end
    apiNameCamelPartsNoHeader = cellfun(@(p) [upper(p(1)) lower(p(2:end))], apiNameCamelParts(2:end), 'UniformOutput', false);
    apiNameCamelParts = [apiNameCamelParts(1); apiNameCamelPartsNoHeader(:)]; 
    apiNameCamelParts{1} = lower(apiNameCamelParts{1});
    cddName = strjoin(apiNameCamelParts, ''); 

    % ===== argsInfo =====
    argsInfo = {};
    cddArgs = {};

    outputPart = regexp(apiDeclaration, '^[^()]+', 'match', 'once');
    inputPart = regexp(apiDeclaration, '\((.*)\)', 'tokens', 'once');
    if isempty(outputPart) || isempty(inputPart)
        error('Api apiDeclaration format error!');
    end

    inputArgStr = strtrim(inputPart{1});
    inputArgs = strtrim(split(inputArgStr, ','));
    
    args = [outputPart; inputArgs];

    for i = 1:length(args)

        % Resolve argType & argName
        arg = strtrim(args{i});
        arg = regexprep(arg, '\s+', ' ');
        arg = strrep(arg, ' *', '*');
        tokens  = regexp(arg, '(const\s+)?([a-zA-Z_][a-zA-Z0-9_]*)(\*?)(\s*[a-zA-Z_][a-zA-Z0-9_]*)', 'tokens', 'once');
        argType = tokens{2};
        argName = strtrim(tokens{4});
        
        % Determine Arg state
        isNowOutputArg = (i == 1);
        isOutputVoid   = strcmp(argType, 'void') && isNowOutputArg;
        isInputVoid    = strcmp(inputArgStr, 'void') && ~isNowOutputArg;
        isArgConst     = ~isempty(tokens{1});
        isArgPointer   = contains(tokens{3}, '*');

        % void
        if isInputVoid || isOutputVoid
            continue
        end

        % Determine Arg Direction based on Arg Info
        if isArgPointer || isNowOutputArg
            cddArgDirection = 'OUT';
        else % ~isPointer && ~isNowOutputArg
            cddArgDirection = 'IN';
        end

        if isArgConst
            cddArgDirection = 'IN';
        end
        
        argType = strrep(argType, '_t', '');
        argTypeAbbr = strrep(argType, 'int', '');
        if strcmp(argTypeAbbr, 'bool')
            argTypeAbbr = 'u8';
        end

        % Arg Name
        splittedParts = split(argName, '_');
        capitalizedParts = cellfun(@(s) [upper(s(1)) s(2:end)], splittedParts, 'UniformOutput', false);
        splitByCaps = @(s) regexp(s, '[A-Z]{2,}[0-9]*(?=[A-Z][a-z]|$)|[A-Z][a-z]+\d*|[A-Z][0-9]+|[A-Z]', 'match');
        allParts = cellfun(splitByCaps, capitalizedParts, 'UniformOutput', false);
        argNameCamelParts = [allParts{:}];

        if isNowOutputArg
            if contains(argNameCamelParts{1}, 'api', 'IgnoreCase', true)
                argNameCamelParts = argNameCamelParts(2:end);
            end
            argNameCamelParts = [{'ret'}; argNameCamelParts(:)];
        end

        % Combine u? and Array?
        if strcmpi(argTypeAbbr, argNameCamelParts{1}) && contains(argNameCamelParts{2}, 'Array')
            argTypeAbbr = [argTypeAbbr argNameCamelParts{2}];
            argNameCamelParts = argNameCamelParts(3:end);
        % Delete duplicated argTypeAbbr
        elseif strcmpi(argTypeAbbr, argNameCamelParts{1})
            argNameCamelParts = argNameCamelParts(2:end);
        end
        argNameCamelParts{1} = lower(argNameCamelParts{1});
        argNameCamelPartsNoHeader = cellfun(@(p) [upper(p(1)) lower(p(2:end))], argNameCamelParts(2:end), 'UniformOutput', false);
        argNameCamelParts = [argNameCamelParts(1); argNameCamelPartsNoHeader(:)]; 
        argNameAbbr = strjoin(argNameCamelParts, '');
                
        cddArgName = [argTypeAbbr '_' argNameAbbr];

        argsInfo{end+1} = struct( ...
            'cddArgName', cddArgName, ...
            'cddArgDirection', cddArgDirection ...
        );
        
        % ===== cddDeclaration =====
        if isArgPointer
            cddArg = [argType ' *' cddArgName];
        else % ~isArgPointer
            cddArg = [argType ' ' cddArgName];
        end
        
        if isArgConst
            cddArg = ['const ' cddArg];
        end

        if ~isNowOutputArg
            cddArgs{end+1} = cddArg;
        end
    end

    cddDeclaration = sprintf('%s %s(%s);', returnType, cddName, strjoin(cddArgs, ', '));
end