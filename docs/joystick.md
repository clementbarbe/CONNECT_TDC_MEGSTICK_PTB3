# Joystick : calibration et courbes

## Calibration

Sélectionner **Joystick**, puis **JCalibration** dans le menu. Explorer le débattement du joystick et terminer avec Échap. Le champ contient les limites `[xmin ymin xmax ymax]` dans le repère de l'expérience.

Les valeurs usuelles `[-29376 -31482 27242 30784]` sont préremplies et peuvent être remplacées par celles de la calibration du jour. Chaque demi-course est normalisée séparément, ce qui tient compte des bornes asymétriques.

## Comparaison des courbes

Le bouton **Comparer les courbes du joystick** ouvre une grande fenêtre, utilisable sans matériel connecté.

- Comparaison du linéaire (`k = 0`) et des exponentielles de coefficients 1, 2, 4, 6 et 8, à gain et amplitude maximale identiques.
- Zoom sur les 15 % de course autour du centre.
- Choix de l'axe X ou Y et réglage de la calibration, du gain, de la zone morte et du coefficient entre 0 et 12.
- Affichage des valeurs brutes en abscisse et de la position du curseur en pourcentage de hauteur de fenêtre en ordonnée.

Plus le coefficient augmente, moins les petits mouvements déplacent le curseur. La courbe choisie est épaissie ; sa réponse à 10 % et 20 % de course est indiquée. Le grand cercle est repéré à environ 40 % de hauteur. Une amplitude insuffisante reste visible pour comparaison mais ne peut pas être appliquée à la tâche.

**Appliquer ce profil à la tâche** ajoute un choix **Personnalisé** au menu et transmet la calibration et le profil aux prochains lancements. Ces réglages sont sauvegardés avec la session. Le choix reste disponible tant que le menu est ouvert ; sélectionner un autre profil rétablit ses réglages habituels.

Le linéaire personnalisé utilise la même référence de sortie que les exponentielles. Le profil historique **Linéaire ×1** conserve sa référence demi-hauteur. L'outil utilise directement la fonction de conversion de l'acquisition, et peut aussi être ouvert avec `ADAPT.JoystickCurveTool` après `setup_AMEDYST`.

## Retour au départ et nouveau zéro

Après chaque tentative, la consigne **« Revenez au point de depart »** invite le participant à revenir en gardant la main sur la manette. Dans la zone tolérée, elle devient **« Restez aussi immobile que possible »**.

Le retour est accepté dans un rayon de 15 % du débattement autour du zéro précédent. Le maintien doit durer au moins 300 ms avec une variation inférieure ou égale à 2 % par axe. Une sortie de la zone recommence le maintien. Une limite absolue de 25 % autour du zéro matériel empêche une dérive cumulative.

La médiane des coordonnées devient le nouveau zéro. Le curseur et sa référence de déplacement sont recentrés ensemble ; une zone morte de 2 % absorbe les petites fluctuations. Le curseur reste masqué pendant le retour et le maintien pour éviter un flash blanc. Échap reste disponible pendant l'attente.

## Conversion en position

Les profils par défaut utilisent `k = 6` et les gains ×0,75, ×0,70, ×0,65 et ×0,60, avec ×0,60 sélectionné par défaut. Les valeurs sont dans `src/+ADAPT/JoystickSettings.m`.

Après soustraction du zéro et normalisation, l'amplitude radiale est corrigée de la zone morte et bornée à 1. Pour cette amplitude `r` :

```text
amplitude = gain × (exp(k × r) − 1) / (exp(k) − 1)
position exponentielle = amplitude × hauteur de fenêtre × ExponentialRangeRatio
```

La référence exponentielle utilise la hauteur de fenêtre (`ExponentialRangeRatio = 1`) afin de garder les cibles accessibles avec ×0,60. Le profil linéaire historique utilise la demi-hauteur. La direction du vecteur normalisé est conservée ; la rotation expérimentale s'applique ensuite aux incréments de position. La souris conserve son fonctionnement habituel.

## Paramètres sauvegardés

- `S.Parameters.ADAPT.Joystick` : profil et critères de maintien.
- `S.Joystick.Center` : dernier zéro.
- `S.Joystick.RestHistory` : bloc, essai, instant, durée, coordonnées, nombre de mesures et variation de chaque recalage.
- `JoystickReturn__…` et `JoystickZero__…` dans le journal `RR` : début du retour et validation du zéro. Aucun marqueur matériel supplémentaire n'est émis.
