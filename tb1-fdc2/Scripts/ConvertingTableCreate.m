function ConvertingTableCreate()
%% path settings
project_path = pwd;
addpath(project_path);
addpath([project_path '/Scripts']);
addpath([project_path '/documents/Templates']);
addpath([project_path '/documents/MessageLink']);

%% Read Converting table
cd([project_path '/documents/MessageMap']);
[ConvertingTableName, path] = uigetfile({'*.xlsx;'}, 'Select Converting table');
passwordFile = 'password.txt';
if isfile(passwordFile)
    password = strtrim(fileread(passwordFile));
else
    filenames = dir;
    filenames = string({filenames.name});
    password = filenames(contains(filenames,'to@'));
    password = extractBefore(password,'.txt');
end

xlsAPP = actxserver('excel.application');
xlsAPP.Visible = 1;
xlsWB = xlsAPP.Workbooks;
xlsFile = xlsWB.Open([path ConvertingTableName],[],false,[],password);
exlSheet1 = xlsFile.Sheets.Item('RoutingTable');
dat_range = exlSheet1.UsedRange;
ConvertingTable = dat_range.value;

% ConvertingTable = readcell(ConvertingTableName,'Sheet','ConvertingTable');
ConvertingTable(cellfun(@(x) all(ismissing(x)), ConvertingTable)) = {'Invalid'};
ConvertingTable(end+1,:) = {'Invalid'};

end