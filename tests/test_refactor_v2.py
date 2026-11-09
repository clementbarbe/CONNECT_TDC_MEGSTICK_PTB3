"""Regression checks for the requested no-EyeLink / always-save / no-width release.
Static checks only; MATLAB and hardware execution still required.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
# Check application code; the unmodified upstream dependency still ships
# its own optional EyeLink and echo utilities.
code={f.relative_to(root).as_posix():f.read_text(encoding='latin1')
      for f in root.rglob('*.m') if 'vendor' not in f.relative_to(root).parts}
main=code['AMEDYST_main.m']
menu=code['AMEDYST_GUI.m']
geometry=code['+MEG/ApplyDisplayGeometry.m']
# 1. No Save/NoSave GUI state or conditional saving remains.
for name,text in code.items():
    for word in ['SaveMode','NoSave','radiobutton_SaveData','radiobutton_NoSave',
                 'EyelinkMode','StartRecordingEyelink.m','Eyelink.',
                 'EchoStart(', 'EchoStop(', 'edit_DisplayWidthMm','DisplayWidthMm']:
        assert word not in text, (name,word)
assert not (root/'+Common/StartRecordingEyelink.m').exists()
assert main.count("save(DataFile, 'S'") >= 1
assert "save([S.DataFile '_SR.mat'],'srD')" in main
assert "save([S.DataFile '_OUT.mat'],'outD')" in main
assert "save([DataFile '_SPM']" in main
assert "save(fullfile(S.DataPath,'LastS.mat'),'S')" in main
assert 'if strcmp(S.OperationMode,\'Acquisition\') && isfield(S,\'MEG\')' in main  # only baseline completed marker
# 2. Menu is independent of the missing GUI package.
assert 'GUI.Pushbutton_Check_SubjectID_data_Callback(' not in menu
assert '@GUI.Listbox_Screens_CreateFcn' not in menu
for token in ('function populateScreens(', 'function checkSubjectData(',
              'checkbox_ParPort','pushbutton_MEG_Task1','pushbutton_MEG_Task2'):
    assert token in menu, token
assert 'uipanel_EyelinkMode' not in menu
assert 'uipanel_SaveMode' not in menu
assert 'edit_DisplayWidthMm' not in menu
# 3. No physical screen width conversion; original relative sizing retained.
assert 'PixelsPerMm' not in geometry
assert 'DimensionRatio = 0.80' in code['GetParameters.m']
assert 'S.MEG.RequestedSamplingHz = 140' in geometry
assert 'outerRatio * 20/320' in geometry
assert 'outerRatio * 16/320' in geometry
# 4. Dependency guard gives an informative message before screen opening.
assert 'MEG:MissingStimTemplate' in main
assert main.index('MEG:MissingStimTemplate') < main.index('S.PTB = StartPTB;')
print('PASS: GUI simplification, always-on save, EyeLink/echo removal, relative display, dependency preflight.')
