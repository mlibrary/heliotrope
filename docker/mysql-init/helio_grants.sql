-- idempotent init script for helio user and database
CREATE DATABASE IF NOT EXISTS `heliotrope_development` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `heliotrope_test` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'helio'@'%' IDENTIFIED BY 'helio';
GRANT CREATE, ALTER, DROP, INSERT, UPDATE, DELETE, SELECT, REFERENCES ON `heliotrope_development`.* TO 'helio'@'%';
GRANT CREATE, ALTER, DROP, INSERT, UPDATE, DELETE, SELECT, REFERENCES ON `heliotrope_test`.* TO 'helio'@'%';
FLUSH PRIVILEG