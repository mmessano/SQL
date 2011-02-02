---------------------------------------------------------------------------------
-- delete retired servers
delete from t_queue_server_assoc where server_id IN
(
select distinct s.server_id--s.server_name, q.queue_name
	from t_server s INNER JOIN
		t_queue_server_assoc qsa ON s.server_id = qsa.server_id INNER JOIN
		t_queue q ON q.queue_id = qsa.queue_id
	where s.active = '0'
)
---------------------------------------------------------------------------------