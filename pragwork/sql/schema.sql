SET CHARSET utf8;
DROP DATABASE IF EXISTS pragwork;
CREATE DATABASE pragwork CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL ON pragwork.* to 'pragwork'@'localhost';
SET PASSWORD FOR 'pragwork'@'localhost' = PASSWORD('secret');
USE pragwork;
