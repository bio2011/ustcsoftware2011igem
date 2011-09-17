# rtc2_counter.sql

DROP TABLE IF EXISTS rtc2_counter;
#@ _CREATE_TABLE_
CREATE TABLE rtc2_counter
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

INSERT INTO rtc2_counter (name,reactant_patterns,product_patterns,is_reversible,forward_rate_law,reverse_rate_law) VALUES

#	---------------
#	AraC regulation
#	---------------

	#	Arabinose binds to AraC
	('binding_AraC_Arabinose','p:c0080(arab,dna);nb:i0003(arac)','p:c0080(arab!1,dna).nb:i0003(arac!1)','True','mass_action_2(1e8,#1,#2)','mass_action_1(10,#1)'),

	#	AraC dimerize
	('dimerization_AraC','p:c0080(dim,dna);p:c0080(dim,dna)','p:c0080(dim!1,dna).p:c0080(dim!1,dna)','True','mass_action_2(1e9,#1,#2)','mass_action_1(0.1,#1)'),

	#	AraC dimer binds to pBAD 
	('binding_AraC2_pBAD','p:c0080(arab,dna,dim!1).p:c0080(arab,dna,dim!1);d:X1-i0500(arac1,arac2)-X2','p:c0080(dna!1,arab,dim!3).p:c0080(dna!2,arab,dim!3).d:X1-i0500(arac1!1,arac2!2)-X2','True','mass_action_2(7.1e10,#1,#2)','mass_action_1(0.01,#1)'),

#	-------------------------
#	T7 RNAp binds to pT7
#	-------------------------

	('binding_pT7_T7rnap','p:i2032(dna);d:X1-r0085(rnap)-X2','p:i2032(dna!1).d:X1-r0085(rnap!1)-X2','True','mass_action_2(2e6,#1,#2)','mass_action_1(0.06,#1)'),

#	------------------------------
#	Transcriptions
#	------------------------------

	#	T7 promoter
	('transcription_pT7','@d:X1-r0085(rnap!+)-X2!>-b0014()-X3','r:X2','False','mass_action_1(0.5,#1)',NULL),

	#	leaky expression of T7 promoter
	#	('transcription_pT7_leakness','@d:X1-r0085(rnap)-X2!>-b0014()-X3','r:X2','False','mass_action_1(3.0e-4,#1)',NULL),

	#	pBAD promoter
	('transcription_pBAD','@d:X1-i0500(arac1,arac2)-X2!>-b0014()-X3','r:X2','False','mass_action_1(0.1,#1)',NULL),

	#	leaky expression of pBAD promoter
	#('transcription_pBAD_leakness','@d:X1-i0500(arac1!+,arac2!+)-X2!>-b0014()-X3','r:X2','False','mass_action_1(0.0005,#1)',NULL),

	#	constitutive promoter j23100
	('transcription_j23100','@d:X1-j23100()-X2!>-b0014()-X3','r:X2','False','mass_action_1(1.5,#1)',NULL),

#	------------------------------
#	Translations
#	------------------------------
	
	#	ribosome binding site crR12
	('translation_rbs_crR12','@r:X1-j01010(rib~on)-X2!1-X3','p:X2','False','mass_action_1(0.1,#1)',NULL),

#	------------------------------
#	Riboswitch
#	------------------------------

	#	taR12 unlock crR12
	('unlock_crR12_by_taR12','r:X3-j01010(rib~off)-X4;@r:X1-j01008()-X2','r:X3-j01010(rib~on)-X4','False','hill_kinetics(7.6,#2,1,9e-4,#1)',NULL),

#	------------------------------
#	Degradation of RNAs
#	------------------------------
	
	#	GFP mRNA
	('degradation_mRNA_gfp','r:X1-e0040()-X2','','False','mass_action_1(0.07,#1)',NULL),
	
	#	T7 Rnap mRNA
	('degradation_mRNA_t7rnap','r:X1-i2032()-X2','','False','mass_action_1(0.0706,#1)',NULL),

	#	Arac mRNA
	#('degradation_mRNA_arac','r:X1-c0080()-X2','','False','mass_action_1(0.01,#1)',NULL),

	#	j01008 mRNA
	('degradation_mRNA_j01008','r:j01008()','','False','mass_action_1(1.67e-1,#1)',NULL),

#	------------------------------
#	Degradation of Proteins
#	------------------------------

	#	T7 Rnap 
	('degradation_t7_rnap','p:i2032()','','False','mass_action_1(0.0056,#1)',NULL),

	#	AraC cannot degrade
	#	('degradation_prot_arac','p:c0080(dna)','','False','mass_action_1(6.6667e-3,#1)',NULL),

	#	GFP 
	('degradation_prot_gfp','p:e0040()','','False','mass_action_1(0.0015,#1)',NULL),

#	------------------------------
#	Degradation of Inducers
#	------------------------------
	
	#	Arabinose
	('degradation_inducer_arabinose','nb:i0003()','','False','mass_action_1(0.35,#1)',NULL);
