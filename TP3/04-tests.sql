USE mediatheque;

-- SCÉNARIO DE TEST - TP3

-- Lấy sẵn dữ liệu mẫu bằng biến session để test không bị cứng ID
SET @code = (SELECT code_barre FROM exemplaire WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);

SET @adherent = (SELECT a.id FROM adherent a
                  WHERE a.actif = 1
                    AND f_nb_emprunts_en_cours(a.id) = 0
                    AND f_penalites_dues(a.id) = 0
                  ORDER BY a.id LIMIT 1);

-- T1: Emprunt normal réussi
CALL p_emprunter(@code, @adherent, @emprunt_id);
-- Kiểm tra sau T1: Exemplaire doit être indisponible (0)
SELECT code_barre, disponible FROM exemplaire WHERE code_barre = @code;


-- T2: Emprunt du même exemplaire (Doit échouer: Exemplaire déjà emprunté)
-- CALL p_emprunter(@code, 2, @id);
-- ERROR 1644 (45000): Exemplaire déjà emprunté.


-- T3: Emprunt avec adhérent inactif (Doit échouer)
-- CALL p_emprunter('MED-00001', <id_adherent_inactif>, @id);
-- ERROR 1644 (45000): Inscription inactive ou adhérent inconnu.


-- T4: Code-barres inconnu (Doit échouer)
-- CALL p_emprunter('MED-99999', @adherent, @id);
-- ERROR 1644 (45000): Code-barres inconnu.


-- T5: Dépassement quota de 5 documents (Doit échouer si l'adhérent a déjà 5 documents)
-- (Bạn có thể test bằng cách mượn liên tiếp cho một adhérent đến cuốn thứ 6)


-- T6: Adhérent avec pénalités > 10 EUR (Doit échouer)
-- SET @mauvais_payeur = (SELECT adherent_id FROM penalite WHERE payee = 0 GROUP BY adherent_id HAVING SUM(montant) > 10 LIMIT 1);
-- CALL p_emprunter(@code, @mauvais_payeur, @id);
-- ERROR 1644 (45000): Pénalités impayées supérieures à 10 EUR.


-- T7: INSERT direct dans emprunt (Test du trigger BEFORE INSERT)
INSERT INTO emprunt (exemplaire_id, adherent_id, date_emprunt, date_retour_prevue) 
VALUES ((SELECT id FROM exemplaire WHERE disponible = 1 LIMIT 1), @adherent, NULL, NULL);
-- Kiểm tra: Lệnh INSERT trực tiếp nhưng trigger tự gán ngày mượn, hạn trả +14 ngày và làm sách đổi thành không khả dụng.


-- T8: Retour de livre (p_rendre)
-- CALL p_rendre(<code_barre_en_cours>);


-- T9: Rendre un livre qui n'est pas en cours (Doit échouer)
-- CALL p_rendre('MED-99999');
-- ERROR 1644 (45000): Aucun emprunt en cours pour ce code-barres.