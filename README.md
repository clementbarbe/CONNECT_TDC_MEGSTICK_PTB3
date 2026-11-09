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

**La largeur physique de l'écran n'est plus demandée.** Les stimuli utilisent des tailles relatives (grand cercle = 80 % de la hauteur de la fenêtre ; diamètre cible et cercle central = 1,5 × 20/320 de celui du grand cercle ; croix = 20/320 ; curseur = 16/320), avec cercle et croix blancs. Le cercle central et les cibles ont été agrandis de 50 % ; ce facteur est réglable avec `Parameters.ADAPT.Target.DiameterMultiplier` dans `GetParameters.m`. Les dimensions physiques exactes « 320 mm / 20 mm / 16 mm » du document MEG ne peuvent donc plus être garanties. Cela ne change pas les positions angulaires des cibles.

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

## Retour au départ et conversion en position

### Outil de comparaison dans le menu d'accueil

Le bouton **Comparer les courbes du joystick** ouvre une grande fenetre interactive, utilisable sans joystick connecte. Les valeurs usuelles `[-29376 -31482 27242 30784]` sont pre-remplies dans le menu et l'outil ; elles restent remplacables par la calibration mesuree avec **JCalibration**.

Le graphique compare le **lineaire (k = 0)** et les exponentielles **k = 1, 2, 4, 6, 8**, avec le meme gain, la meme zone morte et la meme amplitude maximale. Plus `k` augmente, moins les faibles mouvements proches du centre deplacent le curseur. Un deuxieme graphique zoome sur les 15 % de course autour du centre. L'axe horizontal donne les valeurs brutes calibrees de X ou Y ; l'axe vertical donne la position du curseur en pourcentage de la hauteur de fenetre. Les deux demi-courses utilisent leurs propres bornes, ce qui tient compte de l'asymetrie de la calibration.

Les champs et le curseur de reglage permettent de changer la calibration, l'axe, le gain, la zone morte et le coefficient de 0 a 12. La courbe choisie est epaissie ; le panneau lateral indique sa reponse a 10 % et 20 % de course. Le repere du grand cercle est indique a environ 40 % de hauteur. Une amplitude inferieure a ce repere reste visible pour comparaison mais ne peut pas etre appliquee a la tache.

**Appliquer ce profil a la tache** ajoute un choix **Personnalise** au menu. Ce profil et sa calibration sont utilises aux prochains lancements et sauvegardes avec la session. Le choix reste disponible tant que le menu reste ouvert ; selectionner un autre preset remet ses reglages habituels. Pour une comparaison a amplitude identique, le lineaire personnalise utilise la meme reference de sortie que les exponentielles (hauteur de fenetre multipliee par le gain). Le preset historique **Lineaire x1** conserve sa reference demi-hauteur.

L'outil appelle directement la fonction de conversion de l'acquisition ; les courbes affichees et le profil applique utilisent donc le meme calcul. Il peut aussi etre ouvert independamment avec `ADAPT.JoystickCurveTool` pour une simple visualisation.

### Retour et maintien

Après chaque tentative (réussie, manquée ou trop lente), la consigne **« Revenez au point de depart »** apparaît dès le retour du score. Le participant garde la main sur la manette et revient vers sa position de départ. Dès qu'il entre dans la zone tolérée, la consigne devient **« Restez aussi immobile que possible »**. Après au moins 0,3 s de maintien suffisamment stable, la médiane des coordonnées brutes devient le nouveau zéro ; le curseur et sa référence de déplacement sont recentrés ensemble. Il n'y a plus de délai fixe de relâchement. Un premier recalage est également réalisé avant le premier essai et après chaque pause de bloc. La calibration initiale des débattements avec **JCalibration** reste nécessaire.

La zone de retour a un rayon de 15 % du débattement calibré autour du zéro précédent. Une limite absolue de 25 % autour du zéro matériel empêche les corrections successives de dériver vers les extrémités du joystick. La variation autorisée pendant le maintien est de 2 % par axe, pour tolérer de petits mouvements de la main. Toute sortie de la zone recommence le maintien de 300 ms. Tant que ces conditions ne sont pas remplies, la consigne reste affichée ; Échap permet toujours d'interrompre. Une zone morte de 2 % autour du nouveau zéro absorbe les petites fluctuations. Le temps de recalage est inclus dans l'intervalle inter-essais ; si le retour est trop long, l'intervalle est prolongé jusqu'à obtention d'une position stable. Le maintien central de 200 ms de l'essai suivant reste vérifié séparément.

Le curseur reste masqué pendant les consignes de retour et de maintien, y compris sur la dernière image du recalage, pour éviter un flash blanc au centre. Le changement de consigne confirme l'entrée dans la zone tolérée. Le curseur réapparaît lors de la présentation du cercle central de l'essai suivant.

