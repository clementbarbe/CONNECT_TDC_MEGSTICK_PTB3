function rootDir = setup_AMEDYST()
%SETUP_AMEDYST Load the project's paths without changing MATLAB's folder.
% AMEDYST_main calls this automatically. Use it before running tools/tests.
rootDir = fileparts(mfilename('fullpath'));
folders = {rootDir, fullfile(rootDir,'src'), fullfile(rootDir,'analysis'), ...
    fullfile(rootDir,'tools'), fullfile(rootDir,'vendor','joymex2')};
for index = 1:numel(folders)
    addpath(folders{index});
end
stimTemplate = fullfile(rootDir,'vendor','StimTemplate-master');
if exist(stimTemplate,'dir') == 7
    addpath(stimTemplate);
end
end
