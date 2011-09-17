# function.sql

DROP TABLE IF EXISTS function;
#@ _CREATE_TABLE_
CREATE TABLE function
(
	name		VARCHAR(255)     NOT NULL,
	parameters	VARCHAR(255)	 NOT NULL,
    expression  VARCHAR(255)	 NOT NULL
);
#@ _CREATE_TABLE_

INSERT INTO function (name,parameters,expression) VALUES

#	basal rate
    ('basal_rate','k','k'),

#	MassAction-one
	('mass_action_1','k,x','k*x'),

#	MassAction-two
	('mass_action_2','k,x,y','k*x*y'),

#	MassAction-reversible
	('mass_action_reversible','kf,kr,x,y','kf*x-kr*y'),

#	Hill kinetics 
	('hill_kinetics','kcat,E0,n,Kp,S','kcat*E0*S^n/(Kp+S^n)'),

#	Henri-Michaelis-Menten
	('henri_michaelis_menten','Vm,Km,S','Vm*S/(Km+S)'),

#	Henri-Michaelis-Menten-Reversible
	('henri_michaelis_menten_reversible','Vmf,Ks,Vmr,Kp,S,P','(Vmf*S/Ks-Vmr*P/Kp)/(1+S/Ks+P/Kp)'),

#	Iso-Uni-UNi
	('iso_uni_uni','Vmf,Keq,Kms,Kmp,Kiip,S,P','Vmf*(S-P/Keq)/(Kms*(1+P/Kmp)+S*(1+P/Kiip))'),

#	Ordered-Bi-Bi
	('ordered_bi_bi','Vm,Ksa,Ksb,Kma,A,B','Vm/(Ksa*Ksb/A/B+Kma/A+Kmb/B+1)'),

#	Ping-Pong-Bi-Bi
	('ping_pong_bi_bi','Vm,Kma,Kmb,A,B','Vm/(Kma/A+Kmb/B+1)'),

#	Competitive-Inhibition
	('competitive_inhibition','Vm,Km,Ki,S,I','Vm*S/(Km*(1+I/Ki)+S)'),

#	NonCompetitive-Inhibition
	('noncompetitive_inhibition','Vm,Ks,Ki,S,I','Vm*S/((Ks+S)*(1+I/Ki))'),

#	UnCompetitive-Inhibition
	('uncompetitive_inhibition','Vm,Km,Ki,S,I','Vm*S/(Km+S*(1+I/Ki))'),

#	Enzyme-inactive-active
	('enzyme_inactive_active','K1,K2,x,y','x*K1*(1-y)/(1-y+K2)'),

#	Enzyme-active-inactive
	('enzyme_active_inactive','K1,K2,x,y','x*K1*y/(y+K2)');
