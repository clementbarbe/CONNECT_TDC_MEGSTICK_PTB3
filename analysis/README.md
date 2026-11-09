# Analyse et exports

Ces fonctions sont accessibles après `setup_AMEDYST` et sont utilisées par la fin de session :

- `SPMnod.m` : préparation des noms, onsets et durées pour SPM.
- `trajectory_to_CSV.m` : export des trajectoires enregistrées.
- `printResults.m` : affichage des résultats de la tâche SEQ historique.

`legacy/extract_angledev.m` est un script d'analyse historique avec des chemins et des participants codés en dur. Il doit être adapté avant utilisation et son dossier n'est pas ajouté automatiquement au chemin MATLAB.

Les statistiques propres à la tâche ADAPT restent dans `src/+ADAPT/+Stats/`.
