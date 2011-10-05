#	inducer.sql
#	each item is transportation between compartments with assigned tables

DROP TABLE IF EXISTS inducer;
#@ _CREATE_TABLE_
CREATE TABLE inducer
(
	species	CHAR(20)	NOT NULL,
	rule_table_name_out	CHAR(20)	NOT NULL,
	rule_table_name_in	CHAR(20)	NOT NULL,
	transport_rate_out	FLOAT(12,4)	NOT NULL,
	transport_rate_in	FLOAT(12,4)	NOT NULL
);
#@ _CREATE_TABLE_

INSERT INTO inducer (species,rule_table_name_out,rule_table_name_in,transport_rate_out,transport_rate_in) VALUES

#	---------------
#	IPTG
#	---------------
	('nb:i0001(laci)','medium','toggle_switch','0.1','0.1'),

#	---------------
#	aTc
#	---------------
	('nb:i0002(tetr)','medium','toggle_switch','0.1','0.1'),

#	---------------
#	Arabinose
#	---------------
	('nb:i0003(arac)','medium','rtc2_counter','0.2','0.2'),

#	---------------
#	Theophylline
#	---------------
	('nb:theo()','medium','amitosis','0.1','0.1'),

#	---------------
#	AHL
#	---------------
	('nb:ahl(lasr)','medium','amitosis','0.1','0.1');
