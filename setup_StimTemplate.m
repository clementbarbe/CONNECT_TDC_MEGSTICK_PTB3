function installedPath = setup_StimTemplate()
%SETUP_STIMTEMPLATE Install the original open-source MATLAB dependency.
% Run ONCE from the project folder while connected to the internet:
%   setup_StimTemplate
%
% Subsequent launches of AMEDYST_main load the local copy automatically.
% Source: https://github.com/benoitberanger/StimTemplate (Apache-2.0)
% The original library is NOT modified by this installer.

rootDir = fileparts(mfilename('fullpath'));
vendorDir = fullfile(rootDir, 'vendor');
installedPath = fullfile(vendorDir, 'StimTemplate-master');
classes = {'EventPlanning','EventRecorder','SampleRecorder','KbLogger'};

if localHasClasses(installedPath, classes)
    addpath(installedPath);
    fprintf('StimTemplate deja installe : %s\n', installedPath);
    return
end

if ~exist(vendorDir, 'dir')
    [ok, msg] = mkdir(vendorDir);
    if ~ok
        error('MEG:InstallDirectory','Impossible de creer %s : %s',vendorDir,msg);
    end
end

repoURL = 'https://github.com/benoitberanger/StimTemplate/archive/refs/heads/master.zip';
zipFile = fullfile(vendorDir, 'StimTemplate_download.zip');
fprintf('Telechargement de StimTemplate (depot officiel) ...\n');
try
    websave(zipFile,repoURL);
    unzip(zipFile,vendorDir);
catch err
    if exist(zipFile, 'file'), delete(zipFile); end
    error('MEG:StimTemplateDownload', [ ...
        'Telechargement impossible : %s\n' ...
        'Installation manuelle : https://github.com/benoitberanger/StimTemplate\n' ...
        'Extraire StimTemplate-master dans : %s\n' ...
        'Puis relancer MATLAB dans le dossier du projet.'], err.message, vendorDir);
end
if exist(zipFile, 'file'), delete(zipFile); end

if ~localHasClasses(installedPath,classes)
    error('MEG:StimTemplateIncomplete', [ ...
        'Le dossier StimTemplate a ete telecharge, mais les quatre classes requises ' ...
        'sont manquantes dans : %s'],installedPath);
end
addpath(installedPath);
rehash;
fprintf('StimTemplate installe : %s\n',installedPath);
fprintf('Il est pret pour AMEDYST_main. Aucune modification du path permanent n''est necessaire.\n');
end

function tf = localHasClasses(folder, classes)
tf = exist(folder,'dir') == 7;
for k = 1:numel(classes)
    tf = tf && exist(fullfile(folder, ['@' classes{k}], ...
        [classes{k} '.m']), 'file') == 2;
end
end
