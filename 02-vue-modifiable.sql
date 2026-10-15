USE mediatheque;

-- =====================================================================
-- PARTIE A.3 : UNE VUE PAR LAQUELLE ON ÉCRIT (VUES MODIFIABLES)
-- =====================================================================

-- 1. Tạo vue v_adherent_lyon với điều kiện ville = 'Lyon' và WITH CHECK OPTION
CREATE OR REPLACE VIEW v_adherent_lyon AS
SELECT id, nom, prenom, ville
FROM adherent
WHERE ville = 'Lyon'
WITH CHECK OPTION;

-- 2. Thử nghiệm các thao tác ghi (Chạy trực tiếp trong MySQL monitor hoặc thêm vào script kiểm tra):
-- Thí nghiệm 1: Chèn một adhérent ở Lyon qua vue (Phải thành công)
-- INSERT INTO v_adherent_lyon (nom, prenom, ville) VALUES ('Durand', 'Max', 'Lyon');

-- Thí nghiệm 2: Chèn một adhérent ở Bron qua vue (Phải thất bại do vi phạm WITH CHECK OPTION)
-- INSERT INTO v_adherent_lyon (nom, prenom, ville) VALUES ('Martin', 'Sophie', 'Bron');

-- Thí nghiệm 3: Cố gắng UPDATE trên v_catalogue (Phải thất bại vì view có chứa hàm tổng hợp GROUP BY / JOIN)
-- UPDATE v_catalogue SET titre = 'Nouveau titre';


-- =====================================================================
-- PARTIE A.4 : QUELLES VUES SONT MODIFIABLES ?
-- =====================================================================
-- Kiểm tra cột is_updatable của 5 view vừa tạo trong information_schema
SELECT TABLE_NAME, IS_UPDATABLE 
FROM information_schema.views 
WHERE TABLE_SCHEMA = 'mediatheque';