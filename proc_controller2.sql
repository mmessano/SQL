sp_ins_server Vendor3, 4, ' ',1

1	DB                     0	PROD
2	Web                    1	DEMO                             
3	App                    2	IMP                              
4	Connection             3	DEVT                             
5	FileServer             4	FHHLC Production                 
6	PGP                    5	FHHLC Staging                    
7	Mapping                6	Infrastrucutre                   
8	Queueing               7	Non Dexma                        
                               8	Operations
                               9	QA
                               10	Hot Spare


select * from t_server order by active


update t_server set active = '1' where server_name = 'vendor1'

update t_server_type_assoc set type_id = '3' where server_id in ('45','46','47')
update t_server_type_assoc set type_id = '3' where server_id '45'

sp_ins_server_type_assoc Xdev2krs1, App
sp_ins_server_type_assoc 'chara', Web
sp_ins_server_type_assoc hercules, DB
sp_ins_server_type_assoc capella, Queueing
sp_ins_server_type_assoc paftp1, Connection
sp_ins_server_type_assoc boston, PGP
sp_ins_server_type_assoc xfs2, FileServer
sp_ins_server_type_assoc mira, HNC
sp_ins_server_type_assoc scotch2, Security
sp_ins_server_type_assoc xns2, DNS
sp_ins_server_type_assoc ximp2kodi, ODI
sp_ins_server_type_assoc 'alcor', Other
sp_ins_server_type_assoc 'naos', Accounting

select * from t_server_type
sp_ins_server_type 'Accounting'

sp_ins_proc_controller 'fanniemaeconditionsandtasksgenerator'
sp_ins_queue 'digitaldocspostprocessor', ' '


update t_server_type_assoc set type_id = '16' where server_id in ('1','2','3','4','5','210')
delete  from t_server_type_assoc where server_id = '189' and type_id = '3'
update t_server set environment_id = '' where server_id in ('')

delete from t_server where server_name in ('messano338')

delete from t_server_type_assoc where server_id in ('17','53','51','38')

