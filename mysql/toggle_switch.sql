# toggle_switch.sql

DROP TABLE IF EXISTS toggle_switch;
#@ _CREATE_TABLE_
CREATE TABLE toggle_switch
(
	name VARCHAR(255)	NOT NULL,
    reactant_patterns	VARCHAR(255) NULL,
    product_patterns    VARCHAR(255) NULL,
    is_reversible ENUM('True','False') NULL default 'False',
    forward_rate_law	VARCHAR(255) NOT NULL, 
    reverse_rate_law	VARCHAR(255) NULL,
	PRIMARY KEY (name)
);
#@ _CREATE_TABLE_

INSERT INTO toggle_switch (name,reactant_patterns,product_patterns,is_reversible,forward_rate_law,reverse_rate_law) VALUES

#	---------------
#	TetR regulation
#	---------------

	#	aTc binds to TetR
	('binding_TetR_aTc','p:c0040(atc,dna);nb:i0002(tetr)','p:c0040(atc!1,dna).nb:i0002(tetr!1)','True','mass_action_2(7.40e6,#1,#2)','mass_action_1(3.70e-5,#1)'),

	#	TetR dimerize
	('dimerization_TetR','p:c0040(dim,dna);p:c0040(dim,dna)','p:c0040(dim!1,dna).p:c0040(dim!1,dna)','True','mass_action_2(1.79e7,#1,#2)','mass_action_1(10,#1)'),

	#	TetR dimer binds to pTet
	('binding_TetR2_pTet','p:c0040(dna,atc,dim!1).p:c0040(dna,atc,dim!1);d:X1-r0040(tetr1,tetr2)-X2','p:c0040(dna!1,atc,dim!3).p:c0040(dna!2,atc,dim!3).d:X1-r0040(tetr1!1,tetr2!2)-X2','True','mass_action_2(1e8,#1,#2)','mass_action_1(1e-2,#1)'),

#	---------------
#	LacI regulation
#	---------------

	#	IPTG binds to LacI
	('binding_LacI_IPTG','p:c0012(iptg,dna);nb:i0001(laci)','p:c0012(iptg!1,dna).nb:i0001(laci!1)','True','mass_action_2(1.54e5,#1,#2)','mass_action_1(0.2,#1)'),

	#	LacI dimerize
	('dimerization_LacI','p:c0012(dim,dna);p:c0012(dim,dna)','p:c0012(dim!1,dna).p:c0012(dim!1,dna)','True','mass_action_2(1.25e7,#1,#2)','mass_action_1(10,#1)'),

	#	LacI dimer binds to pLac
	('binding_LacI2_pLac','p:c0012(dna,iptg,dim!1).p:c0012(dna,iptg,dim!1);d:X1-r0010(laci1,laci2)-X2','p:c0012(dna!1,iptg,dim!3).p:c0012(dna!2,iptg,dim!3).d:X1-r0010(laci1!1,laci2!2)-X2','True','mass_action_2(2e10,#1,#2)','mass_action_1(0.04,#1)'),

#	------------------------------
#	Transcriptions
#	------------------------------

	#	free lac promoter
	('transcription_pLac','@d:X1-r0010(laci1,laci2)-X2!>-b0014()-X3','r:X2','False','mass_action_1(0.5,#1)',NULL),

	#	leaky expression of lac promoter
	('transcription_plac_leakness','@d:X1-r0010(laci1!+,laci2!+)-X2!>-b0014()-X3','r:X2','False','mass_action_1(0.0005,#1)',NULL),

	#	free tet promoter
	('transcription_pTet','@d:X1-r0040(tetr1,tetr2)-X2!>-b0014()-X3','r:X2','False','mass_action_1(0.5,#1)',NULL),

	#	leaky expression of tet promoter
	('transcription_pTet_leakness','@d:X1-r0040(tetr1!+,tetr2!+)-X2!>-b0014()-X3','r:X2','False','mass_action_1(0.0005,#1)',NULL),

#	------------------------------
#	Translations
#	------------------------------
	
	#	ribosome binding site b0034
	('translation_rbs_b0034','@r:X1-b0034()-X2!1-X3','p:X2','False','mass_action_1(0.01155,#1)',NULL),

#	------------------------------
#	Degradation of RNAs
#	------------------------------
	
	#	laci mRNA
	('degradation_mRNA_laci','r:X1-c0012()-X2','','False','mass_action_1(0.005783,#1)',NULL),

	#	tetr mRNA1
	('degradation_mRNA_tetr','r:X1-c0040()-X2','','False','mass_action_1(0.005783,#1)',NULL),

#	------------------------------
#	Degradation of Proteins
#	------------------------------

	#	LacI protein (monomer)
	('degradation_prot_LacI','p:c0012(dim)','','False','mass_action_1(2.31e-3,#1)',NULL),

	#	TetR protein (monomer)
	('degradation_prot_TetR','p:c0040(dim)','','False','mass_action_1(2.31e-3,#1)',NULL);
