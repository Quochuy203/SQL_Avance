# TP2 — Rapport d'optimisation

> Les chiffres attendus sont des **ordres de grandeur** : l'archive est générée
> aléatoirement, les vôtres seront proches sans être identiques.

## Avant / après

Pour chaque requête : le plan avant tout index, puis le plan après l'index que vous avez posé.

### R1 — les emprunts d'une journée

```sql
SELECT * FROM emprunt WHERE date_emprunt = '2024-03-12';
```

| | `type` | `key` | `rows` | `Extra` |
|---|---|---|---|---|
| avant | ALL | NULL | 199875 | Using where |
| après | ref | idx_emprunt_date | 104 | NULL |

- Index créé : `idx_emprunt_date`
- Lignes réellement renvoyées : `104`
- Une phrase de conclusion :L'index permet de cibler directement les 104 lignes sans parcourir les 200 000 lignes de la table.

### R2 — les emprunts en cours

```sql
SELECT * FROM emprunt WHERE date_retour_reelle IS NULL;
```

| | `type` | `key` | `rows` | `Extra` |
|---|---|---|---|---|
| avant | ALL | NULL | 199875 | Using where |
| après | ref | idx_emprunt_retour | 30 | Using index condition |

- Index créé : `idx_emprunt_retour `
- Lignes réellement renvoyées : `30`
- Une phrase de conclusion : L'index permet d'isoler rapidement les emprunts non rendus.

### R3 — l'historique récent d'un adhérent

```sql
SELECT id, date_emprunt FROM emprunt
 WHERE adherent_id = 12 AND date_emprunt >= '2025-01-01';
```

| | `type` | `key` | `rows` | `Extra` |
|---|---|---|---|---|
| avant | ref | fk_emprunt_adherent | 5070 | Using where |
| après | range | idx_emprunt_adh_date | 741 | Using index |

- Index créé : `fk_emprunt_adherent`
- Pourquoi les colonnes sont-elles dans cet ordre, et pas dans l'autre ?
-> On met la colonne filtrée avec = (adherent_id) en premier, et la colonne de plage >= (date_emprunt) en second pour que l'index composé soit efficace.

## Le préfixe gauche (consigne 7)

| Requête | L'index composite sert-il ? | Pourquoi |
|---|---|---|
| `WHERE adherent_id = 12` | idx_emprunt_adh_date | L'index composite commence par adherent_id, donc la première colonne est sollicitée |
| `WHERE date_emprunt >= '2025-01-01'` | idx_emprunt_date | La colonne date_emprunt est en seconde position ; sans la première colonne (adherent_id), l'index composite ne peut pas être utilisé |

## L'index couvrant (consigne 8)

- Mention présente dans le premier `Extra` : `                    `
- Elle disparaît dans le second parce que :

## La requête réécrite (consigne 9)

```sql
-- version d'origine
SELECT COUNT(*) FROM emprunt WHERE YEAR(date_emprunt) = 2024;
-- type : Index   rows : 199875

-- version réécrite

SELECT COUNT(*) FROM emprunt WHERE date_emprunt >= '2024-01-01' AND date_emprunt < '2025-01-01'

-- type : range   rows : 22203
```

Les deux renvoient bien le même nombre : ` 100.00 `

## Le prix des index (consigne 10)

| | `donnees_mo` | `index_mo` |
|---|---|---|
| avant | | |
| après | 8.52 | 18.06 |

Conclusion :

## Bonus

- Consigne 11 — l'index qu'on ne peut pas supprimer : numéro d'erreur et explication.
Command: ERROR 1553 (HY000)
-> Pourquoi: Cette erreur se produit lorsque vous tentez de supprimer un index ou de modifier une colonne (telle qu'une clé primaire ou un index unique) utilisée par le système pour maintenir une contrainte de clé étrangère. Le mécanisme InnoDB de MySQL exige des index sur les colonnes de clés étrangères afin d'optimiser les performances lors de la validation des données.
- Consigne 12 — `EXPLAIN` sur `v_retard` : tables visitées, index utilisés.
-> Résultat: 

+----+-------------+-------+------------+--------+---------------------------------------------------------------+--------------------+---------+------------------------------+------+----------+------------------------------------+
| id | select_type | table | partitions | type   | possible_keys                                                 | key                | key_len | ref                          | rows | filtered | Extra                              |

|  1 | SIMPLE      | em    | NULL       | ref    | fk_emprunt_exemplaire,idx_emprunt_retour,idx_emprunt_adh_date | idx_emprunt_retour | 4       | const                        |   30 |   100.00 | Using index condition; Using where |
|  1 | SIMPLE      | a     | NULL       | eq_ref | PRIMARY                                                       | PRIMARY            | 4       | mediatheque.em.adherent_id   |    1 |   100.00 | NULL                               |
|  1 | SIMPLE      | ex    | NULL       | eq_ref | PRIMARY,fk_exemplaire_ouvrage                                 | PRIMARY            | 4       | mediatheque.em.exemplaire_id |    1 |   100.00 | NULL                               |
|  1 | SIMPLE      | o     | NULL       | eq_ref | PRIMARY                                                       | PRIMARY            | 4       | mediatheque.ex.ouvrage_id    |    1 |   100.00 | NULL                               |
+----+-------------+-------+------------+--------+---------------------------------------------------------------+--------------------+---------+------------------------------+------+----------+------------------------------------+
