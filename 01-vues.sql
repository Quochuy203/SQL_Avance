USE mediatheque;

-- =====================================================================
-- PARTIE A : LES VUES DU QUOTIDIEN ET DE SÉCURITÉ
-- =====================================================================

-- 1. v_catalogue
CREATE OR REPLACE VIEW v_catalogue AS
SELECT 
    o.id AS ouvrage_id,
    o.titre,
    o.auteur,
    o.annee_publication AS annee,
    c.libelle AS categorie,
    COUNT(e.id) AS nb_exemplaires,
    SUM(e.disponible = 1) AS nb_disponibles
FROM ouvrage o
LEFT JOIN categorie c ON c.id = o.categorie_id
LEFT JOIN exemplaire e ON e.ouvrage_id = o.id
GROUP BY o.id, o.titre, o.auteur, o.annee_publication, c.libelle;

-- 2. v_adherent_public
CREATE OR REPLACE VIEW v_adherent_public AS
SELECT 
    id, 
    nom, 
    prenom, 
    ville, 
    date_inscription, 
    actif
FROM adherent;

-- 3. v_emprunt_en_cours
CREATE OR REPLACE VIEW v_emprunt_en_cours AS
SELECT 
    em.id AS emprunt_id,
    em.date_emprunt,
    em.date_retour_prevue,
    DATEDIFF(CURDATE(), em.date_retour_prevue) AS jours_de_retard,
    CONCAT(a.prenom, ' ', a.nom) AS adherent,
    o.titre,
    ex.code_barre
FROM emprunt em
JOIN exemplaire ex ON ex.id = em.exemplaire_id
JOIN ouvrage o ON o.id = ex.ouvrage_id
JOIN adherent a ON a.id = em.adherent_id
WHERE em.date_retour_reelle IS NULL;

-- 4. v_retard
CREATE OR REPLACE VIEW v_retard AS
SELECT * 
FROM v_emprunt_en_cours
WHERE jours_de_retard > 0;