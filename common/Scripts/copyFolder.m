function copyFolder()
    
    %% Initialization
    commonScriptsPath = pwd;
    if ~contains(commonScriptsPath, 'common\Scripts')
        error('Current folder is not under common\Scripts');
    end

    % Select source and destination folders
    refCarModel = {'d31l-fdc', 'd31f-fdc', 'd31f-fdc2', 'd31hrwd-fdc2', 'd31hawd-fdc2', 'd21rwd-fdc2', 'd21awd-fdc2', 'd31x-fdc'};

    [selectedIdx, ~] = listdlg( ...
        'Name', 'Select the source folder', ...
        'PromptString', {'Select the car model folder to be copied.'}, ...
        'ListSize', [300,150], ...
        'ListString', refCarModel, ...
        'SelectionMode', 'single' ...
    );
    selectedSrcCarModel = refCarModel{selectedIdx};

    [selectedIdx, ~] = listdlg( ...
        'Name', 'Select the destination folder', ...
        'PromptString', {'Select the car model folder to be pasted.'}, ...
        'ListSize', [300,150], ...
        'ListString', refCarModel, ...
        'SelectionMode', 'single' ...
    );
    selectedDstCarModel = refCarModel{selectedIdx};
    
    disp(['Source folder: ', selectedSrcCarModel, ' => Destination folder: ', selectedDstCarModel])
    normalizedSelectedSrcCarModel = regexprep(selectedSrcCarModel, 'rwd|awd', '');
    normalizedSelectedDstCarModel = regexprep(selectedDstCarModel, 'rwd|awd', '');

    isSrcModelAndDstModelSharingWorkspace = strcmp(normalizedSelectedSrcCarModel, normalizedSelectedDstCarModel);

    srcAppFolder = char(strcat(commonScriptsPath, '\..\..\', selectedSrcCarModel));
    srcSourceFolder = char(strcat(commonScriptsPath, '\..\..\..\source\fvt_app\', selectedSrcCarModel));
    srcWorkspaceFolder = char(strcat(commonScriptsPath, '\..\..\..\workspace\', normalizedSelectedSrcCarModel));

    dstAppFolder = char(strcat(commonScriptsPath, '\..\..\', selectedDstCarModel));
    dstSourceFolder = char(strcat(commonScriptsPath, '\..\..\..\source\fvt_app\', selectedDstCarModel));
    dstWorkspaceFolder = char(strcat(commonScriptsPath, '\..\..\..\workspace\', normalizedSelectedDstCarModel));

    if isSrcModelAndDstModelSharingWorkspace
        srcFolders = {srcAppFolder, srcSourceFolder};
        dstFolders = {dstAppFolder, dstSourceFolder};
    else
        srcFolders = {srcAppFolder, srcSourceFolder, srcWorkspaceFolder};
        dstFolders = {dstAppFolder, dstSourceFolder, dstWorkspaceFolder};
    end


    %% Files and folders to exclude
    % app
    excludeAppFiles = {'FVT_API.h'};
    excludeAppFolders = {'tqd', 'tqr', 'pmm', 'inp_sys'};
    excludeAppPatterns = {'^zCar_Model_...\.txt$'};
    % source
    excludeSourceFiles = {'FVT_API.h', 'SWC_FDC_type.c', 'SWC_INP_type.c'};
    excludeSourceFolders = {};
    excludeSourcePatterns = {};
    % workspace
    excludeWorkspaceFiles = {'.project'};
    excludeWorkspaceFolders = {};
    excludeWorkspacePatterns = {'^Car_Model_...\.txt$'};

    if isSrcModelAndDstModelSharingWorkspace
        excludeFiles = {excludeAppFiles, excludeSourceFiles};
        excludeFolders = {excludeAppFolders, excludeSourceFolders};
        excludePatterns = {excludeAppPatterns, excludeSourcePatterns};
    else
        excludeFiles = {excludeAppFiles, excludeSourceFiles, excludeWorkspaceFiles};
        excludeFolders = {excludeAppFolders, excludeSourceFolders, excludeWorkspaceFolders};
        excludePatterns = {excludeAppPatterns, excludeSourcePatterns, excludeWorkspacePatterns};
    end

    %% Check not common .slx files 
    % Check for .slx files in software/sw_development/arch/app
    disp(' ');
    projectRootPath = fullfile(commonScriptsPath, '..', '..');
    targetBasePath = fullfile(projectRootPath, selectedSrcCarModel, 'software', 'sw_development', 'arch', 'app');
    if ~exist(targetBasePath, 'dir')
        disp(['Directory not found: ', targetBasePath]);
    else
        subFoldersList = dir(targetBasePath);
        subFoldersList = subFoldersList([subFoldersList.isdir]);
        subFoldersList = subFoldersList(~ismember({subFoldersList.name}, {'.', '..'}));

        foundSLXInAnySubfolder = false;

        disp('Folders in app containing .slx files:');
        for folderIdx = 1:length(subFoldersList)
            currentSubFolderName = subFoldersList(folderIdx).name;
            currentSubFolderPath = fullfile(targetBasePath, currentSubFolderName);
            slxFilesList = dir(fullfile(currentSubFolderPath, '*.slx'));
            
            if ~isempty(slxFilesList)
                disp([' - ', currentSubFolderName]);
                foundSLXInAnySubfolder = true;
            end
        end
        
        if ~foundSLXInAnySubfolder
            disp('  None');
        end

    end
    disp('Please check whether the DD files of the above models are compatible!');
    disp(' ');
    disp('Press any key to continue...');
    pause;
    disp('Script continued.');

    %% Copy folder
    disp(' ');
    notCopiedFileList = cell(length(srcFolders));
    for folderIdx = 1:length(srcFolders)
        % Clear destination folder
        cleanDestinationFolder(dstFolders{folderIdx}, excludeFiles{folderIdx}, excludeFolders{folderIdx}, excludePatterns{folderIdx});

        % Copy source folder to destination folder
        copyWithExclusion(srcFolders{folderIdx}, dstFolders{folderIdx}, excludeFiles{folderIdx}, excludeFolders{folderIdx}, excludePatterns{folderIdx});

        % Display not overwritten files
        dstFileList = listAllFiles(dstFolders{folderIdx});
        copiedFileList = simulateCopiedFiles(srcFolders{folderIdx}, dstFolders{folderIdx}, excludeFiles{folderIdx}, excludeFolders{folderIdx}, excludePatterns{folderIdx});
        notCopiedFileList{folderIdx} = setdiff(dstFileList, copiedFileList);
    end

    if isempty(notCopiedFileList)
        disp('All files overwritten.');
    else
        disp('Files NOT overwritten:');
        for folderIdx = 1:length(notCopiedFileList)
            disp(['"' strrep(strrep(dstFolders{folderIdx}, '\common\Scripts\..\..', ''), '\app\..', '') '"'])
            for fileIdx = 1:length(notCopiedFileList{folderIdx})
                disp(notCopiedFileList{folderIdx}{fileIdx});
            end
        end
    end

end


function cleanDestinationFolder(dst, excludeFiles, excludeFolders, excludePatterns)
    files = dir(dst);
    files = files(~ismember({files.name}, {'.', '..'}));

    for i = 1:length(files)
        fileName = files(i).name;
        fullPath = fullfile(dst, fileName);

        if files(i).isdir
            if ismember(fileName, excludeFolders)
                continue;
            end
            cleanDestinationFolder(fullPath, excludeFiles, excludeFolders, excludePatterns)
        else
            isExactExcluded = ismember(fileName, excludeFiles);
            matchesPattern = any(cellfun(@(p) ~isempty(regexp(fileName, p, 'once')), excludePatterns));
            if ~(isExactExcluded || matchesPattern)
                delete(fullPath);
            end
        end
    end
end


function copyWithExclusion(src, dst, excludeFiles, excludeFolders, excludePatterns)
    files = dir(src);
    files = files(~ismember({files.name}, {'.', '..'}));

    for i = 1:length(files)
        fileName = files(i).name;
        srcPath = fullfile(src, fileName);
        dstPath = fullfile(dst, fileName);

        if files(i).isdir
            if ismember(fileName, excludeFolders)
                continue;
            end
            if ~exist(dstPath, 'dir')
                mkdir(dstPath);
            end
            copyWithExclusion(srcPath, dstPath, excludeFiles, excludeFolders, excludePatterns);
        else
            isExactExcluded = ismember(fileName, excludeFiles);
            matchesPattern = any(cellfun(@(p) ~isempty(regexp(fileName, p, 'once')), excludePatterns));
            if ~(isExactExcluded || matchesPattern)
                copyfile(srcPath, dstPath);
            end
        end
    end
end


function fileList = listAllFiles(folderPath)
    files = dir(fullfile(folderPath, '**', '*'));
    files = files(~[files.isdir]);
    fileList = {files.name};
end

function copiedFiles = simulateCopiedFiles(src, ~, excludeFiles, excludeFolders, excludePatterns)
    copiedFiles = {};
    files = dir(src);
    files = files(~ismember({files.name}, {'.', '..'}));

    for i = 1:length(files)
        fileName = files(i).name;
        srcPath = fullfile(src, fileName);

        if files(i).isdir
            if ismember(fileName, excludeFolders)
                continue;
            end
            copiedFiles = [copiedFiles, simulateCopiedFiles(srcPath, '', excludeFiles, excludeFolders, excludePatterns)];
        else
            isExactExcluded = ismember(fileName, excludeFiles);
            matchesPattern = any(cellfun(@(p) ~isempty(regexp(fileName, p, 'once')), excludePatterns));
            if ~(isExactExcluded || matchesPattern)
                copiedFiles{end+1} = fileName;
            end
        end
    end
end
