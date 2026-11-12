# AMEDYST — Tâche joystick MEG

Application MATLAB/Psychtoolbox pour une tâche de pointage au joystick : baseline, adaptation avec rotation du curseur et comparaison des courbes de réponse.

## Prérequis

- MATLAB et Psychtoolbox.
- StimTemplate pour le planning et l'enregistrement des événements.
- Un joystick USB HID compatible avec `joymex2` sous Windows ou Linux, ou un Current Designs en série PJS/651 avec `serialport` (MATLAB R2019b ou plus récent). Une souris permet le débogage.
- Python 3 pour les vérifications statiques, facultatif.

## Installation

Dans MATLAB, se placer dans le dossier du projet, puis exécuter :

```matlab
setup_AMEDYST
setup_StimTemplate
```

`setup_AMEDYST` charge les chemins de la session. `setup_StimTemplate` utilise la copie locale lorsqu'elle existe et la télécharge sinon. Les instructions hors ligne sont dans le [guide d'installation](docs/installation.md).

## Utilisation

```matlab
AMEDYST_main
```

1. Renseigner l'identifiant du participant, l'écran et le mode d'exécution.
2. Choisir **Joystick**, puis **USB HID JOY** ou **Série PJS / 651**. En série, sélectionner le port déjà connecté, conserver 57600 bauds et cliquer sur **Tester**. Dans **Calibration**, mesurer d'abord le centre avec la manette au repos (**Espace**), parcourir ensuite toute la course et valider avec **Échap**. Sélectionner le profil de réponse ; **Comparer les courbes du joystick** permet de visualiser et d'appliquer un profil linéaire ou exponentiel.
3. Sélectionner le contrebalancement et la règle de score.
4. Lancer **Tâche 1 : Baseline**, puis **Tâche 2 : Adaptation**, avec les mêmes réglages de joystick.

Les chemins sont chargés automatiquement au lancement. Les données sont sauvegardées dans `data/<SubjectID>/`, en Acquisition comme en Debug. La touche **Échap** permet d'interrompre la tâche.

## Organisation

```text
AMEDYST_main.m          Point d'entrée
setup_AMEDYST.m         Configuration des chemins MATLAB
setup_StimTemplate.m    Installation de StimTemplate
src/                   Interface, paramètres, tâches et classes graphiques
analysis/              Exports, résultats et préparation des données SPM
tools/                 Calibration du joystick
assets/images/         Images de l'expérience
docs/                  Documentation détaillée
tests/                 Tests MATLAB et vérifications Python
vendor/                Dépendances externes et binaires joymex2
data/                  Données locales des participants
```

## Tests

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

Les tests de fenêtres nécessitent un affichage MATLAB. Les tests de ports virtuels et les vérifications Python sont décrits dans [tests/README.md](tests/README.md).

## Documentation

- [Installation et dépannage](docs/installation.md)
- [Déroulement de l'expérience](docs/protocole.md)
- [Calibration, recentrage et courbes du joystick](docs/joystick.md)
- [Branchement et configuration du joystick série PJS](docs/serial_pjs.md)

La fréquence de 140 Hz et les dimensions physiques des stimuli doivent être vérifiées sur le poste expérimental ; le code utilise les rafraîchissements de l'écran et des tailles relatives à la fenêtre.

## Licence

Le projet est distribué sous licence [Apache-2.0](LICENSE.md). Les dépendances externes conservent leurs licences respectives.
