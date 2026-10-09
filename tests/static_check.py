"""Static release checks; executable without MATLAB or hardware.
These checks do NOT replace MATLAB/Psychtoolbox integration testing.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
files = list(ROOT.rglob('*.m'))
assert len(files) > 60
assert len(list(ROOT.glob('+ADAPT/Planning.m'))) == 1
assert len(list(ROOT.rglob('Task.m'))) == 2  # shared ADAPT + unrelated SEQ
assert not list(ROOT.glob('AMEDYST_stim-master_*'))
assert (ROOT/'AMEDYST_GUI.m').exists()
assert (ROOT/'+MEG/BuildParadigm.m').exists()
assert (ROOT/'+ADAPT/Task.m').exists()

menu=(ROOT/'AMEDYST_GUI.m').read_text(encoding='latin1')
main=(ROOT/'AMEDYST_main.m').read_text(encoding='latin1')
planner=(ROOT/'+ADAPT/Planning.m').read_text()
runner=(ROOT/'+ADAPT/Task.m').read_text(encoding='latin1')
proto=(ROOT/'+MEG/BuildParadigm.m').read_text()
rotation=(ROOT/'+ADAPT/ApplyDeviation.m').read_text(encoding='latin1')
geo=(ROOT/'+MEG/ApplyDisplayGeometry.m').read_text()

for tag in ['pushbutton_MEG_Task1','pushbutton_MEG_Task2']:
    assert tag in main and tag in menu
assert "@AMEDYST_main" in menu
assert 'MEG.BuildParadigm(' in planner
assert "case {'Direct_Pre', 'Deviation', 'No_vision'}" in runner
assert 'EP.Data{evt,11}' in runner
assert 'Parameters.TravelMinDuration = 0.100' in planner
assert 'Parameters.TravelMaxDuration = 0.600' in planner
assert 'Parameters.TimeSpentOnTargetToValidate = 0.200' in planner
assert 'Parameters.MinPauseBetweenTrials = 3.5' in planner
assert 'Parameters.MaxPauseBetweenTrials = 4.5' in planner
assert 'previousMovementEnd + EP.Data{evt,8}' in runner
assert 'S.MEG.FirstBreakSeconds' in planner and '300' in proto
assert re.search(r'rotationFirst\s*=\s*\[30\s+-30\s+-30\s+30\]',proto)
assert re.search(r'visibilityFirst\s*=\s*\[1\s+1\s+0\s+0\]',proto)
assert 'familiarisationTrials = 4' in proto
assert "trials = 48" in proto
assert 'Parameters.TargetAngles = [20 60 120 160]' in planner
assert "dTheta - deviation*pi/180" in rotation
assert 'S.MEG.RequestedSamplingHz = 140' in geo
assert 'S.MEG.MedianLoggedHz' in main
assert "DataOUT.mat','outD" not in main
assert "'_SR.mat'" in main and "'_OUT.mat'" in main
assert len(files) == len(set(x.relative_to(ROOT) for x in files))
for f in files:
    b=f.read_bytes()
    assert b'\0' not in b, f
print(f'PASS: {len(files)} shared MATLAB files, one planning engine, two phases, four orders, and required timing/visibility options.  Hardware execution not tested.')
