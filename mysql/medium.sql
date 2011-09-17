#	medium.sql

DROP TABLE IF EXISTS medium;
#@ _CREATE_TABLE_
CREATE TABLE medium
(
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,  
	name VARCHAR(255) NULL,
    reactant_patterns VARCHAR(255) NULL,
    product_patterns  VARCHAR(255) NULL,
    is_reversible ENUM('True','False') NULL default 'False',
    forward_rate_law  VARCHAR(255) NOT NULL, 
    reverse_rate_law VARCHAR(255)  NULL, 
    PRIMARY KEY (id)
);
#@ _CREATE_TABLE_
