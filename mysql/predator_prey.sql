#	predator_prey.sql
#	BioNetGen Wiki, Example "predator_prey"

DROP TABLE IF EXISTS predator_prey;
#@ _CREATE_TABLE_
CREATE TABLE predator_prey
(
	name VARCHAR(255) NOT NULL,
    reactant_patterns VARCHAR(255) NULL,
    product_patterns  VARCHAR(255) NULL,
    is_reversible ENUM('True','False') NULL default 'False',
    forward_rate_law  VARCHAR(255) NOT NULL, 
    reverse_rate_law VARCHAR(255)  NULL, 
    PRIMARY KEY (name)
);
#@ _CREATE_TABLE_

INSERT INTO predator_prey (name,reactant_patterns,product_patterns,is_reversible,forward_rate_law,reverse_rate_law) VALUES

	#	Prey reproduces
	('prey_reproduces','nb:X()','nb:X();nb:X()','False','mass_action_1(0.4,#1)',''),

	#	Predator reproduces
	('predator_reproduces','nb:Y();nb:X()','nb:X();nb:Y();nb:Y()','False','mass_action_2(0.002,#1,#2)',''),

	#	Predator eats prey
	('predator_eats_prey','nb:X();nb:Y()','nb:Y()','False','mass_action_2(0.01,#1,#2)',''),

	#	Predator dies
	('predator_dies','nb:Y()','','False','mass_action_1(0.3,#1)','');