Dans le menu **Conversion en position**, quatre gains exponentiels de coefficient **6** sont proposés, du plus grand au plus petit : **×0,75, ×0,70, ×0,65, ×0,60** (×0,60 par défaut). La réponse par défaut est plus progressive près du centre et à mi-course que l'ancien réglage de coefficient 3 et gain ×0,80. **Linéaire ×1** reste disponible avec son échelle habituelle. Ces réglages s'appliquent aux deux tâches MEG utilisant le joystick. Relancer `AMEDYST_main` actualise les libellés même si le menu est déjà ouvert.

La conversion s'applique à l'amplitude absolue du manche, avant le calcul des incréments et la rotation expérimentale ; elle préserve la direction du mouvement. Après soustraction du repos, chaque axe est normalisé avec le débattement restant de son côté, puis l'amplitude radiale est corrigée de la zone morte et bornée à 1. Pour cette amplitude `r`, la loi est :

```text
amplitude du curseur = gain × (exp(k × r) − 1) / (exp(k) − 1)
position exponentielle en pixels = amplitude du curseur × hauteur de la fenêtre × ExponentialRangeRatio
```

Le coefficient `k = 6` réduit la réponse près du centre et augmente la sensibilité pour les grands mouvements. Un gain plus grand augmente le déplacement du curseur pour une même inclinaison du manche. L'échelle exponentielle utilise désormais la hauteur de la fenêtre comme référence (`ExponentialRangeRatio = 1`) : un gain ×0,60 atteint donc un rayon maximal de 60 % de cette hauteur. Tous les gains permettent ainsi d'atteindre le grand cercle, dont le rayon est légèrement inférieur à 40 % de la hauteur. L'ancien facteur demi-hauteur rendrait les cibles inaccessibles avec ×0,60. Le mode linéaire conserve sa référence demi-hauteur. Les gains, `k`, l'échelle exponentielle, la zone morte et les critères de maintien sont réglables dans `+ADAPT/JoystickSettings.m`. Le mode souris conserve son fonctionnement actuel.

Le fichier de session sauvegarde les réglages dans `S.Parameters.ADAPT.Joystick`, le dernier zéro dans `S.Joystick.Center` et chaque recalage dans `S.Joystick.RestHistory` (bloc, essai, instant, durée, coordonnées brutes, nombre de mesures et variation normalisée). Les événements `JoystickReturn__…` et `JoystickZero__…` sont ajoutés au journal `RR` ; ils n'ajoutent pas de marqueur matériel. `JoystickReturn__…` remplace l'ancien événement `JoystickRelease__…`.

## Dépendances et messages d'erreur

Il faut MATLAB, Psychtoolbox et la bibliotheque libre **StimTemplate** (`EventPlanning`, `EventRecorder`, `SampleRecorder`, `KbLogger`). Pour installer la version officielle dans le projet, executer **une fois** `setup_StimTemplate` dans MATLAB avec une connexion Internet. `AMEDYST_main` ajoutera ensuite automatiquement la copie locale au `path` MATLAB. Si le poste experimental est hors ligne, telecharger StimTemplate sur un autre poste depuis https://github.com/benoitberanger/StimTemplate et copier le dossier decompresse `StimTemplate-master` dans `vendor/`. La bibliotheque officielle est sous licence Apache-2.0 ; son code n'est pas modifie. Si elle n'est pas accessible, un message `MEG:MissingStimTemplate` donne les instructions. Le joystick réel utilise `joymex2` (fichiers binaires inclus pour Windows/Linux, compatibilité à vérifier selon le poste) ; la souris permet des essais de débogage.

La fréquence de **140 Hz n'est pas garantie** : le moteur original enregistre les positions lors des rafraîchissements de l'écran. La fréquence réelle de la chaîne joystick-écran-acquisition doit être mesurée sur le matériel.

## Vérification

Dans MATLAB, après avoir ajouté le dossier racine au `path` :

```matlab
addpath(fullfile(pwd,'tests'))
test_protocol
test_joystick
test_joystick_recenter
test_joystick_curves
test_joystick_curve_tool % necessite un affichage MATLAB, sans PTB ni joystick
```

Les tests MATLAB ci-dessus vérifient le protocole, les courbes et le recalage avec des entrées simulées, sans afficher de fenêtre ni utiliser de joystick. Les vérifications statiques Python se lancent depuis le dossier racine : `python tests/static_check.py` puis `python tests/test_refactor_v2.py`. L'exécution complète avec Psychtoolbox et le joystick MEG reste à vérifier sur le poste expérimental : affichage, timing, calibration, éventuels marqueurs Arduino et sauvegarde.


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
