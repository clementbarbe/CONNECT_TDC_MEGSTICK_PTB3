function test_project_paths()
%TEST_PROJECT_PATHS Resolve application code and assets from another folder.
root = setup_AMEDYST();
previousFolder = pwd;
temporaryFolder = tempname;
mkdir(temporaryFolder);
cleanup = onCleanup(@() restoreFolder(previousFolder,temporaryFolder));
cd(temporaryFolder);
assert(strcmp(setup_AMEDYST(),root));
names = {'AMEDYST_main','AMEDYST_GUI','GetParameters','StartPTB','WaitForTTL', ...
    'ADAPT.Planning','MEG.BuildParadigm','Circle','joystick_calibration', ...
    'SPMnod','trajectory_to_CSV','printResults'};
files = {'AMEDYST_main.m','src/AMEDYST_GUI.m','src/GetParameters.m', ...
    'src/StartPTB.m','src/WaitForTTL.m','src/+ADAPT/Planning.m', ...
    'src/+MEG/BuildParadigm.m','src/@Circle/Circle.m', ...
    'tools/joystick_calibration.m','analysis/SPMnod.m', ...
    'analysis/trajectory_to_CSV.m','analysis/printResults.m'};
for index = 1:numel(names)
    expected = fullfile(root,strrep(files{index},'/',filesep));
    assert(strcmp(which(names{index}),expected),'Incorrect path for %s',names{index});
end
assert(exist(fullfile(root,'assets','images','50centsEURO.png'),'file')==2);
binary = fullfile(root,'vendor','joymex2',['joymex2.' mexext]);
if exist(binary,'file')~=0, assert(strcmp(which('joymex2'),binary)); end
assert(isempty(strfind(path,fullfile(root,'analysis','legacy'))));
disp('All project path assertions passed.');
end

function restoreFolder(previousFolder,temporaryFolder)
cd(previousFolder);
rmdir(temporaryFolder);
end
