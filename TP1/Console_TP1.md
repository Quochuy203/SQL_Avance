# Étape 1: sudo apt update && sudo install mysql-client-y
# Étape 2: mysql --version : Vérifier la commande a été exécuté
# Étape 3: [ mysql -u root -p < Base/01-schema.sql ] && [ mysql -u root -p < Base/02-donner]: recharger les données dans 2 fichiers 01 et 02
# Étape 4: sudo apt install mysql -serveur -y: Pour assurer Mysql Serveur a bien install ou pas
# Étape 5: sudo service mysql status: démarrer sercice Mysql Serveur
# Étape 6: [ mysql -u root -p < Base/01-schema.sql ] && [ mysql -u root -p < Base/02-donner]


# Test: [1-5]

# Étape 1: mysql -u app_media      pw: AppMedia!2026
# - SELECT CURRENT_ROLE();: (VN) truy vấn trực tiếp vào Hệ thống Quản lý Quyền hạn (MySQL Privilege System & Information Schema) nằm trong bộ nhớ hệ thống của MySQL Server (cụ thể là các bảng hệ thống ẩn nằm trong database mysql).                      (FR): Cela implique d'interroger directement le système de privilèges et le schéma d'informations MySQL situés dans la mémoire système du serveur MySQL (plus précisément, les tables système cachées au sein de la base de données MySQL).
# Résultat: `role_catalogue`@`%`,`role_prets`@`%

# Étape2: Après avoir dans app_media --> SELECT id, nom, prenom FROM adherent LIMIT 5;
# Résultat: 
#               | id | nom      | prenom  |
#               +----+----------+---------+
#               |  1 | Durand   | Antoine |   
#               |  2 | Garcia   | Zoe     |
#               |  3 | Girard   | Tom     |
#               |  4 | Francois | Emma    |
#               |  5 | Richard  | Paul    |
#               +----+----------+---------+
# Comment SELECT id, nom, prenom FROM adherent LIMIT 5; fonction ? -> ça prend id, nom, prenom les 5s premieres donnee dans tableau adherent 

# Étape3: Après avoir dans app_media --> SELECT email FROM adherent LIMIT 1;
# Resultat: Refuser (1143/42000): pcq cols email est pas dans la liste de permetion

# Étape4: Après avoir dans app_media --> UPDATE exemplaire SET disponible = 0 WHERE id = 3;
# Résultat: Query OK, 0 rows affected / Rows matched: 1  Changed: 0  Warnings: 0

# Étape5: Après avoir dans app_media --> UPDATE exemplaire SET etat = 'use' WHERE id = 3;
# Résultat: ERROR 1143 (42000): UPDATE command denied to user 'app_media'@'localhost' for column 'etat' in table 'exemplaire'

# [Test 6-7]

# Étape 1: mysql -u biblio_marie -p mediatheque     PW: MarieBiblio!2026
# - SELECT nom, email, telephone FROM adherent LIMIT 3;
# Résultat:  nom    | email                     | telephone      |
#           +--------+---------------------------+----------------+
#           | Durand | antoine.durand@example.fr | 04 78 11 27 33 |
#           | Garcia | zoe.garcia@example.fr     | 04 78 12 34 36 |
#           | Girard | tom.girard@example.fr     | 04 78 13 41 39 |

# Étape 2: CREATE USER 'test'@'localhost' IDENTIFIED BY 'Test!2026';
# Résultat: ERROR 1227 (42000): Access denied; you need (at least one of) the CREATE USER privilege(s) for this operation

# [ Test 8-9-10]
# Étape 1: mysql -u stagiaire -p mediatheque     pw: AppMedia!2026
# SELECT nom, prenom, ville FROM adherent LIMIT 5; 
# Résultat: | nom      | prenom  | ville            |
#           +----------+---------+------------------+
#           | Durand   | Antoine | Villeurbanne     |
#           | Garcia   | Zoe     | Rillieux-la-Pape |
#           | Girard   | Tom     | Caluire-et-Cuire |
#           | Francois | Emma    | Vaulx-en-Velin   |
#           | Richard  | Paul    | Bron             |
#           +----------+---------+------------------+

# Étape 2: SELECT email FROM adherent LIMIT 1;
# Résultat: ERROR 1143 (42000): SELECT command denied to user 'stagiaire'@'localhost' for column 'email' in table 'adherent'

# Étape 3: SELECT * FROM adherent LIMIT 1;
# Résultat: ERROR 1142 (42000): SELECT command denied to user 'stagiaire'@'localhost' for table 'adherent'





















# 1. Nơi lấy dữ liệu để hiển thị (Đối với Test 1 & Test 3)
# Dữ liệu được lưu trữ trong cơ sở dữ liệu mediatheque, vốn đã được nạp từ hai file dữ liệu mẫu ở thư mục Base/
- Trong Test 1 (SELECT id, nom, prenom FROM adherent LIMIT 5;), MySQL truy vấn trực tiếp vào bảng adherent trong bộ nhớ/ổ đĩa. Dữ liệu 5 dòng Durand Antoine, Garcia Zoe,... được định nghĩa từ lệnh INSERT INTO adherent... bên trong file Base/02-donnees.sql.
- Trong Test 3 (UPDATE exemplaire SET disponible = 0 WHERE id = 3;), lệnh này tác động trực tiếp lên bản ghi có id = 3 của bảng exemplaire (được khởi tạo cấu trúc ở 01-schema.sql và nạp dữ liệu ban đầu ở 02-donnees.sql).
# 2. Nơi kiểm tra quyền để trả về lỗi (Đối với Test 2, Test 4 & Test 5)
- Các thông báo từ chối truy cập (ERROR 1143 hoặc ERROR 1142) không lấy dữ liệu từ các bảng nội dung, mà do hệ thống MySQL Privilege System đối chiếu với phân quyền mà bạn đã cài đặt trong file 01-roles-et-comptes.sql
- Test 2 (SELECT email FROM adherent...-> ERROR 1143):
MySQL kiểm tra bảng hệ thống mysql.columns_priv. Bạn chỉ gán quyền GRANT SELECT (id, nom, prenom, actif) cho app_media, nên khi gọi cột email, MySQL đối chiếu thấy không có quyền và lập tức chặn lại.
- Test 4 (UPDATE exemplaire SET etat = 'use'... $\rightarrow$ ERROR 1143):
Trong 01-roles-et-comptes.sql, bạn chỉ gán GRANT UPDATE (disponible) ON exemplaire TO role_prets. Do đó khi cố gắng sửa cột etat, MySQL từ chối vì cột này không được cấp quyền UPDATE.
- Test 5 (DELETE FROM emprunt...-> ERROR 1142):
MySQL kiểm tra bảng phân quyền cấp bảng (mysql.tables_priv). Tài khoản app_media chỉ có các quyền SELECT, INSERT, UPDATE thông qua role_prets và hoàn toàn không có quyền DELETE, nên hệ thống trả về lỗi từ chối thao tác trên bảng emprunt.





