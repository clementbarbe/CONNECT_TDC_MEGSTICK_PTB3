# Tâche joystick MEG — menu unique, version 2

## Démarrage

Dans MATLAB, se placer dans le dossier racine de cette archive et exécuter :

```matlab
cd('CHEMIN/VERS/JOYSTICK_MEG_UNIFIE')
addpath(pwd)
AMEDYST_main
```

Le menu propose **Tâche 1 : Baseline** et **Tâche 2 : Adaptation**. Elles partagent un moteur expérimental unique (`+ADAPT/Task.m`, `+ADAPT/Planning.m`). Renseigner le sujet (identifiant à 2 caractères), le mode Acquisition ou Debug, le joystick calibré ou la souris, l'écran, le contrebalancement A–D et la règle de score. L'option de marqueurs COM/Arduino est **désactivée par défaut** et ne doit être cochée que si un Arduino est effectivement connecté.

**L'enregistrement est systématique**, en Acquisition comme en Debug. Il n'existe plus de bouton Save/No save. Les fichiers sont placés dans `data/<SubjectID>/` : fichier de session `.mat`, `_SPM.mat`, `_SR.mat`, `_OUT.mat`, `.csv` et `LastS.mat`. Le programme calcule un nouveau numéro de run et refuse d'écraser un fichier de run existant. Le fichier `LastS.mat` est intentionnellement mis à jour à chaque session. Après la fin de la tâche, une première sauvegarde du fichier de session est effectuée **avant les analyses et graphiques**. Ce mécanisme ne garantit pas de récupérer un essai interrompu avant la fin de l'exécution de la tâche.

**EyeLink a été supprimé** : ni mode, ni calibration, ni bibliothèque EyeLink ne sont nécessaires. Les marqueurs optionnels COM/Arduino restent disponibles. Les appels `EchoStart`/`EchoStop` et les deux anciens callbacks manquants `GUI.*` ont également été remplacés ou supprimés.

**La largeur physique de l'écran n'est plus demandée.** Les stimuli utilisent les tailles relatives issues du code original (grand cercle = 80 % de la hauteur de la fenêtre ; diamètre cible/croix = 20/320 de celui du grand cercle ; diamètre du curseur = 16/320), avec cercle et croix blancs. Les dimensions physiques exactes « 320 mm / 20 mm / 16 mm » du document MEG ne peuvent donc plus être garanties. Cela ne change pas les positions angulaires des cibles ni la logique des essais.

## Protocole conservé

**Tâche 1** : 4 essais de familiarisation (bloc 0), puis blocs 1 et 2 de 48 essais (0° visible, puis 0° sans curseur pendant le mouvement).

**Tâche 2** : blocs 3 à 8, de 48 essais. Blocs 3–4 et 6–7 avec rotation et visibilité selon le contrebalancement, blocs 5 et 8 à 0° avec curseur. Deux pauses de 5 minutes entre les blocs 2→3 et 5→6, en Acquisition. En `FastDebug`, 4 essais par bloc, sans les pauses longues.

| Ordre | Blocs 3–4 | Blocs 6–7 |
|---|---|---|
| A | +30° horaire, avec curseur | −30° antihoraire, sans curseur |
| B | −30° antihoraire, avec curseur | +30° horaire, sans curseur |
| C | −30° antihoraire, sans curseur | +30° horaire, avec curseur |
| D | +30° horaire, sans curseur | −30° antihoraire, avec curseur |

Quatre cibles : 20°, 60°, 120°, 160° ; permutation aléatoire par cycle de 4 essais. Mouvement trop rapide en dessous de 100 ms, trop lent au-delà de 600 ms ; maintien au centre de 200 ms ; intervalle inter-essais demandé entre 3,5 et 4,5 s. La rotation est appliquée aux incréments du joystick, comme dans l'archive source.

## Dépendances et messages d'erreur

Il faut MATLAB, Psychtoolbox et la bibliotheque libre **StimTemplate** (`EventPlanning`, `EventRecorder`, `SampleRecorder`, `KbLogger`). Pour installer la version officielle dans le projet, executer **une fois** `setup_StimTemplate` dans MATLAB avec une connexion Internet. `AMEDYST_main` ajoutera ensuite automatiquement la copie locale au `path` MATLAB. Si le poste experimental est hors ligne, telecharger StimTemplate sur un autre poste depuis https://github.com/benoitberanger/StimTemplate et copier le dossier decompresse `StimTemplate-master` dans `vendor/`. La bibliotheque officielle est sous licence Apache-2.0 ; son code n'est pas modifie. Si elle n'est pas accessible, un message `MEG:MissingStimTemplate` donne les instructions. Le joystick réel utilise `joymex2` (fichiers binaires inclus pour Windows/Linux, compatibilité à vérifier selon le poste) ; la souris permet des essais de débogage.

La fréquence de **140 Hz n'est pas garantie** : le moteur original enregistre les positions lors des rafraîchissements de l'écran. La fréquence réelle de la chaîne joystick-écran-acquisition doit être mesurée sur le matériel.

## Vérification

Dans MATLAB, après avoir ajouté le dossier racine au `path` :

```matlab
addpath(fullfile(pwd,'tests'))
test_protocol
```

Les vérifications statiques Python se lancent depuis le dossier racine : `python tests/static_check.py` puis `python tests/test_refactor_v2.py`. **MATLAB, Psychtoolbox et le joystick MEG n'ont pas pu être exécutés ici.** Vérifier sur poste expérimental l'affichage, le timing, la calibration, les éventuels marqueurs Arduino et la sauvegarde avant toute acquisition réelle.


## Installation de StimTemplate — correction de l'erreur V2

La version V2 contenait un controle bloquant mais **pas** la bibliotheque.
La version V3 contient `setup_StimTemplate.m`, l'installateur de la bibliotheque publique originale.

```matlab
cd('CHEMIN/VERS/JOYSTICK_MEG_UNIFIE')
setup_StimTemplate  % Une seule fois, connexion Internet requise
AMEDYST_main
```

Les sources de StimTemplate sont telechargees depuis :
https://github.com/benoitberanger/StimTemplate
Licence originale : Apache License 2.0, fichier `vendor/StimTemplate-master/LICENSE.md`.
Ce projet ne copie ni ne modifie son code lors de la distribution de l'archive.

En l'absence de reseau sur le poste experimental : recuperer le ZIP de StimTemplate sur un
autre ordinateur, decompresser son contenu et placer le dossier `StimTemplate-master`
dans `JOYSTICK_MEG_UNIFIE/vendor/`. La commande `AMEDYST_main` le detectera.

Le message `No trigger will be sent.` n'est pas une erreur : il indique simplement que
l'envoi des marqueurs Arduino/COM est desactive dans le menu.

**Rappel :** validation de l'execution, du joystick MEG et des timings necessaire sur
le poste experimental. La frequence de 140 Hz n'est pas garantie par le code original.
