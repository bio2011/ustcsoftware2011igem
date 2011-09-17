# egfr_simple.sql

DROP TABLE IF EXISTS egfr_simple;
#@ _CREATE_TABLE_
CREATE TABLE egfr_simple
(
	name VARCHAR(255) NOT NULL,
    reactant_patterns VARCHAR(255) NULL,
    product_patterns VARCHAR(255) NULL,
    is_reversible ENUM('True','False') NULL default 'False',
    forward_rate_law  VARCHAR(255) NOT NULL, 
    reverse_rate_law  VARCHAR(255) NULL, 
    PRIMARY KEY (name)
);
#@ _CREATE_TABLE_

INSERT INTO egfr_simple (name,reactant_patterns,product_patterns,is_reversible,forward_rate_law,reverse_rate_law) VALUES

	#	Ligand-receptor binding
	('binding_EGFR_EGF','p:EGFR(L,CR1);p:EGF(R)','p:EGFR(L!1,CR1).p:EGF(R!1)','True','mass_action_2(1.49501661129568e-06,#1,#2)','mass_action_1(0.06,#1)'),

	#	Receptor-aggregation
	('dimerization_EGFR','p:EGFR(L!+,CR1);p:EGFR(L!+,CR1)','p:EGFR(L!+,CR1!1).p:EGFR(L!+,CR1!1)','True','mass_action_2(5.53709856035438e-06,#1,#2)','mass_action_1(0.1,#1)'),

	#	Transphosphorylation of EGFR by RTK
	('phosphorylation_EGFR','p:EGFR(CR1!+,Y1068~U)','p:EGFR(CR1!+,Y1068~P)','False','mass_action_1(0.5,#1)',''),

	#	Dephosphorylation
	('dephosphorylation_EGFR','p:EGFR(Y1068~P)','p:EGFR(Y1068~U)','False','mass_action_1(4.505,#1)',''),

	#	Grb2 binding to pY1068
	('binding_EGFR_Grb2','p:EGFR(Y1068~P);p:Grb2(SH2)','p:EGFR(Y1068!1~P).p:Grb2(SH2!1)','True','mass_action_2(8.30564784053156e-07,#1,#2)','mass_action_1(0.05,#1)'),

	#	Grb2 binding to Sos1
	('binding_Grb2_Sos1','p:Grb2(SH3);p:Sos1(PxxP)','p:Grb2(SH3!1).p:Sos1(PxxP!1)','True','mass_action_2(5.53709856035438e-06,#1,#2)','mass_action_1(0.06,#1)'),

	#	Receptor dimer internalization/degradation
	('dimerization_EGFR2_EGF2','p:EGF(R!1).p:EGF(R!2).p:EGFR(L!1,CR1!3).p:EGFR(L!2,CR1!3)','','False','mass_action_1(0.01,#1)','');
