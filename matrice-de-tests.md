# TP1 — Matrice de tests

Douze tests. Dans la colonne **Obtenu**, écrivez `OK` (la commande passe et renvoie des lignes)
ou le numéro d'erreur complet, par exemple `ERROR 1142 (42000)`.

Un test se fait **connecté avec le compte concerné** :

```
mysql -u stagiaire -p mediatheque
```

Premier réflexe à chaque connexion : `SELECT CURRENT_ROLE();`. Si la réponse est `NONE`,
les rôles ne sont pas actifs et tous les tests qui suivent vont échouer pour la mauvaise raison.

## `app_media` — l'application web

| # | Commande | Attendu | Obtenu |
|---|---|---|---|
| 1 | `SELECT id, nom, prenom FROM adherent LIMIT 5;` | OK | +----+----------+---------+
| id | nom      | prenom  |
+----+----------+---------+
|  1 | Durand   | Antoine |
|  2 | Garcia   | Zoe     |
|  3 | Girard   | Tom     |
|  4 | Francois | Emma    |
|  5 | Richard  | Paul    |
+----+----------+---------+ |
| 2 | `SELECT email FROM adherent LIMIT 1;` | refus | ERROR 1143 (42000): SELECT command denied to user 'app_media'@'localhost' for column 'email' in table 'adherent' |
| 3 | `UPDATE exemplaire SET disponible = 0 WHERE id = 3;` | OK | ERROR 1143 (42000): UPDATE command denied to user 'app_media'@'localhost' for column 'etat' in table 'exemplaire' |
| 4 | `UPDATE exemplaire SET etat = 'use' WHERE id = 3;` | refus | ERROR 1143 (42000) |
| 5 | `DELETE FROM emprunt WHERE id = 1;` | refus | ERROR 1142 (42000): DELETE command denied to user 'app_media'@'localhost' for table 'emprunt' |

Les tests 3 et 4 portent sur la **même table** : c'est la colonne qui fait la différence.

## `biblio_marie` — la bibliothécaire

| # | Commande | Attendu | Obtenu |
|---|---|---|---|
| 6 | `SELECT nom, email, telephone FROM adherent LIMIT 3;` | OK | +--------+---------------------------+----------------+
| nom    | email                     | telephone      |
+--------+---------------------------+----------------+
| Durand | antoine.durand@example.fr | 04 78 11 27 33 |
| Garcia | zoe.garcia@example.fr     | 04 78 12 34 36 |
| Girard | tom.girard@example.fr     | 04 78 13 41 39 |
+--------+---------------------------+----------------+ |
| 7 | `CREATE USER 'test'@'localhost' IDENTIFIED BY 'Test!2026';` | refus | ERROR 1227 (42000): Access denied; you need (at least one of) the CREATE USER privilege(s) for this operation |

## `stagiaire`

| # | Commande | Attendu | Obtenu |
|---|---|---|---|
| 8 | `SELECT nom, prenom, ville FROM adherent LIMIT 5;` | OK | |
| 9 | `SELECT email FROM adherent LIMIT 1;` | ERROR 1143 | |
| 10 | `SELECT * FROM adherent LIMIT 1;` | ERROR 1142 | |

**Question :** les tests 9 et 10 échouent tous les deux, mais pas avec le même numéro d'erreur. Pourquoi ?

> _votre réponse :_

## `analyste`

| # | Commande | Attendu | Obtenu |
|---|---|---|---|
| 11 | `SELECT COUNT(*) FROM adherent;` | refus | ERROR 1142 |
| 12 | `SELECT COUNT(*) FROM reservation;` | après le `GRANT` : OK — après le `REVOKE` : refus | ERROR 1142 |

## Conclusion

Une phrase : **parmi les quatre comptes, lequel peut encore faire quelque chose qu'il ne fera jamais — et comment le lui retireriez-vous ?**

> Le compte analyste (ou app_media) peut toujours consulter la liste des œuvres/genres (role_catalogue) ou mettre à jour le statut des livres, mais en réalité, l'analyste statistique n'a besoin que de lire les données statistiques d'emprunt et de retour et ne les modifie jamais. Pour corriger cela, vous pouvez supprimer le rôle inutile à l'aide de la commande :

-> REVOKE role_catalogue FROM 'analyste'@'localhost';
