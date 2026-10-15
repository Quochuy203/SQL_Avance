USE mediatheque;

-- 0. Tạo bảng journal_action (Bảng kiểm tra/audit log nếu chưa có)
CREATE TABLE IF NOT EXISTS journal_action (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  table_cible VARCHAR(40)     NOT NULL,
  operation   VARCHAR(10)     NOT NULL,
  cle         VARCHAR(40)     NOT NULL,
  auteur      VARCHAR(100)    NOT NULL,
  horodatage  DATETIME        NOT NULL,
  details     VARCHAR(255)        NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;


DELIMITER $$

-- 1. BEFORE INSERT ON emprunt : Tự động điền ngày mượn, hạn trả và kiểm tra hợp lệ
DROP TRIGGER IF EXISTS trg_emprunt_avant_insert$$
CREATE TRIGGER trg_emprunt_avant_insert
BEFORE INSERT ON emprunt
FOR EACH ROW
BEGIN
    -- Nếu chưa có ngày mượn thì gán là ngày hiện tại (CURDATE)
    IF NEW.date_emprunt IS NULL THEN
        SET NEW.date_emprunt = CURDATE();
    END IF;

    -- Nếu chưa có ngày trả dự kiến thì tính mặc định là +14 ngày
    IF NEW.date_retour_prevue IS NULL THEN
        SET NEW.date_retour_prevue = DATE_ADD(NEW.date_emprunt, INTERVAL 14 DAY);
    END IF;

    -- Kiểm tra nếu ngày trả dự kiến trước ngày mượn thì báo lỗi
    IF NEW.date_retour_prevue < NEW.date_emprunt THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'La date de retour prévue ne peut pas être antérieure à la date d''emprunt.';
    END IF;
END$$


-- 2. AFTER INSERT ON emprunt : Cập nhật exemplaire thành không khả dụng và ghi log
DROP TRIGGER IF EXISTS trg_emprunt_apres_insert$$
CREATE TRIGGER trg_emprunt_apres_insert
AFTER INSERT ON emprunt
FOR EACH ROW
BEGIN
    -- Cập nhật trạng thái sách thành đã mượn (disponible = 0)
    UPDATE exemplaire
       SET disponible = 0
     WHERE id = NEW.exemplaire_id;

    -- Ghi nhận lịch sử vào bảng journal_action
    INSERT INTO journal_action (table_cible, operation, cle, auteur, horodatage, details)
    VALUES (
        'emprunt', 
        'INSERT', 
        CAST(NEW.id AS CHAR), 
        USER(), 
        NOW(), 
        CONCAT('Emprunt de l''exemplaire ID ', NEW.exemplaire_id, ' par l''adhérent ID ', NEW.adherent_id)
    );
END$$


-- 3. AFTER UPDATE ON emprunt : Xử lý khi sách được trả lại (date_retour_reelle)
DROP TRIGGER IF EXISTS trg_emprunt_apres_update$$
CREATE TRIGGER trg_emprunt_apres_update
AFTER UPDATE ON emprunt
FOR EACH ROW
BEGIN
    -- Kiểm tra sự thay đổi: trước đó date_retour_reelle là NULL, bây giờ đã có giá trị (được trả sách)
    IF OLD.date_retour_reelle IS NULL AND NEW.date_retour_reelle IS NOT NULL THEN
        
        -- Chuyển trạng thái sách về lại khả dụng (disponible = 1)
        UPDATE exemplaire
           SET disponible = 1
         WHERE id = NEW.exemplaire_id;

        -- Ghi nhận lịch sử trả sách vào bảng journal_action
        INSERT INTO journal_action (table_cible, operation, cle, auteur, horodatage, details)
        VALUES (
            'emprunt', 
            'UPDATE', 
            CAST(NEW.id AS CHAR), 
            USER(), 
            NOW(), 
            CONCAT('Retour de l''exemplaire ID ', NEW.exemplaire_id)
        );
        
    END IF;
END$$

DELIMITER ;