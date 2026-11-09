# Déroulement de l'expérience

## Blocs et contrebalancement

La session comprend quatre essais de familiarisation, un par direction, puis huit blocs de 48 essais. Chaque cycle de quatre essais contient les cibles à 20°, 60°, 120° et 160°, dans un ordre aléatoire.

- **Tâche 1** : familiarisation, bloc 1 à 0° avec curseur visible, puis bloc 2 à 0° sans trajectoire visible.
- **Tâche 2** : blocs 3 à 8 ; adaptation dans les blocs 3–4 et 6–7, retour à 0° avec curseur visible dans les blocs 5 et 8.

| Ordre | Blocs 3–4 | Blocs 6–7 |
|---|---|---|
| A | +30° horaire, visible | −30° antihoraire, sans trajectoire |
| B | −30° antihoraire, visible | +30° horaire, sans trajectoire |
| C | −30° antihoraire, sans trajectoire | +30° horaire, visible |
| D | +30° horaire, sans trajectoire | −30° antihoraire, visible |

En Acquisition, deux pauses de cinq minutes sont prévues aux transitions 2→3 et 5→6. La première tient compte du délai écoulé entre les lancements des deux tâches. Les autres transitions de blocs comportent une pause de dix secondes. En `FastDebug`, les blocs sont réduits à quatre essais et les pauses longues sont supprimées.

## Déroulement d'un essai

Le participant part du centre et vise une cible périphérique. Le point final est affiché en jaune et la cible indique la réussite ou l'échec. Les seuils de durée du mouvement sont de 100 à 600 ms, avec les messages « Too fast » et « Too slow ».

Après chaque tentative, le participant revient dans une zone tolérée autour du départ et maintient le joystick aussi immobile que possible pendant 300 ms. Cette mesure définit le zéro suivant. Le maintien central de 200 ms est également vérifié avant le mouvement de l'essai suivant.

L'intervalle demandé entre les essais est tiré entre 3,5 et 4,5 s depuis la fin du mouvement précédent. La présentation du résultat et le recalage sont inclus dans cette attente ; le maintien central intervient ensuite. Un retour trop long peut donc retarder la cible suivante.

## Affichage et réglages

Le diamètre du grand cercle représente 80 % de la hauteur de la fenêtre. Les cibles et le cercle central utilisent un diamètre égal à `1,5 × 20/320` de celui du grand cercle ; la croix utilise `20/320`, et le curseur et le point final `16/320`.

Les paramètres généraux sont dans `src/GetParameters.m`, les tailles MEG dans `src/+MEG/ApplyDisplayGeometry.m`, le planning dans `src/+ADAPT/Planning.m` et l'ordre des blocs dans `src/+MEG/BuildParadigm.m`.

Conserver le même profil de joystick pendant la familiarisation, la baseline et l'adaptation, sauf si sa variation fait explicitement partie du plan expérimental.

## Limites connues

- Les positions sont enregistrées au rythme de l'affichage : 140 Hz ne sont pas garantis.
- Les tailles en millimètres et la distance de vision dépendent de l'installation physique.
- Le retour actif, le recalage, les cibles agrandies et les courbes réglables sont des adaptations du protocole initial.
- Le moteur actuel peut terminer un mouvement dès l'entrée dans une cible, avant le franchissement exact du grand cercle. Une même itération peut également réévaluer une cible après un dépassement de temps. Ces comportements hérités restent à corriger pour une conformité stricte.

## Fichiers enregistrés

Chaque run produit un fichier de session `.mat`, des fichiers `_SR.mat`, `_OUT.mat`, `_SPM.mat` et un export `.csv`. `LastS.mat` est mis à jour dans le dossier du participant. Les réglages du joystick et les recalages sont inclus dans la structure `S`.

Une première sauvegarde est réalisée à la fin de la tâche, avant les analyses. Elle ne garantit pas la récupération d'une session interrompue par une erreur avant cette étape.
