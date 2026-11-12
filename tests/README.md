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
test_pjs_decoder
test_joystick_serial_gui
```

Les tests vérifient la résolution des chemins, le planning, la conversion des positions, le retour et le maintien simulés, ainsi que la cohérence des courbes. `test_joystick_curve_tool` utilise une fenêtre MATLAB ; il ne nécessite ni joystick ni Psychtoolbox. Les tests de recalage remplacent temporairement les entrées matérielles par des simulations.

`test_pjs_decoder` vérifie les axes signés, les boutons et le trigger, les paquets fragmentés, la connexion au milieu d'un flux, la resynchronisation et les 2048 valeurs possibles de chaque axe. `test_joystick_serial_gui` utilise une liste simulée de ports déjà présents ; il vérifie le menu, la séparation des calibrations et l'orientation sans ouvrir de port. Ce dernier test nécessite un affichage MATLAB.

## Série native avec port virtuel (Linux/macOS)

Dans un terminal, démarrer l'émulateur avant MATLAB :

```bash
python tests/pjs_serial_emulator.py /tmp/amedyst_pjs
```

Dans MATLAB, depuis la racine du projet :

```matlab
setup_AMEDYST
addpath('tests')
emulator = jsondecode(fileread('/tmp/amedyst_pjs_port.json'));
test_joystick_serial_transport(emulator.port, emulator.control)
test_joystick_serial_workflow(emulator.port, emulator.control)
```

Ces tests doivent recevoir uniquement le port et le fichier de contrôle de cet émulateur. Ils n'utilisent aucun port matériel. Ils nécessitent `serialport` et les fonctions de temps de Psychtoolbox. Le test de workflow nécessite aussi un affichage MATLAB : il exerce **Tester**, la mesure du repos, la calibration et son annulation, puis le démarrage par trigger série avec un clavier simulé. Il reproduit également une course brute entièrement négative avec les deux axes inversés : le repos doit devenir zéro dans le lecteur de la tâche et les quatre coins normalisés doivent être accessibles.

Le test du transport vérifie un flux actif avant la connexion, des lectures partielles, l'immobilité, les fronts trigger, la consommation des données en attente, l'expiration d'un flux arrêté, le rejet d'un protocole incorrect et la réouverture après erreur. Arrêter l'émulateur avec **Ctrl+C** dans son terminal après les tests.

## Python

```bash
python tests/static_check.py
python tests/test_refactor_v2.py
python tests/test_dependency_installer.py
```

Ces contrôles portent sur l'organisation du code, les paramètres du protocole, les dépendances et la sauvegarde. Ils ne remplacent pas la validation sur le poste MEG de l'affichage, des timings, de la calibration et des marqueurs.
