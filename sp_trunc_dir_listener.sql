CREATE PROCEDURE [dbo].[sp_trunc_dir_listener] 

AS

--drop
alter table t_dir_listener drop constraint FK_t_dir_listener_t_client

alter table t_dir_listener drop constraint FK_t_dir_listener_t_queue

alter table t_dir_listener drop constraint FK_t_dir_listener_t_server

alter table t_dir_monitor drop constraint FK_t_dir_monitor_t_dir_listener


truncate table t_dir_monitor
Truncate table t_dir_listener 

--create
alter table t_dir_listener 
add constraint FK_t_dir_listener_t_client 
FOREIGN KEY 
	(
		[client_id]
	) REFERENCES t_client (client_id)


alter table t_dir_listener add constraint FK_t_dir_listener_t_queue
FOREIGN KEY 
	(
		[queue_id]
	) REFERENCES t_queue (queue_id)


alter table t_dir_listener add constraint FK_t_dir_listener_t_server
FOREIGN KEY 
	(
		[queue_server_id]
	) REFERENCES t_server (server_id)


alter table t_dir_monitor add constraint FK_t_dir_monitor_t_dir_listener
FOREIGN KEY 
	(
		[dir_listener_id]
	) REFERENCES t_dir_listener (dir_listener_id)
GO
