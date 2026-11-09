# Tests

## MATLAB

Depuis la racine du projet :

```matlab
setup_AMEDYST
addpath('tests')
test_project_paths
test_protocol
test_joystick
test_joystick_recenter
test_joystick_curves
test_joystick_curve_tool
```

Les tests vérifient la résolution des chemins, le planning, la conversion des positions, le retour et le maintien simulés, ainsi que la cohérence des courbes. `test_joystick_curve_tool` utilise une fenêtre MATLAB ; il ne nécessite ni joystick ni Psychtoolbox. Les tests de recalage remplacent temporairement les entrées matérielles par des simulations.

## Python

```bash
python tests/static_check.py
python tests/test_refactor_v2.py
python tests/test_dependency_installer.py
```

Ces contrôles portent sur l'organisation du code, les paramètres du protocole, les dépendances et la sauvegarde. Ils ne remplacent pas la validation sur le poste MEG de l'affichage, des timings, de la calibration et des marqueurs.
