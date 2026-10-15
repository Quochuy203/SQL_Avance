USE mediatheque;

-- Đổi delimiter để MySQL không hiểu nhầm dấu chấm phẩy bên trong hàm
DELIMITER $$

-- 1. f_nb_emprunts_en_cours : Trả về số lượng tài liệu đang mượn (chưa trả)
DROP FUNCTION IF EXISTS f_nb_emprunts_en_cours$$
CREATE FUNCTION f_nb_emprunts_en_cours(p_adherent_id INT UNSIGNED)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_nb INT;
    
    SELECT COUNT(*) INTO v_nb
      FROM emprunt
     WHERE adherent_id = p_adherent_id
       AND date_retour_reelle IS NULL;
      
    RETURN v_nb;
END$$

-- 2. f_penalites_dues : Tổng tiền phạt chưa thanh toán (luôn trả về 0.00 nếu không có)
DROP FUNCTION IF EXISTS f_penalites_dues$$
CREATE FUNCTION f_penalites_dues(p_adherent_id INT UNSIGNED)
RETURNS DECIMAL(6,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(6,2);
    
    -- Dùng COALESCE để chuyển đổi kết quả NULL thành 0.00 khi SUM trên 0 dòng[cite: 11]
    SELECT COALESCE(SUM(montant), 0.00) INTO v_total
      FROM penalite
     WHERE adherent_id = p_adherent_id
       AND payee = 0;
      
    RETURN v_total;
END$$


-- 3. f_jours_de_retard : Số ngày quá hạn của một lượt mượn (tính cả khi đã trả hoặc chưa)
DROP FUNCTION IF EXISTS f_jours_de_retard$$
CREATE FUNCTION f_jours_de_retard(p_emprunt_id INT UNSIGNED)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_jours INT;
    
    SELECT 
        GREATEST(0, DATEDIFF(COALESCE(date_retour_reelle, CURDATE()), date_retour_prevue)) INTO v_jours
      FROM emprunt
     WHERE id = p_emprunt_id;
    
    RETURN COALESCE(v_jours, 0);
END$$

-- Trả lại dấu delimiter mặc định
DELIMITER ;

-- Trả lại dấu delimiter mặc định
DELIMITER ;

-- 4. Truy vấn kiểm tra cuối file theo yêu cầu đề bài
-- Liệt kê các adhérent có ít nhất 1 emprunt đang mượn kèm theo tiền phạt của họ
SELECT 
    a.id, 
    a.nom, 
    a.prenom,
    f_nb_emprunts_en_cours(a.id) AS nb_emprunts,
    f_penalites_dues(a.id) AS penalites
FROM adherent a
WHERE f_nb_emprunts_en_cours(a.id) > 0;