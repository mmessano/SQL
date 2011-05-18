select * from Server_View
select * from servers_and_queues
select * from dpc_view
exec sp_rem_queue_server_assoc 'zeus','emagicdexrsosender'

select * from Server_View where server_name like 'sir%'

select server_name from t_server  where server_name like 'sir%'

 
select server_name from t_server where active = '1' and environment_id = '0' order by server_name, timestamp desc

select * from t_proc_controller_assoc where server_id = (select server_id from t_server where server_name = 'xqa2kapp2')

delete from t_proc_controller_assoc where server_id = (select server_id from t_server where server_name = 'zeus')

select component_name from t_component order by component_name