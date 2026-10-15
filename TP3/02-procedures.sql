USE mediatheque;

DELIMITER $$

-- 1. p_emprunter : Thủ tục thực hiện mượn sách với các quy tắc nghiệp vụ và giao dịch
DROP PROCEDURE IF EXISTS p_emprunter$$
CREATE PROCEDURE p_emprunter(
    IN p_code_barre VARCHAR(32),
    IN p_adherent_id INT UNSIGNED,
    OUT p_emprunt_id INT UNSIGNED
)
BEGIN
    -- Khai báo biến lưu thông tin phụ trợ
    DECLARE v_exemplaire_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_disponible TINYINT DEFAULT NULL;
    DECLARE v_actif TINYINT DEFAULT NULL;
    
    -- Xử lý giao dịch và bắt lỗi để rollback tự động
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Règle 1: L'adhérent existe et son inscription est active
    SELECT actif INTO v_actif
      FROM adherent
     WHERE id = p_adherent_id;
     
    IF v_actif IS NULL OR v_actif = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inscription inactive ou adhérent inconnu.';
    END IF;

    -- Règle 2: L'exemplaire existe et il est disponible
    SELECT id, disponible INTO v_exemplaire_id, v_disponible
      FROM exemplaire
     WHERE code_barre = p_code_barre;
     
    IF v_exemplaire_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Code-barres inconnu.';
    ELSEIF v_disponible = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Exemplaire déjà emprunté.';
    END IF;

    -- Règle 3: Il a moins de 5 documents chez lui
    IF f_nb_emprunts_en_cours(p_adherent_id) >= 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quota de 5 documents atteint.';
    END IF;

    -- Règle 4: Il ne doit pas plus de 10 € de pénalités
    IF f_penalites_dues(p_adherent_id) > 10.00 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pénalités impayées supérieures à 10 EUR.';
    END IF;

    -- Thêm bản ghi emprunt (Lưu ý: Không tự sửa exemplaire.disponible ở đây, để trigger lo việc đó)
    INSERT INTO emprunt (exemplaire_id, adherent_id, date_emprunt, date_retour_prevue)
    VALUES (v_exemplaire_id, p_adherent_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY));

    -- Lấy ID vừa tạo trả về cho tham số OUT
    SET p_emprunt_id = LAST_INSERT_ID();

    COMMIT;
END$$


-- 2. p_rendre : Thủ tục trả sách và tính tiền phạt nếu trễ hạn
DROP PROCEDURE IF EXISTS p_rendre$$
CREATE PROCEDURE p_rendre(
    IN p_code_barre VARCHAR(32)
)
BEGIN
    DECLARE v_emprunt_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_retard INT DEFAULT 0;
    DECLARE v_adherent_id INT UNSIGNED DEFAULT NULL;

    -- Tìm emprunt đang mở (chưa trả) của exemplaire này
    SELECT em.id, em.adherent_id INTO v_emprunt_id, v_adherent_id
      FROM emprunt em
      JOIN exemplaire ex ON ex.id = em.exemplaire_id
     WHERE ex.code_barre = p_code_barre
       AND em.date_retour_reelle IS NULL
     LIMIT 1;

    IF v_emprunt_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Aucun emprunt en cours pour ce code-barres.';
    END IF;

    -- Cập nhật ngày trả thực tế
    UPDATE emprunt
       SET date_retour_reelle = CURDATE()
     WHERE id = v_emprunt_id;

    -- Tính số ngày trễ hạn
    SET v_retard = f_jours_de_retard(v_emprunt_id);

    -- Nếu có trễ hạn, tạo khoản phạt (0.20 € / ngày)
    IF v_retard > 0 THEN
        INSERT INTO penalite (adherent_id, montant, motif, payee)
        VALUES (v_adherent_id, v_retard * 0.20, CONCAT('Retard de ', v_retard, ' jour(s)'), 0);
    END IF;

    -- Trả kết quả báo cáo
    SELECT v_emprunt_id AS emprunt_id, v_retard AS jours_de_retard, (v_retard * 0.20) AS montant_facture;
END$$


-- 3. p_bilan_adherent : Trả về 3 tập kết quả thông tin adhérent
DROP PROCEDURE IF EXISTS p_bilan_adherent$$
CREATE PROCEDURE p_bilan_adherent(
    IN p_adherent_id INT UNSIGNED
)
BEGIN
    -- 1. Fiche adhérent et ses indicateurs via fonctions
    SELECT a.*, 
           f_nb_emprunts_en_cours(a.id) AS nb_en_cours,
           f_penalites_dues(a.id) AS total_penalites
      FROM adherent a
     WHERE a.id = p_adherent_id;

    -- 2. Liste des emprunts en cours
    SELECT em.id AS emprunt_id, o.titre, em.date_emprunt, em.date_retour_prevue
      FROM emprunt em
      JOIN exemplaire ex ON ex.id = em.exemplaire_id
      JOIN ouvrage o ON o.id = ex.ouvrage_id
     WHERE em.adherent_id = p_adherent_id
       AND em.date_retour_reelle IS NULL;

    -- 3. Nombre total d'emprunts depuis l'inscription
    SELECT COUNT(*) AS total_emprunts_historique
      FROM emprunt
     WHERE adherent_id = p_adherent_id;
END$$

DELIMITER ;