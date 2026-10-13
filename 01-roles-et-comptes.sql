USE mediatheque;

-- =====================================================================
-- 0. DỌN DẸP TRƯỚC KHI TẠO (Đảm bảo script có thể re-play nhiều lần)
-- =====================================================================
DROP USER IF EXISTS 'app_media'@'localhost';
DROP USER IF EXISTS 'biblio_marie'@'localhost';
DROP USER IF EXISTS 'stagiaire'@'localhost';
DROP USER IF EXISTS 'analyste'@'localhost';

DROP ROLE IF EXISTS role_catalogue;
DROP ROLE IF EXISTS role_prets;
DROP ROLE IF EXISTS role_adherents;

-- =====================================================================
-- 1. TẠO 3 RÔ-LE (ROLES) VÀ GÁN QUYỀN
-- =====================================================================
-- Rô-le 1: Catalogue (Chỉ đọc thông tin sách, bản sao, thể loại)
CREATE ROLE role_catalogue;
GRANT SELECT ON mediatheque.ouvrage TO role_catalogue;
GRANT SELECT ON mediatheque.exemplaire TO role_catalogue;
GRANT SELECT ON mediatheque.categorie TO role_catalogue;

-- Rô-le 2: Prêts (Quản lý mượn/trả, đặt trước, phạt + Cập nhật cột disponible trên exemplaire)
CREATE ROLE role_prets;
GRANT SELECT, INSERT, UPDATE ON mediatheque.emprunt TO role_prets;
GRANT SELECT, INSERT, UPDATE ON mediatheque.reservation TO role_prets;
GRANT SELECT, INSERT, UPDATE ON mediatheque.penalite TO role_prets;
GRANT UPDATE (disponible) ON mediatheque.exemplaire TO role_prets;

-- Rô-le 3: Adhérents (Quản lý hồ sơ thành viên)
CREATE ROLE role_adherents;
GRANT SELECT, INSERT, UPDATE ON mediatheque.adherent TO role_adherents;

-- =====================================================================
-- 2. TẠO 4 TÀI KHOẢN (USERS) VÀ PHÂN QUYỀN
-- =====================================================================
-- Account 1: app_media (Ứng dụng web)
CREATE USER 'app_media'@'localhost' IDENTIFIED BY 'AppMedia!2026';
GRANT role_catalogue, role_prets TO 'app_media'@'localhost';
GRANT SELECT (id, nom, prenom, actif) ON mediatheque.adherent TO 'app_media'@'localhost';
ALTER USER 'app_media'@'localhost' DEFAULT ROLE role_catalogue, role_prets;

-- Account 2: biblio_marie (Thủ thư)
CREATE USER 'biblio_marie'@'localhost' IDENTIFIED BY 'MarieBiblio!2026';
GRANT role_catalogue, role_prets, role_adherents TO 'biblio_marie'@'localhost';
-- [ĐÃ SỬA]: Sửa 'role_adherent' thành đúng tên 'role_adherents'
ALTER USER 'biblio_marie'@'localhost' DEFAULT ROLE role_catalogue, role_prets, role_adherents;

-- Account 3: stagiaire (Thực tập sinh)
CREATE USER 'stagiaire'@'localhost' IDENTIFIED BY 'Stagiaire!2026';
GRANT role_catalogue TO 'stagiaire'@'localhost';
GRANT SELECT (id, nom, prenom, ville, date_inscription, actif) ON mediatheque.adherent TO 'stagiaire'@'localhost';
ALTER USER 'stagiaire'@'localhost' DEFAULT ROLE role_catalogue;

-- Account 4: analyste (Nhà phân tích thống kê)
CREATE USER 'analyste'@'localhost' IDENTIFIED BY 'AnalysteStat!2026';
GRANT role_catalogue TO 'analyste'@'localhost';
GRANT SELECT ON mediatheque.emprunt TO 'analyste'@'localhost';
-- [ĐÃ SỬA]: Sửa nhầm thành 'stagiaire' thành đúng 'analyste'
ALTER USER 'analyste'@'localhost' DEFAULT ROLE role_catalogue;

-- Kích hoạt tất cả rô-le mặc định khi người dùng đăng nhập
SET DEFAULT ROLE ALL TO 
  'app_media'@'localhost', 
  'biblio_marie'@'localhost', 
  'stagiaire'@'localhost', 
  'analyste'@'localhost';

-- =====================================================================
-- 3. KIỂM TRA QUYỀN & CHU KỲ GRANT / REVOKE
-- =====================================================================
-- Đọc quyền của từng tài khoản
SHOW GRANTS FOR 'app_media'@'localhost';
SHOW GRANTS FOR 'biblio_marie'@'localhost';
SHOW GRANTS FOR 'stagiaire'@'localhost';
SHOW GRANTS FOR 'analyste'@'localhost';

-- [ĐÃ SỬA]: Gộp đúng dòng lệnh đọc quyền cấp độ cột từ information_schema
SELECT * 
FROM information_schema.column_privileges 
WHERE table_schema = 'mediatheque';

-- Chu kỳ Grant -> Show -> Revoke -> Show trên tài khoản analyste với bảng reservation
GRANT SELECT ON mediatheque.reservation TO 'analyste'@'localhost';
SHOW GRANTS FOR 'analyste'@'localhost';

REVOKE SELECT ON mediatheque.reservation FROM 'analyste'@'localhost';
SHOW GRANTS FOR 'analyste'@'localhost';