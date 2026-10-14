from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
main = (root / 'AMEDYST_main.m').read_text()
install = (root / 'setup_StimTemplate.m').read_text()
gui = (root / 'AMEDYST_GUI.m').read_text()
readme = (root / 'README_MEG_FR.md').read_text()
for symbol in ['EventPlanning','EventRecorder','SampleRecorder','KbLogger']:
    assert symbol in main and symbol in install
assert 'https://github.com/benoitberanger/StimTemplate/' in install
assert 'websave(zipFile,repoURL)' in install
assert 'addpath(installedPath)' in install
assert 'setup_StimTemplate' in main
assert 'addpath(localStimTemplate)' in main
assert main.index('MEG:MissingStimTemplate') < main.index('S.PTB = StartPTB;')
assert 'C:\\Users\\karim.ndiaye\\' not in gui
assert 'Apache-2.0' in readme
assert (root/'vendor'/'INSTALLATION.txt').exists()
print('PASS: setup, load path, preflight and offline instructions')
