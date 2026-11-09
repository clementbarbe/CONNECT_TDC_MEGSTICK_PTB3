# Installation et dépannage

## Configuration MATLAB

Se placer à la racine du projet et lancer `AMEDYST_main`. Le programme appelle automatiquement `setup_AMEDYST`, qui ajoute `src/`, `analysis/`, `tools/`, `vendor/joymex2/` et la copie locale de StimTemplate au chemin MATLAB. Pour utiliser les fonctions séparément ou lancer les tests, appeler d'abord `setup_AMEDYST`.

Ne pas utiliser `addpath(genpath(...))` sur tout le projet : les dépendances, les classes MATLAB et les analyses historiques disposent de leurs propres dossiers. Les chemins ne sont pas enregistrés dans la configuration permanente de MATLAB.

## Psychtoolbox

Psychtoolbox doit être installé et accessible dans MATLAB. Vérifier son fonctionnement sur le poste expérimental, notamment la synchronisation de l'écran et la fréquence effective des rafraîchissements.

## StimTemplate

```matlab
setup_StimTemplate
```

L'installateur utilise la version locale si elle est complète ; sinon il télécharge la bibliothèque originale depuis [benoitberanger/StimTemplate](https://github.com/benoitberanger/StimTemplate). Les classes nécessaires sont `EventPlanning`, `EventRecorder`, `SampleRecorder` et `KbLogger`.

Sur un poste hors ligne, récupérer la bibliothèque sur un autre ordinateur et placer le dossier extrait dans `vendor/StimTemplate-master/`. Le contrôle des dépendances est effectué avant l'ouverture de la fenêtre de stimulation. Une installation incomplète provoque le message `MEG:MissingStimTemplate`.

## Joystick

Les binaires `joymex2.mexa64` et `joymex2.mexw64`, ainsi que `SDL.dll`, sont regroupés dans `vendor/joymex2/`. Leur compatibilité doit être vérifiée sur le poste. La calibration se lance depuis le bouton **JCalibration** ; Échap termine sa mesure. La souris permet de déboguer l'expérience et l'outil de comparaison des courbes fonctionne sans joystick.

## Déclenchement et marqueurs

En mode Acquisition, le programme attend le déclenchement clavier : **t** sous Linux, **5** sous Windows et macOS. Les modes Debug démarrent sans ce déclenchement.

L'option **Marqueurs COM/Arduino** est désactivée par défaut. L'activer uniquement lorsqu'un Arduino est connecté et configuré. Le message `No trigger will be sent.` signifie que l'envoi des marqueurs est désactivé.

## Données

Les données sont enregistrées dans `data/<SubjectID>/`. Le programme incrémente le numéro de run et refuse d'écraser un run existant. Les fichiers `LastS.mat` et `last_baseline_end.mat` sont des fichiers de suivi mis à jour au cours des sessions.

Le dossier `data/` est exclu des nouveaux ajouts Git. Les fichiers qui étaient déjà suivis par Git ne sont pas automatiquement retirés de son historique.
