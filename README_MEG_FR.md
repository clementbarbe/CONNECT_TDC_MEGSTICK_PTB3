# Tâche joystick MEG — version mutualisée

## But et démarrage

Le programme regroupe les archives initiales `baseline` et `feedback` dans **un seul arbre MATLAB**. **Les deux boutons d'un seul menu** ouvrent respectivement :

- **Tâche 1 — baseline** : 4 essais de familiarisation (bloc 0, une cible par direction), suivis des blocs 1 et 2 de 48 essais (0° avec curseur, puis 0° sans curseur pendant le mouvement).
- **Tâche 2 — adaptation** : blocs 3 à 8 de 48 essais (déviation et visibilité selon l'ordre A–D; 5 et 8 = 0° avec curseur). Attente avant bloc 3 et entre blocs 5 et 6 pour respecter les pauses de 5 minutes.

**Démarrage dans MATLAB** (répertoire de travail = dossier racine fourni, ajouté au path) :

```matlab
cd('CHEMIN/VERS/JOYSTICK_MEG_UNIFIE')
addpath(pwd)
AMEDYST_main
```

Renseigner `Subject ID`, le mode `Acquisition`, l'option `Save data`, le dispositif (joystick calibré, souris pour le débogage), l'écran, la **largeur physique de l'écran en mm** (mesurer la surface d'affichage), et l'**ordre inter-participants A–D**. Les anciens réglages de score *Reward/Punishment* sont proposés séparément ; ils ne pilotent **pas** la visibilité du curseur.

## Contrebalancement

| Ordre | Blocs 3–4 | Blocs 6–7 |
|---|---|---|
| A | +30° (sens horaire), avec curseur | −30° (antihoraire), sans curseur |
| B | −30° (antihoraire), avec curseur | +30° (horaire), sans curseur |
| C | −30° (antihoraire), sans curseur | +30° (horaire), avec curseur |
| D | +30° (horaire), sans curseur | −30° (antihoraire), avec curseur |

Le moteur effectue la rotation des **incréments** du joystick. Dans ce nouveau protocole, le signe des degrés suit le sens physique du document : **+ = horaire** sur l'écran. Les enregistrements conservent les numéros absolus des blocs (0–8) et le type d'essai. La liste pseudo-aléatoire de 4 cibles est renouvelée après chaque cycle complet.

## Chronométrie et afficheur

- Cibles : 20°, 60°, 120°, 160° ; fixation et cible 20 mm, curseur et marqueur 16 mm, cercle externe 320 mm ; distance du participant à l'écran **800 mm** à régler physiquement.
- Passage au centre et maintien de **200 ms** pour valider le départ suivant.
- Mouvements **<100 ms** : « Too fast » ; mouvements **>600 ms** : « Too slow ».
- Intervalle cible entre fin d'un mouvement et début de l'essai suivant : **3,5 à 4,5 s**. Le temps de retour au centre peut prolonger cet intervalle.
- Pauses **300 s** entre blocs 2→3 et 5→6. La tâche 1 enregistre sa date de fin ; la tâche 2 attend uniquement le reliquat des cinq minutes. Sans trace récente de tâche 1, elle attend 300 s.
- En `FastDebug` : 4 essais par bloc et pauses longues désactivées ; en `Acquisition`, 48 essais par bloc.
- La largeur physique est **obligatoire** et n'est volontairement pas préremplie : une mauvaise valeur fausserait les dimensions en mm.

## Architecture et sorties

- `AMEDYST_GUI.m` : menu unique, calibration et paramètres matériels.
- `AMEDYST_main.m` : configuration, ouverture de Psychtoolbox, lancement, sauvegarde, statistiques.
- `+MEG/BuildParadigm.m` : table canonique des blocs ; `+ADAPT/Planning.m` : tirage et planification des essais.
- `+ADAPT/Task.m` : une seule boucle d'essai pour les deux tâches ; `+ADAPT/ApplyDeviation.m` et `UpdateCursor.m` : moteur commun.
- `+MEG/ApplyDisplayGeometry.m` : conversion millimètres → pixels, vérification de place à l'écran ; `+MEG/RemainingFirstBreak.m` : transition inter-tâches.
- `data/<SubjectID>/` : un fichier principal `.mat` avec `S`, son fichier `_SPM.mat`, des fichiers `_SR.mat` et `_OUT.mat`, un CSV, et éventuellement `last_baseline_end.mat`. Les noms incluent la phase et l'ordre de contrebalancement. Aucune écriture automatique dans les anciens `DataSR.mat`/`DataOUT.mat` de la racine.

## Dépendances et validations nécessaires avant expérimentation

MATLAB avec **Psychtoolbox**, classes **StimTemplate** (notamment `EventPlanning`, `SampleRecorder`, `EventRecorder`, `KbLogger`, `EchoStart/EchoStop`), `joymex2` compatible avec le système, matériel réel, et éventuellement modules d'interface MEG/Arduino. L'archive d'origine référence StimTemplate sans l'inclure.

**Important :** l'ancien moteur enregistre un échantillon à chaque `Screen('Flip')`. La spécification « trajectoires échantillonnées à **140 Hz** » est **non garantie** si l'écran tourne à 60/120 Hz. Un avertissement indique la fréquence de l'écran et la fréquence médiane mesurée. Une acquisition indépendante de l'affichage et une validation sur joystick MEG doivent être réalisées avant une étude réelle.

**Non vérifié ici :** l'exécution sur MATLAB/Psychtoolbox/joystick MEG (absents de l'environnement), la latence, le TTL, les couleurs/géométries finales sur le moniteur, les marqueurs/trigger hardware. Effectuer les assertions (`tests/test_protocol.m`) dans MATLAB et une session `FastDebug` sur le matériel avant toute acquisition.

### Test de la planification dans MATLAB

```matlab
addpath(pwd)
addpath(fullfile(pwd,'tests'))
test_protocol
```

La définition source du protocole est le document joint « MEG Experimental paradigm » (brouillon). Il n'indique ni un modèle de joystick MEG précis ni la règle de score à conserver ; les réglages existants restent sélectionnables.
