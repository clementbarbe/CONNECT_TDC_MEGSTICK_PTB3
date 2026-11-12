# Joystick Current Designs en série PJS

AMEDYST accepte deux transports pour le joystick : **USB HID JOY** et **Série PJS / 651**. Le joystick peut être branché et le boîtier allumé avant l'ouverture de MATLAB et de la tâche.

## Branchement

Pour le fORP 932, sélectionner **PJS**, mode **651**, sur le boîtier. Le [manuel Current Designs du 932](https://bpb-us-e2.wpmucdn.com/sites.uci.edu/dist/e/3024/files/2017/06/932_manual.pdf) identifie ce mode comme la sortie série du joystick. Il décrit la sortie série sur **P2 / Aux** avec le câble **CB-932-SER-1**. Utiliser cette liaison vers le port RS-232 du poste ou un adaptateur USB vers RS-232 reconnu par le système.

Le câble branché sur la sortie USB HID du 932 ne crée pas à lui seul un port série. La sélection dans AMEDYST choisit le lecteur logiciel ; le changement de mode du boîtier se fait sur le boîtier.

## Réglages dans le menu

1. Lancer `AMEDYST_main`, puis sélectionner **Joystick**.
2. Choisir **Série PJS / 651** dans le menu de transport.
3. Sélectionner le port du boîtier, par exemple `COM3` sous Windows ou `/dev/ttyUSB0` sous Linux. Les ports déjà branchés sont listés dès l'ouverture du menu. **MAJ** actualise la liste ; le champ en dessous accepte aussi un nom de port saisi manuellement.
4. Conserver **57600** bauds pour le format Programmer's Joystick documenté. Le lecteur utilise **8 bits, aucune parité, 1 bit de stop, aucun contrôle de flux**. Les autres débits du menu servent aux configurations dont le débit est explicitement connu.
5. Cliquer sur **Tester**. Un message vert `SerialPJS OK` confirme la réception de plusieurs positions compatibles. Le port est libéré après le test, y compris en cas d'échec. Le message complet reste accessible dans l'infobulle du statut.
6. Cliquer sur **Calibration**. Laisser la manette au repos, puis cliquer sur **Mesurer le centre** (ou **Espace**) et rester immobile pendant 0,6 seconde. Parcourir ensuite les deux axes dans les deux sens, puis appuyer sur **Échap** pour enregistrer. Fermer la fenêtre annule la mesure. Vérifier les directions dans le graphique normalisé : droite = X positif et haut = Y positif ; utiliser **Inv.X / Inv.Y** puis recalibrer si nécessaire.
7. Choisir la courbe de réponse et lancer la baseline ou l'adaptation.

Les calibrations USB et série sont conservées séparément pendant l'ouverture du menu. Les valeurs USB habituelles ne sont pas automatiquement utilisées pour la série. Les profils de réponse et le recentrage entre essais passent par les mêmes fonctions pour les deux transports.

## Lecture du flux

Le lecteur utilise [`serialport`](https://www.mathworks.com/help/matlab/ref/serialport.html), disponible dans MATLAB à partir de R2019b. Il n'utilise pas `joymex2` pour le transport série.

Le format binaire implémenté est celui du Programmer's Joystick décrit par le [CENIR dans sa documentation d'utilisation du joystick Current Designs](https://icm-institute.atlassian.net/wiki/spaces/CENIR/pages/360560) : quatre octets, axes signés sur 11 bits, états des deux boutons et bit trigger. Cette documentation décrit le mode 7 des anciennes interfaces ; le manuel 932 donne le nom PJS/651 mais ne détaille pas les octets. La compatibilité binaire avec le boîtier utilisé doit donc être confirmée par **Tester** et par les mouvements pendant la calibration.

Les coordonnées décodées vont de −1024 à 1023. Elles sont multipliées par 32 pour conserver une échelle proche des anciennes coordonnées USB ; cette conversion n'ajoute aucune résolution au signal. Le matériel peut n'utiliser qu'une partie de cet intervalle et son repos peut être éloigné de zéro. La calibration mesure ce repos (`RawCenter`) et le lecteur le soustrait pendant la tâche. Les limites affichées dans le menu sont relatives à ce repos. Par défaut, X conserve son signe et Y est inversé ; modifier **Inv.X / Inv.Y** transforme ensemble les limites et le centre mémorisé. Ces choix sont enregistrés avec la session.

La connexion est vérifiée avant l'ouverture de la fenêtre Psychtoolbox : huit trames consécutives compatibles doivent être reçues en moins de trois secondes. Les octets présents à l'ouverture sont purgés, puis le lecteur se synchronise sur le flux déjà actif. Les paquets incomplets sont conservés entre lectures et une désynchronisation provoque une recherche de nouvelle trame.

Chaque lecture consomme les octets disponibles et utilise la position complète la plus récente. L'immobilité du joystick n'empêche pas la lecture puisque le boîtier émet en continu. L'absence de trame valide pendant plus de 0,5 seconde provoque une erreur explicite plutôt qu'un curseur figé. Une sortie normale ou une erreur libère uniquement la connexion ouverte par AMEDYST.

## Déclenchement et données

En Acquisition, l'attente initiale accepte soit la touche TTL habituelle, soit un nouveau front montant du bit trigger du flux PJS. Les triggers déjà reçus avant l'armement sont ignorés ; un bit déjà maintenu à 1 doit revenir à 0 avant de produire un nouveau front.

- `S.JoystickConnection` contient le transport, le port, le débit, les inversions et les délais de connexion.
- `S.Joystick.ConnectionInfo` contient les compteurs de trames, les dernières coordonnées et `TriggerTimes`.
- `TriggerTimes` contient des temps absolus `GetSecs` mesurés lors de la lecture sur le poste. Les trames d'un même lot partagent cet instant ; ce ne sont pas des horodatages matériels.

Le journal clavier conserve sa fonction habituelle. Le stockage des trajectoires reste lié aux lectures de la tâche et aux rafraîchissements d'écran : l'ajout du port série ne constitue pas un enregistreur de toutes les positions à la fréquence native du boîtier.

Le port du joystick doit être distinct du port de sortie des marqueurs Arduino. Le programme refuse la collision avec les ports Arduino actuellement configurés (`COM4` sous Windows, `/dev/ttyACM0` sous Unix).

## Dépannage

| Symptôme | Vérification |
| --- | --- |
| Aucun port dans la liste | Vérifier la liaison série et le pilote de l'adaptateur, puis cliquer sur **MAJ**. Un port connu peut être saisi manuellement. |
| Impossible d'ouvrir le port | Fermer le moniteur série ou l'autre logiciel qui utilise ce port. Sous Linux, vérifier les droits d'accès au périphérique indiqués par l'erreur. |
| Octets reçus mais aucune trame PJS valide | Vérifier le mode PJS/651, le débit et le format du firmware ; un flux ASCII ou un autre mode fORP n'est pas accepté. |
| Aucun octet reçu | Vérifier le port choisi, l'alimentation du boîtier et le câble sur sa sortie série. |
| Axes inversés | Corriger **Inv.X / Inv.Y** et vérifier les directions dans **Calibration**. |
| Flux interrompu pendant la tâche | Vérifier la liaison et l'alimentation. Relancer **Tester** avant une nouvelle acquisition. |

Les tests automatisés utilisent un port virtuel et un émetteur PJS simulé. Ils valident le logiciel et l'API série MATLAB ; le boîtier, son firmware, le câblage et les timings du poste expérimental nécessitent une vérification matérielle.
