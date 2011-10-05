# amitosis.sql

DROP TABLE IF EXISTS amitosis;
#@ _CREATE_TABLE_
CREATE TABLE amitosis
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

INSERT INTO amitosis (name,reactant_patterns,product_patterns,is_reversible,forward_rate_law,reverse_rate_law) VALUES

#	---------------
#	ci434 regulation
#	---------------

	#	ci434 dimerize
	('dimerization_ci434','p:ci434(dim,dna);p:ci434(dim,dna)','p:ci434(dim!1,dna).p:ci434(dim!1,dna)','True','mass_action_2(1.79e7,#1,#2)','mass_action_1(10,#1)'),

	#	ci434 dimer binds to prm
	('binding_ci434_2_prm','p:ci434(dna,dim!1).p:ci434(dna,dim!1);d:X1-prm(ci434_1,ci434_2)-X2','p:ci434(dna!1,dim!3).p:ci434(dna!2,dim!3).d:X1-prm(ci434_1!1,ci434_2!2)-X2','True','mass_action_2(1e8,#1,#2)','mass_action_1(1e-2,#1)'),

#	---------------
#	ci regulation
#	---------------

	#	ci dimerize
	('dimerization_ci','p:ci(dim,dna);p:ci(dim,dna)','p:ci(dim!1,dna).p:ci(dim!1,dna)','True','mass_action_2(1.25e7,#1,#2)','mass_action_1(10,#1)'),

	#	ci dimer binds to pr
	('binding_ci2_pr','p:ci(dna,dim!1).p:ci(dna,dim!1);d:X1-pr(ci1,ci2)-X2','p:ci(dna!1,dim!3).p:ci(dna!2,dim!3).d:X1-pr(ci1!1,ci2!2)-X2','True','mass_action_2(2e10,#1,#2)','mass_action_1(0.04,#1)'),

#	---------------
#	plas regulation
#	---------------

	#	AHL binds to LasR 
	('binding_lasr_ahl','p:lasr(ahl,dna);nb:ahl(lasr)','p:lasr(ahl!1,dna).nb:ahl(lasr!1)','True','mass_action_2(1.54e5,#1,#2)','mass_action_1(0.2,#1)'),

	#	LasR dimerize
	('dimerization_lasr','p:lasr(dim,dna);p:lasr(dim,dna)','p:lasr(dim!1,dna).p:lasr(dim!1,dna)','True','mass_action_2(1.25e7,#1,#2)','mass_action_1(10,#1)'),

	#	LasR dimer binds to pLas	
	('binding_lasr2_plas','p:lasr(dna,ahl!+,dim!1).p:lasr(dna,ahl!+,dim!1);d:X1-plas(lasr1,lasr2)-X2','p:lasr(dna!1,ahl!+,dim!3).p:lasr(dna!2,ahl!+,dim!3).d:X1-plas(lasr1!1,lasr2!2)-X2','True','mass_action_2(2e10,#1,#2)','mass_action_1(0.04,#1)'),

#	------------------------------
#	Transcriptions
#	------------------------------

	#	activated pr promoter
	('transcription_pr','@d:X1-pr(ci1,ci2)-X2!>-term()-X3','r:X2','False','mass_action_1(0.5,#1)',NULL),

	#	leaky expression of pr promoter
	('transcription_pr_leakness','@d:X1-pr(ci1!+,ci2!+)-X2!>-term()-X3','r:X2','False','mass_action_1(0.0005,#1)',NULL),

	#	activated prm promoter
	('transcription_prm','@d:X1-prm(ci434_1,ci434_2)-X2!>-term()-X3','r:X2','False','mass_action_1(0.5,#1)',NULL),

	#	leaky expression of prm promoter
	('transcription_prm_leakness','@d:X1-prm(ci434_1!+,ci434_2!+)-X2!>-term()-X3','r:X2','False','mass_action_1(0.0005,#1)',NULL),

	#	activated plas promoter
	('transcription_plas','@d:X1-plas(lasr1!+,lasr2!+)-X2!>-term()-X3','r:X2','False','mass_action_1(0.5,#1)',NULL),

	#	leaky expression of plas promoter
	('transcription_plas_leakness','@d:X1-plas(lasr1,lasr2)-X2!>-term()-X3','r:X2','False','mass_action_1(0.0005,#1)',NULL),

#	------------------------------
#	Riboswitch
#	------------------------------
	
	#	theophylline activating aptamer
	('unlock_theophylline_by_aptamer','@nb:theo();r:X1-aptamer(rib~off)-X2','r:X1-aptamer(rib~on)-X2','False','hill_kinetics(7.6,#2,1,9e-4,#1)',NULL),

#	------------------------------
#	synthesize AHL
#	------------------------------
	
	#	Lasi
	('synthesis_ahl_by_lasi','@p:lasi()','nb:ahl(lasr)','False','mass_action_1(0.04,#1)',NULL),

#	------------------------------
#	Translations
#	------------------------------
	
	#	rbs
	('translation_rbs','@r:X1-rbs()-X2!1-X3','p:X2','False','mass_action_1(0.01155,#1)',NULL),

	#	aptamer
	('translation_aptamer','@r:X1-aptamer(rib~on)-X2!1-X3','p:X2','False','mass_action_1(0.01155,#1)',NULL),

#	------------------------------
#	Degradation of RNAs
#	------------------------------
	
	#	unified form of mRNA degradation
	('degradation_mRNA_x','r:X','','False','mass_action_1(0.005783,#1)',NULL),

#	------------------------------
#	Degradation of Proteins
#	------------------------------

	#	GFP protein 
	('degradation_prot_gfp','p:gfp()','','False','mass_action_1(2.31e-3,#1)',NULL),

	#	RFP protein 
	('degradation_prot_rfp','p:rfp()','','False','mass_action_1(2.31e-3,#1)',NULL),

	#	LasI protein 
	('degradation_prot_lasi','p:lasi()','','False','mass_action_1(2.31e-3,#1)',NULL),

	#	LasR protein (monomer)
	('degradation_prot_lasr','p:lasr(dim)','','False','mass_action_1(2.31e-3,#1)',NULL),

	#	CheZ protein
	('degradation_prot_chez','p:chez()','','False','mass_action_1(2.31e-3,#1)',NULL),

	#	CI protein (monomer)
	('degradation_prot_ci','p:ci(dim)','','False','mass_action_1(2.31e-3,#1)',NULL),

	#	CI protein (monomer)
	('degradation_prot_ci434','p:ci434(dim)','','False','mass_action_1(2.31e-3,#1)',NULL),

#	------------------------------
#	Degradation of Inducers
#	------------------------------
	
	#	theophylline
	('degradation_theophylline','nb:theo()','','False','mass_action_1(0.35,#1)',NULL),

	#	AHL
	('degradation_ahl','nb:ahl()','','False','mass_action_1(0.35,#1)',NULL);
